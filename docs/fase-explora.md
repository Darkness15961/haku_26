# HAKU — Fase Explora (lugares + territorio)

Documento vivo (mismo estilo que `docs/fase-autenticacion.md`).  
Avanzamos **por bloques y etapas**. No cablear Comunidad, Rutas ni Salidas aquí.

**Informe narrativo de toda la fase (qué se hizo, en orden):** `docs/fase-explora-informe.md`.  
**Atributos de lugar (qué es de tu BD vs qué añadimos / formulario):** `docs/fase-explora-atributos-lugar.md`.

**Objetivo de producto:** las islas de provincia del frontend leen y escriben `public.lugar` + catálogo geo en Supabase.

---

## Principios

| Principio | Detalle |
|-----------|---------|
| Un sector | Solo Explora / lugares. Comunidad = otra fase. |
| Migraciones | Ya aplicadas no se editan. Cambios = migración nueva + `db push` (tú, túnel SSH). |
| SDK | Lectura/escritura con `supabase_flutter` (`.from('…')`). Sin HTTP manual. |
| Identidad | Todo lugar nuevo con `usuario_id = auth.uid()`. Retirar id demo `'yo'` en este sector. |
| UX territorio | Entrada = **provincia** (islas). Distrito = **obligatorio** al crear. Provincia se deriva del distrito. |
| Foto | `lugar.foto_portada` = URL (Storage bucket existente; paths tipados en etapa de media). |

---

## Decisiones de modelo (cerradas para esta fase)

| Tema | Decisión |
|------|----------|
| Departamento | MVP: solo **Cusco** (`codigo = cusco`). |
| Provincias | 13 filas; `codigo` = ids del frontend (`urubamba`, `la_convencion`, …). |
| Distrito | **Obligatorio** al crear. Provincia se deriva del distrito (sin `provincia_id` en `lugar`). |
| Geocoding auto (pin → distrito) | **Fuera** de esta fase (después). |
| Categorías | `categoria.tipo` = `tematica` \| `actividad` + `lugar_categoria` (N:N). |
| Calificación / distancia / nivel exploración | No columnas fijas en `lugar` ahora (derivados o fase 2). |

---

## Estado del backend (Explora)

| Objeto | Estado |
|--------|--------|
| `departamento` / `provincia` / `distrito` + `codigo` | Seed Cusco + 13 provincias + distritos |
| `categoria` (`tematica` / `actividad`) | Catálogo turista-first (Naturaleza, Trekking, …) |
| `lugar` + `provincia_id` + `distrito_id` nullable + ficha | Hecho |
| `lugar_categoria` | Hecho |
| PostGIS `ubicacion` + trigger lat/lon | Hecho (schema remoto) |
| RLS catálogo + lugares | Hecho (`20260912230000_explora_lugar_pulido.sql`) — **push aplicado** |

Migraciones clave:

- `20260912220617_remote_schema.sql` — dominio producto + PostGIS  
- `20260912230000_explora_lugar_pulido.sql` — pulido Explora + seed + RLS  

Detalle corto del pulido: `docs/fase-explora-bd.md`.

---

## Mapa de la fase

```
FASE EXPLORA
├── BLOQUE 0 — Pulido BD + seed + RLS          ← HECHO
├── BLOQUE A — Lectura remota                  ← HECHO
│   ├── Etapa 1  Datasource geo
│   ├── Etapa 2  Listar lugares por provincia
│   ├── Etapa 3  Detalle remoto
│   └── Etapa 4  Filtros distrito + categoría
├── BLOQUE B — Alta / edición de lugar         ← HECHO
│   ├── Etapa 1  Formulario alineado
│   ├── Etapa 2  INSERT lugar + categorías
│   └── Etapa 3  Foto portada Storage
└── BLOQUE C — Mapa / cercanía                 ← HECHO
    ├── Etapa 1  Pines remotos
    └── Etapa 2  RPC PostGIS (cercanía)
```

**Orden:** 0 ✓ → A ✓ → B ✓ → C ✓.  
**No mezclar** con Comunidad / Salidas / Publicaciones remotas en paralelo.

---

# BLOQUE 0 — Pulido BD

**Estado: HECHO** (migración aplicada en VPS).

| Paso | Qué | Estado |
|------|-----|--------|
| 0.1 | `provincia_id` obligatorio; `distrito_id` opcional | [x] |
| 0.2 | Ficha: `dificultad`, `tiempo_estimado`, `acceso` | [x] |
| 0.3 | Seed Cusco + 13 provincias + distritos + categorías | [x] |
| 0.4 | RLS lectura pública catálogo / lugares activos; escritura dueño | [x] |
| 0.5 | Verificar en BD: 13 provincias con `codigo`, categorías `tipo=lugar` | [x] |

Checklist visual en Studio:

- [x] `departamento` → fila Cusco
- [x] `provincia` → 13 filas con `codigo`
- [x] `distrito` → varios por provincia
- [x] `categoria` → 8 con `tipo = lugar`
- [x] `lugar` → columnas `provincia_id`, `distrito_id` (nullable), ficha

### Criterio de cierre Bloque 0

- [x] Migración `20260912230000_explora_lugar_pulido.sql` aplicada (`db push`)
- [x] Verificación visual en Studio (arriba)

---

# BLOQUE A — Lectura remota

**Estado: HECHO** (Flutter cableado a Supabase; provincias vacías = vacío honesto).

**Objetivo:** Explora deja de depender del catálogo hardcode de lugares para el listado real. Las **islas** pueden seguir usando assets locales (SVG/PNG) pero los **lugares** salen de Supabase.

## Etapa 1 — Datasource geo

| Paso | Qué | Estado |
|------|-----|--------|
| 1.1 | Servicio/datasource: `provincia` (filtro `departamento.codigo = cusco`) | [x] |
| 1.2 | Mapear `codigo` → assets del frontend (`ProvinciasDataSourceLocal`) | [x] |
| 1.3 | Datasource `distrito` por `provincia_id` (para filtros) | [x] |
| 1.4 | Datasource `categoria` donde `tipo = 'lugar'` | [x] |

## Etapa 2 — Listar lugares por provincia

| Paso | Qué | Estado |
|------|-----|--------|
| 2.1 | Query `lugar` + join/`select` provincia (y distrito si hay) | [x] |
| 2.2 | Filtrar `estado = true` y `provincia.codigo = …` | [x] |
| 2.3 | Cablear sheet/lista de isla: datos remotos (con loading/error) | [x] |
| 2.4 | Fallback temporal: si no hay filas remotas, lista vacía clara (no silent demo mix) | [x] |

## Etapa 3 — Detalle lugar

| Paso | Qué | Estado |
|------|-----|--------|
| 3.1 | Cargar un `lugar` por id (bigint) + categorías | [x] |
| 3.2 | Mostrar provincia / distrito / ficha / foto | [x] |
| 3.3 | Quitar dependencia de IDs string tipo `machu_picchu` en este flujo | [x] |

## Etapa 4 — Filtros UI (ligeros)

| Paso | Qué | Estado |
|------|-----|--------|
| 4.1 | Chip/filtro “Todos \| distrito…” dentro de la provincia | [x] |
| 4.2 | Filtro por categoría (usando `lugar_categoria`) | [x] |
| 4.3 | No saturar el primer viewport de la isla | [x] |

### Criterio de cierre Bloque A

- [x] Entras a una provincia y ves lugares reales del VPS (o vacío honesto)
- [x] Detalle abre sin crash
- [x] Etapas 1–4 marcadas

---

# BLOQUE B — Crear / editar lugar

**Estado: HECHO** (formulario → Supabase + Storage; sin almacén local).

## Etapa 1 — Formulario

| Paso | Qué | Estado |
|------|-----|--------|
| 1.1 | Provincia precargada desde la isla (obligatoria) | [x] |
| 1.2 | Distrito selector opcional (lista de esa provincia) | [x] |
| 1.3 | Categorías multi-select (`tipo=lugar`) | [x] |
| 1.4 | Dificultad / tiempo / acceso / descripción / coords básicas | [x] |

## Etapa 2 — Persistencia

| Paso | Qué | Estado |
|------|-----|--------|
| 2.1 | `insert` en `lugar` con `usuario_id = auth.uid()` | [x] |
| 2.2 | Inserts en `lugar_categoria` | [x] |
| 2.3 | Gate: requiere sesión (`asegurarSesion`) | [x] |
| 2.4 | Mensajes de error amigables (RLS / FK) | [x] |

## Etapa 3 — Foto portada

| Paso | Qué | Estado |
|------|-----|--------|
| 3.1 | Upload Storage (path tipo `{uid}/lugares/…`) | [x] |
| 3.2 | Guardar URL pública en `foto_portada` | [x] |

### Criterio de cierre Bloque B

- [x] Usuario logueado crea un lugar y aparece en su provincia (tras invalidar lista remota)
- [x] Etapas 1–3 marcadas

**Notas B:** coords por defecto Cusco (−13.53, −71.97) hasta Bloque C (mapa/pin). Edición de lugar ajeno = fuera de alcance ahora (solo alta).

---

# BLOQUE C — Mapa / PostGIS

**Estado: HECHO** (mapa + contorno Cusco + GPS + cercanía 50 km).  
Detalle: [`docs/explora-mapa-cercania.md`](explora-mapa-cercania.md).

## Etapa 1 — Mapa con datos remotos

| Paso | Qué | Estado |
|------|-----|--------|
| 1.1 | Pines desde `latitud` / `longitud` remotas | [x] |

**UI:** Explora → icono mapa → `PantallaMapaExplora` → `MapaExploraLugares`.

## Etapa 2 — Cercanía / geocoding

| Paso | Qué | Estado |
|------|-----|--------|
| 2.1 | RPC `lugares_cerca(lat, lon, radio_m)` con PostGIS | [x] |
| 2.2 | Sugerir distrito al soltar el pin (geocoding) | [ ] aplazado (fase aparte; ver “No hacer”) |

Migración: `supabase/migrations/20260912240000_explora_lugares_cerca.sql` — ya aplicada.

Flutter: GPS del turista → `lugaresCercaProvider` + chip «Cerca 50 km» + contorno departamental.

### Criterio de cierre Bloque C

- [x] Mapa muestra lugares remotos
- [x] Cercanía RPC hecha; geocoding documentado como aplazado

---

## Mapa de archivos (Flutter) — dónde tocar

| Qué | Dónde (hoy → destino) |
|-----|------------------------|
| Islas / Explora UI | `lib/funcionalidades/lugares/pantallas/pantalla_explora_lugares.dart` |
| Catálogo provincias assets | `…/lugares/datos/provincias_datasource_local.dart` (se mantiene para SVG/PNG) |
| Lugares demo | `…/lugares/datos/lugares_datasource_local.dart` (legacy; listado = remoto) |
| Lugares remoto | `…/lugares/datos/lugar_datasource_supabase.dart` (lectura + crear + foto + cerca) |
| Modelo | `…/lugares/dominio/modelos/modelo_lugar.dart` (ids bigint + provinciaCodigo) |
| Registrar | `…/lugares/pantallas/pantalla_registrar_lugar.dart` → Supabase |
| Mapa pines + contorno + GPS | `pantalla_mapa_explora.dart` + `mapa_explora_lugares.dart` |
| Contorno Cusco | `assets/mapas/departamento_cusco.geojson` |
| RPC cercanía | `20260912240000_explora_lugares_cerca.sql` → `lugares_cerca` (centro = GPS) |
| Cliente Supabase | `lib/nucleo/supabase/` |
| Auth gate | `lib/funcionalidades/autenticacion/navegacion_auth.dart` |

---

## No hacer en esta fase

- Cablear `comunidad`, `salida`, `ruta`, `publicacion` remotas.
- Geocoding / ubigeo automático.
- Likes, favoritos, valoraciones en BD.
- Mezclar datos demo `'yo'` con UUID real en inserts.
- Editar migraciones ya pusheadas.
- Volver a poner `provincia_id` en `lugar` (pureza: solo `distrito_id`).

---

## Checklist de avance (marcar al cerrar)

Vista rápida de toda la fase. Al terminar cada etapa, cambia `[ ]` → `[x]`.

### Bloque 0 — Pulido BD
- [x] Etapa / paso 0.1 — `provincia_id` + `distrito_id` nullable
- [x] Etapa / paso 0.2 — Ficha dificultad / tiempo / acceso
- [x] Etapa / paso 0.3 — Seed Cusco + 13 provincias + distritos + categorías
- [x] Etapa / paso 0.4 — RLS Explora
- [x] Etapa / paso 0.5 — Verificación en Studio

### Bloque A — Lectura remota
- [x] Etapa 1 — Datasource geo (provincia / distrito / categoría)
- [x] Etapa 2 — Listar lugares por provincia
- [x] Etapa 3 — Detalle lugar remoto
- [x] Etapa 4 — Filtros UI (distrito + categoría)

### Bloque B — Alta / edición
- [x] Etapa 1 — Formulario alineado a BD
- [x] Etapa 2 — INSERT lugar + categorías (`auth.uid`)
- [x] Etapa 3 — Foto portada Storage

### Bloque C — Mapa / PostGIS
- [x] Etapa 1 — Pines remotos en mapa
- [x] Etapa 2 — RPC cercanía; geocoding aplazado a propósito

### Cierre de fase Explora
- [x] Bloque 0 cerrado
- [x] Bloque A cerrado
- [x] Bloque B cerrado
- [x] Bloque C cerrado (geocoding aplazado y anotado)

---

## Próximo paso concreto

1. **`supabase db push`** de `20260912240000_explora_lugares_cerca.sql` (túnel).
2. Probar Explora → mapa → pines; chip «Cerca 50 km».
3. Fase Explora lista para producto; siguiente sector = Comunidad / Salidas / etc. (otro doc).

