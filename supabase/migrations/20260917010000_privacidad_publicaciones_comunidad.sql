-- Una publicación vinculada a una comunidad privada pertenece a esa audiencia:
-- nunca debe aparecer en el feed público global.

ALTER TABLE public.publicacion
  ADD COLUMN IF NOT EXISTS audiencia_privada_automatica boolean
  NOT NULL DEFAULT false;

-- Comunidades usan baja lógica. RESTRICT evita que una eliminación
-- administrativa en cascada convierta contenido privado en público.
ALTER TABLE public.publicacion_etiqueta_comunidad
  DROP CONSTRAINT IF EXISTS
    publicacion_etiqueta_comunidad_comunidad_id_fkey,
  ADD CONSTRAINT publicacion_etiqueta_comunidad_comunidad_id_fkey
    FOREIGN KEY (comunidad_id)
    REFERENCES public.comunidad(id)
    ON DELETE RESTRICT;

CREATE OR REPLACE FUNCTION public.forzar_audiencia_comunidad_privada()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.comunidad c
    WHERE c.id = NEW.comunidad_id
      AND c.tipo = 'privado'::public.tipo_comunidad
  ) THEN
    UPDATE public.publicacion
    SET
      estado = 'privado'::public.estado_publicacion,
      audiencia_privada_automatica = true
    WHERE id = NEW.publicacion_id
      AND estado = 'publico'::public.estado_publicacion;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_forzar_audiencia_comunidad_privada
  ON public.publicacion_etiqueta_comunidad;
CREATE TRIGGER trg_forzar_audiencia_comunidad_privada
  BEFORE INSERT OR UPDATE OF comunidad_id
  ON public.publicacion_etiqueta_comunidad
  FOR EACH ROW
  EXECUTE FUNCTION public.forzar_audiencia_comunidad_privada();

CREATE OR REPLACE FUNCTION public.reconciliar_audiencia_etiqueta_eliminada()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
BEGIN
  UPDATE public.publicacion p
  SET
    estado = 'publico'::public.estado_publicacion,
    audiencia_privada_automatica = false
  WHERE p.id = OLD.publicacion_id
    AND p.audiencia_privada_automatica = true
    AND p.estado = 'privado'::public.estado_publicacion
    AND NOT EXISTS (
      SELECT 1
      FROM public.publicacion_etiqueta_comunidad pec
      JOIN public.comunidad c ON c.id = pec.comunidad_id
      WHERE pec.publicacion_id = p.id
        AND c.tipo = 'privado'::public.tipo_comunidad
    );
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_reconciliar_audiencia_etiqueta_eliminada
  ON public.publicacion_etiqueta_comunidad;
CREATE TRIGGER trg_reconciliar_audiencia_etiqueta_eliminada
  AFTER DELETE
  ON public.publicacion_etiqueta_comunidad
  FOR EACH ROW
  EXECUTE FUNCTION public.reconciliar_audiencia_etiqueta_eliminada();

CREATE OR REPLACE FUNCTION public.proteger_audiencia_publicacion()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
BEGIN
  IF NEW.estado = 'publico'::public.estado_publicacion
     AND EXISTS (
       SELECT 1
       FROM public.publicacion_etiqueta_comunidad pec
       JOIN public.comunidad c ON c.id = pec.comunidad_id
       WHERE pec.publicacion_id = NEW.id
         AND c.tipo = 'privado'::public.tipo_comunidad
     ) THEN
    NEW.estado := 'privado'::public.estado_publicacion;
    NEW.audiencia_privada_automatica := true;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_proteger_audiencia_publicacion
  ON public.publicacion;
CREATE TRIGGER trg_proteger_audiencia_publicacion
  BEFORE UPDATE OF estado
  ON public.publicacion
  FOR EACH ROW
  EXECUTE FUNCTION public.proteger_audiencia_publicacion();

-- Corregir filas creadas antes de esta regla.
UPDATE public.publicacion p
SET
  estado = 'privado'::public.estado_publicacion,
  audiencia_privada_automatica = true
WHERE p.estado = 'publico'::public.estado_publicacion
  AND EXISTS (
    SELECT 1
    FROM public.publicacion_etiqueta_comunidad pec
    JOIN public.comunidad c ON c.id = pec.comunidad_id
    WHERE pec.publicacion_id = p.id
      AND c.tipo = 'privado'::public.tipo_comunidad
  );

-- Si en el futuro una comunidad cambia de tipo, solo se restauran las
-- publicaciones privatizadas automáticamente; las privadas por decisión del
-- autor permanecen privadas.
CREATE OR REPLACE FUNCTION public.reconciliar_audiencia_tipo_comunidad()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
BEGIN
  IF OLD.tipo = NEW.tipo THEN
    RETURN NEW;
  END IF;

  IF NEW.tipo = 'privado'::public.tipo_comunidad THEN
    UPDATE public.publicacion p
    SET
      estado = 'privado'::public.estado_publicacion,
      audiencia_privada_automatica = true
    FROM public.publicacion_etiqueta_comunidad pec
    WHERE pec.comunidad_id = NEW.id
      AND pec.publicacion_id = p.id
      AND p.estado = 'publico'::public.estado_publicacion;
  ELSE
    UPDATE public.publicacion p
    SET
      estado = 'publico'::public.estado_publicacion,
      audiencia_privada_automatica = false
    WHERE p.audiencia_privada_automatica = true
      AND p.estado = 'privado'::public.estado_publicacion
      AND EXISTS (
        SELECT 1
        FROM public.publicacion_etiqueta_comunidad pec
        WHERE pec.publicacion_id = p.id
          AND pec.comunidad_id = NEW.id
      )
      AND NOT EXISTS (
        SELECT 1
        FROM public.publicacion_etiqueta_comunidad pec
        JOIN public.comunidad c ON c.id = pec.comunidad_id
        WHERE pec.publicacion_id = p.id
          AND c.tipo = 'privado'::public.tipo_comunidad
      );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_reconciliar_audiencia_tipo
  ON public.comunidad;
CREATE TRIGGER trg_reconciliar_audiencia_tipo
  AFTER UPDATE OF tipo
  ON public.comunidad
  FOR EACH ROW
  EXECUTE FUNCTION public.reconciliar_audiencia_tipo_comunidad();

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
        (auth.uid() IS NOT NULL AND p.usuario_id = auth.uid())
        OR (
          p.estado = 'publico'::public.estado_publicacion
          AND NOT EXISTS (
            SELECT 1
            FROM public.publicacion_etiqueta_comunidad pec
            JOIN public.comunidad c ON c.id = pec.comunidad_id
            WHERE pec.publicacion_id = p.id
              AND c.tipo = 'privado'::public.tipo_comunidad
          )
        )
        OR (
          auth.uid() IS NOT NULL
          AND EXISTS (
            SELECT 1
            FROM public.publicacion_etiqueta_comunidad pec
            JOIN public.comunidad c ON c.id = pec.comunidad_id
            WHERE pec.publicacion_id = p.id
              AND c.tipo = 'privado'::public.tipo_comunidad
          )
          AND NOT EXISTS (
            SELECT 1
            FROM public.publicacion_etiqueta_comunidad pec
            JOIN public.comunidad c ON c.id = pec.comunidad_id
            WHERE pec.publicacion_id = p.id
              AND c.tipo = 'privado'::public.tipo_comunidad
              AND c.usuario_creador_id <> auth.uid()
              AND NOT public.es_miembro_comunidad_aprobado(c.id)
              AND NOT public.es_admin_comunidad(c.id)
          )
        )
      )
  );
$$;

DROP POLICY IF EXISTS publicacion_select_visibles ON public.publicacion;
CREATE POLICY publicacion_select_visibles ON public.publicacion
  FOR SELECT TO anon, authenticated
  USING (public.puede_ver_publicacion(id));

REVOKE ALL ON FUNCTION public.forzar_audiencia_comunidad_privada()
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.proteger_audiencia_publicacion()
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reconciliar_audiencia_etiqueta_eliminada()
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reconciliar_audiencia_tipo_comunidad()
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.forzar_audiencia_comunidad_privada()
  TO service_role;
GRANT EXECUTE ON FUNCTION public.proteger_audiencia_publicacion()
  TO service_role;
GRANT EXECUTE ON FUNCTION public.reconciliar_audiencia_etiqueta_eliminada()
  TO service_role;
GRANT EXECUTE ON FUNCTION public.reconciliar_audiencia_tipo_comunidad()
  TO service_role;

COMMENT ON FUNCTION public.puede_ver_publicacion(bigint) IS
  'Visible al autor, al público sin comunidad privada o a miembros de toda audiencia privada vinculada.';
