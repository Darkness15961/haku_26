# HAKU — Fase Comunidad (grupos + salidas + feed)

Documento vivo (mismo estilo que `docs/fase-explora.md` y `docs/fase-autenticacion.md`).  
Avanzamos **por bloques y etapas**. Explora/lugares **no se reabre** salvo bugs; Comunidad **consume** `public.lugar`.

**Estado Explora/lugares:** cerrado para producto (islas, alta, sheet, mapa GPS/PostGIS, ficha).  
**Estado Comunidad:** UI y flujos **demo local**; esquema remoto **existe**; RLS de producto **pendiente**; sin datasources Supabase en este módulo.

`lib/nucleo/supabase/` = solo **cliente + config** (`inicializarSupabase`, `clienteSupabase`, `supabaseListo`). Patrón de envío de datos: `clienteSupabase.from('…').select|insert|update` + `auth.currentUser.id` como UUID en FKs (igual que `LugarDataSourceSupabase`).

Esquema canónico: `supabase/migrations/` (base `20260912220617_remote_schema.sql`; Explora pulido en `20260912230000_explora_lugar_pulido.sql`).

---

## Principios

| Principio | Detalle |
|-----------|---------|
| Un sector | Comunidad + salidas + (después) publicaciones. No mezclar pulido de lugares aquí. |
| Migraciones | No editar migraciones ya aplicadas. Cambios = archivo nuevo + `db push` (tú, túnel SSH). |
| SDK | Solo `supabase_flutter`. Sin HTTP manual a PostgREST. |
| Identidad | `usuario_creador_id` / `organizador_id` / `usuario_id` = `auth.uid()` = `public.usuario.id`. |
| IDs en app | Bigint remoto → `String` en Dart (`'42'`), como lugares. **No** slugs tipo `machu_picchu` en datos remotos. |
| UX honesta | Si `supabaseListo == false` o RLS bloquea → lista vacía / mensaje claro, no mezclar demo silenciosamente. |
| Demo legacy | `salidas_datasource_local`, `proveedor_almacen_feed`, `mensajes_datasource_local` se **retiran por bloque**, no en un solo PR. |

---

## Decisiones MVP (cerradas para esta fase)

| Tema | Decisión |
|------|----------|
| Alcance geográfico | Mismo universo que Explora: **Cusco**; sin `provincia_id` en `comunidad`. |
| Categorías de comunidad | **No** hay N:N en BD. Quitar filtros por `CategoriaLugar` en modelo remoto; buscar por nombre / tipo público-privado. |
| Comunidad privada | `tipo = privado` → unirse crea fila `comunidad_miembro` con `estado = pendiente`; admin aprueba (`aprobado`). MVP: solo **público** auto-aprobado si el tiempo aprieta; diseño RLS ya contempla `estado_membresia`. |
| Salida pública vs de grupo | `tipo_salida`: `publica` (sin `comunidad_id` o abierta) vs `comunidad` (`comunidad_id` obligatorio). **Un solo** `cupos_totales` (no `cupos` + `cuposGrupo` duales). |
| Punto de encuentro | Obligatorio: `punto_encuentro_lat` + `punto_encuentro_lon`; opcional `punto_encuentro_lugar_id` (bigint → ficha Explora). Texto “punto encuentro” en UI = derivado o notas, no columna. |
| Fecha/hora | Un campo: `fecha_hora_inicio` timestamptz. |
| Dificultad en salida | **No** en `salida`. Mostrar solo si hay `ruta_id` (fase Rutas) o quitar chip en UI salida remota. |
| Check-in GPS | **Fuera** del primer corte. UI check-in queda deshabilitada o local hasta tabla dedicada. |
| Chat 1:1 / GrupoRuta | Chat remoto 1:1 implementado después de esta fase; nace desde roster compartido. Ver `docs/fase-mensajes.md`. |
| Feed “Para ti” | **Bloque E**, después de miembros + salidas estables. |
| Foto portada comunidad | URL en `comunidad.foto_portada`; subida vía bucket `haku-storage-produccion-2026` (mismo patrón que `lugar.foto_portada`). |
| Rutas | `salida.ruta_id` opcional; no implementar editor de rutas en Comunidad MVP. |
| Publicaciones | `publicacion` + etiquetas; likes/reels/Bunny = fuera de MVP Comunidad. |

---

## Estado del backend (Comunidad)

| Objeto | En schema | RLS ON | Policies producto | GRANT anon/auth |
|--------|-----------|--------|-------------------|-----------------|
| `comunidad` | Sí | Sí | **No** (solo Explora/lugar) | Sí (tabla completa) |
| `comunidad_miembro` | Sí | Sí | **No** | Sí |
| `comunidad_mensaje` | Sí | Sí | **No** | Sí |
| `salida` | Sí | Sí | **No** | Sí |
| `salida_participante` | Sí | Sí | **No** | Sí |
| `publicacion` (+ hijos) | Sí | Sí | **No** | Parcial en schema base |
| PostGIS `salida.punto_encuentro_ubicacion` | Sí + trigger | — | — | — |
| FK `punto_encuentro_lugar_id` → `lugar` | Sí | — | — | — |

**Consecuencia:** con RLS activado y **cero policies**, el cliente autenticado **no lee ni escribe** filas (comportamiento esperado hasta Bloque 0).

Enums (uso en app = strings del enum Postgres):

| Enum | Valores |
|------|---------|
| `tipo_comunidad` | `publico`, `privado` |
| `rol_miembro` | `admin`, `moderador`, `miembro` |
| `estado_membresia` | `pendiente`, `aprobado`, `rechazado`, `bloqueado` |
| `tipo_salida` | `publica`, `comunidad` |
| `estado_salida` | `programada`, `en_curso`, `finalizada`, `cancelada` |
| `estado_participante` | `confirmado`, `cancelado` |
| `estado_publicacion` | `publico`, `privado`, `eliminado` |

---

## Inventario BD (columnas de producto)

### `public.comunidad`

| Columna | Tipo | Notas MVP |
|---------|------|-----------|
| `id` | bigint identity | Id app = string |
| `nombre` | varchar | Requerido |
| `descripcion` | text | Opcional |
| `foto_portada` | text | URL Storage |
| `usuario_creador_id` | uuid → `usuario` | = auth.uid al crear |
| `estado` | bool | `true` = activa |
| `tipo` | `tipo_comunidad` | default `publico` |
| `fecha_creacion`, `updated_at` | timestamptz | |

### `public.comunidad_miembro` (PK compuesta)

| Columna | Tipo | Notas MVP |
|---------|------|-----------|
| `comunidad_id`, `usuario_id` | bigint, uuid | |
| `fecha_union` | timestamptz | |
| `rol` | `rol_miembro` | Creador → `admin` |
| `estado` | `estado_membresia` | default `aprobado` en público |

### `public.comunidad_mensaje`

| Columna | Tipo |
|---------|------|
| `id` | bigint identity |
| `comunidad_id` | bigint |
| `usuario_id` | uuid |
| `mensaje` | text |
| `fecha_envio` | timestamptz |

### `public.salida`

| Columna | Tipo | Notas MVP |
|---------|------|-----------|
| `id` | bigint identity | |
| `titulo` | varchar | Sustituye “nombre lugar” como título de card si hace falta |
| `organizador_id` | uuid | auth.uid |
| `comunidad_id` | bigint nullable | Obligatorio si `tipo = comunidad` |
| `ruta_id` | bigint nullable | No UI MVP |
| `fecha_hora_inicio` | timestamptz | |
| `punto_encuentro_lat/lon` | numeric(9,6) | Trigger llena `punto_encuentro_ubicacion` |
| `punto_encuentro_lugar_id` | bigint nullable | Join Explora |
| `notas_grupales` | text | |
| `cupos_totales`, `minimo_para_salir` | int | Conteo inscritos vía `salida_participante` |
| `tipo` | `tipo_salida` | |
| `estado` | `estado_salida` | default `programada` |

### `public.salida_participante` (PK compuesta)

| Columna | Tipo |
|---------|------|
| `salida_id`, `usuario_id` | bigint, uuid |
| `fecha_inscripcion` | timestamptz |
| `estado` | `estado_participante` |

### Feed (Bloque E, referencia)

- `publicacion` (`usuario_id`, `contenido`, `estado`, fechas)
- `publicacion_etiqueta_comunidad`, `publicacion_lugar`, `publicacion_multimedia`, `publicacion_usuario_etiqueta`

---

## Contrato cliente Supabase (cómo se envían datos)

Mismo entrypoint que Explora:

```dart
import '../../../nucleo/supabase/cliente_supabase.dart';

final user = clienteSupabase.auth.currentUser; // uuid
await clienteSupabase.from('comunidad').insert({ ... });
await clienteSupabase.from('comunidad').select('id, nombre, ...').eq('estado', true);
```

### Lectura comunidad (listado / detalle)

```dart
const selectComunidad = '''
id,
nombre,
descripcion,
foto_portada,
usuario_creador_id,
estado,
tipo,
fecha_creacion,
comunidad_miembro ( count )
''';
// PostgREST: embed count vía head o RPC aparte; alternativa: select miembros y length en Dart
```

Patrón probado en Explora: `.select(_selectFicha).eq('estado', true).order('nombre')` → `desdeFilaRemota(Map)`.

### Crear comunidad (transacción lógica en app)

1. `insert` en `comunidad` con `usuario_creador_id: user.id`, `estado: true`, `tipo`.
2. `insert` en `comunidad_miembro`: `{ comunidad_id, usuario_id: user.id, rol: 'admin', estado: 'aprobado' }`.
3. Opcional: subir foto → URL → `update` `foto_portada`.

### Unirse a comunidad

- Público: `insert` miembro `estado: aprobado`, `rol: miembro`.
- Privado (fase 1.1): `estado: pendiente` hasta policy/UI de admin.

### Crear salida

```dart
await clienteSupabase.from('salida').insert({
  'titulo': titulo,
  'organizador_id': user.id,
  'comunidad_id': comunidadId, // null si publica
  'tipo': comunidadId != null ? 'comunidad' : 'publica',
  'fecha_hora_inicio': fechaHora.toUtc().toIso8601String(),
  'punto_encuentro_lat': lat,
  'punto_encuentro_lon': lon,
  'punto_encuentro_lugar_id': lugarIdInt,
  'cupos_totales': cupos,
  'minimo_para_salir': minimo,
  'notas_grupales': notas,
  'estado': 'programada',
});
```

### Inscribirse en salida

```dart
await clienteSupabase.from('salida_participante').insert({
  'salida_id': salidaId,
  'usuario_id': user.id,
  'estado': 'confirmado',
});
```

Validaciones en app (hasta RPC): cupos vs count participantes confirmados; no duplicar PK.

### Mensaje de comunidad

```dart
await clienteSupabase.from('comunidad_mensaje').insert({
  'comunidad_id': id,
  'usuario_id': user.id,
  'mensaje': texto,
});
// Realtime: channel postgres_changes on comunidad_mensaje (Bloque D)
```

---

## Inventario frontend (hoy)

### `lib/funcionalidades/comunidad/`

| Archivo | Rol |
|---------|-----|
| `pantalla_comunidad.dart` | Tabs Para ti / Salidas / Comunidades / Mensajes |
| `pantalla_detalle_comunidad.dart` | Detalle grupo |
| `pantalla_crear_salida.dart` | Alta salida demo |
| `pantalla_salidas.dart`, `pantalla_check_in.dart` | Listado + check-in local |
| `dominio/modelo_comunidad.dart` | `ComunidadHaku` (no alineado 1:1 BD) |
| `datos/salidas_datasource_local.dart` | `ModeloSalida` + semilla en memoria |
| `widgets/*` | Tarjetas, mapa punto encuentro |

### Fuera del módulo (acoplado al demo)

| Archivo | Rol |
|---------|-----|
| `inicio/proveedores/proveedor_almacen_feed.dart` | Comunidades + posts + salidas persistidas local |
| `inicio/pantallas/pantalla_crear_grupo_comunidad.dart` | `PantallaCrearComunidad` → almacén |
| `inicio/datos/mensajes_datasource_local.dart` | `GrupoRuta`, chats demo |
| `lugares/widgets/sheet_provincia_lugares.dart` | Importa salidas locales para chip “salidas” |

### Referencia Explora (reutilizar)

| Archivo | Patrón |
|---------|--------|
| `lugares/datos/lugar_datasource_supabase.dart` | select anidado, insert, Storage |
| `lugares/proveedores/proveedor_lugares.dart` | `FutureProvider` + `supabaseListo` |
| `autenticacion/dominio/servicios/servicio_perfil_supabase.dart` | Updates `usuario` |

---

## Brecha BD ↔ app (mapeo objetivo)

| Demo (`ComunidadHaku` / `ModeloSalida`) | Remoto | Acción al cablear |
|----------------------------------------|--------|-------------------|
| `id` string arbitrario | `comunidad.id` bigint | `desdeFilaRemota`: `'$id'` |
| `imagen_url` | `foto_portada` | Renombrar en mapper |
| `creador_id` | `usuario_creador_id` | UUID string |
| `estado` `'activa'` | `estado` bool | `estado == true` |
| `provincia`, `categorias` | — | No enviar; simplificar UI |
| `miembroIds` en memoria | `comunidad_miembro` | Query / join |
| `lugarId` slug | `punto_encuentro_lugar_id` | Solo ids Explora; picker de lugares remotos |
| `fecha` + `hora` | `fecha_hora_inicio` | Unir en DateTime |
| `organizador` nombre | `organizador_id` | Join `usuario` o cache perfil |
| `inscritoIds` / counts | `salida_participante` | Agregación |
| `checkinIds` | — | Feature aplazada |
| `cupos` + `cuposGrupo` | `cupos_totales` | Un campo en formulario |

---

## Riesgos y diseño RLS (Bloque 0 — especificación)

Patrón alineado a Explora (`20260912230000_explora_lugar_pulido.sql`):

| Tabla | Select | Insert | Update | Delete |
|-------|--------|--------|--------|--------|
| `comunidad` | Activas (`estado=true`) visibles para todos; privadas solo si miembro aprobado o creador | Auth: `usuario_creador_id = auth.uid()` | Admin/creador | Admin/creador (soft: `estado=false` preferible) |
| `comunidad_miembro` | Miembros de comunidades visibles para miembros; count público opcional vía vista/RPC | Usuario = `auth.uid()`; privado → `pendiente` | Admin cambia `estado`/`rol` | Propio leave o admin |
| `comunidad_mensaje` | Solo miembros `aprobado` | Miembro aprobado | — | Autor o moderador (fase 2) |
| `salida` | `programada`/`en_curso` visibles; tipo comunidad si miembro | Organizador auth | Organizador | Organizador cancela → `estado=cancelada` |
| `salida_participante` | Participantes + organizador ven lista | Usuario inscribe `auth.uid()` | Propio `cancelado` | — |

Migración prevista: `*_comunidad_rls.sql` (+ GRANT USAGE enums si faltan, como en Explora).

**Verificación post-push (Studio o SQL):**

- [ ] Usuario anon: `select` comunidades activas públicas → OK
- [ ] Usuario auth no miembro: no lee mensajes de grupo privado
- [ ] Creador: insert comunidad + miembro admin en una sesión
- [ ] Inscripción salida respeta RLS sin service_role

---

## Relación con Explora

- Salidas y publicaciones pueden **etiquetar** `lugar_id` remoto → navegación a `pantalla_detalle_lugar`.
- Sheet/mapa Explora: chips de salidas deben usar **mismo id** que `ModeloLugar.id`.
- Contenido (más lugares seed) acelera QA pero **no bloquea** Bloque A si hay ≥1 lugar activo en BD.

---

## Qué NO hacer (esta fase)

- Cablear publicaciones/Bunny/multimedia antes de salidas estables.
- Reintroducir slugs de demo en inserts remotos.
- Añadir columnas “dificultad” o “check-in” en `salida` sin migración acordada.
- Mezclar `GrupoRuta` con `comunidad` en la misma tabla remota.
- Editar migraciones Explora ya aplicadas.
- Usar service_role en la app móvil.

---

# Criterio «terreno listo» (documentación)

Todo lo siguiente debe estar **verde** antes de escribir código de Bloque 0. (Implementación real = sección «Puerta de implementación».)

### Análisis y decisiones

- [x] Inventario tablas comunidad / salida / publicación en BD
- [x] Columnas y enums documentados
- [x] Estado RLS vs policies documentado
- [x] Inventario UI y datasources demo
- [x] Mapa de brechas demo → remoto
- [x] Decisiones MVP cerradas (tabla arriba)
- [x] Contrato `clienteSupabase.from` / inserts de referencia
- [x] Diseño RLS esbozado para migración
- [x] Relación con Explora y ids bigint
- [x] Lista explícita «qué NO hacer»
- [x] Mapa de archivos frontend objetivo
- [x] Orden de bloques 0 → E acordado

### Puerta de implementación (siguiente trabajo en código/BD)

- [x] Migración escrita: `20260915010000_comunidad_salida_rls.sql` (**solo** policies + 2 helpers; sin ALTER/DROP de columnas)
- [x] Migración aplicada en VPS (`db push` 2026-09-13)
- [x] Checklist RLS verificado en Postgres (15 policies + 2 helpers; tablas comunidad/salida vacías = OK)
- [x] Seed QA aplicado (`20260915020000`) — 3 comunidades contexto Cusco; `foto_portada` NULL
- [x] Primer datasource remoto + tab Comunidades leyendo Supabase
- [ ] Retirar semilla demo del almacén feed (sigue para posts; tab Comunidades ya no la usa)

**Bloque 0 + A cerrados.** Siguiente: Bloque B (crear / unirse remoto).

---

## Análisis forense pre–Bloque 0 (2026-09-13)

Probes contra `https://supabase.haku.best` (anon key) + migraciones locales.

| Chequeo | Resultado | Implicación |
|---------|-----------|-------------|
| `lugar` SELECT activos | 1 fila (`Machu Picchu`) | Explora RLS OK |
| `lugar.provincia_id` | `42703` no existe | Migración `lugar_solo_distrito` aplicada |
| `lugar.dificultad` | `42703` no existe | Migración `lugar_sin_dificultad` aplicada |
| `categoria.tipo` | `tematica` / … | Catálogo vivo alineado |
| `comunidad` SELECT | `200` + `content-range: */0` | Vacía **o** sin policy SELECT (síntoma clásico RLS) |
| `comunidad` INSERT anon | `42501` viola RLS | RLS **ON**; sin policy INSERT usable |
| Columnas `comunidad` / `salida` / `miembro` del schema base | SELECT de columnas canónicas → `200` | **No falta ni sobra columna** para MVP |
| `salida.dificultad` | no existe | Correcto (dificultad es de `ruta`) |
| Policies producto comunidad/salida en migraciones | Solo grants + RLS enable; **cero** `CREATE POLICY` | Bloque 0 = policies, no remodelar tablas |
| `publicacion*` | Fuera de este bloque | Bloque E |

**Lección (Explora):** no repetir migraciones que `DROP COLUMN` / cambian modelo “por si acaso”.  
**Bloque 0 acotado a:** policies + `es_miembro_comunidad_aprobado` / `es_admin_comunidad` (SECURITY DEFINER anti-recursión). Sin seed, sin tocar `publicacion`, sin ALTER de `comunidad`/`salida`.

---

# Mapa de la fase (bloques y etapas)

```
FASE COMUNIDAD
├── BLOQUE 0 — RLS + grants + seed opcional          ← HECHO
├── BLOQUE A — Lectura remota (comunidades)          ← HECHO
│   ├── Etapa A.1  Modelo + mapper `ModeloComunidad`
│   ├── Etapa A.2  `comunidad_datasource_supabase`
│   ├── Etapa A.3  Providers Riverpod
│   └── Etapa A.4  Tab Comunidades sin semilla local
├── BLOQUE B — Crear / unirse                        ← HECHO
├── BLOQUE C — Salidas remotas                       ← HECHO
│   ├── Etapa C.1  Modelo remoto (columnas BD)
│   ├── Etapa C.2  Listados tab + sheet + lugar
│   ├── Etapa C.3  Crear (lugar Explora → lat/lon)
│   ├── Etapa C.4  Inscripción / cancelar
│   └── Etapa C.5  Check-in no inventado
├── BLOQUE D — Chat de comunidad                     ← SIGUIENTE
│   ├── Etapa B.1  Crear comunidad (+ miembro admin)
│   ├── Etapa B.2  Foto portada Storage
│   ├── Etapa B.3  Unirse / salir (`comunidad_miembro`)
│   └── Etapa B.4  Detalle comunidad remoto + conteo miembros
├── BLOQUE C — Salidas remotas
│   ├── Etapa C.1  `ModeloSalida` remoto + datasource
│   ├── Etapa C.2  Listar salidas (tab + por `lugar_id`)
│   ├── Etapa C.3  Crear salida (lugar picker Explora)
│   ├── Etapa C.4  Inscripción / cancelación participante
│   └── Etapa C.5  Desactivar check-in demo o marcar “próximamente”
├── BLOQUE D — Chat de comunidad
│   ├── Etapa D.1  CRUD `comunidad_mensaje`
│   └── Etapa D.2  Realtime en detalle / tab Mensajes (solo grupos)
└── BLOQUE E — Feed publicaciones
    ├── Etapa E.1  Listar `publicacion` + etiqueta comunidad
    ├── Etapa E.2  Crear post + etiquetar comunidad
    └── Etapa E.3  Tab Para ti remoto; retirar posts demo
```

**Orden:** 0 → A → B → C → D → E. No saltar RLS.

---

## BLOQUE 0 — RLS (cimiento)

| Paso | Qué | Criterio de cierre |
|------|-----|-------------------|
| 0.1 | Crear migración policies (+ helpers, sin ALTER) | [x] `20260915010000_comunidad_salida_rls.sql` |
| 0.2 | `db push` en VPS | [x] Applied `20260915010000` |
| 0.3 | Verificar policies + helpers en BD | [x] 15 policies; helpers OK; 0 filas |
| 0.4 | (Opcional) Seed comunidades Cusco | [x] push OK — 3 filas QA |

---

## BLOQUE A — Lectura remota

| Paso | Qué | Criterio de cierre |
|------|-----|-------------------|
| A.1 | `ComunidadHaku.desdeFilaRemota` | [x] Sin provincia/categorías en path remoto |
| A.2 | Datasource list + byId | [x] `comunidad_datasource_supabase.dart` |
| A.3 | `proveedor_comunidad.dart` | [x] FutureProviders |
| A.4 | Tab Comunidades | [x] Solo Supabase; vacío/error honestos |

---

## BLOQUE B — Crear / unirse

| Paso | Qué | Criterio de cierre |
|------|-----|-------------------|
| B.1 | Crear → insert comunidad + miembro admin | [x] Datasource + pantalla remota |
| B.2 | Foto portada opcional (NULL si no hay) | [x] Storage path `…/comunidades/` |
| B.3 | Unirse / salir | [x] Público aprobado; privado pendiente |
| B.4 | Detalle miembros nick + rol | [x] Embed `usuario` |
| B.3b | RLS ver solicitud pendiente | [x] Push `20260915030000` OK |

---

## BLOQUE C — Salidas remotas

| Paso | Qué | Criterio de cierre |
|------|-----|-------------------|
| C.1 | `ModeloSalidaRemota` (columnas BD) | [x] Sin dificultad/cuposGrupo/check-in |
| C.2 | Datasource + providers + tab/sheet | [x] Filtro por `punto_encuentro_lugar_id` |
| C.3 | Crear salida remota | [x] lugar Explora → lat/lon reales |
| C.4 | Inscripción / cancelar | [x] `confirmado` / `cancelado` |
| C.5 | Check-in | [x] Aviso honesto: no hay tabla |

---

## BLOQUE D — Mensajes

| Paso | Qué | Criterio de cierre |
|------|-----|-------------------|
| D.1 | Listar últimos N + enviar `comunidad_mensaje` | [x] Solo miembros aprobados; append-only |
| D.2 | Realtime + tab Mensajes / detalle | [x] Publication + canal INSERT; sin demo mezclado |

**Cuidados aplicados (forense pre-push)**
- Migration `20260915040000`: publication + CHECK texto 1..2000 + RLS miembro **o** admin/creador.
- Previews: 1 query `limit 1` por comunidad (no `limit` global que ocultaba chats quietos).
- Race Realtime: suscribir **antes** de fetch; dedupe por `id`; orden estable `fecha+id`.
- Canal con sufijo temporal anti-colisión al reabrir.
- Sin inventar `DateTime.now()` si falta `fecha_envio`.
- Nick desde embed o cache miembros; Realtime payload sin embed no inventa nombre.
- Badge no-leídos: no (sin tabla). Tab sin demo DMs mezclados.

---

## BLOQUE E — Feed

| Paso | Qué | Criterio de cierre |
|------|-----|-------------------|
| E.0 | RLS `publicacion*` (antes estaba ON sin policies) | [x] `20260915050000` + fix soft-delete `20260915060000` |
| E.1 | Lectura `estado=publico` + embeds | [x] Tab Para ti remoto |
| E.2 | Alta + etiqueta comunidad / lugar / foto opc. | [x] `PantallaCrearPublicacionRemota` |
| E.3 | Retirar demo del tab Para ti | [x] Sin mezclar `almacenFeed` posts |

**Cuidados forenses**
- **Bug crítico evitado:** RLS ON + 0 policies = feed vacío eterno.
- Sin likes/comentarios/Bunny (no hay tablas) → UI “próximamente”, no inventar contadores.
- Sin imagen inventada (`CatalogoImagenesHaku`) si no hay `publicacion_multimedia`.
- Soft-delete: `estado=eliminado` fuera de SELECT.
- CHECK contenido 1..4000.
- Botón `+` del shell → remoto si `supabaseListo`.
- **Requiere `db push`** de `20260915050000` y `20260915060000` (soft-delete) antes de probar.

---

## Orden de archivos frontend (implementación)

```
lib/funcionalidades/comunidad/
  datos/
    comunidad_datasource_supabase.dart
    salida_datasource_supabase.dart
    mensaje_comunidad_datasource_supabase.dart  ← Bloque D
    salidas_datasource_local.dart               ← legacy
  dominio/
    modelo_comunidad.dart
    modelo_salida.dart
    modelo_mensaje_comunidad.dart               ← Bloque D
  proveedores/
    proveedor_comunidad.dart
    proveedor_salidas.dart
    proveedor_mensajes_comunidad.dart           ← Bloque D
  pantallas/
    pantalla_chat_comunidad.dart                ← Bloque D
    …
```

Patrón: `supabaseListo` → datasource → provider → UI con vacío honesto (Explora).

---

## Checklist de avance (marcar al cerrar cada etapa)

### Terreno listo (doc)
- [x] Decisiones MVP
- [x] Inventarios BD + frontend + brechas
- [x] Contrato Supabase + RLS diseño
- [x] Mapa bloques 0–E

### Bloque 0
- [x] 0.1 Migración RLS (archivo local)
- [x] 0.2 Push VPS
- [x] 0.3 Verificación Postgres (policies + helpers)
- [x] 0.4 Seed QA (3 comunidades; push OK)

### Bloque A
- [x] A.1 Modelo
- [x] A.2 Datasource
- [x] A.3 Providers
- [x] A.4 Tab Comunidades

### Bloque B
- [x] B.1 Crear remota
- [x] B.2 Foto opcional
- [x] B.3 Unirse / salir
- [x] B.4 Miembros nick+rol
- [x] Push `20260915030000_comunidad_select_membresia.sql`

### Bloque C
- [x] C.1 Modelo remoto
- [x] C.2 Listados
- [x] C.3 Crear
- [x] C.4 Inscripción
- [x] C.5 Check-in no inventado

### Bloque D
- [x] D.1 Listar + enviar
- [x] D.2 Realtime + tab/detalle
- [x] Push `20260915040000_comunidad_mensaje_realtime.sql`

### Bloque E
- [x] E.0 RLS publicacion
- [x] E.1–E.3 app
- [x] Push `20260915050000_publicacion_rls.sql`
- [x] Push `20260915060000_publicacion_soft_delete_select.sql` (autor ve propias → soft-delete real; evita huérfanas en feed)
- [x] Push `20260915070000_publicacion_multimedia_tipo_default.sql` (DEFAULT `tipo=imagen`; front ya envía la columna)
- [x] Push `20260915080000_comunidad_salida_soft_select.sql` (creador/organizador SELECT tras soft-cancel; admin en INSERT salida)
- [x] Push `20260915090000_membresia_cupos_storage.sql` (sin auto-aprobación; cupos server-side; storage carpeta propia)

---

## Auditoría forense pre–smoke (hilos)

| Hilo | Inicio → Fin | Fixes aplicados |
|------|--------------|-----------------|
| H1 Comunidades | Listar → detalle → unir/salir/crear | `unirse(conocida:)`; create con rollback `estado=false` si falla admin; detalle sin demo si `supabaseListo` |
| H2 Salidas | Listar → crear → inscribir/cancelar | Re-inscripción tras `cancelado` = UPDATE (no INSERT PK); create rollback `cancelada` si falla org |
| H3 Chat | Previews → chat → send/realtime | (ya sólido: suscribir antes, dedupe, dispose) |
| H4 Para ti | Listar → crear | Soft-delete verificado + SELECT autor (mig 600); precheck etiqueta; snack con causa real |
| Transversal | Login/logout | `sesionProvider` en list providers; badges demo → 0 |

**Pendiente de producto (no bug de código):** discovery de privadas sin invitación; likes; cupos con race server-side.

---

*Documento de fase Comunidad — Bloques 0–E cerrados (código + pushes). Siguiente: smoke test.*
