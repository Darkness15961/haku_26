-- Cierre de hilos de creación: entidad + membresía inicial en una transacción.

CREATE OR REPLACE FUNCTION public.crear_comunidad_con_admin(
  p_nombre text,
  p_descripcion text DEFAULT NULL,
  p_tipo text DEFAULT 'publico',
  p_foto_portada text DEFAULT NULL
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_id bigint;
  v_nombre text := btrim(COALESCE(p_nombre, ''));
  v_tipo public.tipo_comunidad;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No autenticado' USING ERRCODE = '42501';
  END IF;
  IF v_nombre = '' OR char_length(v_nombre) > 255 THEN
    RAISE EXCEPTION 'Nombre de comunidad inválido' USING ERRCODE = '22023';
  END IF;

  v_tipo := CASE
    WHEN lower(btrim(COALESCE(p_tipo, ''))) = 'privado'
      THEN 'privado'::public.tipo_comunidad
    ELSE 'publico'::public.tipo_comunidad
  END;

  INSERT INTO public.comunidad (
    nombre,
    descripcion,
    foto_portada,
    usuario_creador_id,
    tipo,
    estado
  )
  VALUES (
    v_nombre,
    NULLIF(btrim(COALESCE(p_descripcion, '')), ''),
    NULLIF(btrim(COALESCE(p_foto_portada, '')), ''),
    auth.uid(),
    v_tipo,
    true
  )
  RETURNING id INTO v_id;

  INSERT INTO public.comunidad_miembro (
    comunidad_id,
    usuario_id,
    rol,
    estado
  )
  VALUES (
    v_id,
    auth.uid(),
    'admin'::public.rol_miembro,
    'aprobado'::public.estado_membresia
  );

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.crear_salida_con_organizador(
  p_titulo text,
  p_fecha_hora_inicio timestamptz,
  p_latitud numeric,
  p_longitud numeric,
  p_cupos_totales integer,
  p_minimo_para_salir integer DEFAULT 1,
  p_lugar_id bigint DEFAULT NULL,
  p_ruta_id bigint DEFAULT NULL,
  p_comunidad_id bigint DEFAULT NULL,
  p_notas_grupales text DEFAULT NULL
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_id bigint;
  v_titulo text := btrim(COALESCE(p_titulo, ''));
  v_tipo public.tipo_salida;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No autenticado' USING ERRCODE = '42501';
  END IF;
  IF v_titulo = '' OR char_length(v_titulo) > 255 THEN
    RAISE EXCEPTION 'Título de salida inválido' USING ERRCODE = '22023';
  END IF;
  IF p_fecha_hora_inicio IS NULL OR p_fecha_hora_inicio <= now() THEN
    RAISE EXCEPTION 'La salida debe comenzar en el futuro'
      USING ERRCODE = '22023';
  END IF;
  IF p_latitud IS NULL OR p_latitud < -90 OR p_latitud > 90
     OR p_longitud IS NULL OR p_longitud < -180 OR p_longitud > 180 THEN
    RAISE EXCEPTION 'Coordenadas inválidas' USING ERRCODE = '22023';
  END IF;
  IF p_cupos_totales < 1
     OR p_minimo_para_salir < 1
     OR p_minimo_para_salir > p_cupos_totales THEN
    RAISE EXCEPTION 'Cupos o mínimo inválidos' USING ERRCODE = '22023';
  END IF;

  IF p_lugar_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.lugar l
    WHERE l.id = p_lugar_id AND l.estado = true
  ) THEN
    RAISE EXCEPTION 'Lugar no disponible' USING ERRCODE = '22023';
  END IF;

  IF p_ruta_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.ruta r
    WHERE r.id = p_ruta_id
      AND r.estado = true
      AND r.estado_editorial = 'publicado'
  ) THEN
    RAISE EXCEPTION 'Ruta no publicada' USING ERRCODE = '22023';
  END IF;

  IF p_comunidad_id IS NULL THEN
    v_tipo := 'publica'::public.tipo_salida;
  ELSE
    IF NOT (
      public.es_miembro_comunidad_aprobado(p_comunidad_id)
      OR public.es_admin_comunidad(p_comunidad_id)
    ) THEN
      RAISE EXCEPTION 'Sin acceso a la comunidad' USING ERRCODE = '42501';
    END IF;
    v_tipo := 'comunidad'::public.tipo_salida;
  END IF;

  INSERT INTO public.salida (
    titulo,
    organizador_id,
    comunidad_id,
    ruta_id,
    fecha_hora_inicio,
    punto_encuentro_lat,
    punto_encuentro_lon,
    punto_encuentro_lugar_id,
    notas_grupales,
    tipo,
    cupos_totales,
    minimo_para_salir,
    estado
  )
  VALUES (
    v_titulo,
    auth.uid(),
    p_comunidad_id,
    p_ruta_id,
    p_fecha_hora_inicio,
    p_latitud,
    p_longitud,
    p_lugar_id,
    NULLIF(btrim(COALESCE(p_notas_grupales, '')), ''),
    v_tipo,
    p_cupos_totales,
    p_minimo_para_salir,
    'programada'::public.estado_salida
  )
  RETURNING id INTO v_id;

  INSERT INTO public.salida_participante (
    salida_id,
    usuario_id,
    estado
  )
  VALUES (
    v_id,
    auth.uid(),
    'confirmado'::public.estado_participante
  );

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.crear_publicacion_completa(
  p_contenido text,
  p_estado text DEFAULT 'publico',
  p_comunidad_id bigint DEFAULT NULL,
  p_lugar_id bigint DEFAULT NULL,
  p_ruta_id bigint DEFAULT NULL,
  p_imagen_url text DEFAULT NULL
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_id bigint;
  v_contenido text := btrim(COALESCE(p_contenido, ''));
  v_estado public.estado_publicacion;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No autenticado' USING ERRCODE = '42501';
  END IF;
  IF v_contenido = '' OR char_length(v_contenido) > 4000 THEN
    RAISE EXCEPTION 'Contenido de publicación inválido' USING ERRCODE = '22023';
  END IF;

  v_estado := CASE
    WHEN lower(btrim(COALESCE(p_estado, ''))) = 'privado'
      THEN 'privado'::public.estado_publicacion
    ELSE 'publico'::public.estado_publicacion
  END;

  IF p_comunidad_id IS NOT NULL AND NOT (
    EXISTS (
      SELECT 1
      FROM public.comunidad c
      WHERE c.id = p_comunidad_id
        AND c.estado = true
        AND c.tipo = 'publico'::public.tipo_comunidad
    )
    OR public.es_miembro_comunidad_aprobado(p_comunidad_id)
    OR public.es_admin_comunidad(p_comunidad_id)
  ) THEN
    RAISE EXCEPTION 'Sin acceso para etiquetar la comunidad'
      USING ERRCODE = '42501';
  END IF;

  IF p_lugar_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.lugar l
    WHERE l.id = p_lugar_id AND l.estado = true
  ) THEN
    RAISE EXCEPTION 'Lugar no disponible' USING ERRCODE = '22023';
  END IF;

  IF p_ruta_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.ruta r
    WHERE r.id = p_ruta_id
      AND r.estado = true
      AND r.estado_editorial = 'publicado'
  ) THEN
    RAISE EXCEPTION 'Ruta no publicada' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.publicacion (
    usuario_id,
    contenido,
    estado
  )
  VALUES (
    auth.uid(),
    v_contenido,
    v_estado
  )
  RETURNING id INTO v_id;

  IF NULLIF(btrim(COALESCE(p_imagen_url, '')), '') IS NOT NULL THEN
    INSERT INTO public.publicacion_multimedia (
      publicacion_id,
      url_archivo,
      orden,
      tipo
    )
    VALUES (
      v_id,
      btrim(p_imagen_url),
      1,
      'imagen'
    );
  END IF;

  IF p_comunidad_id IS NOT NULL THEN
    INSERT INTO public.publicacion_etiqueta_comunidad (
      publicacion_id,
      comunidad_id
    ) VALUES (v_id, p_comunidad_id);
  END IF;

  IF p_lugar_id IS NOT NULL THEN
    INSERT INTO public.publicacion_lugar (
      publicacion_id,
      lugar_id
    ) VALUES (v_id, p_lugar_id);
  END IF;

  IF p_ruta_id IS NOT NULL THEN
    INSERT INTO public.publicacion_ruta (
      publicacion_id,
      ruta_id
    ) VALUES (v_id, p_ruta_id);
  END IF;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.crear_comunidad_con_admin(text, text, text, text)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crear_comunidad_con_admin(text, text, text, text)
  TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.crear_salida_con_organizador(
  text, timestamptz, numeric, numeric, integer, integer, bigint, bigint, bigint, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crear_salida_con_organizador(
  text, timestamptz, numeric, numeric, integer, integer, bigint, bigint, bigint, text
) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.crear_publicacion_completa(
  text, text, bigint, bigint, bigint, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crear_publicacion_completa(
  text, text, bigint, bigint, bigint, text
) TO authenticated, service_role;

COMMENT ON FUNCTION public.crear_comunidad_con_admin(text, text, text, text) IS
  'Crea comunidad y membresía admin inicial atómicamente.';
COMMENT ON FUNCTION public.crear_salida_con_organizador(
  text, timestamptz, numeric, numeric, integer, integer, bigint, bigint, bigint, text
) IS 'Crea salida y participación confirmada del organizador atómicamente.';
COMMENT ON FUNCTION public.crear_publicacion_completa(
  text, text, bigint, bigint, bigint, text
) IS 'Crea publicación y todas sus relaciones opcionales atómicamente.';
