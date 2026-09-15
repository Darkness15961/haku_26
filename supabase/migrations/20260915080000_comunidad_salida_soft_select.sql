-- Soft-delete / cancel RLS: el dueño debe poder SELECT la fila resultante
-- (estado=false / cancelada). Sin esto, UPDATE de rollback falla en silencio
-- (mismo bug clase que publicacion 600).

-- ---------------------------------------------------------------------------
-- public.comunidad: creador ve las suyas aunque inactivas
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS comunidad_select_visibles ON public.comunidad;
CREATE POLICY comunidad_select_visibles ON public.comunidad
  FOR SELECT TO anon, authenticated
  USING (
    (auth.uid() IS NOT NULL AND usuario_creador_id = auth.uid())
    OR (
      estado = true
      AND (
        tipo = 'publico'::public.tipo_comunidad
        OR (auth.uid() IS NOT NULL AND public.es_miembro_comunidad_aprobado(id))
        OR (auth.uid() IS NOT NULL AND public.tiene_membresia_comunidad(id))
      )
    )
  );

-- ---------------------------------------------------------------------------
-- public.salida: organizador ve las suyas en cualquier estado (incl. cancelada)
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS salida_select_visibles ON public.salida;
CREATE POLICY salida_select_visibles ON public.salida
  FOR SELECT TO anon, authenticated
  USING (
    (auth.uid() IS NOT NULL AND organizador_id = auth.uid())
    OR (
      estado IN (
        'programada'::public.estado_salida,
        'en_curso'::public.estado_salida,
        'finalizada'::public.estado_salida
      )
      AND (
        tipo = 'publica'::public.tipo_salida
        OR (
          comunidad_id IS NOT NULL
          AND auth.uid() IS NOT NULL
          AND (
            public.es_miembro_comunidad_aprobado(comunidad_id)
            OR public.es_admin_comunidad(comunidad_id)
          )
        )
      )
    )
  );

DROP POLICY IF EXISTS salida_insert_organizador ON public.salida;
CREATE POLICY salida_insert_organizador ON public.salida
  FOR INSERT TO authenticated
  WITH CHECK (
    organizador_id = auth.uid()
    AND (
      (
        tipo = 'publica'::public.tipo_salida
        AND comunidad_id IS NULL
      )
      OR (
        tipo = 'comunidad'::public.tipo_salida
        AND comunidad_id IS NOT NULL
        AND (
          public.es_miembro_comunidad_aprobado(comunidad_id)
          OR public.es_admin_comunidad(comunidad_id)
        )
      )
    )
  );

COMMENT ON POLICY comunidad_select_visibles ON public.comunidad IS
  'Creador ve propias (incl. inactivas); resto solo activas visibles.';

COMMENT ON POLICY salida_select_visibles ON public.salida IS
  'Organizador ve propias (incl. cancelada); resto solo programada/en_curso/finalizada visibles.';
