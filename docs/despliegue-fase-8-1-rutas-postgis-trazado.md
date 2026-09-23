# HAKU - Despliegue Fase 8.1 Rutas/PostGIS

## Objetivo

Corregir el bloqueo de creacion/actualizacion de Rutas asociado a errores de
tipo espacial, por ejemplo `type geography does not exist`.

Esta fase no cambia la UX ni elimina columnas. Solo asegura:

- extension `postgis` disponible en `public`;
- columna `public.ruta.trazado` como `geography(LineString,4326)`;
- indice GiST de trazado;
- RPC `guardar_trazado_ruta_propia(bigint, jsonb)` recreada con casts
  explicitos a `public.geometry` y `public.geography`.

## Archivos

- Migracion:
  `supabase/migrations/20260923094449_fase_8_1_rutas_postgis_trazado.sql`
- Diagnostico:
  `supabase/diagnostics/rutas_postgis_trazado_check.sql`

## Antes del push

Ejecutar el diagnostico en Supabase SQL Editor:

```sql
-- contenido de supabase/diagnostics/rutas_postgis_trazado_check.sql
```

Resultado esperado:

- `postgis` existe.
- `public_geometry_type` y `public_geography_type` no son `null`.
- `ruta_trazado_type` es `geography(LineString,4326)`.
- Existe `guardar_trazado_ruta_propia`.

Si `postgis` aparece en otro schema y `public.geography` es `null`, no avanzar
con pruebas de trazado hasta aplicar la migracion y revisar el resultado.

## Push

El propietario del proyecto ejecuta el push remoto:

```bash
supabase db push
```

## Despues del push

1. Ejecutar otra vez `rutas_postgis_trazado_check.sql`.
2. Crear una Ruta sin trazado desde Flutter.
3. Editar esa Ruta e importar un GeoJSON LineString simple.
4. Confirmar que `distancia_m` se calcula.
5. Abrir detalle de Ruta y verificar que el mapa dibuja el recorrido real.
6. Limpiar trazado desde edicion y confirmar que la Ruta queda solo con
   paradas.

## Reversion

No hay rollback destructivo recomendado para PostGIS ni para la columna
`trazado`.

Si la migracion falla, detener el despliegue y guardar el mensaje exacto. La
migracion esta escrita para fallar temprano con una explicacion si PostGIS no
esta disponible en `public`.
