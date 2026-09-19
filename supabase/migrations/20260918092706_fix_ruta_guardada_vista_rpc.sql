-- Fix 1: Permitir que PostgREST recupere la propiedad guardada directamente desde la vista
CREATE OR REPLACE FUNCTION public.ruta_guardada_por_mi(ruta public.rutas_publicadas_lista)
RETURNS boolean LANGUAGE sql STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.ruta_guardada
    WHERE ruta_id = ruta.id AND usuario_id = auth.uid()
  );
$$;

-- Fix 2: Inyectar la propiedad en el JSON generado por el RPC de detalle
CREATE OR REPLACE FUNCTION public.ruta_publicada_detalle(p_ruta_id bigint)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path TO public
AS $$
  SELECT to_jsonb(v)
    || jsonb_build_object(
      'ruta_guardada_por_mi', public.ruta_guardada_por_mi(r),
      'trazado_geojson',
        CASE
          WHEN r.trazado IS NULL THEN NULL
          ELSE ST_AsGeoJSON(r.trazado::geometry)::jsonb
        END,
      'paradas',
        COALESCE(
          (
            SELECT jsonb_agg(
              jsonb_build_object(
                'id', rp.id,
                'nombre', rp.nombre,
                'tipo', rp.tipo,
                'latitud', rp.latitud,
                'longitud', rp.longitud,
                'altitud_m', rp.altitud_m,
                'orden', rp.orden,
                'instrucciones', rp.instrucciones,
                'distancia_acumulada_m', rp.distancia_acumulada_m,
                'tiempo_acumulado_minutos', rp.tiempo_acumulado_minutos,
                'lugar_id', rp.lugar_id
              )
              ORDER BY rp.orden
            )
            FROM public.ruta_parada rp
            WHERE rp.ruta_id = r.id
          ),
          '[]'::jsonb
        )
    )
  FROM public.ruta r
  JOIN public.rutas_publicadas_lista v ON v.id = r.id
  WHERE r.id = p_ruta_id
    AND r.estado = true
    AND r.estado_editorial = 'publicado';
$$;
