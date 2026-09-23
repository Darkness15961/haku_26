# HAKU - Despliegue Fase 8.6 Rutas Forense PostGIS/RPC

## Motivo

El error remoto `type "geography" does not exist` aparece al publicar una Ruta
sin recorrido real. Flutter no envia `geography`; la escritura llama a la RPC
`crear_ruta_publicada`.

La causa mas probable es que la RPC remota siga acoplada a funciones de detalle
que planifican casts/funciones PostGIS antes de responder. Eso puede fallar
aunque `ruta.trazado` sea `NULL`.

## Cambio

La migracion `20260923111527_fase_8_6_rutas_forense_postgis_rpc.sql`:

- crea `ruta_trazado_geojson(bigint)` como helper aislado para el trazado;
- reescribe `ruta_publicada_detalle()` y `ruta_propia_detalle()` para usar ese
  helper;
- reescribe `crear_ruta_publicada()`, `guardar_ruta_propia()` y
  `archivar_ruta_propia()` para devolver `ruta_escritura_respuesta()`;
- evita que las escrituras de Rutas llamen `ST_AsGeoJSON` o casteen trazado;
- conserva el trazado real para lectura de detalle/mapa.

## Verificacion

Despues del `db push`, ejecutar:

```sql
-- supabase/diagnostics/rutas_forense_geography_error_check.sql
```

Resultado esperado:

- `crear_ruta_publicada`: `usa_respuesta_escritura = true`,
  `llama_detalle_publicado = false`, `usa_st_asgeojson = false`.
- `guardar_ruta_propia`: `usa_respuesta_escritura = true`,
  `llama_detalle_propio = false`, `usa_st_asgeojson = false`.
- `ruta_publicada_detalle` y `ruta_propia_detalle`: usan
  `ruta_trazado_geojson`.
- `ruta.trazado` sigue siendo `geography(LineString,4326)`.

## Prueba manual

1. Crear una Ruta con dos Lugares.
2. No pegar recorrido real.
3. Confirmar publicacion solo con paradas.
4. Debe publicar sin mostrar `type "geography" does not exist`.

Si el error persiste, copiar del SQL Editor el resultado del diagnostico y del
log de PostgREST el `code`, `message`, `details` y `hint`.
