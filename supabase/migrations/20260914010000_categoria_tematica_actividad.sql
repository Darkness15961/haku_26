-- Alinea facetas de categoría de lugar (tematica | actividad).
-- El catálogo (Naturaleza, Trekking, …) ya está cargado a mano en BD:
-- esta migración NO inserta filas nuevas.

COMMENT ON COLUMN public.categoria.tipo IS
  'Faceta de categoría de lugar: tematica | actividad. '
  'Legacy: lugar / Interés (se normaliza abajo).';

-- Semillas viejas tipo=lugar → faceta según nombre.
UPDATE public.categoria
SET tipo = 'tematica'
WHERE tipo = 'lugar'
  AND lower(nombre) IN ('naturaleza', 'cultura', 'misterioso', 'magico');

UPDATE public.categoria
SET tipo = 'actividad'
WHERE tipo = 'lugar'
  AND lower(nombre) IN (
    'gastronomia', 'aventura', 'caminata', 'fotografia'
  );

-- Normaliza etiquetas manuales / alias a valores canónicos ASCII.
UPDATE public.categoria
SET tipo = 'tematica'
WHERE lower(tipo) IN ('interés', 'interes', 'temática', 'tematica')
   OR lower(tipo) LIKE 'temat%';

UPDATE public.categoria
SET tipo = 'actividad'
WHERE lower(tipo) IN ('actividad')
   OR lower(tipo) LIKE 'activ%';
