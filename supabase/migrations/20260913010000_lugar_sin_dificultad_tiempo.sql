-- Lugar no es ruta: quitar ficha de experiencia mal colocada.
-- NO tocar public.ruta (dificultad allí se mantiene).

ALTER TABLE public.lugar
  DROP COLUMN IF EXISTS dificultad;

ALTER TABLE public.lugar
  DROP COLUMN IF EXISTS tiempo_estimado;

COMMENT ON COLUMN public.lugar.acceso IS
  'Cómo se llega / cómo llegó el explorador (caminando, auto, etc.)';
