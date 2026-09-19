CREATE OR REPLACE FUNCTION public.le_di_me_gusta(publicacion public.publicacion)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.publicacion_me_gusta
    WHERE publicacion_id = publicacion.id
    AND usuario_id = auth.uid()
  );
$$;
