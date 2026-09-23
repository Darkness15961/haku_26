-- Diagnostico de solo lectura para Fase 8.1 Rutas/PostGIS.
-- Ejecutar en el SQL editor remoto antes/despues del db push.

select
  e.extname,
  n.nspname as extension_schema,
  e.extversion
from pg_extension e
join pg_namespace n on n.oid = e.extnamespace
where e.extname = 'postgis';

select
  to_regtype('public.geometry') as public_geometry_type,
  to_regtype('public.geography') as public_geography_type;

select
  format_type(a.atttypid, a.atttypmod) as ruta_trazado_type,
  i.relname as gist_index
from pg_attribute a
join pg_class c on c.oid = a.attrelid
join pg_namespace n on n.oid = c.relnamespace
left join pg_index ix
  on ix.indrelid = c.oid
 and a.attnum = any(ix.indkey)
left join pg_class i
  on i.oid = ix.indexrelid
 and i.relname = 'idx_ruta_trazado_gist'
where n.nspname = 'public'
  and c.relname = 'ruta'
  and a.attname = 'trazado'
  and not a.attisdropped;

select
  p.proname,
  pg_get_function_identity_arguments(p.oid) as arguments
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'guardar_trazado_ruta_propia',
    'crear_ruta_publicada',
    'guardar_ruta_propia',
    'ruta_publicada_detalle',
    'ruta_propia_detalle'
  )
order by p.proname;
