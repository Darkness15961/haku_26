-- Los mensajes anteriores al ingreso de un participante no son "no leídos".
CREATE OR REPLACE FUNCTION public.listar_bandeja_chat()
RETURNS TABLE (
  sala_id bigint,
  tipo text,
  comunidad_id bigint,
  salida_id bigint,
  usuario_id uuid,
  titulo text,
  foto_portada text,
  puede_crear_sala boolean,
  ultimo_id bigint,
  ultimo_contenido text,
  ultimo_tipo text,
  ultimo_fecha timestamptz,
  ultimo_eliminado_en timestamptz,
  no_leidos integer
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
  WITH privado AS (
    SELECT
      s.id AS sala_id,
      'privado'::text AS tipo,
      NULL::bigint AS comunidad_id,
      NULL::bigint AS salida_id,
      otro.id AS usuario_id,
      COALESCE(
        NULLIF(btrim(concat_ws(' ', otro.nombres, otro.apellidos)), ''),
        NULLIF(btrim(otro.nombre_nick), ''),
        'Explorador'
      ) AS titulo,
      otro.foto_perfil AS foto_portada,
      false AS puede_crear_sala,
      um.id AS ultimo_id,
      um.contenido AS ultimo_contenido,
      um.tipo_mensaje::text AS ultimo_tipo,
      um.fecha_envio AS ultimo_fecha,
      um.eliminado_en AS ultimo_eliminado_en,
      COALESCE(nl.total, 0)::integer AS no_leidos
    FROM public.sala_privada p
    JOIN public.sala_chat s ON s.id = p.sala_id AND s.estado = true
    JOIN public.sala_participante yo
      ON yo.sala_id = s.id AND yo.usuario_id = auth.uid()
    JOIN public.usuario otro
      ON otro.id = CASE
        WHEN p.usuario_a = auth.uid() THEN p.usuario_b
        ELSE p.usuario_a
      END
    LEFT JOIN LATERAL (
      SELECT m.id, m.contenido, m.tipo_mensaje, m.fecha_envio, m.eliminado_en
      FROM public.mensaje m
      WHERE m.sala_id = s.id
      ORDER BY m.fecha_envio DESC, m.id DESC
      LIMIT 1
    ) um ON true
    LEFT JOIN LATERAL (
      SELECT count(*) AS total
      FROM public.mensaje m
      WHERE m.sala_id = s.id
        AND m.usuario_id <> auth.uid()
        AND m.eliminado_en IS NULL
        AND m.fecha_envio > COALESCE(yo.ultima_lectura, yo.fecha_ingreso)
    ) nl ON true
    WHERE auth.uid() IN (p.usuario_a, p.usuario_b)
  ),
  comunidad AS (
    SELECT
      CASE WHEN yo.usuario_id IS NOT NULL THEN s.id END AS sala_id,
      'comunidad'::text AS tipo,
      c.id AS comunidad_id,
      NULL::bigint AS salida_id,
      NULL::uuid AS usuario_id,
      c.nombre::text AS titulo,
      c.foto_portada,
      (
        c.usuario_creador_id = auth.uid()
        OR (cm.rol::text = 'admin' AND cm.estado::text = 'aprobado')
      ) AS puede_crear_sala,
      CASE WHEN yo.usuario_id IS NOT NULL THEN um.id END AS ultimo_id,
      CASE WHEN yo.usuario_id IS NOT NULL THEN um.contenido END AS ultimo_contenido,
      CASE WHEN yo.usuario_id IS NOT NULL THEN um.tipo_mensaje::text END AS ultimo_tipo,
      CASE WHEN yo.usuario_id IS NOT NULL THEN um.fecha_envio END AS ultimo_fecha,
      CASE WHEN yo.usuario_id IS NOT NULL THEN um.eliminado_en END
        AS ultimo_eliminado_en,
      CASE
        WHEN yo.usuario_id IS NOT NULL THEN COALESCE(nl.total, 0)::integer
        ELSE 0
      END AS no_leidos
    FROM public.comunidad c
    LEFT JOIN public.comunidad_miembro cm
      ON cm.comunidad_id = c.id AND cm.usuario_id = auth.uid()
    LEFT JOIN public.sala_chat s
      ON s.comunidad_id = c.id
      AND s.tipo = 'comunidad'::public.tipo_sala_chat
      AND s.estado = true
    LEFT JOIN public.sala_participante yo
      ON yo.sala_id = s.id AND yo.usuario_id = auth.uid()
    LEFT JOIN LATERAL (
      SELECT m.id, m.contenido, m.tipo_mensaje, m.fecha_envio, m.eliminado_en
      FROM public.mensaje m
      WHERE m.sala_id = s.id
      ORDER BY m.fecha_envio DESC, m.id DESC
      LIMIT 1
    ) um ON true
    LEFT JOIN LATERAL (
      SELECT count(*) AS total
      FROM public.mensaje m
      WHERE m.sala_id = s.id
        AND m.usuario_id <> auth.uid()
        AND m.eliminado_en IS NULL
        AND m.fecha_envio > COALESCE(yo.ultima_lectura, yo.fecha_ingreso)
    ) nl ON true
    WHERE c.estado = true
      AND (
        c.usuario_creador_id = auth.uid()
        OR cm.estado::text = 'aprobado'
      )
      AND (
        yo.usuario_id IS NOT NULL
        OR c.usuario_creador_id = auth.uid()
        OR (cm.rol::text = 'admin' AND cm.estado::text = 'aprobado')
      )
  ),
  salida AS (
    SELECT
      CASE WHEN yo.usuario_id IS NOT NULL THEN s.id END AS sala_id,
      'salida'::text AS tipo,
      NULL::bigint AS comunidad_id,
      sa.id AS salida_id,
      NULL::uuid AS usuario_id,
      COALESCE(
        NULLIF(btrim(sa.titulo), ''),
        NULLIF(btrim(l.nombre), ''),
        'Salida'
      )::text AS titulo,
      l.foto_portada,
      (sa.organizador_id = auth.uid()) AS puede_crear_sala,
      CASE WHEN yo.usuario_id IS NOT NULL THEN um.id END AS ultimo_id,
      CASE WHEN yo.usuario_id IS NOT NULL THEN um.contenido END AS ultimo_contenido,
      CASE WHEN yo.usuario_id IS NOT NULL THEN um.tipo_mensaje::text END AS ultimo_tipo,
      CASE WHEN yo.usuario_id IS NOT NULL THEN um.fecha_envio END AS ultimo_fecha,
      CASE WHEN yo.usuario_id IS NOT NULL THEN um.eliminado_en END
        AS ultimo_eliminado_en,
      CASE
        WHEN yo.usuario_id IS NOT NULL THEN COALESCE(nl.total, 0)::integer
        ELSE 0
      END AS no_leidos
    FROM public.salida sa
    LEFT JOIN public.lugar l ON l.id = sa.punto_encuentro_lugar_id
    LEFT JOIN public.salida_participante sap
      ON sap.salida_id = sa.id
      AND sap.usuario_id = auth.uid()
      AND sap.estado::text = 'confirmado'
    LEFT JOIN public.sala_chat s
      ON s.salida_id = sa.id
      AND s.tipo = 'salida'::public.tipo_sala_chat
      AND s.estado = true
    LEFT JOIN public.sala_participante yo
      ON yo.sala_id = s.id AND yo.usuario_id = auth.uid()
    LEFT JOIN LATERAL (
      SELECT m.id, m.contenido, m.tipo_mensaje, m.fecha_envio, m.eliminado_en
      FROM public.mensaje m
      WHERE m.sala_id = s.id
      ORDER BY m.fecha_envio DESC, m.id DESC
      LIMIT 1
    ) um ON true
    LEFT JOIN LATERAL (
      SELECT count(*) AS total
      FROM public.mensaje m
      WHERE m.sala_id = s.id
        AND m.usuario_id <> auth.uid()
        AND m.eliminado_en IS NULL
        AND m.fecha_envio > COALESCE(yo.ultima_lectura, yo.fecha_ingreso)
    ) nl ON true
    WHERE sa.estado::text <> 'cancelada'
      AND (sa.organizador_id = auth.uid() OR sap.usuario_id IS NOT NULL)
      AND (yo.usuario_id IS NOT NULL OR sa.organizador_id = auth.uid())
  )
  SELECT * FROM privado
  UNION ALL
  SELECT * FROM comunidad
  UNION ALL
  SELECT * FROM salida
  ORDER BY ultimo_fecha DESC NULLS LAST, titulo ASC;
$$;

REVOKE ALL ON FUNCTION public.listar_bandeja_chat() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_bandeja_chat()
  TO authenticated, service_role;

COMMENT ON FUNCTION public.listar_bandeja_chat() IS
  'Bandeja unificada; no cuenta mensajes anteriores al ingreso al roster.';
