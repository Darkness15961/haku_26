-- Bloque C Explora: RPC PostGIS de cercanía.
-- Geocoding (pin → distrito) queda fuera; ver docs/fase-explora.md.

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
    l.provincia_id,
    l.distrito_id
  FROM public.lugar l
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

COMMENT ON FUNCTION public.lugares_cerca(double precision, double precision, double precision) IS
  'Lugares activos dentro de radio_m (metros) del punto (lat, lon). PostGIS geography.';

GRANT EXECUTE ON FUNCTION public.lugares_cerca(double precision, double precision, double precision)
  TO anon, authenticated, service_role;
