-- Lectura pública de objetos del bucket de producción (avatares / media).
-- Necesario para que foto_perfil (URL pública) se vea sin sesión en otros clientes.
-- Cuando migren a S3/MinIO, esta policy deja de importar; public.usuario.foto_perfil
-- sigue siendo solo un string URL.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Lectura publica bucket haku'
  ) THEN
    CREATE POLICY "Lectura publica bucket haku"
      ON storage.objects
      FOR SELECT
      TO public
      USING (bucket_id = 'haku-storage-produccion-2026');
  END IF;
END $$;
