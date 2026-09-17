-- Segundo `db pull` tras devolver el nombre remoto a
-- `publicacion_multimedia`. El SQL generado proponía DROP/CREATE y podía borrar
-- adjuntos. Una corrección de nombre debe conservar físicamente las filas.
DO $$
BEGIN
  IF to_regclass('public.publicacion_multimedia') IS NULL
     AND to_regclass('public.multimedia') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.multimedia RENAME TO publicacion_multimedia';
  ELSIF to_regclass('public.publicacion_multimedia') IS NULL THEN
    RAISE EXCEPTION
      'No existe public.publicacion_multimedia ni public.multimedia';
  ELSIF to_regclass('public.multimedia') IS NOT NULL THEN
    RAISE EXCEPTION
      'Existen ambas tablas multimedia; se requiere conciliación manual para no perder datos';
  END IF;
END;
$$;

COMMENT ON TABLE public.publicacion_multimedia IS
  'Adjuntos de publicaciones: imágenes en Storage y videos en Bunny Stream.';

