-- Cierre forense P0/P1: membresía sin auto-escalada + cupos server-side.
-- Append-only policies; sin DROP de datos.

-- ---------------------------------------------------------------------------
-- 1) comunidad_miembro: solo admin cambia estado/rol (cierra auto-aprobación)
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS comunidad_miembro_update_admin_o_propio ON public.comunidad_miembro;
CREATE POLICY comunidad_miembro_update_admin_o_propio ON public.comunidad_miembro
  FOR UPDATE TO authenticated
  USING (public.es_admin_comunidad(comunidad_id))
  WITH CHECK (public.es_admin_comunidad(comunidad_id));

COMMENT ON POLICY comunidad_miembro_update_admin_o_propio ON public.comunidad_miembro IS
  'Solo admin/creador aprueba o cambia rol. El miembro sale con DELETE propio.';

-- ---------------------------------------------------------------------------
-- 2) Cupos + estado de salida al confirmar participación (INSERT u UPDATE)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_salida_participante_respetar_cupos()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_cupos integer;
  v_estado public.estado_salida;
  v_confirmados integer;
BEGIN
  -- Solo cuando la fila queda confirmada.
  IF NEW.estado IS DISTINCT FROM 'confirmado'::public.estado_participante THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'UPDATE'
     AND OLD.estado = 'confirmado'::public.estado_participante THEN
    RETURN NEW;
  END IF;

  SELECT s.cupos_totales, s.estado
    INTO v_cupos, v_estado
  FROM public.salida s
  WHERE s.id = NEW.salida_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Salida no encontrada'
      USING ERRCODE = 'P0002';
  END IF;

  IF v_estado IS DISTINCT FROM 'programada'::public.estado_salida THEN
    RAISE EXCEPTION 'Esta salida no admite inscripciones'
      USING ERRCODE = 'P0001';
  END IF;

  SELECT count(*)::integer
    INTO v_confirmados
  FROM public.salida_participante p
  WHERE p.salida_id = NEW.salida_id
    AND p.estado = 'confirmado'::public.estado_participante
    AND p.usuario_id IS DISTINCT FROM NEW.usuario_id;

  IF v_confirmados >= v_cupos THEN
    RAISE EXCEPTION 'No hay cupos disponibles'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_salida_participante_cupos ON public.salida_participante;
CREATE TRIGGER trg_salida_participante_cupos
  BEFORE INSERT OR UPDATE OF estado ON public.salida_participante
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_salida_participante_respetar_cupos();

REVOKE ALL ON FUNCTION public.fn_salida_participante_respetar_cupos() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fn_salida_participante_respetar_cupos()
  TO authenticated, service_role;

COMMENT ON FUNCTION public.fn_salida_participante_respetar_cupos() IS
  'Anti-carrera de cupos: bloquea salida al confirmar y cuenta confirmados.';

-- ---------------------------------------------------------------------------
-- 3) Storage: solo escribir bajo carpeta propia (uid/...)
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Solo usuarios autenticados pueden subir" ON storage.objects;
CREATE POLICY "Solo usuarios autenticados pueden subir"
  ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'haku-storage-produccion-2026'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
