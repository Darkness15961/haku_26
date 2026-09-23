-- Diagnostico forense de Rutas / PostGIS.
-- Ejecutar en Supabase SQL Editor despues de aplicar la migracion 8.6.

select
  e.extname,
  n.nspname as extension_schema
from pg_extension e
join pg_namespace n on n.oid = e.extnamespace
where e.extname = 'postgis';

select
  to_regtype('public.geometry') as public_geometry,
  to_regtype('public.geography') as public_geography,
  to_regtype('extensions.geometry') as extensions_geometry,
  to_regtype('extensions.geography') as extensions_geography;

select
  format_type(a.atttypid, a.atttypmod) as ruta_trazado_type
from pg_attribute a
join pg_class c on c.oid = a.attrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname = 'ruta'
  and a.attname = 'trazado'
  and not a.attisdropped;

select
  p.proname,
  pg_get_function_identity_arguments(p.oid) as args,
  pg_get_functiondef(p.oid) ilike '%ruta_escritura_respuesta%' as usa_respuesta_escritura,
  pg_get_functiondef(p.oid) ilike '%ruta_publicada_detalle%' as llama_detalle_publicado,
  pg_get_functiondef(p.oid) ilike '%ruta_propia_detalle%' as llama_detalle_propio,
  pg_get_functiondef(p.oid) ilike '%st_asgeojson%' as usa_st_asgeojson,
  pg_get_functiondef(p.oid) ilike '%::geography%' as cast_geography_sin_schema,
  pg_get_functiondef(p.oid) ilike '%::geometry%' as cast_geometry_sin_schema,
  pg_get_functiondef(p.oid) ilike '%::public.geography%' as cast_public_geography,
  pg_get_functiondef(p.oid) ilike '%::public.geometry%' as cast_public_geometry
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.prokind = 'f'
  and p.proname in (
    'crear_ruta_publicada',
    'guardar_ruta_propia',
    'archivar_ruta_propia',
    'ruta_escritura_respuesta',
    'ruta_publicada_detalle',
    'ruta_propia_detalle',
    'ruta_trazado_geojson',
    'guardar_trazado_ruta_propia'
  )
order by p.proname, args;

select
  tg.tgname as trigger_name,
  c.relname as table_name,
  p.proname as function_name,
  pg_get_functiondef(p.oid) ilike '%geography%' as function_mentions_geography,
  pg_get_functiondef(p.oid) ilike '%geometry%' as function_mentions_geometry
from pg_trigger tg
join pg_class c on c.oid = tg.tgrelid
join pg_proc p on p.oid = tg.tgfoid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('ruta', 'ruta_parada')
  and not tg.tgisinternal
order by c.relname, tg.tgname;

select
  con.conname,
  c.relname as table_name,
  pg_get_constraintdef(con.oid) as definition
from pg_constraint con
join pg_class c on c.oid = con.conrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('ruta', 'ruta_parada')
  and pg_get_constraintdef(con.oid) ilike any (array[
    '%geography%',
    '%geometry%',
    '%st_%'
  ])
order by c.relname, con.conname;
