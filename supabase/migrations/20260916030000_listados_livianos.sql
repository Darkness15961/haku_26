-- Resúmenes de Comunidad y Salida sin hidratar todos sus miembros.

CREATE OR REPLACE FUNCTION public.listar_comunidades_resumen()
RETURNS TABLE (
  id bigint,
  nombre text,
  descripcion text,
  foto_portada text,
  usuario_creador_id uuid,
  estado boolean,
  tipo text,
  fecha_creacion timestamptz,
  miembros_count integer,
  mi_rol text,
  mi_estado text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT
    c.id,
    c.nombre::text,
    c.descripcion,
    c.foto_portada,
    c.usuario_creador_id,
    c.estado,
    c.tipo::text,
    c.fecha_creacion,
    (
      SELECT count(*)::integer
      FROM public.comunidad_miembro todos
      WHERE todos.comunidad_id = c.id
        AND todos.estado::text = 'aprobado'
    ),
    cm.rol::text,
    cm.estado::text
  FROM public.comunidad c
  LEFT JOIN public.comunidad_miembro cm
    ON cm.comunidad_id = c.id AND cm.usuario_id = auth.uid()
  WHERE c.estado = true
    AND (
      c.tipo::text = 'publico'
      OR c.usuario_creador_id = auth.uid()
      OR cm.estado::text = 'aprobado'
      OR (cm.rol::text = 'admin' AND cm.estado::text = 'aprobado')
    )
  ORDER BY c.nombre;
$$;

CREATE OR REPLACE FUNCTION public.listar_salidas_resumen()
RETURNS TABLE (
  id bigint,
  titulo text,
  organizador_id uuid,
  organizador_nick text,
  comunidad_id bigint,
  comunidad_nombre text,
  ruta_id bigint,
  ruta_nombre text,
  ruta_resumen text,
  fecha_hora_inicio timestamptz,
  punto_encuentro_lat numeric,
  punto_encuentro_lon numeric,
  punto_encuentro_lugar_id bigint,
  lugar_nombre text,
  lugar_foto_portada text,
  tipo text,
  cupos_totales integer,
  minimo_para_salir integer,
  estado text,
  fecha_creacion timestamptz,
  inscritos_count integer,
  mi_estado_participante text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT
    s.id,
    s.titulo::text,
    s.organizador_id,
    u.nombre_nick::text,
    s.comunidad_id,
    c.nombre::text,
    s.ruta_id,
    r.nombre::text,
    r.resumen,
    s.fecha_hora_inicio,
    s.punto_encuentro_lat,
    s.punto_encuentro_lon,
    s.punto_encuentro_lugar_id,
    l.nombre::text,
    l.foto_portada,
    s.tipo::text,
    s.cupos_totales,
    s.minimo_para_salir,
    s.estado::text,
    s.fecha_creacion,
    (
      SELECT count(*)::integer
      FROM public.salida_participante todos
      WHERE todos.salida_id = s.id
        AND todos.estado::text = 'confirmado'
    ),
    mia.estado::text
  FROM public.salida s
  JOIN public.usuario u ON u.id = s.organizador_id
  LEFT JOIN public.comunidad c ON c.id = s.comunidad_id
  LEFT JOIN public.lugar l ON l.id = s.punto_encuentro_lugar_id
  LEFT JOIN public.ruta r
    ON r.id = s.ruta_id
    AND r.estado = true
    AND r.estado_editorial = 'publicado'
  LEFT JOIN public.salida_participante mia
    ON mia.salida_id = s.id AND mia.usuario_id = auth.uid()
  WHERE (
    (auth.uid() IS NOT NULL AND s.organizador_id = auth.uid())
    OR (
      s.estado::text IN ('programada', 'en_curso', 'finalizada')
      AND (
        s.tipo::text = 'publica'
        OR (
          s.comunidad_id IS NOT NULL
          AND auth.uid() IS NOT NULL
          AND (
            public.es_miembro_comunidad_aprobado(s.comunidad_id)
            OR public.es_admin_comunidad(s.comunidad_id)
          )
        )
      )
    )
  )
  ORDER BY s.fecha_hora_inicio;
$$;

REVOKE ALL ON FUNCTION public.listar_comunidades_resumen() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_comunidades_resumen()
  TO anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.listar_salidas_resumen() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_salidas_resumen()
  TO anon, authenticated, service_role;

COMMENT ON FUNCTION public.listar_comunidades_resumen() IS
  'Listado liviano: conteo y membresía actual, no roster completo.';
COMMENT ON FUNCTION public.listar_salidas_resumen() IS
  'Listado liviano: conteo y participación actual, no roster completo.';
