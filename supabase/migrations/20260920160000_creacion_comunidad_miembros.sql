CREATE OR REPLACE FUNCTION public.crear_comunidad_con_admin_y_miembros(
  p_nombre text,
  p_descripcion text DEFAULT NULL,
  p_tipo text DEFAULT 'publico',
  p_foto_portada text DEFAULT NULL,
  p_miembros_extra uuid[] DEFAULT '{}'
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
  v_uid uuid;
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

  -- Insertar al creador como admin
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

  -- Insertar a los miembros extra
  IF array_length(p_miembros_extra, 1) > 0 THEN
    FOREACH v_uid IN ARRAY p_miembros_extra
    LOOP
      -- Evitar insertar duplicado al propio creador
      IF v_uid != auth.uid() THEN
        INSERT INTO public.comunidad_miembro (
          comunidad_id,
          usuario_id,
          rol,
          estado
        )
        VALUES (
          v_id,
          v_uid,
          'miembro'::public.rol_miembro,
          'aprobado'::public.estado_membresia
        )
        ON CONFLICT (comunidad_id, usuario_id) DO NOTHING;
      END IF;
    END LOOP;
  END IF;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.crear_comunidad_con_admin_y_miembros(text, text, text, text, uuid[])
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crear_comunidad_con_admin_y_miembros(text, text, text, text, uuid[])
  TO authenticated, service_role;

COMMENT ON FUNCTION public.crear_comunidad_con_admin_y_miembros(text, text, text, text, uuid[]) IS
  'Crea comunidad, membresía admin inicial y añade miembros opcionales aprobados atómicamente.';
