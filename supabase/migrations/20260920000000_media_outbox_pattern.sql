-- =================================================================================
-- PATRÓN OUTBOX PARA LIMPIEZA DE MEDIOS (S3 y BunnyStream)
-- =================================================================================

-- 1. Crear la tabla de la cola (Outbox)
CREATE TABLE IF NOT EXISTS public.cola_limpieza_media (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    url_archivo text NOT NULL,
    proveedor character varying NOT NULL, -- 's3' o 'bunny'
    intentos integer NOT NULL DEFAULT 0,
    fecha_creacion timestamp with time zone NOT NULL DEFAULT now()
);

-- Asegurar la tabla con RLS (nadie desde el cliente debe poder leer/escribir aquí)
ALTER TABLE public.cola_limpieza_media ENABLE ROW LEVEL SECURITY;

-- =================================================================================
-- BLOQUE 2: TRIGGER ACTUALIZAR/REEMPLAZAR (Actúa sobre publicacion_multimedia)
-- =================================================================================

-- Función que atrapa la fila eliminada y la mete a la cola
CREATE OR REPLACE FUNCTION public.fn_encolar_media_eliminada()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_proveedor varchar;
    v_url text;
BEGIN
    -- Determinar el proveedor y el identificador del archivo
    IF OLD.tipo = 'video' THEN
        -- Para videos de BunnyStream necesitamos su ID interno
        v_proveedor := 'bunny';
        v_url := COALESCE(OLD.proveedor_video_id, OLD.url_archivo);
    ELSE
        -- Para imágenes, es una URL de Supabase Storage (S3)
        v_proveedor := 's3';
        v_url := OLD.url_archivo;
    END IF;

    -- Solo encolar si realmente hay algo que borrar
    IF v_url IS NOT NULL AND v_url <> '' THEN
        INSERT INTO public.cola_limpieza_media (url_archivo, proveedor)
        VALUES (v_url, v_proveedor);
    END IF;

    RETURN OLD;
END;
$$;

-- Disparador que ejecuta la función cada vez que se borra un archivo multimedia
DROP TRIGGER IF EXISTS trg_publicacion_multimedia_outbox ON public.publicacion_multimedia;
CREATE TRIGGER trg_publicacion_multimedia_outbox
AFTER DELETE ON public.publicacion_multimedia
FOR EACH ROW
EXECUTE FUNCTION public.fn_encolar_media_eliminada();


-- =================================================================================
-- BLOQUE 1: TRIGGER ELIMINAR (Actúa sobre publicacion)
-- =================================================================================

-- Función que detecta el Soft-Delete y borra la multimedia asociada
CREATE OR REPLACE FUNCTION public.fn_publicacion_soft_delete_media()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Si la publicación acaba de cambiar su estado a 'eliminado'
    IF NEW.estado = 'eliminado' AND OLD.estado <> 'eliminado' THEN
        -- Borrar físicamente sus registros en publicacion_multimedia.
        -- ¡Magia! Este DELETE disparará automáticamente el trg_publicacion_multimedia_outbox 
        -- enviando todos los archivos de esta publicación a la cola.
        DELETE FROM public.publicacion_multimedia WHERE publicacion_id = NEW.id;
    END IF;

    RETURN NEW;
END;
$$;

-- Disparador que escucha los updates en la tabla publicación
DROP TRIGGER IF EXISTS trg_publicacion_soft_delete_media ON public.publicacion;
CREATE TRIGGER trg_publicacion_soft_delete_media
AFTER UPDATE OF estado ON public.publicacion
FOR EACH ROW
EXECUTE FUNCTION public.fn_publicacion_soft_delete_media();
