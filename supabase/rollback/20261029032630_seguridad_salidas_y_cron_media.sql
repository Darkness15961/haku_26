-- Reversion operativa fail-closed. No restaura el endpoint anonimo anterior.
-- Ejecutar manualmente solo si el despliegue nuevo impide operar.
BEGIN;

SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'limpiador-media-cron';

REVOKE ALL ON FUNCTION public.listar_salidas_resumen(bigint, bigint, bigint)
  FROM PUBLIC, anon, authenticated;

COMMIT;
