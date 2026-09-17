-- Esta migración fue generada por `supabase db pull` mientras la tabla había
-- sido renombrada temporalmente a `multimedia`. La versión generada hacía
-- DROP/CREATE y podía perder todos los adjuntos existentes.
--
-- El nombre canónico del dominio es `publicacion_multimedia`. Si una
-- instalación alcanzó a conservar el nombre temporal, se normaliza mediante
-- RENAME, que preserva filas, identidad, índices, FK, grants y políticas.
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

