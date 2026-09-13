-- Pureza relacional: lugar solo ancla a distrito (obligatorio).
-- provincia se obtiene por distrito → provincia. Sin provincia_id en lugar.
-- Sin distritos comodín: filas sin distrito se eliminan.

-- 1) Quitar trigger de coherencia provincia/distrito en lugar
DROP TRIGGER IF EXISTS trg_lugar_distrito_misma_provincia ON public.lugar;
DROP FUNCTION IF EXISTS public.fn_lugar_distrito_misma_provincia();

-- 2) Lugares sin distrito no caben en el modelo estricto
DELETE FROM public.lugar
WHERE distrito_id IS NULL;

-- 3) distrito obligatorio
ALTER TABLE public.lugar
  ALTER COLUMN distrito_id SET NOT NULL;

-- 4) Quitar provincia_id del lugar
ALTER TABLE public.lugar
  DROP CONSTRAINT IF EXISTS lugar_provincia_id_fkey;

DROP INDEX IF EXISTS public.idx_lugar_provincia_id;

ALTER TABLE public.lugar
  DROP COLUMN IF EXISTS provincia_id;

COMMENT ON COLUMN public.lugar.distrito_id IS
  'Obligatorio. La provincia se deriva: distrito → provincia → departamento.';

-- 5) RPC cercanía: provincia vía distrito (ya no columna en lugar)
CREATE OR REPLACE FUNCTION public.lugares_cerca(
  p_lat double precision,
  p_lon double precision,
  p_radio_m double precision DEFAULT 50000
)
RETURNS TABLE (
  id bigint,
  nombre character varying,
  latitud numeric,
  longitud numeric,
  distancia_m double precision,
  foto_portada text,
  provincia_id integer,
  distrito_id integer
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path TO public, extensions
AS $$
  SELECT
    l.id,
    l.nombre,
    l.latitud,
    l.longitud,
    ST_Distance(
      l.ubicacion,
      ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography
    ) AS distancia_m,
    l.foto_portada,
    d.provincia_id,
    l.distrito_id
  FROM public.lugar l
  INNER JOIN public.distrito d ON d.id = l.distrito_id
  WHERE l.estado = true
    AND l.ubicacion IS NOT NULL
    AND ST_DWithin(
      l.ubicacion,
      ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography,
      p_radio_m
    )
  ORDER BY 5 ASC
  LIMIT 200;
$$;
