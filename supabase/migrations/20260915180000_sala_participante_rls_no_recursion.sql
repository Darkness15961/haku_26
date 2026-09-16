-- Fix: infinite recursion en RLS de sala_participante.
-- Causa: policy SELECT de sala_participante se auto-consulta; al INSERT mensaje
-- la policy de mensaje lee sala_participante → recursión.
-- NO es tema de salas/comunidades viejas: afecta a todas.
-- Solución: helper SECURITY DEFINER (bypass RLS) + policies que lo usan.

CREATE OR REPLACE FUNCTION public.es_participante_sala(p_sala_id bigint)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.sala_participante sp
    WHERE sp.sala_id = p_sala_id
      AND sp.usuario_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION public.es_participante_sala(bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.es_participante_sala(bigint)
  TO authenticated, service_role;

COMMENT ON FUNCTION public.es_participante_sala(bigint) IS
  'True si auth.uid() está en sala_participante. SECURITY DEFINER evita recursión RLS.';

-- ---------------------------------------------------------------------------
-- sala_participante: ver filas de salas donde participo (sin auto-query RLS)
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS sala_participante_select ON public.sala_participante;
CREATE POLICY sala_participante_select ON public.sala_participante
  FOR SELECT
  TO authenticated
  USING (public.es_participante_sala(sala_id));

-- ---------------------------------------------------------------------------
-- sala_chat / mensaje
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS sala_chat_select ON public.sala_chat;
CREATE POLICY sala_chat_select ON public.sala_chat
  FOR SELECT
  TO authenticated
  USING (public.es_participante_sala(id));

DROP POLICY IF EXISTS mensaje_select ON public.mensaje;
CREATE POLICY mensaje_select ON public.mensaje
  FOR SELECT
  TO authenticated
  USING (public.es_participante_sala(sala_id));

DROP POLICY IF EXISTS mensaje_insert ON public.mensaje;
CREATE POLICY mensaje_insert ON public.mensaje
  FOR INSERT
  TO authenticated
  WITH CHECK (
    usuario_id = auth.uid()
    AND public.es_participante_sala(sala_id)
  );

DROP POLICY IF EXISTS mensaje_update_propio ON public.mensaje;
CREATE POLICY mensaje_update_propio ON public.mensaje
  FOR UPDATE
  TO authenticated
  USING (
    usuario_id = auth.uid()
    AND public.es_participante_sala(sala_id)
  )
  WITH CHECK (
    usuario_id = auth.uid()
    AND public.es_participante_sala(sala_id)
  );

-- ---------------------------------------------------------------------------
-- mensaje_reaccion: usar sala_id denormalizado + helper (sin subquery RLS)
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS mensaje_reaccion_select ON public.mensaje_reaccion;
CREATE POLICY mensaje_reaccion_select ON public.mensaje_reaccion
  FOR SELECT
  TO authenticated
  USING (public.es_participante_sala(sala_id));

DROP POLICY IF EXISTS mensaje_reaccion_insert ON public.mensaje_reaccion;
CREATE POLICY mensaje_reaccion_insert ON public.mensaje_reaccion
  FOR INSERT
  TO authenticated
  WITH CHECK (
    usuario_id = auth.uid()
    AND public.es_participante_sala(sala_id)
  );

DROP POLICY IF EXISTS mensaje_reaccion_update ON public.mensaje_reaccion;
CREATE POLICY mensaje_reaccion_update ON public.mensaje_reaccion
  FOR UPDATE
  TO authenticated
  USING (
    usuario_id = auth.uid()
    AND public.es_participante_sala(sala_id)
  )
  WITH CHECK (
    usuario_id = auth.uid()
    AND public.es_participante_sala(sala_id)
  );

DROP POLICY IF EXISTS mensaje_reaccion_delete ON public.mensaje_reaccion;
CREATE POLICY mensaje_reaccion_delete ON public.mensaje_reaccion
  FOR DELETE
  TO authenticated
  USING (
    usuario_id = auth.uid()
    AND public.es_participante_sala(sala_id)
  );
