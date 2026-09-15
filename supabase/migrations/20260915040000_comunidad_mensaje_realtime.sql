-- Bloque D: Realtime + endurecimiento backend de comunidad_mensaje.
-- Idempotente. Sin DROP de datos. Sin tocar otras tablas de producto.

-- ---------------------------------------------------------------------------
-- 1) Publication Realtime (sin esto postgres_changes no emite INSERTs)
-- ---------------------------------------------------------------------------

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_publication
    WHERE pubname = 'supabase_realtime'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'comunidad_mensaje'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.comunidad_mensaje;
  END IF;
END $$;

-- INSERT-only: DEFAULT basta. FULL solo haría falta para UPDATE/DELETE con old row.
-- (MVP append-only → no cambiamos REPLICA IDENTITY.)

-- ---------------------------------------------------------------------------
-- 2) Integridad de contenido (anti spam vacío / payloads absurdos)
-- ---------------------------------------------------------------------------

ALTER TABLE public.comunidad_mensaje
  DROP CONSTRAINT IF EXISTS comunidad_mensaje_texto_valido;

ALTER TABLE public.comunidad_mensaje
  ADD CONSTRAINT comunidad_mensaje_texto_valido
  CHECK (
    char_length(btrim(mensaje)) >= 1
    AND char_length(mensaje) <= 2000
  );

-- ---------------------------------------------------------------------------
-- 3) RLS: creador/admin también (edge: fila miembro faltante / desfase)
--    Policies previas solo usaban es_miembro_comunidad_aprobado.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS comunidad_mensaje_select_miembro ON public.comunidad_mensaje;
CREATE POLICY comunidad_mensaje_select_miembro ON public.comunidad_mensaje
  FOR SELECT TO authenticated
  USING (
    public.es_miembro_comunidad_aprobado(comunidad_id)
    OR public.es_admin_comunidad(comunidad_id)
  );

DROP POLICY IF EXISTS comunidad_mensaje_insert_miembro ON public.comunidad_mensaje;
CREATE POLICY comunidad_mensaje_insert_miembro ON public.comunidad_mensaje
  FOR INSERT TO authenticated
  WITH CHECK (
    usuario_id = auth.uid()
    AND (
      public.es_miembro_comunidad_aprobado(comunidad_id)
      OR public.es_admin_comunidad(comunidad_id)
    )
  );

-- Sin UPDATE/DELETE en MVP (historial append-only).

COMMENT ON TABLE public.comunidad_mensaje IS
  'Chat comunidad. Realtime=supabase_realtime. SELECT/INSERT: miembro aprobado o admin/creador. texto 1..2000.';

COMMENT ON CONSTRAINT comunidad_mensaje_texto_valido ON public.comunidad_mensaje IS
  'Mensaje no vacío (trim) y máximo 2000 caracteres.';
