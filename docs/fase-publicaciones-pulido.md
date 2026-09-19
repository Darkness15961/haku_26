# HAKU — Fase Publicaciones Pulido

Documento vivo. Objetivo: **unificar** las dos pantallas de creación de publicación
(`PantallaPublicaciones` legacy 1745L + `PantallaCrearPublicacionRemota` 609L) en
**una sola** experiencia moderna, con identidad visual propia de HAKU.

---

## Principios

| Principio | Detalle |
|-----------|---------|
| Una sola pantalla | Eliminar duplicación. La nueva reemplaza ambas. |
| Identidad HAKU | Tema oscuro oro/carbon/piedra. Diseño propio, no copia. |
| Texto libre | La publicación puede ser solo texto (sin media obligatorio). |
| Solo backend real | No inventar features sin tabla/RPC. |
| Privacidad contextual | Público por defecto. El autor puede cambiarlo a "solo comunidad" explícitamente. Las etiquetas (comunidad, salida, lugar, ruta) son **solo menciones (contexto informativo)** y **NO** fuerzan a la publicación a volverse privada. La publicación **no aparece** en feeds públicos si el autor decide ponerla como privada manualmente. |
| Patrón HAKU | `supabaseListo` + `clienteSupabase` + `asegurarSesion` + `desdeFilaRemota`. |

---

## Funcionalidades de la nueva pantalla

| Funcionalidad | Backend | Estado |
|--------------|---------|--------|
| 📝 Texto libre (1..4000 chars) | `publicacion.contenido` | ✅ Ya existe |
| 📸 Foto | Storage + `publicacion_multimedia (tipo=imagen)` | ✅ Ya existe |
| 🎬 Video | BunnyCDN + `publicacion_multimedia (tipo=video)` | ✅ Ya existe |
| 📍 Etiquetar lugar (Explora) | `publicacion_lugar` → `lugar` | ✅ Ya existe |
| 👥 Etiquetar comunidad | `publicacion_etiqueta_comunidad` | ✅ Ya existe |
| 🚶 Etiquetar salida | `publicacion_salida` → `salida` | ✅ NUEVO (`20260917060000`) |
| 🥾 Etiquetar ruta | `publicacion_ruta` → `ruta` | ✅ Ya existe |
| 🔒 Público / Solo comunidad | `publicacion.estado` = `publico` / `privado` | ✅ Ya existe |

### Lógica de privacidad (en BD)

- **Público** (default): visible para todos. Las etiquetas solo referencian lugares/salidas/comunidades a modo de contexto.
- **Solo comunidad** (privado): visible solo para el autor y los miembros de las comunidades vinculadas.
- **Se elimina el automatismo**: Etiquetar una comunidad o salida privada ya NO cambia el estado a privado. El usuario es el único que decide si es público o privado usando el toggle de la UI.
- RLS `puede_ver_publicacion()` gobierna el acceso basado únicamente en la decisión manual del autor.

### Migración nueva

`supabase/migrations/20260917144000_publicacion_salida_privacidad.sql`:

1. `CREATE TABLE publicacion_salida` (PK compuesta, FK con RESTRICT).
2. RLS: SELECT hereda `puede_ver_publicacion`, INSERT/DELETE solo autor.
3. Eliminar triggers previos de privacidad automática (`trg_forzar_audiencia_comunidad_privada`, etc).
4. Actualización de `puede_ver_publicacion` (ahora se basa solo en `estado = 'publico' | 'privado'`).
5. Actualización de `crear_publicacion_completa` (+`p_salida_id`, validación, insert).

---

## Mapa de la fase

```
FASE PUBLICACIONES PULIDO
├── BLOQUE 0 — Backend salida + privacidad      ← HECHO ✅
│   └── Migración 20260917060000
├── BLOQUE A — Nueva pantalla unificada         ← EN PROGRESO
│   ├── Etapa A.1  Layout HAKU (avatar + texto expandible + barra adjuntos)
│   ├── Etapa A.2  Toggle público / solo comunidad
│   ├── Etapa A.3  Adjuntar foto/video (inline preview con quitar)
│   ├── Etapa A.4  Etiquetar lugar (bottom sheet buscable)
│   ├── Etapa A.5  Etiquetar comunidad (bottom sheet)
│   ├── Etapa A.6  Etiquetar salida (bottom sheet)
│   ├── Etapa A.7  Etiquetar ruta (bottom sheet)
│   ├── Etapa A.8  Chips de contexto (lugar/comunidad/salida/ruta seleccionados)
│   └── Etapa A.9  Publicar (RPC + video + compensación Storage)
├── BLOQUE B — Limpiar legacy                   ← DESPUÉS de A
│   ├── Etapa B.1  Reemplazar referencias a PantallaPublicaciones
│   ├── Etapa B.2  Reemplazar referencias a PantallaCrearPublicacionRemota
│   ├── Etapa B.3  Eliminar archivos legacy
│   └── Etapa B.4  Limpiar imports y catálogo demo
└── BLOQUE C — Pulir feed (tarjeta)             ← DESPUÉS de B
    ├── Etapa C.1  Tarjeta soporta texto-only correctamente
    ├── Etapa C.2  Badge salida + ruta + privacidad en tarjeta
    └── Etapa C.3  Menú "..." (eliminar publicación propia)
```

---

## Checklist de avance

### Bloque 0 — Backend
- [x] Migración `publicacion_salida` + privacidad salida

### Bloque A — Nueva pantalla
- [x] A.1 Layout HAKU (avatar + textarea expandible + barra adjuntos)
- [x] A.2 Toggle público / solo comunidad (🌐 / 🔒)
- [x] A.3 Foto/video inline con preview y quitar
- [x] A.4 Lugar bottom sheet buscable
- [x] A.5 Comunidad bottom sheet
- [x] A.6 Salida bottom sheet
- [x] A.7 Ruta bottom sheet
- [x] A.8 Chips de contexto debajo del texto
- [x] A.9 Publicar (crear RPC + video Bunny + compensación)

### Bloque B — Limpiar legacy
- [x] B.1 Reemplazar todas las rutas a PantallaPublicaciones
- [x] B.2 Reemplazar todas las rutas a PantallaCrearPublicacionRemota
- [x] B.3 Eliminar archivos obsoletos
- [x] B.4 Limpiar imports y catálogo demo

### Bloque C — Pulir feed
- [x] C.1 Tarjeta texto-only sin crash
- [x] C.2 Badge salida + ruta + privacidad en tarjeta
- [x] C.3 Menú eliminar publicación propia

---

## Archivos principales

| Qué | Archivo |
|-----|---------|
| **NUEVO** — Migración salida+privacidad | `supabase/migrations/20260917060000_publicacion_salida_privacidad.sql` |
| **NUEVO** — Pantalla unificada | `lib/funcionalidades/publicaciones/pantallas/pantalla_crear_publicacion.dart` |
| Legacy 1 (eliminar) | `lib/funcionalidades/publicaciones/pantallas/pantalla_publicaciones.dart` |
| Legacy 2 (eliminar) | `lib/funcionalidades/comunidad/pantallas/pantalla_crear_publicacion_remota.dart` |
| Datasource | `lib/funcionalidades/comunidad/datos/publicacion_datasource_supabase.dart` |
| Modelo | `lib/funcionalidades/comunidad/dominio/modelo_publicacion.dart` |
| Providers | `lib/funcionalidades/comunidad/proveedores/proveedor_publicaciones.dart` |
| Tarjeta feed | `lib/funcionalidades/comunidad/widgets/tarjeta_publicacion_remota.dart` |
| Video servicio | `lib/funcionalidades/comunidad/datos/servicio_video_publicacion.dart` |
| Privacidad BD | `supabase/migrations/20260917010000_privacidad_publicaciones_comunidad.sql` |

---

*Documento de fase Publicaciones Pulido — inicio: 2026-09-17.*
