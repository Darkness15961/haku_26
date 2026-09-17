-- =============================================================================
-- Etiquetado de publicación a salida + corrección de privacidad
-- =============================================================================
--
-- Cambios de producto:
--
--   1. `publicacion_salida`: nueva tabla que vincula publicación ↔ salida.
--
--   2. CORRECCIÓN DE PRIVACIDAD: las etiquetas (comunidad, salida, ruta, lugar)
--      son CONTEXTO INFORMATIVO, no control de acceso. Ya NO fuerzan privacidad.
--
--      - Una persona publica lo que quiera: texto, foto, video, etiquetas.
--      - Todo es PÚBLICO por defecto.
--      - El autor PUEDE elegir "solo comunidad" (privado) si quiere.
--      - Si elige privado, solo miembros de la comunidad etiquetada la ven.
--      - Etiquetar una comunidad privada NO fuerza la publicación a privada.
--        El tag simplemente dice "fui con este grupo"; no da acceso al grupo.
--
--   3. Se eliminan los triggers de privacidad automática que forzaban
--      `estado = 'privado'` al etiquetar comunidad privada (migración
--      20260917010000). La columna `audiencia_privada_automatica` se
--      conserva por compatibilidad pero ya no la escribe ningún trigger.
--
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Tabla publicacion_salida
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.publicacion_salida (
  publicacion_id  bigint      NOT NULL
    REFERENCES public.publicacion(id) ON DELETE CASCADE,
  salida_id       bigint      NOT NULL
    REFERENCES public.salida(id) ON DELETE RESTRICT,
  fecha_etiquetado timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT publicacion_salida_pkey
    PRIMARY KEY (publicacion_id, salida_id)
);

CREATE INDEX IF NOT EXISTS idx_publicacion_salida_salida_id
  ON public.publicacion_salida (salida_id);

ALTER TABLE public.publicacion_salida ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.publicacion_salida IS
  'Vínculo informativo publicación ↔ salida. Indica contexto ("fui a esta salida"), '
  'no controla privacidad.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. RLS para publicacion_salida
-- ─────────────────────────────────────────────────────────────────────────────

-- SELECT: cualquier publicación visible.
DROP POLICY IF EXISTS publicacion_salida_select ON public.publicacion_salida;
CREATE POLICY publicacion_salida_select ON public.publicacion_salida
  FOR SELECT TO anon, authenticated
  USING (
    public.puede_ver_publicacion(publicacion_id)
  );

-- INSERT: solo el autor de la publicación.
DROP POLICY IF EXISTS publicacion_salida_insert ON public.publicacion_salida;
CREATE POLICY publicacion_salida_insert ON public.publicacion_salida
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.publicacion p
      WHERE p.id = publicacion_id
        AND p.usuario_id = auth.uid()
        AND p.estado <> 'eliminado'::public.estado_publicacion
    )
  );

-- DELETE: solo el autor de la publicación.
DROP POLICY IF EXISTS publicacion_salida_delete ON public.publicacion_salida;
CREATE POLICY publicacion_salida_delete ON public.publicacion_salida
  FOR DELETE TO authenticated
  USING (
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.publicacion p
      WHERE p.id = publicacion_id
        AND p.usuario_id = auth.uid()
    )
  );

GRANT SELECT, INSERT, DELETE ON public.publicacion_salida TO authenticated;
GRANT SELECT ON public.publicacion_salida TO anon;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Eliminar triggers de privacidad automática (de 20260917010000)
--
--    Estos triggers forzaban `estado = 'privado'` al etiquetar comunidad
--    privada. Ya no: las etiquetas son contexto, no control de acceso.
-- ─────────────────────────────────────────────────────────────────────────────

DROP TRIGGER IF EXISTS trg_forzar_audiencia_comunidad_privada
  ON public.publicacion_etiqueta_comunidad;

DROP TRIGGER IF EXISTS trg_reconciliar_audiencia_etiqueta_eliminada
  ON public.publicacion_etiqueta_comunidad;

DROP TRIGGER IF EXISTS trg_proteger_audiencia_publicacion
  ON public.publicacion;

DROP TRIGGER IF EXISTS trg_reconciliar_audiencia_tipo
  ON public.comunidad;

-- Las funciones quedan huérfanas; se eliminan para no confundir.
DROP FUNCTION IF EXISTS public.forzar_audiencia_comunidad_privada();
DROP FUNCTION IF EXISTS public.reconciliar_audiencia_etiqueta_eliminada();
DROP FUNCTION IF EXISTS public.proteger_audiencia_publicacion();
DROP FUNCTION IF EXISTS public.reconciliar_audiencia_tipo_comunidad();

-- Restaurar publicaciones que fueron privatizadas automáticamente.
-- Solo las que el trigger forzó (audiencia_privada_automatica = true).
-- Las que el usuario eligió privado manualmente se quedan privadas.
UPDATE public.publicacion
SET
  estado = 'publico'::public.estado_publicacion,
  audiencia_privada_automatica = false
WHERE audiencia_privada_automatica = true
  AND estado = 'privado'::public.estado_publicacion;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Simplificar puede_ver_publicacion
--
--    Ahora la lógica es simple:
--      - Eliminadas: nadie las ve.
--      - Públicas: todos las ven.
--      - Privadas (elegidas por el autor): solo el autor y miembros de las
--        comunidades etiquetadas.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.puede_ver_publicacion(
  p_publicacion_id bigint
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.publicacion p
    WHERE p.id = p_publicacion_id
      AND p.estado <> 'eliminado'::public.estado_publicacion
      AND (
        -- Pública: todo el mundo la ve
        p.estado = 'publico'::public.estado_publicacion

        -- El autor siempre ve la suya
        OR (auth.uid() IS NOT NULL AND p.usuario_id = auth.uid())

        -- Privada: miembros de AL MENOS UNA comunidad etiquetada
        OR (
          p.estado = 'privado'::public.estado_publicacion
          AND auth.uid() IS NOT NULL
          AND EXISTS (
            SELECT 1
            FROM public.publicacion_etiqueta_comunidad pec
            WHERE pec.publicacion_id = p.id
              AND (
                public.es_miembro_comunidad_aprobado(pec.comunidad_id)
                OR public.es_admin_comunidad(pec.comunidad_id)
              )
          )
        )
      )
  );
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Actualizar RPC crear_publicacion_completa: agregar p_salida_id
-- ─────────────────────────────────────────────────────────────────────────────

-- Borrar función con firma vieja (6 params) para evitar overloads.
DROP FUNCTION IF EXISTS public.crear_publicacion_completa(
  text, text, bigint, bigint, bigint, text
);

CREATE OR REPLACE FUNCTION public.crear_publicacion_completa(
  p_contenido text,
  p_estado text DEFAULT 'publico',
  p_comunidad_id bigint DEFAULT NULL,
  p_lugar_id bigint DEFAULT NULL,
  p_ruta_id bigint DEFAULT NULL,
  p_salida_id bigint DEFAULT NULL,
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

  -- Validar comunidad: pública = cualquier auth, privada = solo miembros
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

  -- Validar lugar: debe existir y estar activo
  IF p_lugar_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.lugar l
    WHERE l.id = p_lugar_id AND l.estado = true
  ) THEN
    RAISE EXCEPTION 'Lugar no disponible' USING ERRCODE = '22023';
  END IF;

  -- Validar ruta: debe existir, activa y publicada
  IF p_ruta_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.ruta r
    WHERE r.id = p_ruta_id
      AND r.estado = true
      AND r.estado_editorial = 'publicado'
  ) THEN
    RAISE EXCEPTION 'Ruta no publicada' USING ERRCODE = '22023';
  END IF;

  -- Validar salida: debe existir y no estar cancelada
  IF p_salida_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.salida s
    WHERE s.id = p_salida_id
      AND s.estado <> 'cancelada'::public.estado_salida
  ) THEN
    RAISE EXCEPTION 'Salida no disponible o cancelada' USING ERRCODE = '22023';
  END IF;

  -- Crear publicación
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

  -- Imagen opcional
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

  -- Etiqueta comunidad
  IF p_comunidad_id IS NOT NULL THEN
    INSERT INTO public.publicacion_etiqueta_comunidad (
      publicacion_id,
      comunidad_id
    ) VALUES (v_id, p_comunidad_id);
  END IF;

  -- Etiqueta lugar
  IF p_lugar_id IS NOT NULL THEN
    INSERT INTO public.publicacion_lugar (
      publicacion_id,
      lugar_id
    ) VALUES (v_id, p_lugar_id);
  END IF;

  -- Etiqueta ruta
  IF p_ruta_id IS NOT NULL THEN
    INSERT INTO public.publicacion_ruta (
      publicacion_id,
      ruta_id
    ) VALUES (v_id, p_ruta_id);
  END IF;

  -- Etiqueta salida
  IF p_salida_id IS NOT NULL THEN
    INSERT INTO public.publicacion_salida (
      publicacion_id,
      salida_id
    ) VALUES (v_id, p_salida_id);
  END IF;

  RETURN v_id;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Grants
-- ─────────────────────────────────────────────────────────────────────────────

REVOKE ALL ON FUNCTION public.crear_publicacion_completa(
  text, text, bigint, bigint, bigint, bigint, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crear_publicacion_completa(
  text, text, bigint, bigint, bigint, bigint, text
) TO authenticated, service_role;

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. Comentarios
-- ─────────────────────────────────────────────────────────────────────────────

COMMENT ON FUNCTION public.crear_publicacion_completa(
  text, text, bigint, bigint, bigint, bigint, text
) IS 'Crea publicación + relaciones opcionales (comunidad, lugar, ruta, salida, imagen) '
     'atómicamente. Privacidad es decisión del autor, no automática.';

COMMENT ON FUNCTION public.puede_ver_publicacion(bigint) IS
  'Pública = todos. Privada = autor + miembros de comunidad etiquetada. Eliminada = nadie.';
