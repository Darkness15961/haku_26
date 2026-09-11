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
| SDK oficial | Auth solo con `supabase_flutter` (`signUp`, `signInWithPassword`, `signInWithOAuth`). Sin HTTP manual a GoTrue. |
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
    ├── Etapa 1  GCP + .env VPS + redirect URLs
    ├── Etapa 2  Deep link Android
    ├── Etapa 3  signInWithOAuth + completar perfil
    └── Etapa 4  Reglas de oro / hand-off equipo
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

| Paso | Qué | Estado |
|------|-----|--------|
| 1.1 | OAuth Client ID en Google Cloud; redirect URI → GoTrue del VPS | Pendiente |
| 1.2 | `.env` Docker: habilitar Google + Client ID / Secret | Pendiente |
| 1.3 | `SITE_URL` + `ADDITIONAL_REDIRECT_URLS` (esquema app, ej. `hakuapp://login-callback`) | Pendiente |
| 1.4 | `docker compose stop auth` + `up -d` | Pendiente |

## Etapa 2 — Deep link Android (frontend)

| Paso | Qué | Estado |
|------|-----|--------|
| 2.1 | `AndroidManifest.xml` | Pendiente |
| 2.2 | `<intent-filter>` esquema/host acordados | Pendiente |
| 2.3 | iOS (si aplica más adelante): URL scheme / Associated Domains | Fuera de alcance inmediato |

## Etapa 3 — Flujo en Flutter

| Paso | Qué | Estado |
|------|-----|--------|
| 3.1 | `signInWithOAuth(Provider.google, redirectTo: …)` | Pendiente |
| 3.2 | Trigger crea `usuario` con lo que dé Google (nombre/correo/foto) | Depende de A.3 |
| 3.3 | Pantalla **Completa tu registro** si faltan `nombre_nick` o `nacionalidad_id` (u otros obligatorios) | Pendiente |

## Etapa 4 — Hand-off / reglas de oro

| Regla | Detalle |
|-------|---------|
| Solo SDK | Login = métodos oficiales de Supabase Flutter. |
| Editar perfil | `from('usuario').update(...)` + RLS; no mutar Auth salvo email/password del SDK. |
| Equipo | Andrea / Saúl: no inventar clientes HTTP a `/auth/v1`. |

**Criterio de salida Bloque B:** Google login → perfil creado o forzado a completar → entrada a la app.

---

## Fuera de alcance inmediato (backlog Auth)

- SMTP + `ENABLE_EMAIL_AUTOCONFIRM=false`
- Recuperar contraseña real (`resetPasswordForEmail`)
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
- [ ] Etapa 1 — GCP + .env + redirects
- [ ] Etapa 2 — Deep link Android
- [ ] Etapa 3 — OAuth + completar perfil
- [ ] Etapa 4 — Reglas de oro al equipo

---

## Próximo paso concreto

1. Probar registro + login + reinicio de app (sesión debe volver) + logout.  
2. Confirmar fila en `public.usuario` tras registro.  
3. Luego **Bloque B (Google)** o pulir catálogo `nacionalidad` (FK por `id`; `codigo_iso` como dato estable de negocio — se afina después).
