-- Existencia de sala sin RLS (no confundir "no existe" con "no estoy en roster").
-- Evita ambigüedad de firmas: solo (bigint, boolean) con DEFAULT + wrappers 1-arg claros.
-- Append-only sobre 15190000.

CREATE OR REPLACE FUNCTION public.sala_comunidad_id_si_existe(p_comunidad_id bigint)
RETURNS bigint
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT s.id
  FROM public.sala_chat s
  WHERE s.tipo = 'comunidad'::public.tipo_sala_chat
    AND s.comunidad_id = p_comunidad_id
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.sala_salida_id_si_existe(p_salida_id bigint)
RETURNS bigint
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT s.id
  FROM public.sala_chat s
  WHERE s.tipo = 'salida'::public.tipo_sala_chat
    AND s.salida_id = p_salida_id
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.sala_comunidad_id_si_existe(bigint) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.sala_salida_id_si_existe(bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sala_comunidad_id_si_existe(bigint)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.sala_salida_id_si_existe(bigint)
  TO authenticated, service_role;

COMMENT ON FUNCTION public.sala_comunidad_id_si_existe(bigint) IS
  'Id de sala comunidad si existe, sin filtrar por roster (SECURITY DEFINER).';
COMMENT ON FUNCTION public.sala_salida_id_si_existe(bigint) IS
  'Id de sala salida si existe, sin filtrar por roster (SECURITY DEFINER).';

-- Firmas sin ambigüedad:
-- 1) (bigint, boolean) — canónica, sin DEFAULT
-- 2) (bigint) — compat, llama a la canónica con seed=true

DROP FUNCTION IF EXISTS public.asegurar_sala_comunidad(bigint, boolean);
DROP FUNCTION IF EXISTS public.asegurar_sala_comunidad(bigint);
DROP FUNCTION IF EXISTS public.asegurar_sala_salida(bigint, boolean);
DROP FUNCTION IF EXISTS public.asegurar_sala_salida(bigint);

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
  v_es_admin boolean;
  v_es_miembro boolean;
  v_ya_participa boolean;
  v_creada boolean := false;
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
    v_creada := true;
  END IF;

  IF v_es_admin THEN
    IF v_creada AND COALESCE(p_seed_aprobados, true) THEN
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

CREATE OR REPLACE FUNCTION public.asegurar_sala_comunidad(p_comunidad_id bigint)
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
  v_org uuid;
  v_es_org boolean;
  v_confirmado boolean;
  v_creada boolean := false;
  v_ya_participa boolean;
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
    v_creada := true;
  END IF;

  IF v_es_org THEN
    IF v_creada AND COALESCE(p_seed_confirmados, true) THEN
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

REVOKE ALL ON FUNCTION public.asegurar_sala_comunidad(bigint, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.asegurar_sala_comunidad(bigint) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.asegurar_sala_salida(bigint, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.asegurar_sala_salida(bigint) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.asegurar_sala_comunidad(bigint, boolean)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.asegurar_sala_comunidad(bigint)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.asegurar_sala_salida(bigint, boolean)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.asegurar_sala_salida(bigint)
  TO authenticated, service_role;
