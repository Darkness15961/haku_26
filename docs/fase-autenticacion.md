# HAKU — Fase de autenticación

Documento vivo. Avanzamos por bloques y etapas **solo cuando haga falta**, no por anticipación.  
Tú diseñas/aplicas la base en el VPS; el frontend se integra contra lo que exista en migraciones.

---

## Principios de trabajo

| Principio | Detalle |
|-----------|---------|
| Migraciones = historial | `supabase/migrations/` es el registro de lo aplicado. **No editar** archivos ya aplicados salvo excepción grave. Cambios nuevos = migración nueva + `db push` (tú, con túnel SSH). |
| Pull / push | Tú abres el túnel y ejecutas CLI. No compartir contraseñas del VPS en el chat. |
| Edge Functions | Se usan **cuando el caso lo pida** (SMTP avanzado, webhooks, jobs). No son requisito del Bloque A. |
| Decisiones | Lo más beneficioso para el proyecto en ese momento; no “porque es lo más rápido” a ciegas. |
| SDK oficial | Auth solo con `supabase_flutter` (`signUp`, `signInWithPassword`, `signInWithIdToken` / Google nativo). Sin HTTP manual a GoTrue. |
| Perfil público | Lecturas/updates de perfil van a `public.usuario` + RLS, no a `auth.users` desde la app. |

---

## Estado actual del backend (referencia)

Último esquema relevante en repo: `supabase/migrations/20260910200326_remote_schema.sql`.

### Listo / usable para Auth

| Objeto | Notas |
|--------|--------|
| `public.nacionalidad` | Catálogo ISO; RLS ON. Seed: migración `20260911040000_seed_nacionalidades_iso.sql` (tú la aplicas con push). |
| `public.usuario` | PK = `auth.users.id` (UUID), FK a nacionalidad. Columnas: `nombres`, `apellidos`, `nombre_nick`, `correo`, `foto_perfil`, `estado`, `nacionalidad_id`, `fecha_registro`. RLS ON. |
| `handle_new_user` + trigger `on_auth_user_created` | Ya en `remote_schema` (pull). |
| Auth (GoTrue) | Capa `auth` del self-host. |
| Storage policies | Bucket `haku-storage-produccion-2026` (actualizar/borrar dueño; insert autenticado). |

### Pendiente / limpiar

| Objeto | Acción sugerida |
|--------|-----------------|
| Funciones Bunny (`create_bunny_video`, `get_bunny_video_result`) + `pg_net` | Legado. No bloquean Auth; borrar cuando limpies el VPS. |
| `tabla_de_prueba` | Borrar cuando no sirva. |
| `documento` / `tipo_documento` | **No existen** en `usuario`. Fuera del MVP de registro (después, si aplica). |
| `001_fase1.sql` (si reaparece) | Borrador viejo. **No es la fuente de verdad.** Canónico: `public.usuario`. |

### Frontend (Auth MVP) — este repo

- Registro: **nombres, apellidos, nickname, correo, contraseña ×2, nacionalidad (buscable)**.
- Sin foto ni DNI/carnet (después). Login real + sesión Supabase; Google = Bloque B.
- Nacionalidad: `SELECT` a `public.nacionalidad` + sheet con búsqueda (no dropdown eterno).
- Configuración (tornillo): editar nombres/apellidos/nickname/nacionalidad, correo, contraseña y foto (`foto_perfil` = URL; Storage ahora, S3/MinIO después).
- Init: `main` → `inicializarSupabase()` → credenciales en `config_supabase.dart`.

---

## Mapa de la fase

```
FASE AUTENTICACIÓN
├── BLOQUE A — Correo y contraseña (registro nativo)   ← empezar aquí
│   ├── Etapa 1  Servidor (GoTrue / .env)
│   ├── Etapa 2  Registro Flutter (signUp + metadata)
│   ├── Etapa 3  Trigger → public.usuario
│   └── Etapa 4  Login (signInWithPassword + sesión)
└── BLOQUE B — Google OAuth
    ├── Etapa 1  GCP + .env VPS + redirect URLs          ← hecha (VPS)
    ├── Etapa 2  Deep link Android                       ← hecha
    ├── Etapa 3  signInWithOAuth (sin pantalla extra)    ← hecha
    └── Etapa 4  Reglas de oro / hand-off                 ← hecha
```

**Orden:** cerrar Bloque A usable → luego Bloque B.  
**Fuera de esta fase (después):** SMTP real, verificación de correo obligatoria, Edge Functions si hacen falta.

---

# BLOQUE A — Autenticación por correo y contraseña

Ruta más directa: sin Google Cloud ni deep links.

## Etapa 1 — Configuración en el servidor (GoTrue / Auth)

**Estado: HECHA** (autoconfirm activo en VPS).

**Objetivo:** GoTrue acepta signup/login por email sin depender de SMTP todavía.

| Paso | Qué | Estado |
|------|-----|--------|
| 1.1 | Confirmar proveedor email habilitado en `.env` del Docker (VPS) | Hecho |
| 1.2 | `ENABLE_EMAIL_AUTOCONFIRM=true` (o equivalente de tu versión GoTrue) | Hecho (MVP) |
| 1.3 | Documentar rollback: cuando haya SMTP → `false` + verificación obligatoria | **PENDIENTE** (post-MVP) |

### Flag: autoconfirm

- **Ahora (`true`):** al registrarse, el usuario puede entrar sin abrir el correo. Ideal para probar Flutter ↔ Auth ↔ trigger.
- **Riesgo:** cualquiera puede poner un correo inventado.
- **Luego (`false` + SMTP):** el flujo correcto de producto. Probar con proveedor externo (Resend, Brevo, Amazon SES, etc.).

### ¿Qué es SMTP?

Protocolo estándar para **enviar** correo. No es un “producto” que compras: es lo que usa GoTrue (vía un proveedor) para mandar el link de confirmación / reset.  
**Investigar 2 opciones** y elegir una cuando salgamos del MVP autoconfirm. No bloquea Etapas 2–4 del Bloque A.

**Criterio de salida Etapa 1:** signup/login por API/SDK posible en el VPS con autoconfirm.

---

## Etapa 2 — Flujo de registro en Frontend (Flutter)

**Estado: HECHA en este repo** (probar contra VPS).

**Objetivo:** `supabase.auth.signUp` + metadata alineada al trigger.

| Paso | Qué | Estado |
|------|-----|--------|
| 2.0 | Añadir `supabase_flutter`, init vía `config_supabase` | Hecho |
| 2.1 | Formulario MVP alineado a `usuario` (sin documento) | Hecho |
| 2.2 | `ServicioAuthSupabase.registrarConCorreo` → `signUp` + `data` | Hecho |
| 2.3 | Manejo `AuthException` + sesión UUID vía `sincronizarDesdeAuth` | Hecho |

### Metadatos en `data` (signUp) — solo columnas de `public.usuario`

```text
nombres            ← form «Nombres»
apellidos          ← form «Apellidos»
nombre_nick        ← form «Nombre de usuario» (nickname libre)
nacionalidad_id    ← default MVP (picker después)
```

Sin documento en el MVP. `correo` / defaults de BD los completa Auth + trigger.

---

## Etapa 3 — Automatización del perfil (base de datos)

**Estado: HECHA en VPS** — visible en `20260910200326_remote_schema.sql` (pull).

**Objetivo:** cada `auth.users` nuevo genera una fila en `public.usuario`.

| Paso | Qué | Estado |
|------|-----|--------|
| 3.1 | Función `handle_new_user()` → `INSERT` en **`public.usuario`** | Hecho (remote_schema) |
| 3.2 | Trigger `on_auth_user_created` AFTER INSERT ON `auth.users` | Hecho |
| 3.3 | RLS: `nacionalidad` SELECT público; `usuario` SELECT auth + UPDATE propio | Hecho |
| 3.4 | Seed `nacionalidad` | Hecho en VPS (tú) |
| 3.5 | Fuente de verdad | `remote_schema` del pull (no editar) |

Contrato del trigger = columnas reales de `usuario`:  
`id, nombres, apellidos, nombre_nick, correo, foto_perfil, estado, nacionalidad_id`.

**Criterio de salida Etapa 3:** tras `db push` + registro Flutter → fila en `public.usuario` con el mismo UUID.

---

## Etapa 4 — Inicio de sesión (login)

**Estado: HECHA en código** (probar con usuario registrado).

**Objetivo:** sesión real con JWT de Supabase.

| Paso | Qué | Estado |
|------|-----|--------|
| 4.1 | `signInWithPassword` en pantalla login | Hecho |
| 4.2 | `onAuthStateChange` + restauración `currentSession` al abrir app | Hecho |
| 4.3 | `SesionNotifier` usa UUID de Auth; hidrata nick desde `public.usuario` | Hecho |
| 4.4 | `cerrarSesion` → `signOut`; gate `asegurarSesion` sin cambio de UX | Hecho |

Google sigue aplazado (Bloque B). Feed local aún usa id demo `'yo'` en varios sitios — no bloquea login; se unifica cuando el feed pase a remoto.

**Criterio de salida Etapa 4:** registro + login + sesión al reiniciar app + logout real.

---

# BLOQUE B — Autenticación con Google (OAuth)

Basado en la lógica del documento “IMPLEMENTANDO EL AUTH”.  
Empezar **después** de tener Bloque A estable (mismo trigger de perfil).

## Etapa 1 — Infraestructura y Google Cloud

**Estado: HECHA en VPS** (según equipo). Confirmar que el redirect de app es exactamente `hakuapp://login-callback`.

| Paso | Qué | Estado |
|------|-----|--------|
| 1.1 | OAuth Client ID en Google Cloud; redirect URI → GoTrue del VPS | Hecho (VPS) |
| 1.2 | `.env` Docker: habilitar Google + Client ID / Secret | Hecho (VPS) |
| 1.3 | `SITE_URL` + `ADDITIONAL_REDIRECT_URLS` incluye `hakuapp://login-callback` | Hecho (VPS) — verificar |
| 1.4 | `docker compose stop auth` + `up -d` | Hecho (VPS) |

## Etapa 2 — Deep link Android (frontend)

**Estado: HECHA** en este repo.

| Paso | Qué | Estado |
|------|-----|--------|
| 2.1 | `AndroidManifest.xml` + `INTERNET` | Hecho |
| 2.2 | `<intent-filter>` `hakuapp` / `login-callback` | Hecho |
| 2.3 | Constante Flutter `ConfigSupabase.oauthRedirectUri` | Hecho |
| 2.4 | iOS URL scheme | Fuera de alcance inmediato |

## Etapa 3 — Flujo en Flutter

**Estado: HECHA** — Google **nativo** (ventana de cuentas Android, no navegador externo).

| Paso | Qué | Estado |
|------|-----|--------|
| 3.1 | `google_sign_in` + `signInWithIdToken` (Web Client ID = `GOOGLE_WEB_CLIENT_ID`) | Hecho |
| 3.1b | Cliente **Android** en Google Cloud: package `com.example.haku` + SHA-1 (debug/release) | Hecho por equipo — verificar |
| 3.2 | Trigger crea `usuario`: correo, foto Google, nick del correo, PE por defecto | Hecho (`20260911060000_…`) |
| 3.2b | Nick único si choca (sufijo uuid) | Hecho (`20260911070000_…` — **aplicar `db push`**) |
| 3.3 | Completar nick/nacionalidad | En **Configuración** (después), no al primer login |

**Por qué el SHA-1 no bastaba solo:** el flujo viejo abría el navegador (`signInWithOAuth`). El SHA-1 solo aplica al login nativo de Google Play Services. Hace falta además el **Web Client ID** en la app (mismo valor que Auth en el VPS).

**Contrato Google → `public.usuario` (trigger):**

| Campo | Origen |
|-------|--------|
| correo | Google |
| foto_perfil | `avatar_url` / `picture` si viene |
| nombre_nick | Parte antes de `@` (sanitizada) |
| nombres | Nombre Google si viene; si no, el nick |
| apellidos | Resto del nombre Google o `N/D` |
| nacionalidad_id | PE (editable después) |

## Etapa 4 — Hand-off / reglas de oro

**Estado: HECHA.** Contrato para el equipo (frontend Auth). No inventar clientes HTTP a GoTrue.

### Reglas de oro

| # | Regla | Detalle |
|---|--------|---------|
| 0 | **1 correo = 1 usuario** | Misma cuenta aunque entre por Google o por contraseña (`auth.identities`). Correo→Google: auto-link. Google→registro correo: error amigable + «Olvidé mi contraseña» / Google. |
| 1 | Solo SDK | Login/registro/logout/OAuth/reset = `supabase_flutter`. **Prohibido** HTTP manual a `/auth/v1`. |
| 2 | Perfil en `public.usuario` | Lectura/update de nick, nombres, apellidos, nacionalidad, foto = `from('usuario')` + RLS (`auth.uid() = id`). |
| 3 | Auth vs perfil | Correo/contraseña → SDK Auth. Datos de ficha → tabla `usuario`. Foto: Storage/S3 → solo URL en `foto_perfil`. |
| 4 | Google nativo + deep link | Login Google = nativo + idToken. Deep link `hakuapp://login-callback` sigue para recuperar clave / flujos web. Web Client ID en app = mismo del VPS. |
| 5 | Google sin pantalla extra | Trigger: nick (correo), PE, foto si viene. Nick/nacionalidad en **Configuración**. |
| 6 | Credenciales | Anon key en cliente OK. **Nunca** `service_role` en la app. |

#### Escenarios 1 correo = 1 usuario (UX)

| Orden | Qué pasa | Frontend |
|-------|----------|----------|
| Primero correo → luego Google | Supabase vincula identidad Google a la misma cuenta | Flujo normal |
| Primero Google → luego «Crear cuenta» con ese correo | Auth: user already registered | Diálogo amigable + ir a login / Olvidé contraseña |
| Google-only quiere contraseña | Configuración → **Crear contraseña** (`updateUser` con JWT, sin SMTP). Luego Google **o** correo+clave | Misma fila `auth.users` |

### Mapa de archivos (dónde tocar Auth)

| Qué | Dónde |
|-----|--------|
| Init Supabase | `lib/nucleo/supabase/cliente_supabase.dart` + `config_supabase.dart` |
| Correo / Google / sesión SDK | `lib/funcionalidades/autenticacion/dominio/servicios/servicio_auth_supabase.dart` |
| Flujo UI Google | `lib/funcionalidades/autenticacion/flujo_google.dart` |
| Estado sesión app | `lib/funcionalidades/autenticacion/proveedores/proveedor_sesion.dart` |
| Update perfil / foto | `lib/funcionalidades/autenticacion/dominio/servicios/servicio_perfil_supabase.dart` |
| Gate “necesita login” | `lib/funcionalidades/autenticacion/navegacion_auth.dart` |
| Trigger → `usuario` | migraciones `handle_new_user` en `supabase/migrations/` |

### No hacer

- Llamadas REST propias a `/auth/v1/token`, `/authorize`, etc.
- Insertar filas en `public.usuario` desde la app (lo hace el trigger).
- Hardcodear `nacionalidad_id = 1` como verdad absoluta (preferir `codigo_iso`, p. ej. PE).
- Mostrar textos técnicos (SMTP, Storage, tablas) al usuario final.

### Criterio de salida Bloque B

- [x] Correo/contraseña (Bloque A)
- [x] Google nativo (`google_sign_in` + `signInWithIdToken`) + deep link (recuperar clave)
- [x] Fila en `public.usuario` vía trigger
- [x] Configuración: editar perfil / nick / nacionalidad / clave / foto
- [x] Reglas de oro documentadas para el equipo

---

## Fuera de alcance inmediato (backlog Auth)

- SMTP + `ENABLE_EMAIL_AUTOCONFIRM=false`
- Recuperar contraseña real (`resetPasswordForEmail`) — **cableado en app**; falta SMTP en VPS para que el correo salga
- Edge Function solo si el proveedor SMTP o un webhook lo exige
- Limpieza definitiva Bunny / `tabla_de_prueba` / policies Storage obsoletas
- Unificar formulario Flutter (quitar demo DNI o mapearlo a columnas nuevas si el producto lo pide)

---

## Checklist de avance (marcar al cerrar)

### Bloque A
- [x] Etapa 1 — GoTrue + autoconfirm documentado
- [x] Etapa 2 — `supabase_flutter` + signUp con metadata (configurar URL/key)
- [x] Etapa 3 — Trigger `usuario` + RLS (aplicar push)
- [x] Etapa 4 — Login + sesión real (`signInWithPassword` + `onAuthStateChange`)

### Bloque B
- [x] Etapa 1 — GCP + .env + redirects (VPS; verificar `hakuapp://login-callback`)
- [x] Etapa 2 — Deep link Android (`hakuapp` / `login-callback`)
- [x] Etapa 3 — OAuth Google (sin pantalla extra; nick del correo + PE; editar en Config)
- [x] Etapa 4 — Reglas de oro / hand-off al equipo

---

## Próximo paso concreto

1. Probar Google en Android (si aún no).
2. Backlog Auth cuando toque: SMTP + verificación correo, recuperar contraseña real, iOS URL scheme.
3. Fuera de Auth: unificar feed/comunidad al `id` real de sesión (hoy parte del demo sigue con id local).
