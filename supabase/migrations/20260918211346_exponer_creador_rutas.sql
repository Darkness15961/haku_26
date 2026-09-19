-- Añadir usuario_creador_id al final para permitir CREATE OR REPLACE VIEW
CREATE OR REPLACE VIEW public.rutas_publicadas_lista
WITH (security_invoker = true)
AS
SELECT
  r.id,
  r.slug,
  r.nombre,
  r.resumen,
  r.descripcion,
  r.foto_portada,
  r.tipo,
  r.hilo_cultural,
  r.zona,
  r.dificultad::text AS dificultad,
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
  count(rp.id)::integer AS cantidad_paradas,
  r.usuario_creador_id
FROM public.ruta r
LEFT JOIN public.ruta_parada rp ON rp.ruta_id = r.id
WHERE r.estado = true
  AND r.estado_editorial = 'publicado'
GROUP BY r.id;
