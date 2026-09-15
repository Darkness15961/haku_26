-- Cierre bugs forenses post-900:
-- 1) Bloqueado no puede DELETE propia fila (bypass re-join).
-- 2) Participantes visibles en salidas públicas finalizadas (conteo cards).

DROP POLICY IF EXISTS comunidad_miembro_delete_propio_o_admin
  ON public.comunidad_miembro;
CREATE POLICY comunidad_miembro_delete_propio_o_admin ON public.comunidad_miembro
  FOR DELETE TO authenticated
  USING (
    (
      usuario_id = auth.uid()
      AND estado IS DISTINCT FROM 'bloqueado'::public.estado_membresia
    )
    OR public.es_admin_comunidad(comunidad_id)
  );

COMMENT ON POLICY comunidad_miembro_delete_propio_o_admin ON public.comunidad_miembro IS
  'Salir: propio si no bloqueado. Admin puede expulsar (incl. bloqueados).';

DROP POLICY IF EXISTS salida_participante_select_visible ON public.salida_participante;
CREATE POLICY salida_participante_select_visible ON public.salida_participante
  FOR SELECT TO authenticated
  USING (
    usuario_id = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM public.salida s
      WHERE s.id = salida_id
        AND s.organizador_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1
      FROM public.salida s
      WHERE s.id = salida_id
        AND s.tipo = 'publica'::public.tipo_salida
        AND s.estado IN (
          'programada'::public.estado_salida,
          'en_curso'::public.estado_salida,
          'finalizada'::public.estado_salida
        )
    )
    OR EXISTS (
      SELECT 1
      FROM public.salida s
      WHERE s.id = salida_id
        AND s.comunidad_id IS NOT NULL
        AND public.es_miembro_comunidad_aprobado(s.comunidad_id)
    )
  );

COMMENT ON POLICY salida_participante_select_visible ON public.salida_participante IS
  'Propio, organizador, pública programada/en_curso/finalizada, o miembro de comunidad.';
