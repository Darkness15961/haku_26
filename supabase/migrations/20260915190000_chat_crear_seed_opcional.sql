-- Crear chat con seed opcional (todos vs solo admin/org).
-- Salida: roster híbrido (sin auto-alta al confirmar; org gestiona).
-- Append-only sobre 15180000.

-- ---------------------------------------------------------------------------
-- 1) asegurar_sala_comunidad(id, seed)
-- ---------------------------------------------------------------------------

DROP FUNCTION IF EXISTS public.asegurar_sala_comunidad(bigint);

CREATE OR REPLACE FUNCTION public.asegurar_sala_comunidad(
  p_comunidad_id bigint,
  p_seed_aprobados boolean DEFAULT true
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

REVOKE ALL ON FUNCTION public.asegurar_sala_comunidad(bigint, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.asegurar_sala_comunidad(bigint, boolean)
  TO authenticated, service_role;

COMMENT ON FUNCTION public.asegurar_sala_comunidad(bigint, boolean) IS
  'Admin crea sala. p_seed_aprobados solo aplica al crear. Miembro abre si ya está en roster.';

-- ---------------------------------------------------------------------------
-- 2) asegurar_sala_salida(id, seed)
-- ---------------------------------------------------------------------------

DROP FUNCTION IF EXISTS public.asegurar_sala_salida(bigint);

CREATE OR REPLACE FUNCTION public.asegurar_sala_salida(
  p_salida_id bigint,
  p_seed_confirmados boolean DEFAULT true
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

REVOKE ALL ON FUNCTION public.asegurar_sala_salida(bigint, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.asegurar_sala_salida(bigint, boolean)
  TO authenticated, service_role;

COMMENT ON FUNCTION public.asegurar_sala_salida(bigint, boolean) IS
  'Org crea sala. p_seed_confirmados solo al crear. Confirmado abre si ya está en roster.';

-- ---------------------------------------------------------------------------
-- 3) Trigger salida: solo quitar del chat; NO auto-alta (roster híbrido)
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

  -- Si deja de estar confirmado → sale del chat. Alta = org vía RPC/picker.
  IF NEW.estado IS DISTINCT FROM 'confirmado'::public.estado_participante THEN
    SELECT s.id INTO v_sala_id
    FROM public.sala_chat s
    WHERE s.tipo = 'salida'::public.tipo_sala_chat
      AND s.salida_id = NEW.salida_id
    LIMIT 1;
    IF v_sala_id IS NOT NULL THEN
      DELETE FROM public.sala_participante
      WHERE sala_id = v_sala_id
        AND usuario_id = NEW.usuario_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.fn_sala_on_salida_participante() IS
  'Quita del chat si deja de estar confirmado. No auto-agrega (opt-in org).';

-- ---------------------------------------------------------------------------
-- 4) Batch roster salida (organizador)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.sala_salida_set_participantes_batch(
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
  v_salida_id bigint;
  v_org uuid;
  v_uid uuid;
  v_elegible boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No autenticado'
      USING ERRCODE = '42501';
  END IF;

  SELECT s.salida_id, sal.organizador_id
    INTO v_salida_id, v_org
  FROM public.sala_chat s
  JOIN public.salida sal ON sal.id = s.salida_id
  WHERE s.id = p_sala_id
    AND s.tipo = 'salida'::public.tipo_sala_chat
    AND s.estado = true;

  IF v_salida_id IS NULL OR v_org IS NULL THEN
    RAISE EXCEPTION 'Sala de salida no encontrada'
      USING ERRCODE = 'P0002';
  END IF;

  IF v_org <> auth.uid() THEN
    RAISE EXCEPTION 'Solo el organizador puede gestionar el chat'
      USING ERRCODE = '42501';
  END IF;

  IF p_agregar IS NOT NULL THEN
    FOREACH v_uid IN ARRAY p_agregar
    LOOP
      v_elegible := (v_uid = v_org)
        OR EXISTS (
          SELECT 1
          FROM public.salida_participante p
          WHERE p.salida_id = v_salida_id
            AND p.usuario_id = v_uid
            AND p.estado = 'confirmado'::public.estado_participante
        );
      IF v_elegible THEN
        INSERT INTO public.sala_participante (sala_id, usuario_id)
        VALUES (p_sala_id, v_uid)
        ON CONFLICT DO NOTHING;
      END IF;
    END LOOP;
  END IF;

  IF p_quitar IS NOT NULL THEN
    FOREACH v_uid IN ARRAY p_quitar
    LOOP
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

REVOKE ALL ON FUNCTION public.sala_salida_set_participantes_batch(bigint, uuid[], uuid[])
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sala_salida_set_participantes_batch(bigint, uuid[], uuid[])
  TO authenticated, service_role;

COMMENT ON FUNCTION public.sala_salida_set_participantes_batch(bigint, uuid[], uuid[]) IS
  'Organizador: alta/baja roster chat salida. Solo confirmados + org. No auto-quita al caller.';
