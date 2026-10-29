-- Ejecutar solo si auditoria_integral_vps.sql confirma cron.job disponible.
-- Solo lectura. Los posibles tokens Bearer se redactan en el resultado.

BEGIN TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '15s';

SELECT
  jobid,
  jobname,
  schedule,
  active,
  database,
  username,
  regexp_replace(
    command,
    '(Bearer[[:space:]]+)[A-Za-z0-9._~-]+',
    '\1[REDACTED]',
    'gi'
  ) AS comando_redactado
FROM cron.job
ORDER BY jobid;

SELECT
  jobid,
  status,
  start_time,
  end_time
FROM cron.job_run_details
ORDER BY start_time DESC
LIMIT 20;

ROLLBACK;
