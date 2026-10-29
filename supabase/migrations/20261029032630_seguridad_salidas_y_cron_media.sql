-- Seguridad incremental para dos superficies privilegiadas:
-- 1. El RPC de salidas conserva SECURITY DEFINER para calcular el roster,
--    pero aplica explicitamente la misma visibilidad que la RLS.
-- 2. El cron de medios usa un secreto dedicado; nunca service_role.
--
-- Secretos requeridos antes de habilitar el job en cada entorno:
--   vault: limpiador_media_function_url
--   vault: limpiador_media_cron_secret
--   Edge Runtime: LIMPIADOR_MEDIA_CRON_SECRET (mismo valor que Vault)

CREATE OR REPLACE FUNCTION public.listar_salidas_resumen(
  p_lugar_id bigint DEFAULT NULL,
  p_ruta_id bigint DEFAULT NULL,
  p_comunidad_id bigint DEFAULT NULL
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
  inscripcion_abierta boolean,
  inscritos_count integer,
  mi_estado_participante text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  WITH salidas_filtradas AS MATERIALIZED (
    SELECT s.*
    FROM public.salida AS s
    WHERE s.fecha_hora_inicio >= (now() - interval '2 days')
      AND (p_lugar_id IS NULL OR s.punto_encuentro_lugar_id = p_lugar_id)
      AND (p_ruta_id IS NULL OR s.ruta_id = p_ruta_id)
      AND (p_comunidad_id IS NULL OR s.comunidad_id = p_comunidad_id)
      AND (
        (
          auth.uid() IS NOT NULL
          AND s.organizador_id = auth.uid()
        )
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
    FROM public.salida_participante AS sp
    JOIN salidas_filtradas AS sf ON sf.id = sp.salida_id
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
    r.resumen::text,
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
    s.inscripcion_abierta,
    coalesce(ct.inscritos_count, 0),
    mia.estado::text
  FROM salidas_filtradas AS s
  JOIN public.usuario AS u ON u.id = s.organizador_id
  LEFT JOIN public.comunidad AS c ON c.id = s.comunidad_id
  LEFT JOIN public.ruta AS r
    ON r.id = s.ruta_id
    AND r.estado = true
    AND r.estado_editorial = 'publicado'
  LEFT JOIN public.lugar AS l ON l.id = s.punto_encuentro_lugar_id
  LEFT JOIN conteos AS ct ON ct.salida_id = s.id
  LEFT JOIN public.salida_participante AS mia
    ON mia.salida_id = s.id
    AND mia.usuario_id = auth.uid()
  ORDER BY s.fecha_hora_inicio;
$$;

REVOKE ALL ON FUNCTION public.listar_salidas_resumen(bigint, bigint, bigint)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_salidas_resumen(bigint, bigint, bigint)
  TO anon, authenticated, service_role;

COMMENT ON FUNCTION public.listar_salidas_resumen(bigint, bigint, bigint) IS
  'Listado liviano con conteos privilegiados y visibilidad explicita equivalente a salida_select_visibles.';

-- Reemplaza cualquier job historico que enviaba un POST anonimo. Si los
-- secretos no existen, la consulta produce cero filas y no hace una llamada.
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'limpiador-media-cron';

SELECT cron.schedule(
  'limpiador-media-cron',
  '0 * * * *',
  $cron$
    WITH configuracion AS (
      SELECT
        max(decrypted_secret) FILTER (
          WHERE name = 'limpiador_media_function_url'
        ) AS function_url,
        max(decrypted_secret) FILTER (
          WHERE name = 'limpiador_media_cron_secret'
        ) AS cron_secret
      FROM vault.decrypted_secrets
      WHERE name IN (
        'limpiador_media_function_url',
        'limpiador_media_cron_secret'
      )
    )
    SELECT net.http_post(
      url := function_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-haku-cron-secret', cron_secret
      ),
      body := '{}'::jsonb
    )
    FROM configuracion
    WHERE function_url IS NOT NULL
      AND cron_secret IS NOT NULL;
  $cron$
);
