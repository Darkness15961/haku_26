-- Rutas remotas: ficha técnica, nodos narrativos y trazado real.
-- Esta fase es deliberadamente de solo lectura para la app pública.

ALTER TABLE public.ruta
  ADD COLUMN IF NOT EXISTS slug text,
  ADD COLUMN IF NOT EXISTS tipo text NOT NULL DEFAULT 'senderismo',
  ADD COLUMN IF NOT EXISTS hilo_cultural text NOT NULL DEFAULT 'camino',
  ADD COLUMN IF NOT EXISTS resumen text,
  ADD COLUMN IF NOT EXISTS zona text,
  ADD COLUMN IF NOT EXISTS distancia_m integer,
  ADD COLUMN IF NOT EXISTS duracion_minutos integer,
  ADD COLUMN IF NOT EXISTS dias smallint NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS altitud_min_m integer,
  ADD COLUMN IF NOT EXISTS altitud_max_m integer,
  ADD COLUMN IF NOT EXISTS desnivel_positivo_m integer,
  ADD COLUMN IF NOT EXISTS meses_recomendados smallint[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS acceso text,
  ADD COLUMN IF NOT EXISTS transporte text,
  ADD COLUMN IF NOT EXISTS requisitos text[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS advertencias text[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS etiquetas text[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS estado_editorial text NOT NULL DEFAULT 'borrador',
  ADD COLUMN IF NOT EXISTS version smallint NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS publicada_en timestamptz,
  ADD COLUMN IF NOT EXISTS trazado public.geography(LineString, 4326);

UPDATE public.ruta
SET slug = 'ruta-' || id::text
WHERE slug IS NULL OR btrim(slug) = '';

-- Las filas activas anteriores eran el catálogo oficial del esquema original.
UPDATE public.ruta
SET estado_editorial = 'publicado',
    publicada_en = COALESCE(publicada_en, fecha_creacion)
WHERE estado = true
  AND estado_editorial = 'borrador';

ALTER TABLE public.ruta
  ALTER COLUMN slug SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_ruta_slug
  ON public.ruta (lower(slug));
CREATE INDEX IF NOT EXISTS idx_ruta_publicada
  ON public.ruta (publicada_en DESC, id DESC)
  WHERE estado = true AND estado_editorial = 'publicado';
CREATE INDEX IF NOT EXISTS idx_ruta_trazado_gist
  ON public.ruta USING gist (trazado);

ALTER TABLE public.ruta
  DROP CONSTRAINT IF EXISTS ruta_slug_formato,
  ADD CONSTRAINT ruta_slug_formato
    CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  DROP CONSTRAINT IF EXISTS ruta_tipo_valido,
  ADD CONSTRAINT ruta_tipo_valido
    CHECK (tipo IN ('senderismo', 'circuito', 'urbana', 'cultural', 'mixta')),
  DROP CONSTRAINT IF EXISTS ruta_hilo_cultural_valido,
  ADD CONSTRAINT ruta_hilo_cultural_valido
    CHECK (hilo_cultural IN (
      'camino', 'tejido', 'ceramica', 'comida', 'teatro', 'pintura'
    )),
  DROP CONSTRAINT IF EXISTS ruta_estado_editorial_valido,
  ADD CONSTRAINT ruta_estado_editorial_valido
    CHECK (estado_editorial IN (
      'borrador', 'propuesta', 'en_revision', 'publicado', 'rechazado', 'archivado'
    )),
  DROP CONSTRAINT IF EXISTS ruta_metricas_validas,
  ADD CONSTRAINT ruta_metricas_validas CHECK (
    (distancia_m IS NULL OR distancia_m >= 0)
    AND (duracion_minutos IS NULL OR duracion_minutos > 0)
    AND dias > 0
    AND (altitud_min_m IS NULL OR altitud_min_m >= 0)
    AND (altitud_max_m IS NULL OR altitud_max_m >= 0)
    AND (
      altitud_min_m IS NULL OR altitud_max_m IS NULL
      OR altitud_max_m >= altitud_min_m
    )
    AND (desnivel_positivo_m IS NULL OR desnivel_positivo_m >= 0)
    AND version > 0
  ),
  DROP CONSTRAINT IF EXISTS ruta_meses_validos,
  ADD CONSTRAINT ruta_meses_validos CHECK (
    meses_recomendados <@ ARRAY[1,2,3,4,5,6,7,8,9,10,11,12]::smallint[]
  ),
  DROP CONSTRAINT IF EXISTS ruta_trazado_valido,
  ADD CONSTRAINT ruta_trazado_valido CHECK (
    trazado IS NULL OR ST_NPoints(trazado::geometry) >= 2
  );

ALTER TABLE public.ruta_parada
  ADD COLUMN IF NOT EXISTS nombre text,
  ADD COLUMN IF NOT EXISTS tipo text NOT NULL DEFAULT 'parada',
  ADD COLUMN IF NOT EXISTS altitud_m integer,
  ADD COLUMN IF NOT EXISTS distancia_acumulada_m integer,
  ADD COLUMN IF NOT EXISTS tiempo_acumulado_minutos integer;

UPDATE public.ruta_parada rp
SET nombre = COALESCE(NULLIF(btrim(l.nombre), ''), 'Parada ' || rp.orden::text)
FROM public.lugar l
WHERE rp.lugar_id = l.id
  AND (rp.nombre IS NULL OR btrim(rp.nombre) = '');

UPDATE public.ruta_parada
SET nombre = 'Parada ' || orden::text
WHERE nombre IS NULL OR btrim(nombre) = '';

ALTER TABLE public.ruta_parada
  ALTER COLUMN nombre SET NOT NULL,
  DROP CONSTRAINT IF EXISTS ruta_parada_tipo_valido,
  ADD CONSTRAINT ruta_parada_tipo_valido
    CHECK (tipo IN ('inicio', 'parada', 'mirador', 'descanso', 'servicio', 'destino')),
  DROP CONSTRAINT IF EXISTS ruta_parada_metricas_validas,
  ADD CONSTRAINT ruta_parada_metricas_validas CHECK (
    orden >= 0
    AND (altitud_m IS NULL OR altitud_m >= 0)
    AND (distancia_acumulada_m IS NULL OR distancia_acumulada_m >= 0)
    AND (tiempo_acumulado_minutos IS NULL OR tiempo_acumulado_minutos >= 0)
  );

-- Relación explícita para publicaciones y métricas sociales de una Ruta.
CREATE TABLE IF NOT EXISTS public.publicacion_ruta (
  publicacion_id bigint NOT NULL
    REFERENCES public.publicacion(id) ON DELETE CASCADE,
  ruta_id bigint NOT NULL
    REFERENCES public.ruta(id) ON DELETE RESTRICT,
  fecha_etiquetado timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (publicacion_id, ruta_id)
);

CREATE INDEX IF NOT EXISTS idx_publicacion_ruta_ruta_id
  ON public.publicacion_ruta (ruta_id);

ALTER TABLE public.ruta ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ruta_parada ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.publicacion_ruta ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ruta_select_publicada ON public.ruta;
CREATE POLICY ruta_select_publicada ON public.ruta
  FOR SELECT TO anon, authenticated
  USING (estado = true AND estado_editorial = 'publicado');

DROP POLICY IF EXISTS ruta_parada_select_publicada ON public.ruta_parada;
CREATE POLICY ruta_parada_select_publicada ON public.ruta_parada
  FOR SELECT TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.ruta r
      WHERE r.id = ruta_id
        AND r.estado = true
        AND r.estado_editorial = 'publicado'
    )
  );

-- Una Salida solo puede enlazar una Ruta visible; conserva las reglas
-- actuales de salida pública o de membresía en comunidad.
DROP POLICY IF EXISTS salida_insert_organizador ON public.salida;
CREATE POLICY salida_insert_organizador ON public.salida
  FOR INSERT TO authenticated
  WITH CHECK (
    organizador_id = auth.uid()
    AND (
      (
        tipo = 'publica'::public.tipo_salida
        AND comunidad_id IS NULL
      )
      OR (
        tipo = 'comunidad'::public.tipo_salida
        AND comunidad_id IS NOT NULL
        AND (
          public.es_miembro_comunidad_aprobado(comunidad_id)
          OR public.es_admin_comunidad(comunidad_id)
        )
      )
    )
    AND (
      ruta_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.ruta r
        WHERE r.id = ruta_id
          AND r.estado = true
          AND r.estado_editorial = 'publicado'
      )
    )
  );

DROP POLICY IF EXISTS salida_update_organizador ON public.salida;
CREATE POLICY salida_update_organizador ON public.salida
  FOR UPDATE TO authenticated
  USING (organizador_id = auth.uid())
  WITH CHECK (
    organizador_id = auth.uid()
    AND (
      (
        tipo = 'publica'::public.tipo_salida
        AND comunidad_id IS NULL
      )
      OR (
        tipo = 'comunidad'::public.tipo_salida
        AND comunidad_id IS NOT NULL
        AND (
          public.es_miembro_comunidad_aprobado(comunidad_id)
          OR public.es_admin_comunidad(comunidad_id)
        )
      )
    )
    AND (
      ruta_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.ruta r
        WHERE r.id = ruta_id
          AND r.estado = true
          AND r.estado_editorial = 'publicado'
      )
    )
  );

DROP POLICY IF EXISTS publicacion_ruta_select ON public.publicacion_ruta;
CREATE POLICY publicacion_ruta_select ON public.publicacion_ruta
  FOR SELECT TO anon, authenticated
  USING (
    public.puede_ver_publicacion(publicacion_id)
    AND EXISTS (
      SELECT 1
      FROM public.ruta r
      WHERE r.id = ruta_id
        AND r.estado = true
        AND r.estado_editorial = 'publicado'
    )
  );

DROP POLICY IF EXISTS publicacion_ruta_insert ON public.publicacion_ruta;
CREATE POLICY publicacion_ruta_insert ON public.publicacion_ruta
  FOR INSERT TO authenticated
  WITH CHECK (
    public.es_autor_publicacion(publicacion_id)
    AND EXISTS (
      SELECT 1
      FROM public.ruta r
      WHERE r.id = ruta_id
        AND r.estado = true
        AND r.estado_editorial = 'publicado'
    )
  );

DROP POLICY IF EXISTS publicacion_ruta_delete ON public.publicacion_ruta;
CREATE POLICY publicacion_ruta_delete ON public.publicacion_ruta
  FOR DELETE TO authenticated
  USING (public.es_autor_publicacion(publicacion_id));

-- Listado liviano: sin nodos ni geometría.
CREATE OR REPLACE VIEW public.rutas_publicadas_lista
WITH (security_invoker = true)
AS
SELECT
  r.id,
  r.slug,
  r.nombre,
  r.resumen,
  r.descripcion,
  r.foto_portada,
  r.tipo,
  r.hilo_cultural,
  r.zona,
  r.dificultad::text AS dificultad,
  r.distancia_m,
  r.duracion_minutos,
  r.dias,
  r.altitud_min_m,
  r.altitud_max_m,
  r.desnivel_positivo_m,
  r.meses_recomendados,
  r.acceso,
  r.transporte,
  r.requisitos,
  r.advertencias,
  r.etiquetas,
  r.version,
  r.publicada_en,
  count(rp.id)::integer AS cantidad_paradas
FROM public.ruta r
LEFT JOIN public.ruta_parada rp ON rp.ruta_id = r.id
WHERE r.estado = true
  AND r.estado_editorial = 'publicado'
GROUP BY r.id;

-- Detalle en una sola ida; GeoJSON solo se entrega si hay trazado real.
CREATE OR REPLACE FUNCTION public.ruta_publicada_detalle(p_ruta_id bigint)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path TO public
AS $$
  SELECT to_jsonb(v)
    || jsonb_build_object(
      'trazado_geojson',
        CASE
          WHEN r.trazado IS NULL THEN NULL
          ELSE ST_AsGeoJSON(r.trazado::geometry)::jsonb
        END,
      'paradas',
        COALESCE(
          (
            SELECT jsonb_agg(
              jsonb_build_object(
                'id', rp.id,
                'nombre', rp.nombre,
                'tipo', rp.tipo,
                'latitud', rp.latitud,
                'longitud', rp.longitud,
                'altitud_m', rp.altitud_m,
                'orden', rp.orden,
                'instrucciones', rp.instrucciones,
                'distancia_acumulada_m', rp.distancia_acumulada_m,
                'tiempo_acumulado_minutos', rp.tiempo_acumulado_minutos,
                'lugar_id', rp.lugar_id
              )
              ORDER BY rp.orden
            )
            FROM public.ruta_parada rp
            WHERE rp.ruta_id = r.id
          ),
          '[]'::jsonb
        )
    )
  FROM public.ruta r
  JOIN public.rutas_publicadas_lista v ON v.id = r.id
  WHERE r.id = p_ruta_id
    AND r.estado = true
    AND r.estado_editorial = 'publicado';
$$;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON public.ruta, public.ruta_parada FROM anon, authenticated;
GRANT SELECT ON public.ruta, public.ruta_parada TO anon, authenticated;
GRANT SELECT ON public.rutas_publicadas_lista TO anon, authenticated;
GRANT SELECT, INSERT, DELETE ON public.publicacion_ruta TO authenticated;
GRANT SELECT ON public.publicacion_ruta TO anon;

REVOKE ALL ON FUNCTION public.ruta_publicada_detalle(bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ruta_publicada_detalle(bigint)
  TO anon, authenticated, service_role;

COMMENT ON COLUMN public.ruta.trazado IS
  'LineString real importado/validado. NULL significa que no debe dibujarse una línea.';
COMMENT ON COLUMN public.ruta.estado_editorial IS
  'Preparado para moderación futura; la app pública solo lee publicado.';
COMMENT ON TABLE public.publicacion_ruta IS
  'Una publicación puede etiquetar una Ruta publicada para experiencias y métricas.';
