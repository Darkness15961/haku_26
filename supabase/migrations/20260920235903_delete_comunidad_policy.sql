-- Permitir eliminar la comunidad si el usuario es el creador.
-- (Al eliminar, las reglas ON DELETE CASCADE limpiarán los miembros y el chat).

DROP POLICY IF EXISTS comunidad_delete_propio ON public.comunidad;
CREATE POLICY comunidad_delete_propio ON public.comunidad
  FOR DELETE TO authenticated
  USING (usuario_creador_id = auth.uid());
