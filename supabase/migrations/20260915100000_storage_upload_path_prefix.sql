-- Hotfix storage INSERT: foldername a veces falla según path;
-- aceptar también prefijo uid/ explícito (mismo contrato de app).

DROP POLICY IF EXISTS "Solo usuarios autenticados pueden subir" ON storage.objects;
CREATE POLICY "Solo usuarios autenticados pueden subir"
  ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'haku-storage-produccion-2026'
    AND (
      (storage.foldername(name))[1] = (auth.uid())::text
      OR name LIKE ((auth.uid())::text || '/%')
    )
  );
