-- Etapa 3: Optimización de Consumo de Red Flutter
-- RPC para obtener el último mensaje de cada comunidad en un solo request (eliminando N+1)

CREATE OR REPLACE FUNCTION public.obtener_ultimos_mensajes_comunidades(
  p_comunidad_ids bigint[]
)
RETURNS TABLE (
  comunidad_id bigint,
  id bigint,
  sala_id bigint,
  usuario_id uuid,
  contenido text,
  tipo_mensaje text,
  fecha_envio timestamptz,
  usuario jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
BEGIN
  -- 1. Verificar sesión activa
  IF auth.uid() IS NULL THEN
    RETURN;
  END IF;

  -- 2. Ejecutar consulta optimizada usando DISTINCT ON
  RETURN QUERY
  WITH salas_comunidad AS (
    SELECT sc.id AS sala_id, sc.comunidad_id 
    FROM public.sala_chat sc
    WHERE sc.tipo = 'comunidad'::public.tipo_sala_chat 
      AND sc.comunidad_id = ANY(p_comunidad_ids)
  ),
  ultimos_mensajes AS (
    SELECT DISTINCT ON (m.sala_id)
      sc.comunidad_id,
      m.id,
      m.sala_id,
      m.usuario_id,
      m.contenido,
      m.tipo_mensaje,
      m.fecha_envio
    FROM public.mensaje m
    JOIN salas_comunidad sc ON m.sala_id = sc.sala_id
    WHERE m.eliminado_en IS NULL
    ORDER BY m.sala_id, m.fecha_envio DESC, m.id DESC
  )
  SELECT 
    um.comunidad_id,
    um.id,
    um.sala_id,
    um.usuario_id,
    um.contenido,
    um.tipo_mensaje::text,
    um.fecha_envio,
    jsonb_build_object(
      'id', u.id,
      'nombre_nick', u.nombre_nick
    ) AS usuario
  FROM ultimos_mensajes um
  LEFT JOIN public.usuario u ON u.id = um.usuario_id;
END;
$$;

-- Otorgar permisos
REVOKE ALL ON FUNCTION public.obtener_ultimos_mensajes_comunidades(bigint[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.obtener_ultimos_mensajes_comunidades(bigint[]) TO authenticated;
