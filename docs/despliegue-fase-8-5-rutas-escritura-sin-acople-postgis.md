# HAKU - Despliegue Fase 8.5 Rutas sin acople PostGIS en escritura

## Motivo

La base remota confirma que `public.geography` existe y que
`public.ruta.trazado` es `geography(LineString,4326)`. Por eso, si crear una
Ruta sin recorrido real falla con un error espacial, el problema no debe
resolverse tocando PostGIS globalmente.

La causa estructural era que las RPC de escritura devolvian el detalle completo
de Ruta, y ese detalle procesa `trazado` con `ST_AsGeoJSON`. Crear/editar una
Ruta sin recorrido no debe depender de ese paso.

## Cambio

La migracion `20260923103438_fase_8_5_rutas_escritura_sin_acople_postgis.sql`:

- agrega `public.ruta_escritura_respuesta(bigint)`;
- hace que `crear_ruta_publicada()` devuelva esa respuesta liviana;
- hace que `guardar_ruta_propia()` devuelva esa respuesta liviana;
- hace que `archivar_ruta_propia()` devuelva esa respuesta liviana;
- mantiene `trazado_geojson` como `null` en respuestas de escritura;
- deja el procesamiento espacial para detalle/mapa o para
  `guardar_trazado_ruta_propia()`.

## Verificacion remota

Antes y despues del `db push`, ejecutar:

```sql
-- supabase/diagnostics/rutas_escritura_sin_acople_postgis_check.sql
```

Resultado esperado despues del push:

- `crear_ruta_publicada`: `usa_st_asgeojson = false`,
  `castea_trazado = false`, `usa_respuesta_liviana = true`.
- `guardar_ruta_propia`: `usa_st_asgeojson = false`,
  `castea_trazado = false`, `usa_respuesta_liviana = true`.
- `archivar_ruta_propia`: `usa_respuesta_liviana = true`.
- `ruta.trazado` sigue siendo `geography(LineString,4326)`.

## Prueba manual

1. Crear Ruta con dos Lugares y sin recorrido real.
2. Confirmar publicacion solo con paradas.
3. Abrir el detalle de la Ruta.
4. Editar la Ruta sin tocar recorrido.
5. Importar recorrido real solo despues, desde el flujo de recorrido.

Si falla la creacion sin recorrido real, capturar el `code`, `message`,
`details` y `hint` del `PostgrestException`.
