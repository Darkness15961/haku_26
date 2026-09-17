# 🏔️ Análisis Completo del Proyecto HAKU V2

## 1. Identidad del Proyecto

**HAKU** es una app móvil Flutter de **turismo de aventura** enfocada en la región de **Cusco, Perú**. Permite a los usuarios:

- **Explorar** lugares turísticos geolocalizados por provincia/distrito
- **Crear y unirse a comunidades** temáticas de aventura
- **Organizar salidas** grupales con punto de encuentro real
- **Chat en tiempo real** (grupal y privado 1:1)
- **Publicar** experiencias con multimedia
- **Consultar rutas** curadas con ficha técnica completa
- **Autenticarse** vía correo/contraseña o Google OAuth nativo

> [!IMPORTANT]
> El proyecto tiene **dos directorios**: `Haku produccion/Haku` (app principal + Supabase) y `hakuprueba` (prototipo de pruebas multimedia/video S3). El análisis se centra en la app de producción.

---

## 2. Stack Tecnológico

| Capa | Tecnología | Versión/Detalle |
|------|-----------|-----------------|
| **Frontend** | Flutter (Dart) | SDK `^3.9.2` |
| **State Management** | Riverpod | `flutter_riverpod: ^2.6.1` |
| **Backend** | Supabase Self-Hosted | VPS propio en `supabase.haku.best` |
| **Base de Datos** | PostgreSQL 17 + PostGIS | Extensión `postgis` para geolocalización |
| **Auth** | GoTrue (Supabase Auth) | Email/contraseña + Google OAuth nativo |
| **Storage** | Supabase Storage | Bucket `haku-storage-produccion-2026` + `haku-chat-privado` |
| **Realtime** | Supabase Realtime | PostgreSQL changes (chat, mensajes) |
| **Video CDN** | BunnyCDN | Via `pg_net` (legado, para limpiar) |
| **Mapas** | `flutter_map` + `latlong2` | OpenStreetMap tiles |
| **GPS** | `geolocator` | Permisos + ubicación real |
| **Google Sign-In** | `google_sign_in: ^7.2.0` | Nativo Android (no navegador) |
| **Edge Functions** | Deno (Supabase) | 1 función: `bunny-ticket` |
| **Imágenes** | `cached_network_image` | Cache de red |

---

## 3. Arquitectura Flutter

### Estructura de directorios

```
lib/
├── main.dart                          # Entry point + MaterialApp dark theme
├── funcionalidades/                   # Feature modules (Clean-ish Architecture)
│   ├── autenticacion/                 # Auth (login, registro, Google OAuth)
│   │   ├── datos/                     # Datasources (nacionalidad)
│   │   ├── dominio/                   # Modelos, repositorios, servicios
│   │   ├── pantallas/                 # Screens (login, registro, recuperar)
│   │   ├── proveedores/              # Riverpod providers (sesión)
│   │   └── widgets/                   # UI components
│   ├── carga_inicial/                 # Splash / loading screen
│   ├── inicio/                        # Home screen + tabs + feed providers
│   ├── lugares/                       # Explora (islas por provincia)
│   ├── comunidad/                     # Comunidades + Salidas + Publicaciones
│   ├── chat/                          # Chat unificado (grupal + privado)
│   ├── rutas/                         # Rutas curadas (read-only catálogo)
│   ├── publicaciones/                 # Feed "Para ti"
│   ├── favoritos/                     # Favoritos (pendiente remoto)
│   └── perfil_usuario/                # Perfil propio y ajeno
└── nucleo/                            # Core / shared
    ├── supabase/                      # Cliente + config (URL, anon key, OAuth)
    ├── datos/                         # EsquemaHaku (constantes de tablas)
    ├── almacenamiento/                # SharedPreferences (legacy local)
    ├── navegacion/                    # Helpers de navegación
    ├── responsive/                    # Lienzo + rejilla responsiva
    ├── widgets/                       # Avatar, imagen, badge, indicadores
    ├── recursos/                      # Catálogo de imágenes + copy
    ├── metricas/                      # Métricas de descubrimiento
    └── demo/                          # Flags de demo + señales de atención
```

### Patrones Clave

| Patrón | Implementación |
|--------|---------------|
| **Feature-first** | Cada módulo tiene `datos/`, `dominio/`, `pantallas/`, `proveedores/`, `widgets/` |
| **Datasource dual** | Legacy local (`_datasource_local.dart`) + Supabase (`_datasource_supabase.dart`) |
| **Guard `supabaseListo`** | Providers verifican que Supabase inicializó antes de consultar |
| **`desdeFilaRemota(Map)`** | Factory en cada modelo para mapear respuesta PostgREST |
| **Auth gate** | `asegurarSesion()` redirige a login si no hay JWT |
| **Tema oscuro** | Paleta tipo oro/carbon/ink definida en `PaletaRutas` |
| **IDs bigint como String** | Postgres bigint → `'$id'` en Dart |

---

## 4. Infraestructura Supabase (Self-Hosted)

### Conexión

| Parámetro | Valor |
|-----------|-------|
| **URL producción** | `https://supabase.haku.best` |
| **Puerto local API** | `54321` |
| **Puerto local DB** | `54322` |
| **Puerto local Studio** | `54323` |
| **Project ID** | `Haku` |
| **DB versión** | PostgreSQL 17 |
| **OAuth redirect** | `hakuapp://login-callback` |
| **Google Web Client ID** | `30837355283-jvlh7jvjjtcg3f69ibnbgd3icpq3vur9.apps.googleusercontent.com` |

### Configuración Auth

- Email signup: habilitado, **autoconfirm activo** (sin SMTP aún)
- Google OAuth: nativo Android (`signInWithIdToken`)
- Deep link Android: `hakuapp://login-callback`
- Refresh token rotation: activo
- Confirmación de email: deshabilitada (MVP)

### Storage

- **Bucket principal**: `haku-storage-produccion-2026` (público con policies)
- **Bucket chat privado**: `haku-chat-privado` (privado, URLs firmadas)
- Límite de archivo: 50 MiB
- Protocolo S3 habilitado

### Edge Functions

- `bunny-ticket/index.ts` — Integración con BunnyCDN para video streaming (legado)

---

## 5. Base de Datos — Esquema Completo

### 53 Migraciones (cronología)

El esquema ha evolucionado a través de **53 migraciones** desde `2026-09-10` hasta `2026-09-17`:

```mermaid
flowchart LR
    A["Fase 0\nBase"] --> B["Fase Auth\nUsuario + Trigger"]
    B --> C["Fase Explora\nLugares + PostGIS"]
    C --> D["Fase Comunidad\nGrupos + Salidas + RLS"]
    D --> E["Fase Chat\nSalas + Mensajes + Realtime"]
    E --> F["Fase Rutas\nCatálogo editorial"]
    F --> G["Fase Publicaciones\nFeed + Privacidad"]
```

### Tablas Principales

| Tabla | Propósito | RLS | Policies |
|-------|-----------|-----|----------|
| `usuario` | Perfil público (FK → `auth.users`) | ✅ | SELECT auth, UPDATE propio |
| `nacionalidad` | Catálogo ISO (249 países) | ✅ | SELECT público |
| `departamento` | Cusco (1 fila MVP) | ✅ | SELECT público |
| `provincia` | 13 provincias de Cusco | ✅ | SELECT público |
| `distrito` | Distritos por provincia | ✅ | SELECT público |
| `categoria` | Temática + Actividad | ✅ | SELECT público |
| `lugar` | Puntos de interés geolocalizados | ✅ | SELECT activos, INSERT/UPDATE dueño |
| `lugar_categoria` | N:N lugar↔categoría | ✅ | SELECT público |
| `comunidad` | Grupos de aventura | ✅ | 15+ policies |
| `comunidad_miembro` | Membresía con rol y estado | ✅ | Completo |
| `comunidad_mensaje` | Chat legacy de comunidad | ✅ | Solo miembros |
| `salida` | Salidas programadas | ✅ | Completo |
| `salida_participante` | Inscripción con estado | ✅ | Completo |
| `publicacion` | Posts del feed | ✅ | Completo + soft-delete |
| `publicacion_multimedia` | Fotos/videos de publicación | ✅ | Hereda de publicación |
| `publicacion_etiqueta_comunidad` | Tag pub↔comunidad | ✅ | Autor |
| `publicacion_lugar` | Tag pub↔lugar | ✅ | Autor |
| `publicacion_usuario_etiqueta` | Tag pub↔usuario | ✅ | Autor |
| `ruta` | Rutas curadas con ficha técnica | ✅ | Solo SELECT publicadas |
| `ruta_parada` | Waypoints de ruta ordenados | ✅ | Solo SELECT |
| `sala_chat` | Contenedor de conversaciones | ✅ | Participante |
| `sala_participante` | Roster de chat | ✅ | Anti-recursión |
| `sala_privada` | Parejas 1:1 | ✅ | Via RPC |
| `mensaje` | Mensajes de chat | ✅ | Participante + autor |
| `mensaje_reaccion` | Emojis en mensajes | ✅ | Participante |

### Enums PostgreSQL

```
tipo_comunidad       → publico, privado
rol_miembro          → admin, moderador, miembro
estado_membresia     → pendiente, aprobado, rechazado, bloqueado
tipo_salida          → publica, comunidad
estado_salida        → programada, en_curso, finalizada, cancelada
estado_participante  → confirmado, cancelado
estado_publicacion   → publico, privado, eliminado
estado_video         → pending, processing, ready, error
dificultad_nivel     → facil, moderado, exigente
tipo_sala_chat       → comunidad, salida, privado
tipo_mensaje         → texto, imagen, audio, ubicacion, sticker
estado_editorial     → borrador, propuesta, en_revision, publicado, rechazado, archivado
```

### Funciones / RPCs Clave

| Función | Tipo | Propósito |
|---------|------|-----------|
| `handle_new_user()` | Trigger | Auto-crea `usuario` al registrarse |
| `fn_sync_ubicacion()` | Trigger | Sincroniza `geography` desde lat/lon |
| `fn_actualizar_updated_at()` | Trigger | Auto-actualiza `updated_at` |
| `lugares_cerca(lat, lon, radio)` | RPC | PostGIS cercanía |
| `es_miembro_comunidad_aprobado()` | Helper | RLS anti-recursión |
| `es_admin_comunidad()` | Helper | RLS anti-recursión |
| `es_participante_sala()` | Helper | RLS chat anti-recursión |
| `sala_comunidad_id_si_existe()` | RPC | Detecta sala sin crear duplicados |
| `sala_salida_id_si_existe()` | RPC | Detecta sala sin crear duplicados |
| `asegurar_sala_privada()` | RPC | Crea/reusa DM 1:1 con validaciones |
| `crear_sala_comunidad_con_participantes()` | RPC | Transacción atómica sala + roster |
| `crear_sala_salida_con_participantes()` | RPC | Transacción atómica sala + roster |
| `listar_bandeja_chat()` | RPC | Bandeja unificada (comunidad+salida+privado) |
| `marcar_sala_leida()` | RPC | Cursor no-leídos server-side |
| `editar_mensaje_chat()` | RPC | Edición segura |
| `eliminar_mensaje_chat()` | RPC | Soft-delete seguro |
| `crear_salida_con_organizador()` | RPC | Salida + inscripción atómica |
| `crear_publicacion_completa()` | RPC | Pub + media + tags atómica |
| `rutas_publicadas_lista` | View | Listado liviano de rutas |
| `ruta_publicada_detalle()` | RPC | Ficha completa + paradas + GeoJSON |
| `create_bunny_video()` | RPC | Legacy BunnyCDN |
| `get_bunny_video_result()` | RPC | Legacy BunnyCDN |

---

## 6. Módulos Funcionales — Estado

### ✅ Autenticación — COMPLETA

| Funcionalidad | Estado |
|--------------|--------|
| Registro email/contraseña | ✅ Hecho |
| Login con sesión persistente | ✅ Hecho |
| Google OAuth nativo Android | ✅ Hecho |
| Trigger `handle_new_user` | ✅ Hecho |
| Deep link `hakuapp://login-callback` | ✅ Hecho |
| Edición de perfil | ✅ Hecho |
| Manejo correo duplicado | ✅ Hecho |
| SMTP / verificación email | ❌ Pendiente (MVP con autoconfirm) |
| Recuperar contraseña real | ❌ Pendiente (necesita SMTP) |

**Archivos clave:**
- [servicio_auth_supabase.dart](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/lib/funcionalidades/autenticacion/dominio/servicios) — SDK auth
- [flujo_google.dart](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/lib/funcionalidades/autenticacion/flujo_google.dart) — Google nativo
- [config_supabase.dart](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/lib/nucleo/supabase/config_supabase.dart) — Credenciales

---

### ✅ Explora (Lugares) — COMPLETA

| Funcionalidad | Estado |
|--------------|--------|
| Catálogo geo (dept → prov → distrito) | ✅ Seed Cusco aplicado |
| Listado lugares por provincia remoto | ✅ Hecho |
| Detalle lugar con ficha | ✅ Hecho |
| Filtros distrito + categoría | ✅ Hecho |
| Crear lugar + foto Storage | ✅ Hecho |
| Mapa pines remotos | ✅ Hecho |
| RPC cercanía PostGIS (50 km) | ✅ Hecho |
| Geocoding auto | ❌ Aplazado |

**Archivos clave:**
- [lugar_datasource_supabase.dart](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/lib/funcionalidades/lugares/datos/lugar_datasource_supabase.dart)
- [territorio_datasource_supabase.dart](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/lib/funcionalidades/lugares/datos/territorio_datasource_supabase.dart)

---

### ✅ Comunidad — COMPLETA (Bloques 0–E)

| Funcionalidad | Estado |
|--------------|--------|
| RLS 15+ policies | ✅ Aplicado |
| Listado comunidades remotas | ✅ Hecho |
| Crear comunidad + foto + admin | ✅ Hecho |
| Unirse/salir (público auto, privado pendiente) | ✅ Hecho |
| Detalle con miembros nick+rol | ✅ Hecho |
| Salidas remotas (crear, inscribir, cancelar) | ✅ Hecho |
| Mensajes comunidad + Realtime | ✅ Hecho |
| Feed publicaciones + soft-delete | ✅ Hecho |
| Crear publicación + etiquetar | ✅ Hecho |
| Likes/comentarios | ❌ No hay tablas aún |

**Archivos clave:**
- [comunidad_datasource_supabase.dart](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/lib/funcionalidades/comunidad/datos/comunidad_datasource_supabase.dart)
- [salida_datasource_supabase.dart](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/lib/funcionalidades/comunidad/datos/salida_datasource_supabase.dart)
- [pantalla_comunidad.dart](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/lib/funcionalidades/comunidad/pantallas/pantalla_comunidad.dart) — 37 KB

---

### ✅ Chat — COMPLETO

| Funcionalidad | Estado |
|--------------|--------|
| Salas comunidad / salida / privado | ✅ Infraestructura completa |
| Creación atómica con roster | ✅ RPCs transaccionales |
| Texto, imagen, ubicación, sticker | ✅ Hecho |
| Editar / borrar (soft-delete) | ✅ RPCs seguros |
| Reacciones emoji | ✅ Toggle + dedupe |
| No-leídos server-side | ✅ `marcar_sala_leida` |
| Bandeja unificada | ✅ `listar_bandeja_chat()` |
| Chat privado 1:1 contextual | ✅ `asegurar_sala_privada()` |
| Realtime bidireccional | ✅ `REPLICA IDENTITY FULL` |
| Imágenes en bucket privado | ✅ URLs firmadas |
| Push notifications | ❌ Pendiente |
| Audio | ❌ Pendiente |
| E2E encryption | ❌ Pendiente |

**Archivos clave:**
- [chat_datasource_supabase.dart](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/lib/funcionalidades/chat/datos/chat_datasource_supabase.dart) — 37 KB
- [pantalla_chat_sala.dart](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/lib/funcionalidades/chat/pantallas/pantalla_chat_sala.dart) — 48 KB

---

### ✅ Rutas — COMPLETA (lectura)

| Funcionalidad | Estado |
|--------------|--------|
| Catálogo publicadas (vista liviana) | ✅ RPC |
| Detalle + paradas + GeoJSON trazado | ✅ RPC |
| Integración con Salidas (`ruta_id`) | ✅ FK validada |
| Integración con Publicaciones | ✅ `publicacion_ruta` |
| Editor de rutas en app | ❌ Fuera de alcance (carga oficial) |
| Panel de moderación | ❌ Fase futura |

**Archivos clave:**
- [rutas_datasource_supabase.dart](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/lib/funcionalidades/rutas/datos/rutas_datasource_supabase.dart)

---

## 7. Proyecto de Pruebas (`hakuprueba`)

Directorio separado con prototipos de multimedia:

| Archivo | Propósito |
|---------|-----------|
| [main.dart](file:///c:/Users/Administrador/Desktop/HAKU V2/hakuprueba/lib/main.dart) | App de prueba multimedia |
| [multimedia_service.dart](file:///c:/Users/Administrador/Desktop/HAKU V2/hakuprueba/lib/multimedia_service.dart) | Servicio de multimedia |
| [video_service.dart](file:///c:/Users/Administrador/Desktop/HAKU V2/hakuprueba/lib/video_service.dart) | Servicio de video |
| [reproductor_haku.dart](file:///c:/Users/Administrador/Desktop/HAKU V2/hakuprueba/lib/reproductor_haku.dart) | Reproductor de video |
| [pantalla_prueba_s3.dart](file:///c:/Users/Administrador/Desktop/HAKU V2/hakuprueba/lib/pantalla_prueba_s3.dart) | Pruebas de S3 storage |

---

## 8. Documentación Existente

| Documento | Contenido |
|-----------|-----------|
| [fase-autenticacion.md](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/docs/fase-autenticacion.md) | Bloques A+B Auth completos |
| [fase-explora.md](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/docs/fase-explora.md) | Bloques 0–C Lugares completos |
| [fase-comunidad.md](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/docs/fase-comunidad.md) | Bloques 0–E Comunidad completos |
| [fase-mensajes.md](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/docs/fase-mensajes.md) | Sistema de chat completo |
| [fase-rutas.md](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/docs/fase-rutas.md) | Dominio de rutas |
| [guia-pruebas-manuales-haku.md](file:///c:/Users/Administrador/Desktop/HAKU V2/Haku produccion/Haku/docs/guia-pruebas-manuales-haku.md) | Guía de QA manual (43 KB) |

---

## 9. Estado Global y Pendientes

### ✅ Completado

- Auth completa (correo + Google nativo)
- Explora completa (CRUD + PostGIS + mapa)
- Comunidades completa (CRUD + membresía + RLS)
- Salidas completa (CRUD + inscripción + lugar Explora)
- Chat completo (grupal + privado + Realtime + imágenes)
- Publicaciones completa (CRUD + etiquetas + soft-delete)
- Rutas lectura completa (catálogo oficial)
- Nickname público único (`20260916090000`)
- Privacidad publicaciones comunidad (`20260917010000`)
- Handle new user seguro (`20260917030000`)

### ❌ Pendientes Conocidos

| Ítem | Prioridad | Detalle |
|------|-----------|---------|
| **SMTP real** | Alta | Autoconfirm activo; sin verificación de email |
| **Recuperar contraseña real** | Alta | UI cableada; falta SMTP en VPS |
| **Push notifications** | Alta | Sin implementar |
| **Likes / comentarios** | Media | Sin tablas en BD |
| **Favoritos remotos** | Media | Módulo existe pero es local |
| **Audio en chat** | Media | Enum existe; sin implementar |
| **Geocoding auto** | Baja | Pin → distrito automático aplazado |
| **Check-in GPS** | Baja | UI honesta "próximamente" |
| **Bloqueo/denuncia usuarios** | Media | Sin implementar |
| **E2E encryption** | Baja | No planeado a corto plazo |
| **Editor de rutas en app** | Baja | Solo carga oficial por ahora |
| **Panel admin de moderación** | Media | Diseño documentado; sin implementar |
| **Presencia online / "escribiendo..."** | Baja | Sin implementar |
| **iOS URL scheme** | Media | Solo Android configurado |
| **Limpieza Bunny / `tabla_de_prueba`** | Baja | Código legado; no bloquea |

---

## 10. Convenciones y Reglas del Proyecto

> [!CAUTION]
> **Reglas estrictas** documentadas en los docs de fase:

1. **Solo SDK** — Auth, queries, storage todo via `supabase_flutter`. **Prohibido** HTTP manual a GoTrue/PostgREST
2. **Nunca `service_role` en la app** — Solo anon key en el cliente
3. **No editar migraciones aplicadas** — Cambios = migración nueva
4. **No inventar datos** — Si no hay backend, UI honesta "próximamente"
5. **No mezclar demo con remoto** — Datasources locales se retiran por bloque
6. **IDs bigint como String** en Dart
7. **`auth.uid()` en toda FK** de usuario
8. **Trigger crea usuario** — No insertar en `public.usuario` desde la app
9. **Perfil en tabla `usuario`** — No leer `auth.users` desde la app

---

## 11. Diagrama de Relaciones Principal

```mermaid
erDiagram
    auth_users ||--|| usuario : "id (UUID)"
    usuario ||--o{ comunidad : "usuario_creador_id"
    usuario ||--o{ lugar : "usuario_id"
    usuario ||--o{ publicacion : "usuario_id"
    usuario ||--o{ salida : "organizador_id"
    
    comunidad ||--o{ comunidad_miembro : "comunidad_id"
    comunidad ||--o{ salida : "comunidad_id"
    comunidad ||--o{ sala_chat : "comunidad_id"
    
    salida ||--o{ salida_participante : "salida_id"
    salida ||--o{ sala_chat : "salida_id"
    salida }o--o| ruta : "ruta_id"
    salida }o--o| lugar : "punto_encuentro_lugar_id"
    
    ruta ||--o{ ruta_parada : "ruta_id"
    ruta_parada }o--o| lugar : "lugar_id"
    
    sala_chat ||--o{ sala_participante : "sala_id"
    sala_chat ||--o{ mensaje : "sala_id"
    sala_chat ||--o| sala_privada : "sala_id"
    
    lugar }|--|| distrito : "distrito_id"
    distrito }|--|| provincia : "provincia_id"
    provincia }|--|| departamento : "departamento_id"
    lugar ||--o{ lugar_categoria : "lugar_id"
    
    publicacion ||--o{ publicacion_multimedia : "publicacion_id"
    publicacion ||--o{ publicacion_etiqueta_comunidad : "publicacion_id"
    publicacion ||--o{ publicacion_lugar : "publicacion_id"
```

---

## 12. Cómo Correr el Proyecto

### Opción A — Con VPS de producción (default)

```bash
cd "c:\Users\Administrador\Desktop\HAKU V2\Haku produccion\Haku"
flutter run
```

Los fallbacks en `config_supabase.dart` apuntan a `https://supabase.haku.best`.

### Opción B — Con dart-define

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://supabase.haku.best \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=GOOGLE_WEB_CLIENT_ID=30837355283-...
```

### Opción C — Supabase local

```bash
supabase start
# Luego usar SUPABASE_URL_DEV y SUPABASE_ANON_KEY_DEV
```

### DB Pull (sincronizar migraciones del VPS)

```bash
supabase db pull --db-url "postgresql://postgres:PASSWORD@localhost:54322/postgres?sslmode=disable"
```

---

Estoy listo para trabajar con el proyecto. ¿Qué quieres abordar primero?
