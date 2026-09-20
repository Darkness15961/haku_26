-- 1. Añadir columna cantidad_paradas a la tabla ruta
ALTER TABLE public.ruta ADD COLUMN IF NOT EXISTS cantidad_paradas integer NOT NULL DEFAULT 0;

-- 2. Poblar los contadores existentes para que no empiecen en cero si ya hay paradas
UPDATE public.ruta r
SET cantidad_paradas = (
  SELECT count(*)
  FROM public.ruta_parada rp
  WHERE rp.ruta_id = r.id
);

-- 3. Crear función de trigger para mantener el contador actualizado
CREATE OR REPLACE FUNCTION public.trg_actualizar_cantidad_paradas()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.ruta SET cantidad_paradas = cantidad_paradas + 1 WHERE id = NEW.ruta_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.ruta SET cantidad_paradas = cantidad_paradas - 1 WHERE id = OLD.ruta_id;
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.ruta_id <> NEW.ruta_id THEN
      UPDATE public.ruta SET cantidad_paradas = cantidad_paradas - 1 WHERE id = OLD.ruta_id;
      UPDATE public.ruta SET cantidad_paradas = cantidad_paradas + 1 WHERE id = NEW.ruta_id;
    END IF;
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Asignar el trigger a la tabla ruta_parada
DROP TRIGGER IF EXISTS trg_ruta_parada_cantidad ON public.ruta_parada;
CREATE TRIGGER trg_ruta_parada_cantidad
AFTER INSERT OR UPDATE OR DELETE ON public.ruta_parada
FOR EACH ROW
EXECUTE FUNCTION public.trg_actualizar_cantidad_paradas();

-- 5. Destruir funciones dependientes y vista original
DROP FUNCTION IF EXISTS public.ruta_guardada_por_mi(public.rutas_publicadas_lista);
DROP VIEW IF EXISTS public.rutas_publicadas_lista;

-- 6. Recrear vista sin los JOINs ni GROUP BY pesados, usando la nueva columna
CREATE VIEW public.rutas_publicadas_lista WITH (security_invoker = true) AS
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
  r.cantidad_paradas
FROM public.ruta r
WHERE r.estado = true AND r.estado_editorial = 'publicado';

-- 7. Recrear la función dependiente
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

-- 8. Otorgar permisos
GRANT EXECUTE ON FUNCTION "public"."ruta_guardada_por_mi"(public.rutas_publicadas_lista) TO PUBLIC, "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."rutas_publicadas_lista" TO "anon", "authenticated", "postgres", "service_role";
