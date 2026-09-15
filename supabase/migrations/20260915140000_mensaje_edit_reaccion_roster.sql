-- Chat escalable: soft edit/delete + reacciones + Realtime UPDATE.
-- Append-only sobre 15130000. No rompe INSERT/SELECT existentes.

-- ---------------------------------------------------------------------------
-- 1) Soft edit / delete en mensaje
-- ---------------------------------------------------------------------------

ALTER TABLE public.mensaje
  ADD COLUMN IF NOT EXISTS editado_en timestamptz;

ALTER TABLE public.mensaje
  ADD COLUMN IF NOT EXISTS eliminado_en timestamptz;

COMMENT ON COLUMN public.mensaje.editado_en IS
  'Marca de edición; contenido sigue sujeto a mensaje_contenido_valido.';
COMMENT ON COLUMN public.mensaje.eliminado_en IS
  'Soft delete. El contenido se conserva; la UI muestra placeholder.';

CREATE INDEX IF NOT EXISTS idx_mensaje_sala_vivos
  ON public.mensaje (sala_id, fecha_envio DESC)
  WHERE eliminado_en IS NULL;

-- Autor puede editar/soft-borrar su mensaje (sigue siendo participante).
DROP POLICY IF EXISTS mensaje_update_propio ON public.mensaje;
CREATE POLICY mensaje_update_propio ON public.mensaje
  FOR UPDATE
  TO authenticated
  USING (
    usuario_id = auth.uid()
    AND sala_id IN (
      SELECT sp.sala_id
      FROM public.sala_participante sp
      WHERE sp.usuario_id = auth.uid()
    )
  )
  WITH CHECK (
    usuario_id = auth.uid()
    AND sala_id IN (
      SELECT sp.sala_id
      FROM public.sala_participante sp
      WHERE sp.usuario_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- 2) Reacciones: 1 emoji por usuario por mensaje (toggle/replace)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.mensaje_reaccion (
  mensaje_id bigint NOT NULL
    REFERENCES public.mensaje (id) ON DELETE CASCADE,
  usuario_id uuid NOT NULL
    REFERENCES public.usuario (id) ON DELETE CASCADE,
  emoji text NOT NULL,
  fecha timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT mensaje_reaccion_pkey PRIMARY KEY (mensaje_id, usuario_id),
  CONSTRAINT mensaje_reaccion_emoji_valido CHECK (
    char_length(btrim(emoji)) >= 1
    AND char_length(emoji) <= 16
  )
);

ALTER TABLE public.mensaje_reaccion ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_mensaje_reaccion_mensaje
  ON public.mensaje_reaccion (mensaje_id);

COMMENT ON TABLE public.mensaje_reaccion IS
  'Reacción única por usuario/mensaje. Escalable sin hinchar mensaje.';

-- Ver reacciones de mensajes de salas donde participo.
DROP POLICY IF EXISTS mensaje_reaccion_select ON public.mensaje_reaccion;
CREATE POLICY mensaje_reaccion_select ON public.mensaje_reaccion
  FOR SELECT
  TO authenticated
  USING (
    mensaje_id IN (
      SELECT m.id
      FROM public.mensaje m
      WHERE m.sala_id IN (
        SELECT sp.sala_id
        FROM public.sala_participante sp
        WHERE sp.usuario_id = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS mensaje_reaccion_insert ON public.mensaje_reaccion;
CREATE POLICY mensaje_reaccion_insert ON public.mensaje_reaccion
  FOR INSERT
  TO authenticated
  WITH CHECK (
    usuario_id = auth.uid()
    AND mensaje_id IN (
      SELECT m.id
      FROM public.mensaje m
      WHERE m.eliminado_en IS NULL
        AND m.sala_id IN (
          SELECT sp.sala_id
          FROM public.sala_participante sp
          WHERE sp.usuario_id = auth.uid()
        )
    )
  );

DROP POLICY IF EXISTS mensaje_reaccion_update ON public.mensaje_reaccion;
CREATE POLICY mensaje_reaccion_update ON public.mensaje_reaccion
  FOR UPDATE
  TO authenticated
  USING (usuario_id = auth.uid())
  WITH CHECK (
    usuario_id = auth.uid()
    AND mensaje_id IN (
      SELECT m.id
      FROM public.mensaje m
      WHERE m.eliminado_en IS NULL
        AND m.sala_id IN (
          SELECT sp.sala_id
          FROM public.sala_participante sp
          WHERE sp.usuario_id = auth.uid()
        )
    )
  );

DROP POLICY IF EXISTS mensaje_reaccion_delete ON public.mensaje_reaccion;
CREATE POLICY mensaje_reaccion_delete ON public.mensaje_reaccion
  FOR DELETE
  TO authenticated
  USING (usuario_id = auth.uid());

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mensaje_reaccion
  TO authenticated, service_role;

-- Realtime: edits + reacciones (INSERT ya estaba en mensaje).
ALTER PUBLICATION supabase_realtime ADD TABLE public.mensaje_reaccion;

-- ---------------------------------------------------------------------------
-- 3) RPC batch roster (admin): menos round-trips en picker
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.sala_comunidad_set_participantes_batch(
  p_sala_id bigint,
  p_agregar uuid[],
  p_quitar uuid[]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_comunidad_id bigint;
  v_uid uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No autenticado'
      USING ERRCODE = '42501';
  END IF;

  SELECT s.comunidad_id
    INTO v_comunidad_id
  FROM public.sala_chat s
  WHERE s.id = p_sala_id
    AND s.tipo = 'comunidad'::public.tipo_sala_chat
    AND s.estado = true;

  IF v_comunidad_id IS NULL THEN
    RAISE EXCEPTION 'Sala de comunidad no encontrada'
      USING ERRCODE = 'P0002';
  END IF;

  IF NOT public.es_admin_comunidad(v_comunidad_id) THEN
    RAISE EXCEPTION 'Solo admin puede gestionar el chat'
      USING ERRCODE = '42501';
  END IF;

  IF p_agregar IS NOT NULL THEN
    FOREACH v_uid IN ARRAY p_agregar
    LOOP
      IF EXISTS (
        SELECT 1
        FROM public.comunidad_miembro m
        WHERE m.comunidad_id = v_comunidad_id
          AND m.usuario_id = v_uid
          AND m.estado = 'aprobado'::public.estado_membresia
      ) THEN
        INSERT INTO public.sala_participante (sala_id, usuario_id)
        VALUES (p_sala_id, v_uid)
        ON CONFLICT DO NOTHING;
      END IF;
    END LOOP;
  END IF;

  IF p_quitar IS NOT NULL THEN
    FOREACH v_uid IN ARRAY p_quitar
    LOOP
      -- No permitir que el admin se auto-quite del roster vía batch
      -- (evita quedar sin acceso al chat que administra).
      IF v_uid = auth.uid() THEN
        CONTINUE;
      END IF;
      DELETE FROM public.sala_participante
      WHERE sala_id = p_sala_id
        AND usuario_id = v_uid;
    END LOOP;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.sala_comunidad_set_participantes_batch(bigint, uuid[], uuid[])
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sala_comunidad_set_participantes_batch(bigint, uuid[], uuid[])
  TO authenticated, service_role;

COMMENT ON FUNCTION public.sala_comunidad_set_participantes_batch(bigint, uuid[], uuid[]) IS
  'Admin: alta/baja masiva de participantes. Solo miembros aprobados. No auto-quita al admin.';
