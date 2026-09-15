-- Bloque E: RLS producto para publicacion (+ hijos).
-- Hoy: RLS ON sin policies → SELECT siempre vacío (síntoma clásico).
-- Sin seed. Sin Bunny/likes (no hay tablas). Append + soft-delete por estado.

-- ---------------------------------------------------------------------------
-- Helper: ¿auth puede ver esta publicación?
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.puede_ver_publicacion(p_publicacion_id bigint)
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
        p.estado = 'publico'::public.estado_publicacion
        OR (auth.uid() IS NOT NULL AND p.usuario_id = auth.uid())
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.es_autor_publicacion(p_publicacion_id bigint)
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
      AND auth.uid() IS NOT NULL
      AND p.usuario_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION public.puede_ver_publicacion(bigint) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.es_autor_publicacion(bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.puede_ver_publicacion(bigint)
  TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.es_autor_publicacion(bigint)
  TO anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Integridad contenido
-- ---------------------------------------------------------------------------

ALTER TABLE public.publicacion
  DROP CONSTRAINT IF EXISTS publicacion_contenido_valido;

ALTER TABLE public.publicacion
  ADD CONSTRAINT publicacion_contenido_valido
  CHECK (
    char_length(btrim(contenido)) >= 1
    AND char_length(contenido) <= 4000
  );

-- ---------------------------------------------------------------------------
-- public.publicacion
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS publicacion_select_visibles ON public.publicacion;
CREATE POLICY publicacion_select_visibles ON public.publicacion
  FOR SELECT TO anon, authenticated
  USING (
    estado <> 'eliminado'::public.estado_publicacion
    AND (
      estado = 'publico'::public.estado_publicacion
      OR (auth.uid() IS NOT NULL AND usuario_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS publicacion_insert_propia ON public.publicacion;
CREATE POLICY publicacion_insert_propia ON public.publicacion
  FOR INSERT TO authenticated
  WITH CHECK (
    usuario_id = auth.uid()
    AND estado IN (
      'publico'::public.estado_publicacion,
      'privado'::public.estado_publicacion
    )
  );

DROP POLICY IF EXISTS publicacion_update_propia ON public.publicacion;
CREATE POLICY publicacion_update_propia ON public.publicacion
  FOR UPDATE TO authenticated
  USING (usuario_id = auth.uid())
  WITH CHECK (usuario_id = auth.uid());

-- Sin DELETE duro: soft → estado = eliminado.

-- ---------------------------------------------------------------------------
-- public.publicacion_etiqueta_comunidad
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS publicacion_etiqueta_comunidad_select ON public.publicacion_etiqueta_comunidad;
CREATE POLICY publicacion_etiqueta_comunidad_select ON public.publicacion_etiqueta_comunidad
  FOR SELECT TO anon, authenticated
  USING (public.puede_ver_publicacion(publicacion_id));

DROP POLICY IF EXISTS publicacion_etiqueta_comunidad_insert ON public.publicacion_etiqueta_comunidad;
CREATE POLICY publicacion_etiqueta_comunidad_insert ON public.publicacion_etiqueta_comunidad
  FOR INSERT TO authenticated
  WITH CHECK (
    public.es_autor_publicacion(publicacion_id)
    AND (
      EXISTS (
        SELECT 1
        FROM public.comunidad c
        WHERE c.id = comunidad_id
          AND c.estado = true
          AND c.tipo = 'publico'::public.tipo_comunidad
      )
      OR public.es_miembro_comunidad_aprobado(comunidad_id)
      OR public.es_admin_comunidad(comunidad_id)
    )
  );

DROP POLICY IF EXISTS publicacion_etiqueta_comunidad_delete ON public.publicacion_etiqueta_comunidad;
CREATE POLICY publicacion_etiqueta_comunidad_delete ON public.publicacion_etiqueta_comunidad
  FOR DELETE TO authenticated
  USING (public.es_autor_publicacion(publicacion_id));

-- ---------------------------------------------------------------------------
-- public.publicacion_lugar
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS publicacion_lugar_select ON public.publicacion_lugar;
CREATE POLICY publicacion_lugar_select ON public.publicacion_lugar
  FOR SELECT TO anon, authenticated
  USING (public.puede_ver_publicacion(publicacion_id));

DROP POLICY IF EXISTS publicacion_lugar_insert ON public.publicacion_lugar;
CREATE POLICY publicacion_lugar_insert ON public.publicacion_lugar
  FOR INSERT TO authenticated
  WITH CHECK (
    public.es_autor_publicacion(publicacion_id)
    AND EXISTS (
      SELECT 1 FROM public.lugar l
      WHERE l.id = lugar_id AND l.estado = true
    )
  );

DROP POLICY IF EXISTS publicacion_lugar_delete ON public.publicacion_lugar;
CREATE POLICY publicacion_lugar_delete ON public.publicacion_lugar
  FOR DELETE TO authenticated
  USING (public.es_autor_publicacion(publicacion_id));

-- ---------------------------------------------------------------------------
-- public.publicacion_multimedia
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS publicacion_multimedia_select ON public.publicacion_multimedia;
CREATE POLICY publicacion_multimedia_select ON public.publicacion_multimedia
  FOR SELECT TO anon, authenticated
  USING (public.puede_ver_publicacion(publicacion_id));

DROP POLICY IF EXISTS publicacion_multimedia_insert ON public.publicacion_multimedia;
CREATE POLICY publicacion_multimedia_insert ON public.publicacion_multimedia
  FOR INSERT TO authenticated
  WITH CHECK (
    public.es_autor_publicacion(publicacion_id)
    AND char_length(btrim(url_archivo)) >= 1
  );

DROP POLICY IF EXISTS publicacion_multimedia_delete ON public.publicacion_multimedia;
CREATE POLICY publicacion_multimedia_delete ON public.publicacion_multimedia
  FOR DELETE TO authenticated
  USING (public.es_autor_publicacion(publicacion_id));

-- ---------------------------------------------------------------------------
-- public.publicacion_usuario_etiqueta (RLS listo; UI MVP no etiqueta usuarios)
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS publicacion_usuario_etiqueta_select ON public.publicacion_usuario_etiqueta;
CREATE POLICY publicacion_usuario_etiqueta_select ON public.publicacion_usuario_etiqueta
  FOR SELECT TO anon, authenticated
  USING (public.puede_ver_publicacion(publicacion_id));

DROP POLICY IF EXISTS publicacion_usuario_etiqueta_insert ON public.publicacion_usuario_etiqueta;
CREATE POLICY publicacion_usuario_etiqueta_insert ON public.publicacion_usuario_etiqueta
  FOR INSERT TO authenticated
  WITH CHECK (public.es_autor_publicacion(publicacion_id));

DROP POLICY IF EXISTS publicacion_usuario_etiqueta_delete ON public.publicacion_usuario_etiqueta;
CREATE POLICY publicacion_usuario_etiqueta_delete ON public.publicacion_usuario_etiqueta
  FOR DELETE TO authenticated
  USING (public.es_autor_publicacion(publicacion_id));

COMMENT ON FUNCTION public.puede_ver_publicacion(bigint) IS
  'Helper RLS: publica visible a todos; privadas/propias solo al autor. eliminado no pasa.';

COMMENT ON CONSTRAINT publicacion_contenido_valido ON public.publicacion IS
  'Contenido trim >= 1 y <= 4000 caracteres.';
