-- Verificacion posterior al despliegue. Solo lectura y sin valores secretos.
BEGIN TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '15s';

SELECT
  p.proname AS funcion,
  pg_get_function_identity_arguments(p.oid) AS argumentos,
  p.prosecdef AS security_definer,
  p.proconfig AS configuracion,
  EXISTS (
    SELECT 1
    FROM aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) AS a
    WHERE a.grantee = 0
      AND a.privilege_type = 'EXECUTE'
  ) AS ejecutable_por_public,
  has_function_privilege('anon', p.oid, 'EXECUTE') AS ejecutable_por_anon,
  has_function_privilege('authenticated', p.oid, 'EXECUTE')
    AS ejecutable_por_authenticated
FROM pg_proc AS p
JOIN pg_namespace AS n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
    'listar_salidas_resumen',
    'fn_encolar_media_eliminada',
    'fn_publicacion_soft_delete_media'
  )
ORDER BY p.proname;

SELECT
  jobid,
  jobname,
  schedule,
  active,
  command LIKE '%limpiador_media_function_url%' AS url_desde_vault,
  command LIKE '%limpiador_media_cron_secret%' AS secreto_desde_vault,
  command LIKE '%service_role%' AS contiene_service_role,
  command LIKE '%supabase.haku.best%' AS contiene_url_produccion_hardcodeada
FROM cron.job
WHERE jobname = 'limpiador-media-cron';

SELECT
  name,
  created_at IS NOT NULL AS configurado
FROM vault.secrets
WHERE name IN (
  'limpiador_media_function_url',
  'limpiador_media_cron_secret'
)
ORDER BY name;

ROLLBACK;
