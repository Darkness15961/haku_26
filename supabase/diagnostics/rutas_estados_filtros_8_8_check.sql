-- Diagnostico fase 8.8: estados de Mis Rutas y filtros publicos.
-- Ejecutar en Supabase SQL Editor despues de `supabase db push`.
--
-- Si la app muestra:
--   Could not find the function public.restaurar_ruta_propia(...) in the schema cache
-- entonces esta consulta debe confirmar si las RPC existen en el remoto.

select
  p.proname as funcion,
  pg_get_function_identity_arguments(p.oid) as argumentos,
  has_function_privilege('authenticated', p.oid, 'execute') as authenticated_execute
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'publicar_ruta_propia',
    'restaurar_ruta_propia',
    'eliminar_ruta_propia'
  )
order by p.proname;

select
  pol.polname as policy_name,
  pg_get_expr(pol.polqual, pol.polrelid) as using_expr
from pg_policy pol
join pg_class c on c.oid = pol.polrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname = 'ruta'
  and pol.polname = 'ruta_delete_propietario';

select
  estado_editorial,
  count(*) as total
from public.ruta
group by estado_editorial
order by estado_editorial;

select pg_notify('pgrst', 'reload schema') as recarga_postgrest_solicitada;
