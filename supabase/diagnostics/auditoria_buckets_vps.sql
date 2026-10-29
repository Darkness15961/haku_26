-- Ejecutar solo si auditoria_integral_vps.sql confirma storage.buckets.
-- Solo recopila configuracion de buckets; no lista objetos ni propietarios.

BEGIN TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '15s';

SELECT
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets
ORDER BY id;

ROLLBACK;
