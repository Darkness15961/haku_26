# Explora — notas del pulido BD (Bloque 0 + C)

Complemento de `docs/fase-explora.md`.

Migraciones:

- `supabase/migrations/20260912230000_explora_lugar_pulido.sql` — territorio + ficha + RLS
- `supabase/migrations/20260912240000_explora_lugares_cerca.sql` — RPC `lugares_cerca` (PostGIS)

| Tema | Decisión |
|------|----------|
| Navegación | Cusco → 13 provincias → lugares; distrito = filtro opcional |
| Categorías | `categoria.tipo = 'lugar'` + `lugar_categoria` |
| Distrito | nullable; `provincia_id` obligatorio |
| Foto | `lugar.foto_portada` (URL) |
| Cercanía | `lugares_cerca` desde **GPS del turista** (no plaza fija) + contorno Cusco en mapa |
| Geocoding | Aplazado (fuera de Explora MVP) |

Ver fases y etapas de integración Flutter en **`docs/fase-explora.md`**.
