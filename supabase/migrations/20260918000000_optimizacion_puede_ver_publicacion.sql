-- Optimización de puede_ver_publicacion para evitar recursividad y seq scans masivos.
-- Al cambiarlo a plpgsql, garantizamos que el flujo haga short-circuit si la publicación es pública,
-- evitando consultar la tabla publicacion_etiqueta_comunidad y comunidad_miembro innecesariamente.

CREATE OR REPLACE FUNCTION public.puede_ver_publicacion(
  p_publicacion_id bigint
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_estado public.estado_publicacion;
  v_usuario_id uuid;
BEGIN
  -- 1. Consultar la publicación (id, estado, usuario_id) de una sola vez
  SELECT p.estado, p.usuario_id
  INTO v_estado, v_usuario_id
  FROM public.publicacion p
  WHERE p.id = p_publicacion_id;

  -- Si no existe o está eliminada, no se puede ver
  IF v_estado IS NULL OR v_estado = 'eliminado'::public.estado_publicacion THEN
    RETURN false;
  END IF;

  -- 2. Si es pública, short-circuit inmediato (99% de los casos)
  IF v_estado = 'publico'::public.estado_publicacion THEN
    RETURN true;
  END IF;

  -- 3. Si el usuario actual es el autor, también la ve
  IF auth.uid() IS NOT NULL AND v_usuario_id = auth.uid() THEN
    RETURN true;
  END IF;

  -- 4. Si es privada y no somos el autor, verificar si pertenecemos a la comunidad etiquetada
  IF v_estado = 'privado'::public.estado_publicacion AND auth.uid() IS NOT NULL THEN
    RETURN EXISTS (
      SELECT 1
      FROM public.publicacion_etiqueta_comunidad pec
      WHERE pec.publicacion_id = p_publicacion_id
        AND (
          public.es_miembro_comunidad_aprobado(pec.comunidad_id)
          OR public.es_admin_comunidad(pec.comunidad_id)
        )
    );
  END IF;

  -- 5. Caso por defecto (invitado intentando ver publicación privada, etc)
  RETURN false;
END;
$$;
