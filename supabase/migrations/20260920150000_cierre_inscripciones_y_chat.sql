-- ---------------------------------------------------------------------------
-- Fase 1: Cierre de inscripciones en comunidades y corrección de Auto-join
-- ---------------------------------------------------------------------------

-- 1. Agregar columna de inscripción abierta a la tabla comunidad
ALTER TABLE public.comunidad 
ADD COLUMN IF NOT EXISTS inscripcion_abierta BOOLEAN DEFAULT true;

-- 2. Función y Trigger para bloquear nuevos registros si está cerrado
CREATE OR REPLACE FUNCTION public.func_comunidad_miembro_check_abierta()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_abierta boolean;
BEGIN
  -- Consultar el estado de la comunidad
  SELECT inscripcion_abierta INTO v_abierta
  FROM public.comunidad
  WHERE id = NEW.comunidad_id;

  -- Si está cerrada, lanzar excepción para bloquear el INSERT
  IF v_abierta = false THEN
    RAISE EXCEPTION 'La comunidad tiene las inscripciones cerradas' USING ERRCODE = '23503';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_comunidad_miembro_check_abierta ON public.comunidad_miembro;
CREATE TRIGGER trg_comunidad_miembro_check_abierta
  BEFORE INSERT ON public.comunidad_miembro
  FOR EACH ROW
  EXECUTE FUNCTION public.func_comunidad_miembro_check_abierta();


-- 3. Corrección del RPC de Auto-Join en Chat
-- Sobrescribimos el overload que recibe 2 argumentos (que es el que Flutter llama)
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
  v_estado_actual boolean;
  v_creada boolean := false;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No autenticado' USING ERRCODE = '42501';
  END IF;

  v_es_admin := public.es_admin_comunidad(p_comunidad_id);
  v_es_miembro := public.es_miembro_comunidad_aprobado(p_comunidad_id);

  IF NOT (v_es_admin OR v_es_miembro) THEN
    RAISE EXCEPTION 'Sin acceso a esta comunidad' USING ERRCODE = '42501';
  END IF;

  SELECT s.id, s.estado
    INTO v_sala_id, v_estado_actual
  FROM public.sala_chat s
  WHERE s.tipo = 'comunidad'::public.tipo_sala_chat
    AND s.comunidad_id = p_comunidad_id
  LIMIT 1;

  IF v_sala_id IS NULL THEN
    IF NOT v_es_admin THEN
      RAISE EXCEPTION 'Solo admin puede crear el chat de la comunidad' USING ERRCODE = '42501';
    END IF;
    INSERT INTO public.sala_chat (comunidad_id, tipo, estado)
    VALUES (p_comunidad_id, 'comunidad'::public.tipo_sala_chat, true)
    RETURNING id INTO v_sala_id;
    v_creada := true;
  ELSIF NOT v_estado_actual AND v_es_admin THEN
    UPDATE public.sala_chat SET estado = true WHERE id = v_sala_id;
  ELSIF NOT v_estado_actual THEN
    RAISE EXCEPTION 'El chat grupal está desactivado por el administrador' USING ERRCODE = '42501';
  END IF;

  IF v_es_admin THEN
    IF v_creada AND p_seed_aprobados THEN
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

  -- Lógica de Auto-Join para el miembro común
  SELECT EXISTS (
    SELECT 1
    FROM public.sala_participante sp
    WHERE sp.sala_id = v_sala_id
      AND sp.usuario_id = auth.uid()
  ) INTO v_ya_participa;

  IF NOT v_ya_participa THEN
    INSERT INTO public.sala_participante (sala_id, usuario_id)
    VALUES (v_sala_id, auth.uid())
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN v_sala_id;
END;
$$;

-- Alias para la función con un solo parámetro
CREATE OR REPLACE FUNCTION public.asegurar_sala_comunidad(p_comunidad_id bigint)
RETURNS bigint
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT public.asegurar_sala_comunidad(p_comunidad_id, true);
$$;

REVOKE ALL ON FUNCTION public.asegurar_sala_comunidad(bigint, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.asegurar_sala_comunidad(bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.asegurar_sala_comunidad(bigint, boolean) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.asegurar_sala_comunidad(bigint) TO authenticated, service_role;
