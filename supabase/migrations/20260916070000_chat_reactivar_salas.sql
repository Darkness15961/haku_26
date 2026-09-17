-- Una sala inactiva no debe bloquear para siempre el chat de una entidad activa.
-- Solo el administrador/organizador puede reactivarla y repoblar su roster.

CREATE OR REPLACE FUNCTION public.asegurar_sala_comunidad(
  p_comunidad_id bigint,
  p_seed_aprobados boolean
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_sala_id bigint;
  v_sala_activa boolean;
  v_es_admin boolean;
  v_es_miembro boolean;
  v_ya_participa boolean;
  v_inicializar boolean := false;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No autenticado' USING ERRCODE = '42501';
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended('sala_chat_comunidad:' || p_comunidad_id::text, 0)
  );
  PERFORM 1
  FROM public.comunidad c
  WHERE c.id = p_comunidad_id
  FOR KEY SHARE;
  PERFORM 1
  FROM public.comunidad_miembro m
  WHERE m.comunidad_id = p_comunidad_id
    AND m.usuario_id = auth.uid()
  FOR KEY SHARE;

  v_es_admin := public.es_admin_comunidad(p_comunidad_id);
  v_es_miembro := public.es_miembro_comunidad_aprobado(p_comunidad_id);

  IF NOT (v_es_admin OR v_es_miembro) THEN
    RAISE EXCEPTION 'Sin acceso a esta comunidad' USING ERRCODE = '42501';
  END IF;

  SELECT s.id, s.estado
    INTO v_sala_id, v_sala_activa
  FROM public.sala_chat s
  WHERE s.tipo = 'comunidad'::public.tipo_sala_chat
    AND s.comunidad_id = p_comunidad_id
  LIMIT 1
  FOR UPDATE;

  IF v_sala_id IS NULL THEN
    IF NOT v_es_admin THEN
      RAISE EXCEPTION 'Solo admin puede crear el chat de la comunidad'
        USING ERRCODE = '42501';
    END IF;
    INSERT INTO public.sala_chat (comunidad_id, tipo, estado)
    VALUES (p_comunidad_id, 'comunidad'::public.tipo_sala_chat, true)
    RETURNING id INTO v_sala_id;
    v_inicializar := true;
  ELSIF NOT COALESCE(v_sala_activa, false) THEN
    IF NOT v_es_admin THEN
      RAISE EXCEPTION 'Solo admin puede reactivar el chat de la comunidad'
        USING ERRCODE = '42501';
    END IF;
    UPDATE public.sala_chat
    SET estado = true
    WHERE id = v_sala_id;
    v_inicializar := true;
  END IF;

  IF v_es_admin THEN
    IF v_inicializar AND COALESCE(p_seed_aprobados, true) THEN
      PERFORM 1
      FROM public.comunidad_miembro m
      WHERE m.comunidad_id = p_comunidad_id
        AND m.estado = 'aprobado'::public.estado_membresia
      FOR KEY SHARE;

      INSERT INTO public.sala_participante (sala_id, usuario_id)
      SELECT v_sala_id, m.usuario_id
      FROM public.comunidad_miembro m
      WHERE m.comunidad_id = p_comunidad_id
        AND m.estado = 'aprobado'::public.estado_membresia
      ON CONFLICT DO NOTHING;
    END IF;

    INSERT INTO public.sala_participante (sala_id, usuario_id)
    VALUES (v_sala_id, auth.uid())
    ON CONFLICT DO NOTHING;
    RETURN v_sala_id;
  END IF;

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

CREATE OR REPLACE FUNCTION public.asegurar_sala_comunidad(
  p_comunidad_id bigint
)
RETURNS bigint
LANGUAGE sql
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT public.asegurar_sala_comunidad(p_comunidad_id, true);
$$;

CREATE OR REPLACE FUNCTION public.asegurar_sala_salida(
  p_salida_id bigint,
  p_seed_confirmados boolean
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_sala_id bigint;
  v_sala_activa boolean;
  v_org uuid;
  v_es_org boolean;
  v_confirmado boolean;
  v_ya_participa boolean;
  v_inicializar boolean := false;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No autenticado' USING ERRCODE = '42501';
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended('sala_chat_salida:' || p_salida_id::text, 0)
  );
  SELECT s.organizador_id
    INTO v_org
  FROM public.salida s
  WHERE s.id = p_salida_id
    AND s.estado IS DISTINCT FROM 'cancelada'::public.estado_salida
  FOR KEY SHARE;

  IF v_org IS NULL THEN
    RAISE EXCEPTION 'Salida no encontrada' USING ERRCODE = 'P0002';
  END IF;

  v_es_org := (v_org = auth.uid());
  PERFORM 1
  FROM public.salida_participante p
  WHERE p.salida_id = p_salida_id
    AND p.usuario_id = auth.uid()
  FOR KEY SHARE;
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

  SELECT s.id, s.estado
    INTO v_sala_id, v_sala_activa
  FROM public.sala_chat s
  WHERE s.tipo = 'salida'::public.tipo_sala_chat
    AND s.salida_id = p_salida_id
  LIMIT 1
  FOR UPDATE;

  IF v_sala_id IS NULL THEN
    IF NOT v_es_org THEN
      RAISE EXCEPTION 'Solo el organizador puede crear el chat de la salida'
        USING ERRCODE = '42501';
    END IF;
    INSERT INTO public.sala_chat (salida_id, tipo, estado)
    VALUES (p_salida_id, 'salida'::public.tipo_sala_chat, true)
    RETURNING id INTO v_sala_id;
    v_inicializar := true;
  ELSIF NOT COALESCE(v_sala_activa, false) THEN
    IF NOT v_es_org THEN
      RAISE EXCEPTION 'Solo el organizador puede reactivar el chat de la salida'
        USING ERRCODE = '42501';
    END IF;
    UPDATE public.sala_chat
    SET estado = true
    WHERE id = v_sala_id;
    v_inicializar := true;
  END IF;

  IF v_es_org THEN
    IF v_inicializar AND COALESCE(p_seed_confirmados, true) THEN
      PERFORM 1
      FROM public.salida_participante p
      WHERE p.salida_id = p_salida_id
        AND p.estado = 'confirmado'::public.estado_participante
      FOR KEY SHARE;

      INSERT INTO public.sala_participante (sala_id, usuario_id)
      SELECT v_sala_id, p.usuario_id
      FROM public.salida_participante p
      WHERE p.salida_id = p_salida_id
        AND p.estado = 'confirmado'::public.estado_participante
      ON CONFLICT DO NOTHING;
    END IF;

    INSERT INTO public.sala_participante (sala_id, usuario_id)
    VALUES (v_sala_id, v_org)
    ON CONFLICT DO NOTHING;
    RETURN v_sala_id;
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM public.sala_participante sp
    WHERE sp.sala_id = v_sala_id
      AND sp.usuario_id = auth.uid()
  ) INTO v_ya_participa;

  IF NOT v_ya_participa THEN
    RAISE EXCEPTION 'No estás en el chat de esta salida'
      USING ERRCODE = '42501';
  END IF;

  RETURN v_sala_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.asegurar_sala_salida(p_salida_id bigint)
RETURNS bigint
LANGUAGE sql
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT public.asegurar_sala_salida(p_salida_id, true);
$$;

REVOKE ALL ON FUNCTION public.asegurar_sala_comunidad(bigint, boolean)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.asegurar_sala_comunidad(bigint) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.asegurar_sala_salida(bigint, boolean)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.asegurar_sala_salida(bigint) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.asegurar_sala_comunidad(bigint, boolean)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.asegurar_sala_comunidad(bigint)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.asegurar_sala_salida(bigint, boolean)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.asegurar_sala_salida(bigint)
  TO authenticated, service_role;
