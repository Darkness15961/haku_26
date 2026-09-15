-- Fix soft-delete de publicacion.
-- Bug: SELECT excluía estado=eliminado → UPDATE a eliminado fallaba en silencio
-- (PostgREST 0 filas) → publicaciones huérfanas seguían en el feed tras un
-- fallo de etiqueta/foto. El autor debe poder ver SUS filas en cualquier estado
-- para que el soft-delete pase el chequeo RLS de SELECT implícito en UPDATE.

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
      AND (
        (auth.uid() IS NOT NULL AND p.usuario_id = auth.uid())
        OR p.estado = 'publico'::public.estado_publicacion
      )
  );
$$;

DROP POLICY IF EXISTS publicacion_select_visibles ON public.publicacion;
CREATE POLICY publicacion_select_visibles ON public.publicacion
  FOR SELECT TO anon, authenticated
  USING (
    (auth.uid() IS NOT NULL AND usuario_id = auth.uid())
    OR estado = 'publico'::public.estado_publicacion
  );

COMMENT ON FUNCTION public.puede_ver_publicacion(bigint) IS
  'Helper RLS: autor ve las suyas (incl. eliminado/privado); resto solo publico.';
