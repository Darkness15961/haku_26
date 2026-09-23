# Fase 8.7 - Rutas: PostGIS y error `geography`

## Motivo

El error remoto:

```text
type "geography" does not exist
```

no venia del formulario ni de pegar GPX. Al publicar una Ruta se insertan filas
en `public.ruta_parada`; esa tabla conserva el trigger
`public.fn_sync_ubicacion()`, que sincroniza `ubicacion` con PostGIS.

El trigger usaba `ST_SetSRID`, `ST_MakePoint` y `::geography` sin calificar.
Cuando se ejecutaba desde los RPC de Rutas, que venian con `search_path = ''`,
Postgres no podia resolver el tipo `geography`.

## Cambios

- Se reescribe `public.fn_sync_ubicacion()` usando `public.st_setsrid`,
  `public.st_makepoint` y `::public.geography`.
- Se fija `search_path = public, extensions` en los RPC/funciones de Rutas que
  escriben o leen detalle.
- Se recrea `ruta_trazado_valido` con casts PostGIS calificados.
- Se notifica a PostgREST para recargar schema cache.
- En Flutter, `Crear Ruta` guarda una referencia segura al `ScaffoldMessenger`
  para no disparar el error de widget desactivado al mostrar un fallo remoto.

## Aplicacion

Aplicar la migracion:

```bash
supabase db push
```

Luego reconstruir/reiniciar la app Flutter antes de probar publicacion.

## Verificacion

Si vuelve a aparecer el error, ejecutar:

```sql
-- supabase/diagnostics/rutas_postgis_search_path_check.sql
```

El resultado esperado es:

- `public.geometry` y `public.geography` existen.
- `fn_sync_ubicacion` contiene `search_path=public, extensions`.
- `sync_usa_geography_calificada = true`.
- `sync_usa_postgis_calificado = true`.
