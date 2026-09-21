-- 1. Agregar columna de inscripción abierta a la tabla salida
ALTER TABLE public.salida 
ADD COLUMN IF NOT EXISTS inscripcion_abierta BOOLEAN DEFAULT true;

-- 2. Función y Trigger para bloquear nuevos registros si la salida está cerrada
CREATE OR REPLACE FUNCTION public.func_salida_participante_check_abierta()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_abierta boolean;
BEGIN
  -- Consultar el estado de la salida
  SELECT inscripcion_abierta INTO v_abierta
  FROM public.salida
  WHERE id = NEW.salida_id;

  -- Si está cerrada, lanzar excepción para bloquear el INSERT
  IF v_abierta = false THEN
    RAISE EXCEPTION 'La salida tiene las inscripciones cerradas' USING ERRCODE = '23503';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_salida_participante_check_abierta ON public.salida_participante;
CREATE TRIGGER trg_salida_participante_check_abierta
  BEFORE INSERT ON public.salida_participante
  FOR EACH ROW
  EXECUTE FUNCTION public.func_salida_participante_check_abierta();

-- 3. Actualizar listar_salidas_resumen para devolver inscripcion_abierta
DROP FUNCTION IF EXISTS public.listar_salidas_resumen();
DROP FUNCTION IF EXISTS public.listar_salidas_resumen(bigint, bigint, bigint);

CREATE OR REPLACE FUNCTION public.listar_salidas_resumen(
  p_lugar_id bigint DEFAULT NULL,
  p_ruta_id bigint DEFAULT NULL,
  p_comunidad_id bigint DEFAULT NULL
)
RETURNS TABLE (
  id bigint,
  titulo text,
  organizador_id uuid,
  organizador_nick text,
  comunidad_id bigint,
  comunidad_nombre text,
  ruta_id bigint,
  ruta_nombre text,
  ruta_resumen text,
  fecha_hora_inicio timestamptz,
  punto_encuentro_lat numeric,
  punto_encuentro_lon numeric,
  punto_encuentro_lugar_id bigint,
  lugar_nombre text,
  lugar_foto_portada text,
  tipo text,
  cupos_totales integer,
  minimo_para_salir integer,
  estado text,
  inscripcion_abierta boolean,
  inscritos_count integer,
  mi_estado_participante text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT
    s.id,
    s.titulo::text,
    s.organizador_id,
    u.nombre_nick::text,
    s.comunidad_id,
    c.nombre::text,
    s.ruta_id,
    r.nombre::text,
    r.resumen::text,
    s.fecha_hora_inicio,
    s.punto_encuentro_lat,
    s.punto_encuentro_lon,
    s.punto_encuentro_lugar_id,
    l.nombre::text,
    l.foto_portada,
    s.tipo::text,
    s.cupos_totales,
    s.minimo_para_salir,
    s.estado::text,
    s.inscripcion_abierta,
    (
      SELECT count(*)::integer
      FROM public.salida_participante
      WHERE salida_id = s.id AND estado::text = 'confirmado'
    ),
    (
      SELECT estado::text
      FROM public.salida_participante
      WHERE salida_id = s.id AND usuario_id = auth.uid()
    )
  FROM public.salida s
  LEFT JOIN public.usuario u ON u.id = s.organizador_id
  LEFT JOIN public.comunidad c ON c.id = s.comunidad_id
  LEFT JOIN public.ruta r ON r.id = s.ruta_id
  LEFT JOIN public.lugar l ON l.id = s.punto_encuentro_lugar_id
  WHERE s.estado::text != 'cancelada'
    AND (p_lugar_id IS NULL OR s.punto_encuentro_lugar_id = p_lugar_id)
    AND (p_ruta_id IS NULL OR s.ruta_id = p_ruta_id)
    AND (p_comunidad_id IS NULL OR s.comunidad_id = p_comunidad_id)
    AND s.fecha_hora_inicio >= (now() - interval '2 days')
  ORDER BY s.fecha_hora_inicio ASC;
$$;
