-- Chat prod fase 1: admin crea comunidad; set_participante; sala salida + triggers.
-- Append-only sobre 15120000.

-- ---------------------------------------------------------------------------
-- 1) asegurar_sala_comunidad: solo admin CREA; sync aprobados si admin;
--    miembro solo entra si sala ya existe y está (o queda) en roster.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.asegurar_sala_comunidad(p_comunidad_id bigint)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_sala_id bigint;
  v_es_admin boolean;
  v_es_miembro boolean;
  v_ya_participa boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No autenticado'
      USING ERRCODE = '42501';
  END IF;

  v_es_admin := public.es_admin_comunidad(p_comunidad_id);
  v_es_miembro := public.es_miembro_comunidad_aprobado(p_comunidad_id);

  IF NOT (v_es_admin OR v_es_miembro) THEN
    RAISE EXCEPTION 'Sin acceso a esta comunidad'
      USING ERRCODE = '42501';
  END IF;

  SELECT s.id
    INTO v_sala_id
  FROM public.sala_chat s
  WHERE s.tipo = 'comunidad'::public.tipo_sala_chat
    AND s.comunidad_id = p_comunidad_id
  LIMIT 1;

  IF v_sala_id IS NULL THEN
    IF NOT v_es_admin THEN
      RAISE EXCEPTION 'Solo admin puede crear el chat de la comunidad'
        USING ERRCODE = '42501';
    END IF;
    INSERT INTO public.sala_chat (comunidad_id, tipo, estado)
    VALUES (
      p_comunidad_id,
      'comunidad'::public.tipo_sala_chat,
      true
    )
    RETURNING id INTO v_sala_id;
  END IF;

  -- Admin: sync todos los miembros aprobados (+ self).
  IF v_es_admin THEN
    INSERT INTO public.sala_participante (sala_id, usuario_id)
    SELECT v_sala_id, m.usuario_id
    FROM public.comunidad_miembro m
    WHERE m.comunidad_id = p_comunidad_id
      AND m.estado = 'aprobado'::public.estado_membresia
    ON CONFLICT DO NOTHING;

    INSERT INTO public.sala_participante (sala_id, usuario_id)
    VALUES (v_sala_id, auth.uid())
    ON CONFLICT DO NOTHING;

    RETURN v_sala_id;
  END IF;

  -- Miembro no-admin: solo si ya está en el roster (o acaba de ser sync por trigger).
  SELECT EXISTS (
    SELECT 1
    FROM public.sala_participante sp
    WHERE sp.sala_id = v_sala_id
      AND sp.usuario_id = auth.uid()
  ) INTO v_ya_participa;

  IF NOT v_ya_participa THEN
    RAISE EXCEPTION 'No estás en el chat de esta comunidad'
      USING ERRCODE = '42501';
  END IF;

  RETURN v_sala_id;
END;
$$;

COMMENT ON FUNCTION public.asegurar_sala_comunidad(bigint) IS
  'Admin crea sala + sync aprobados. Miembro solo abre si ya es sala_participante.';

-- ---------------------------------------------------------------------------
-- 2) Admin añade/quita participante (debe ser miembro aprobado)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.sala_comunidad_set_participante(
  p_sala_id bigint,
  p_usuario_id uuid,
  p_activo boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_comunidad_id bigint;
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

  IF p_activo THEN
    IF NOT EXISTS (
      SELECT 1
      FROM public.comunidad_miembro m
      WHERE m.comunidad_id = v_comunidad_id
        AND m.usuario_id = p_usuario_id
        AND m.estado = 'aprobado'::public.estado_membresia
    ) THEN
      RAISE EXCEPTION 'El usuario debe ser miembro aprobado'
        USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO public.sala_participante (sala_id, usuario_id)
    VALUES (p_sala_id, p_usuario_id)
    ON CONFLICT DO NOTHING;
  ELSE
    DELETE FROM public.sala_participante
    WHERE sala_id = p_sala_id
      AND usuario_id = p_usuario_id;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.sala_comunidad_set_participante(bigint, uuid, boolean)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sala_comunidad_set_participante(bigint, uuid, boolean)
  TO authenticated, service_role;

COMMENT ON FUNCTION public.sala_comunidad_set_participante(bigint, uuid, boolean) IS
  'Admin añade (activo=true) o quita (false) participante de sala comunidad.';

-- ---------------------------------------------------------------------------
-- 3) asegurar_sala_salida: organizador o confirmado; sync confirmados
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.asegurar_sala_salida(p_salida_id bigint)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_sala_id bigint;
  v_org uuid;
  v_es_org boolean;
  v_confirmado boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No autenticado'
      USING ERRCODE = '42501';
  END IF;

  SELECT s.organizador_id
    INTO v_org
  FROM public.salida s
  WHERE s.id = p_salida_id
    AND s.estado IS DISTINCT FROM 'cancelada'::public.estado_salida;

  IF v_org IS NULL THEN
    RAISE EXCEPTION 'Salida no encontrada'
      USING ERRCODE = 'P0002';
  END IF;

  v_es_org := (v_org = auth.uid());
  SELECT EXISTS (
    SELECT 1
    FROM public.salida_participante p
    WHERE p.salida_id = p_salida_id
      AND p.usuario_id = auth.uid()
      AND p.estado = 'confirmado'::public.estado_participante
  ) INTO v_confirmado;

  IF NOT (v_es_org OR v_confirmado) THEN
    RAISE EXCEPTION 'Sin acceso al chat de esta salida'
      USING ERRCODE = '42501';
  END IF;

  SELECT s.id
    INTO v_sala_id
  FROM public.sala_chat s
  WHERE s.tipo = 'salida'::public.tipo_sala_chat
    AND s.salida_id = p_salida_id
  LIMIT 1;

  IF v_sala_id IS NULL THEN
    IF NOT v_es_org THEN
      RAISE EXCEPTION 'Solo el organizador puede crear el chat de la salida'
        USING ERRCODE = '42501';
    END IF;
    INSERT INTO public.sala_chat (salida_id, tipo, estado)
    VALUES (
      p_salida_id,
      'salida'::public.tipo_sala_chat,
      true
    )
    RETURNING id INTO v_sala_id;
  END IF;

  -- Sync organizador + confirmados.
  INSERT INTO public.sala_participante (sala_id, usuario_id)
  VALUES (v_sala_id, v_org)
  ON CONFLICT DO NOTHING;

  INSERT INTO public.sala_participante (sala_id, usuario_id)
  SELECT v_sala_id, p.usuario_id
  FROM public.salida_participante p
  WHERE p.salida_id = p_salida_id
    AND p.estado = 'confirmado'::public.estado_participante
  ON CONFLICT DO NOTHING;

  RETURN v_sala_id;
END;
$$;

REVOKE ALL ON FUNCTION public.asegurar_sala_salida(bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.asegurar_sala_salida(bigint)
  TO authenticated, service_role;

COMMENT ON FUNCTION public.asegurar_sala_salida(bigint) IS
  'Organizador crea sala salida; sync confirmados. Confirmado puede abrir sala existente.';

-- ---------------------------------------------------------------------------
-- 4) Triggers salida_participante ↔ sala_participante
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_sala_on_salida_participante()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_sala_id bigint;
BEGIN
  IF TG_OP = 'DELETE' THEN
    SELECT s.id INTO v_sala_id
    FROM public.sala_chat s
    WHERE s.tipo = 'salida'::public.tipo_sala_chat
      AND s.salida_id = OLD.salida_id
    LIMIT 1;
    IF v_sala_id IS NOT NULL THEN
      DELETE FROM public.sala_participante
      WHERE sala_id = v_sala_id
        AND usuario_id = OLD.usuario_id;
    END IF;
    RETURN OLD;
  END IF;

  SELECT s.id INTO v_sala_id
  FROM public.sala_chat s
  WHERE s.tipo = 'salida'::public.tipo_sala_chat
    AND s.salida_id = NEW.salida_id
  LIMIT 1;

  IF v_sala_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.estado = 'confirmado'::public.estado_participante THEN
    INSERT INTO public.sala_participante (sala_id, usuario_id)
    VALUES (v_sala_id, NEW.usuario_id)
    ON CONFLICT DO NOTHING;
  ELSE
    DELETE FROM public.sala_participante
    WHERE sala_id = v_sala_id
      AND usuario_id = NEW.usuario_id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sala_on_salida_participante ON public.salida_participante;
CREATE TRIGGER trg_sala_on_salida_participante
  AFTER INSERT OR UPDATE OF estado OR DELETE ON public.salida_participante
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_sala_on_salida_participante();

REVOKE ALL ON FUNCTION public.fn_sala_on_salida_participante() FROM PUBLIC;
