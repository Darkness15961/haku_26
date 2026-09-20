-- Etapa 2: Optimización de Seguridad RLS
-- Objetivo: Evitar subconsultas EXISTS masivas (N+1 interno) en lecturas de listas.

-- 1. Optimización para comunidad_miembro
CREATE OR REPLACE FUNCTION public.puede_ver_comunidad_miembro(
  p_comunidad_id bigint,
  p_usuario_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_tipo_comunidad public.tipo_comunidad;
  v_estado_comunidad boolean;
BEGIN
  -- 1. Short-circuit: Si yo soy el usuario consultado, siempre lo veo
  IF auth.uid() IS NOT NULL AND p_usuario_id = auth.uid() THEN
    RETURN true;
  END IF;

  -- 2. Si ya soy miembro aprobado de esa comunidad, lo veo
  IF public.es_miembro_comunidad_aprobado(p_comunidad_id) THEN
    RETURN true;
  END IF;

  -- 3. Si la comunidad es pública y está activa, cualquiera lo ve
  SELECT estado, tipo INTO v_estado_comunidad, v_tipo_comunidad
  FROM public.comunidad
  WHERE id = p_comunidad_id;

  IF v_estado_comunidad = true AND v_tipo_comunidad = 'publico'::public.tipo_comunidad THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$;

DROP POLICY IF EXISTS comunidad_miembro_select_visible ON public.comunidad_miembro;
CREATE POLICY comunidad_miembro_select_visible ON public.comunidad_miembro
  FOR SELECT TO anon, authenticated
  USING (public.puede_ver_comunidad_miembro(comunidad_id, usuario_id));


-- 2. Optimización para salida_participante
CREATE OR REPLACE FUNCTION public.puede_ver_salida_participante(
  p_salida_id bigint,
  p_usuario_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_organizador_id uuid;
  v_tipo_salida public.tipo_salida;
  v_estado_salida public.estado_salida;
  v_comunidad_id bigint;
BEGIN
  -- 1. Short-circuit: Si soy yo mismo, lo veo
  IF auth.uid() IS NOT NULL AND p_usuario_id = auth.uid() THEN
    RETURN true;
  END IF;

  -- 2. Consultar toda la info de la salida una sola vez
  SELECT organizador_id, tipo, estado, comunidad_id 
  INTO v_organizador_id, v_tipo_salida, v_estado_salida, v_comunidad_id
  FROM public.salida
  WHERE id = p_salida_id;

  -- 3. Si soy el organizador, lo veo
  IF auth.uid() IS NOT NULL AND v_organizador_id = auth.uid() THEN
    RETURN true;
  END IF;

  -- 4. Si la salida es pública y activa, lo veo
  IF v_tipo_salida = 'publica'::public.tipo_salida 
     AND v_estado_salida IN ('programada'::public.estado_salida, 'en_curso'::public.estado_salida) THEN
    RETURN true;
  END IF;

  -- 5. Si la salida pertenece a una comunidad de la que soy miembro, lo veo
  IF v_comunidad_id IS NOT NULL AND public.es_miembro_comunidad_aprobado(v_comunidad_id) THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$;

DROP POLICY IF EXISTS salida_participante_select_visible ON public.salida_participante;
CREATE POLICY salida_participante_select_visible ON public.salida_participante
  FOR SELECT TO authenticated
  USING (public.puede_ver_salida_participante(salida_id, usuario_id));

-- Otorgar permisos
REVOKE ALL ON FUNCTION public.puede_ver_comunidad_miembro(bigint, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.puede_ver_salida_participante(bigint, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.puede_ver_comunidad_miembro(bigint, uuid) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.puede_ver_salida_participante(bigint, uuid) TO authenticated, service_role;
