-- Diagnostico posterior a Fase 8.7.
-- Ejecutar en Supabase SQL Editor si vuelve a aparecer:
--   type "geography" does not exist

select
  'postgis_types' as chequeo,
  to_regtype('public.geometry') as geometry_type,
  to_regtype('public.geography') as geography_type;

select
  n.nspname as schema,
  p.proname as funcion,
  p.proconfig as configuracion
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname in ('public', 'privado')
  and p.proname in (
    'fn_sync_ubicacion',
    'crear_ruta_publicada',
    'guardar_ruta_propia',
    'guardar_trazado_ruta_propia',
    'ruta_escritura_respuesta',
    'preparar_ruta_parada_desde_lugar'
  )
order by n.nspname, p.proname;

select
  t.tgname as trigger,
  t.tgfoid::regprocedure::text as funcion
from pg_trigger t
where t.tgrelid = 'public.ruta_parada'::regclass
  and not t.tgisinternal
order by t.tgname;

select
  pg_get_functiondef('public.fn_sync_ubicacion()'::regprocedure)
    ilike '%::public.geography%' as sync_usa_geography_calificada,
  pg_get_functiondef('public.fn_sync_ubicacion()'::regprocedure)
    ilike '%public.st_makepoint%' as sync_usa_postgis_calificado;
