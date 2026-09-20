SET local check_function_bodies = off;

DROP FUNCTION "public"."ruta_guardada_por_mi"(public.rutas_publicadas_lista);

DROP VIEW "public"."rutas_publicadas_lista";

CREATE VIEW "public"."rutas_publicadas_lista" WITH (security_invoker=true) AS  SELECT r.id,
    r.slug,
    r.nombre,
    r.resumen,
    r.descripcion,
    r.foto_portada,
    r.tipo,
    r.hilo_cultural,
    r.zona,
    (r.dificultad)::text AS dificultad,
    r.distancia_m,
    r.duracion_minutos,
    r.dias,
    r.altitud_min_m,
    r.altitud_max_m,
    r.desnivel_positivo_m,
    r.meses_recomendados,
    r.acceso,
    r.transporte,
    r.requisitos,
    r.advertencias,
    r.etiquetas,
    r.version,
    r.publicada_en,
    (count(rp.id))::integer AS cantidad_paradas
   FROM (public.ruta r
     LEFT JOIN public.ruta_parada rp ON ((rp.ruta_id = r.id)))
  WHERE ((r.estado = true) AND (r.estado_editorial = 'publicado'::text))
  GROUP BY r.id;

CREATE OR REPLACE FUNCTION public.ruta_guardada_por_mi (
  ruta public.rutas_publicadas_lista
)
  RETURNS boolean
  LANGUAGE sql
  STABLE
  AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.ruta_guardada
    WHERE ruta_id = ruta.id AND usuario_id = auth.uid()
  );
$function$;

GRANT EXECUTE ON FUNCTION "public"."ruta_guardada_por_mi"(public.rutas_publicadas_lista) TO PUBLIC, "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."rutas_publicadas_lista" TO "anon", "authenticated", "postgres", "service_role";

