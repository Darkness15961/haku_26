-- Ajuste fino RLS: quien tiene fila en comunidad_miembro (aunque pendiente)
-- puede SELECT la comunidad (ver su solicitud). Sin ALTER de tablas.

CREATE OR REPLACE FUNCTION public.tiene_membresia_comunidad(p_comunidad_id bigint)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.comunidad_miembro m
    WHERE m.comunidad_id = p_comunidad_id
      AND m.usuario_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION public.tiene_membresia_comunidad(bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tiene_membresia_comunidad(bigint)
  TO anon, authenticated, service_role;

DROP POLICY IF EXISTS comunidad_select_visibles ON public.comunidad;
CREATE POLICY comunidad_select_visibles ON public.comunidad
  FOR SELECT TO anon, authenticated
  USING (
    estado = true
    AND (
      tipo = 'publico'::public.tipo_comunidad
      OR (auth.uid() IS NOT NULL AND usuario_creador_id = auth.uid())
      OR (auth.uid() IS NOT NULL AND public.es_miembro_comunidad_aprobado(id))
      OR (auth.uid() IS NOT NULL AND public.tiene_membresia_comunidad(id))
    )
  );

COMMENT ON FUNCTION public.tiene_membresia_comunidad(bigint) IS
  'Helper RLS: true si auth.uid() tiene cualquier fila en comunidad_miembro (incl. pendiente).';
