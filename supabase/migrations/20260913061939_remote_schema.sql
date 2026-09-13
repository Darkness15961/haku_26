SET local check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.create_bunny_video (
  p_title text
)
  RETURNS bigint
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
DECLARE
    v_library_id text;
    v_api_key text;
    v_request_id bigint;
BEGIN

    -- Obtener Bunny Library ID
    SELECT decrypted_secret
    INTO v_library_id
    FROM vault.decrypted_secrets
    WHERE name = 'bunny_library_id'
    LIMIT 1;

    -- Obtener Bunny API Key
    SELECT decrypted_secret
    INTO v_api_key
    FROM vault.decrypted_secrets
    WHERE name = 'bunny_library_api_key'
    LIMIT 1;

    -- Verificar que existan ambos secretos
    IF v_library_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró el secreto bunny_library_id';
    END IF;

    IF v_api_key IS NULL THEN
        RAISE EXCEPTION 'No se encontró el secreto bunny_library_api_key';
    END IF;

    -- Crear video en Bunny mediante pg_net
    SELECT net.http_post(
        url := 'https://video.bunnycdn.com/library/' ||
               v_library_id ||
               '/videos',

        headers := jsonb_build_object(
            'AccessKey', v_api_key,
            'Content-Type', 'application/json'
        ),

        body := jsonb_build_object(
            'title', p_title
        )
    )
    INTO v_request_id;

    RETURN v_request_id;

END;
$function$;

CREATE OR REPLACE FUNCTION public.fn_actualizar_updated_at()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.fn_sync_ubicacion()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $function$
BEGIN
  -- Revisa si las columnas específicas de la tabla actual se actualizaron
  IF TG_TABLE_NAME = 'salida' THEN
    IF NEW.punto_encuentro_lat IS NOT NULL AND NEW.punto_encuentro_lon IS NOT NULL THEN
      NEW.punto_encuentro_ubicacion = ST_SetSRID(ST_MakePoint(NEW.punto_encuentro_lon, NEW.punto_encuentro_lat), 4326)::geography;
    END IF;
  ELSE
    IF NEW.latitud IS NOT NULL AND NEW.longitud IS NOT NULL THEN
      NEW.ubicacion = ST_SetSRID(ST_MakePoint(NEW.longitud, NEW.latitud), 4326)::geography;
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_bunny_video_result (
  p_request_id bigint
)
  RETURNS TABLE (
    request_id  bigint,
    status_code integer,
    video_id    text,
    title       text,
    error_msg   text
  )
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
BEGIN

    RETURN QUERY
    SELECT
        r.id AS request_id,
        r.status_code,

        CASE
            WHEN r.status_code BETWEEN 200 AND 299
                 AND r.content IS NOT NULL
            THEN (r.content::jsonb ->> 'guid')
            ELSE NULL
        END AS video_id,

        CASE
            WHEN r.status_code BETWEEN 200 AND 299
                 AND r.content IS NOT NULL
            THEN (r.content::jsonb ->> 'title')
            ELSE NULL
        END AS title,

        r.error_msg

    FROM net._http_response r
    WHERE r.id = p_request_id;

END;
$function$;

COMMENT ON COLUMN "public"."lugar"."acceso" IS 'Cómo se llega / cómo llegó el explorador (caminando, auto, etc.). No es dificultad de ruta.';

