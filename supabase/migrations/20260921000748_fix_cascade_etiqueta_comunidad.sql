-- La restricción RESTRICT se introdujo en 20260917010000 para proteger
-- la lógica automática de privacidad (triggers que pasaban publicaciones de 
-- privado a público).
-- Sin embargo, esos triggers fueron ELIMINADOS en 20260917144000.
-- Mantener RESTRICT ahora solo causa que sea IMPOSIBLE eliminar una 
-- comunidad que ha sido etiquetada en alguna publicación.
-- Restauramos ON DELETE CASCADE para que la etiqueta se elimine si la 
-- comunidad desaparece (la publicación original quedará intacta).

ALTER TABLE public.publicacion_etiqueta_comunidad
  DROP CONSTRAINT IF EXISTS publicacion_etiqueta_comunidad_comunidad_id_fkey;

ALTER TABLE public.publicacion_etiqueta_comunidad
  ADD CONSTRAINT publicacion_etiqueta_comunidad_comunidad_id_fkey 
  FOREIGN KEY (comunidad_id) 
  REFERENCES public.comunidad(id) 
  ON DELETE CASCADE;
