-- Permitir eliminar una salida (o comunidad que en cascada elimina salidas)
-- sin que sea bloqueado por publicaciones que la hayan etiquetado.
-- La etiqueta de la publicación se borrará, pero la publicación en sí se mantiene.

ALTER TABLE public.publicacion_salida
  DROP CONSTRAINT IF EXISTS publicacion_salida_salida_id_fkey;

ALTER TABLE public.publicacion_salida
  ADD CONSTRAINT publicacion_salida_salida_id_fkey 
  FOREIGN KEY (salida_id) 
  REFERENCES public.salida(id) 
  ON DELETE CASCADE;
