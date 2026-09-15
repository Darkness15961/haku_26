-- Bloque 0 Comunidad: RLS de producto para comunidad + salidas.
-- SOLO policies + helpers SECURITY DEFINER (anti-recursión RLS).
-- NO ALTER TABLE, NO DROP COLUMN, NO seed, NO tocar publicacion/*.
-- Enum USAGE ya concedido en 20260912230000_explora_lugar_pulido.sql.
-- GRANT de tablas ya existen en remote_schema; no se re-tocan.

-- ---------------------------------------------------------------------------
-- Helpers (bypassean RLS de miembro para que las policies no se auto-referencien)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.es_miembro_comunidad_aprobado(p_comunidad_id bigint)
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
      AND m.estado = 'aprobado'::public.estado_membresia
  );
$$;

CREATE OR REPLACE FUNCTION public.es_admin_comunidad(p_comunidad_id bigint)
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
      AND m.estado = 'aprobado'::public.estado_membresia
      AND m.rol = 'admin'::public.rol_miembro
  )
  OR EXISTS (
    SELECT 1
    FROM public.comunidad c
    WHERE c.id = p_comunidad_id
      AND c.usuario_creador_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION public.es_miembro_comunidad_aprobado(bigint) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.es_admin_comunidad(bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.es_miembro_comunidad_aprobado(bigint)
  TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.es_admin_comunidad(bigint)
  TO anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- public.comunidad
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS comunidad_select_visibles ON public.comunidad;
CREATE POLICY comunidad_select_visibles ON public.comunidad
  FOR SELECT TO anon, authenticated
  USING (
    estado = true
    AND (
      tipo = 'publico'::public.tipo_comunidad
      OR (auth.uid() IS NOT NULL AND usuario_creador_id = auth.uid())
      OR (auth.uid() IS NOT NULL AND public.es_miembro_comunidad_aprobado(id))
    )
  );

DROP POLICY IF EXISTS comunidad_insert_propio ON public.comunidad;
CREATE POLICY comunidad_insert_propio ON public.comunidad
  FOR INSERT TO authenticated
  WITH CHECK (usuario_creador_id = auth.uid());

DROP POLICY IF EXISTS comunidad_update_admin ON public.comunidad;
CREATE POLICY comunidad_update_admin ON public.comunidad
  FOR UPDATE TO authenticated
  USING (
    usuario_creador_id = auth.uid()
    OR public.es_admin_comunidad(id)
  )
  WITH CHECK (
    usuario_creador_id = auth.uid()
    OR public.es_admin_comunidad(id)
  );

-- Sin DELETE duro: desactivar con UPDATE estado = false (mismo USING).

-- ---------------------------------------------------------------------------
-- public.comunidad_miembro
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS comunidad_miembro_select_visible ON public.comunidad_miembro;
CREATE POLICY comunidad_miembro_select_visible ON public.comunidad_miembro
  FOR SELECT TO anon, authenticated
  USING (
    usuario_id = auth.uid()
    OR public.es_miembro_comunidad_aprobado(comunidad_id)
    OR EXISTS (
      SELECT 1
      FROM public.comunidad c
      WHERE c.id = comunidad_id
        AND c.estado = true
        AND c.tipo = 'publico'::public.tipo_comunidad
    )
  );

DROP POLICY IF EXISTS comunidad_miembro_insert_propio ON public.comunidad_miembro;
CREATE POLICY comunidad_miembro_insert_propio ON public.comunidad_miembro
  FOR INSERT TO authenticated
  WITH CHECK (
    usuario_id = auth.uid()
    AND (
      -- Creador se registra como admin al crear el grupo
      (
        EXISTS (
          SELECT 1
          FROM public.comunidad c
          WHERE c.id = comunidad_id
            AND c.usuario_creador_id = auth.uid()
        )
        AND rol = 'admin'::public.rol_miembro
        AND estado = 'aprobado'::public.estado_membresia
      )
      -- Unirse a pública → aprobado / miembro
      OR (
        EXISTS (
          SELECT 1
          FROM public.comunidad c
          WHERE c.id = comunidad_id
            AND c.estado = true
            AND c.tipo = 'publico'::public.tipo_comunidad
        )
        AND rol = 'miembro'::public.rol_miembro
        AND estado = 'aprobado'::public.estado_membresia
      )
      -- Pedir ingreso a privada → pendiente
      OR (
        EXISTS (
          SELECT 1
          FROM public.comunidad c
          WHERE c.id = comunidad_id
            AND c.estado = true
            AND c.tipo = 'privado'::public.tipo_comunidad
        )
        AND rol = 'miembro'::public.rol_miembro
        AND estado = 'pendiente'::public.estado_membresia
      )
    )
  );

DROP POLICY IF EXISTS comunidad_miembro_update_admin_o_propio ON public.comunidad_miembro;
CREATE POLICY comunidad_miembro_update_admin_o_propio ON public.comunidad_miembro
  FOR UPDATE TO authenticated
  USING (
    public.es_admin_comunidad(comunidad_id)
    OR usuario_id = auth.uid()
  )
  WITH CHECK (
    public.es_admin_comunidad(comunidad_id)
    OR usuario_id = auth.uid()
  );

DROP POLICY IF EXISTS comunidad_miembro_delete_propio_o_admin ON public.comunidad_miembro;
CREATE POLICY comunidad_miembro_delete_propio_o_admin ON public.comunidad_miembro
  FOR DELETE TO authenticated
  USING (
    usuario_id = auth.uid()
    OR public.es_admin_comunidad(comunidad_id)
  );

-- ---------------------------------------------------------------------------
-- public.comunidad_mensaje
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS comunidad_mensaje_select_miembro ON public.comunidad_mensaje;
CREATE POLICY comunidad_mensaje_select_miembro ON public.comunidad_mensaje
  FOR SELECT TO authenticated
  USING (public.es_miembro_comunidad_aprobado(comunidad_id));

DROP POLICY IF EXISTS comunidad_mensaje_insert_miembro ON public.comunidad_mensaje;
CREATE POLICY comunidad_mensaje_insert_miembro ON public.comunidad_mensaje
  FOR INSERT TO authenticated
  WITH CHECK (
    usuario_id = auth.uid()
    AND public.es_miembro_comunidad_aprobado(comunidad_id)
  );

-- Sin update/delete de mensajes en MVP (historial append-only).

-- ---------------------------------------------------------------------------
-- public.salida
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS salida_select_visibles ON public.salida;
CREATE POLICY salida_select_visibles ON public.salida
  FOR SELECT TO anon, authenticated
  USING (
    estado IN (
      'programada'::public.estado_salida,
      'en_curso'::public.estado_salida,
      'finalizada'::public.estado_salida
    )
    AND (
      tipo = 'publica'::public.tipo_salida
      OR (auth.uid() IS NOT NULL AND organizador_id = auth.uid())
      OR (
        comunidad_id IS NOT NULL
        AND auth.uid() IS NOT NULL
        AND public.es_miembro_comunidad_aprobado(comunidad_id)
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
        AND public.es_miembro_comunidad_aprobado(comunidad_id)
      )
    )
  );

DROP POLICY IF EXISTS salida_update_organizador ON public.salida;
CREATE POLICY salida_update_organizador ON public.salida
  FOR UPDATE TO authenticated
  USING (organizador_id = auth.uid())
  WITH CHECK (organizador_id = auth.uid());

-- ---------------------------------------------------------------------------
-- public.salida_participante
-- ---------------------------------------------------------------------------

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
          'en_curso'::public.estado_salida
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

DROP POLICY IF EXISTS salida_participante_insert_propio ON public.salida_participante;
CREATE POLICY salida_participante_insert_propio ON public.salida_participante
  FOR INSERT TO authenticated
  WITH CHECK (
    usuario_id = auth.uid()
    AND estado = 'confirmado'::public.estado_participante
    AND EXISTS (
      SELECT 1
      FROM public.salida s
      WHERE s.id = salida_id
        AND s.estado = 'programada'::public.estado_salida
        AND (
          s.tipo = 'publica'::public.tipo_salida
          OR s.organizador_id = auth.uid()
          OR (
            s.comunidad_id IS NOT NULL
            AND public.es_miembro_comunidad_aprobado(s.comunidad_id)
          )
        )
    )
  );

DROP POLICY IF EXISTS salida_participante_update_propio ON public.salida_participante;
CREATE POLICY salida_participante_update_propio ON public.salida_participante
  FOR UPDATE TO authenticated
  USING (usuario_id = auth.uid())
  WITH CHECK (usuario_id = auth.uid());

COMMENT ON FUNCTION public.es_miembro_comunidad_aprobado(bigint) IS
  'Helper RLS Comunidad: true si auth.uid() es miembro aprobado. SECURITY DEFINER para evitar recursión.';
COMMENT ON FUNCTION public.es_admin_comunidad(bigint) IS
  'Helper RLS Comunidad: true si auth.uid() es admin aprobado o creador.';
