-- Corrección del RPC listar_comunidades_resumen para incluir la columna inscripcion_abierta
-- que fue agregada a la tabla comunidad pero olvidada en el tipo de retorno de esta función.

DROP FUNCTION IF EXISTS public.listar_comunidades_resumen();

CREATE OR REPLACE FUNCTION public.listar_comunidades_resumen()
RETURNS TABLE (
  id bigint,
  nombre text,
  descripcion text,
  foto_portada text,
  usuario_creador_id uuid,
  estado boolean,
  tipo text,
  fecha_creacion timestamptz,
  inscripcion_abierta boolean,
  miembros_count integer,
  mi_rol text,
  mi_estado text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT
    c.id,
    c.nombre::text,
    c.descripcion,
    c.foto_portada,
    c.usuario_creador_id,
    c.estado,
    c.tipo::text,
    c.fecha_creacion,
    c.inscripcion_abierta,
    (
      SELECT count(*)::integer
      FROM public.comunidad_miembro todos
      WHERE todos.comunidad_id = c.id
        AND todos.estado::text = 'aprobado'
    ),
    cm.rol::text,
    cm.estado::text
  FROM public.comunidad c
  LEFT JOIN public.comunidad_miembro cm
    ON cm.comunidad_id = c.id AND cm.usuario_id = auth.uid()
  WHERE c.estado = true
    AND (
      c.tipo::text = 'publico'
      OR c.usuario_creador_id = auth.uid()
      OR cm.estado::text = 'aprobado'
    )
  ORDER BY c.nombre;
$$;

REVOKE ALL ON FUNCTION public.listar_comunidades_resumen() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_comunidades_resumen()
  TO anon, authenticated, service_role;
