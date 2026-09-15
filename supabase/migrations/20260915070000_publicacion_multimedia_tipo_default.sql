-- DEFAULT para publicacion_multimedia.tipo (NOT NULL sin default rompía INSERT
-- desde el cliente si olvidaba la columna). El front ya envía 'imagen'.

ALTER TABLE public.publicacion_multimedia
  ALTER COLUMN tipo SET DEFAULT 'imagen'::public.tipo_multimedia;

COMMENT ON COLUMN public.publicacion_multimedia.tipo IS
  'imagen|video. Default imagen para altas de feed sin Bunny.';
