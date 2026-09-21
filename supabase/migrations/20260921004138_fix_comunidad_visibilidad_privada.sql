-- Corrección de visibilidad de comunidades privadas.
-- Anteriormente, las comunidades privadas solo eran visibles (SELECT) 
-- por el creador o sus miembros. Esto impedía que otros usuarios 
-- pudieran verlas en la lista o buscarlas para poder solicitar unirse.
-- Ahora, todas las comunidades con estado=true son visibles, permitiendo 
-- a cualquiera ver su "perfil público" (nombre, descripción). 
-- OJO: El contenido interno (miembros, chat, eventos) sigue protegido 
-- por las políticas de sus respectivas tablas.

DROP POLICY IF EXISTS comunidad_select_visibles ON public.comunidad;
CREATE POLICY comunidad_select_visibles ON public.comunidad
  FOR SELECT TO anon, authenticated
  USING (
    (auth.uid() IS NOT NULL AND usuario_creador_id = auth.uid())
    OR estado = true
  );

COMMENT ON POLICY comunidad_select_visibles ON public.comunidad IS
  'Creador ve las propias (incluso inactivas). Todas las comunidades activas (estado=true) son visibles para que puedan ser encontradas, sin importar si son públicas o privadas.';
