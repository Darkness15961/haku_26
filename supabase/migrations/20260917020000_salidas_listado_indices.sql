-- Filtrar primero y contar después: el costo depende de las salidas visibles,
-- no del roster histórico completo.

CREATE INDEX IF NOT EXISTS idx_salida_lugar_fecha_visible
  ON public.salida (punto_encuentro_lugar_id, fecha_hora_inicio)
  WHERE estado <> 'cancelada'::public.estado_salida;

CREATE INDEX IF NOT EXISTS idx_salida_ruta_fecha_visible
  ON public.salida (ruta_id, fecha_hora_inicio)
  WHERE estado <> 'cancelada'::public.estado_salida;

CREATE INDEX IF NOT EXISTS idx_salida_comunidad_fecha_visible
  ON public.salida (comunidad_id, fecha_hora_inicio)
  WHERE estado <> 'cancelada'::public.estado_salida;

CREATE INDEX IF NOT EXISTS idx_salida_participante_confirmado
  ON public.salida_participante (salida_id)
  WHERE estado = 'confirmado'::public.estado_participante;

CREATE OR REPLACE FUNCTION public.listar_salidas_resumen(
  p_lugar_id bigint,
  p_ruta_id bigint,
  p_comunidad_id bigint
)
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
  WITH salidas_filtradas AS MATERIALIZED (
    SELECT s.*
    FROM public.salida s
    WHERE (p_lugar_id IS NULL OR s.punto_encuentro_lugar_id = p_lugar_id)
      AND (p_ruta_id IS NULL OR s.ruta_id = p_ruta_id)
      AND (p_comunidad_id IS NULL OR s.comunidad_id = p_comunidad_id)
      AND (
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
  ),
  conteos AS (
    SELECT
      sp.salida_id,
      count(*)::integer AS inscritos_count
    FROM public.salida_participante sp
    JOIN salidas_filtradas sf ON sf.id = sp.salida_id
    WHERE sp.estado::text = 'confirmado'
    GROUP BY sp.salida_id
  )
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
    COALESCE(ct.inscritos_count, 0),
    mia.estado::text
  FROM salidas_filtradas s
  JOIN public.usuario u ON u.id = s.organizador_id
  LEFT JOIN public.comunidad c ON c.id = s.comunidad_id
  LEFT JOIN public.lugar l ON l.id = s.punto_encuentro_lugar_id
  LEFT JOIN public.ruta r
    ON r.id = s.ruta_id
    AND r.estado = true
    AND r.estado_editorial = 'publicado'
  LEFT JOIN conteos ct ON ct.salida_id = s.id
  LEFT JOIN public.salida_participante mia
    ON mia.salida_id = s.id AND mia.usuario_id = auth.uid()
  ORDER BY s.fecha_hora_inicio;
$$;

REVOKE ALL ON FUNCTION public.listar_salidas_resumen(bigint, bigint, bigint)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_salidas_resumen(
  bigint,
  bigint,
  bigint
) TO anon, authenticated, service_role;

COMMENT ON FUNCTION public.listar_salidas_resumen(bigint, bigint, bigint) IS
  'Listado filtrable: restringe candidatas antes de contar participantes.';
