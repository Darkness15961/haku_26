-- Chat: tipo sticker (ubicación ya existe en enum).
-- Append-only. No rompe texto/imagen/ubicacion/audio.

ALTER TYPE public.tipo_mensaje_chat ADD VALUE IF NOT EXISTS 'sticker';

COMMENT ON TYPE public.tipo_mensaje_chat IS
  'texto | imagen | audio | ubicacion | sticker. Audio/video UI fuera de alcance.';
