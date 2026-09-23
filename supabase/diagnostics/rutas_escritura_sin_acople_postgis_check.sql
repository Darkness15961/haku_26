-- Diagnostico de solo lectura para Fase 8.5.
-- Verifica que las RPC de escritura de Rutas no procesen trazado/PostGIS.

select
  p.proname,
  pg_get_function_identity_arguments(p.oid) as args,
  pg_get_functiondef(p.oid) ilike '%st_asgeojson%' as usa_st_asgeojson,
  pg_get_functiondef(p.oid) ilike '%trazado::%' as castea_trazado,
  pg_get_functiondef(p.oid) ilike '%ruta_escritura_respuesta%' as usa_respuesta_liviana
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.prokind = 'f'
  and p.proname in (
    'crear_ruta_publicada',
    'guardar_ruta_propia',
    'archivar_ruta_propia',
    'ruta_escritura_respuesta'
  )
order by p.proname;

select
  format_type(a.atttypid, a.atttypmod) as ruta_trazado_type
from pg_attribute a
join pg_class c on c.oid = a.attrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname = 'ruta'
  and a.attname = 'trazado'
  and not a.attisdropped;
