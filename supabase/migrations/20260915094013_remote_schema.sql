SET local check_function_bodies = off;

ALTER PUBLICATION "supabase_realtime" DROP TABLE "public"."comunidad_mensaje";

ALTER TABLE "public"."comunidad_mensaje"
  DROP CONSTRAINT "comunidad_mensaje_comunidad_id_fkey";

ALTER TABLE "public"."comunidad_mensaje"
  DROP CONSTRAINT "comunidad_mensaje_usuario_id_fkey";

DROP TABLE "public"."comunidad_mensaje";

CREATE TABLE "public"."mensaje" (
  "id"          bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "sala_id"     bigint                   NOT NULL,
  "usuario_id"  uuid                     NOT NULL,
  "contenido"   text                     NOT NULL,
  "fecha_envio" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "mensaje_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."mensaje"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."sala_chat" (
  "id"             bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "comunidad_id"   bigint,
  "salida_id"      bigint,
  "fecha_creacion" timestamp with time zone NOT NULL DEFAULT now(),
  "estado"         boolean                  NOT NULL DEFAULT true,
  CONSTRAINT "sala_chat_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."sala_chat"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."sala_participante" (
  "sala_id"        bigint                   NOT NULL,
  "usuario_id"     uuid                     NOT NULL,
  "fecha_ingreso"  timestamp with time zone NOT NULL DEFAULT now(),
  "ultima_lectura" timestamp with time zone,
  CONSTRAINT "sala_participante_pkey" PRIMARY KEY (sala_id, usuario_id)
);

ALTER TABLE "public"."sala_participante"
  ENABLE ROW LEVEL SECURITY;

CREATE TYPE "public"."tipo_mensaje_chat" AS ENUM (
  'texto',
  'imagen',
  'audio',
  'ubicacion'
);

ALTER TABLE "public"."mensaje"
  ADD COLUMN "tipo_mensaje" public.tipo_mensaje_chat NOT NULL DEFAULT 'texto'::public.tipo_mensaje_chat;

CREATE TYPE "public"."tipo_sala_chat" AS ENUM (
  'comunidad',
  'salida',
  'privado'
);

ALTER TABLE "public"."sala_chat"
  ADD COLUMN "tipo" public.tipo_sala_chat NOT NULL;

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

ALTER TABLE "public"."mensaje"
  ADD CONSTRAINT "mensaje_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE CASCADE;

ALTER TABLE "public"."sala_chat"
  ADD CONSTRAINT "chk_sala_tipo_coherente" CHECK ((((tipo = 'comunidad'::public.tipo_sala_chat) AND (comunidad_id IS
    NOT NULL) AND (salida_id IS NULL)) OR ((tipo = 'salida'::public.tipo_sala_chat) AND (salida_id IS
    NOT NULL) AND (comunidad_id IS NULL)) OR ((tipo = 'privado'::public.tipo_sala_chat) AND (comunidad_id IS NULL) AND (salida_id IS NULL))));

ALTER TABLE "public"."sala_chat"
  ADD CONSTRAINT "sala_chat_comunidad_id_fkey" FOREIGN KEY (comunidad_id) REFERENCES public.comunidad(id) ON DELETE CASCADE;

ALTER TABLE "public"."mensaje"
  ADD CONSTRAINT "mensaje_sala_id_fkey" FOREIGN KEY (sala_id) REFERENCES public.sala_chat(id) ON DELETE CASCADE;

ALTER TABLE "public"."sala_chat"
  ADD CONSTRAINT "sala_chat_salida_id_fkey" FOREIGN KEY (salida_id) REFERENCES public.salida(id) ON DELETE CASCADE;

ALTER TABLE "public"."sala_participante"
  ADD CONSTRAINT "sala_participante_sala_id_fkey" FOREIGN KEY (sala_id) REFERENCES public.sala_chat(id) ON DELETE CASCADE;

ALTER TABLE "public"."sala_participante"
  ADD CONSTRAINT "sala_participante_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE CASCADE;

CREATE INDEX idx_mensaje_sala_fecha ON public.mensaje USING btree (sala_id, fecha_envio DESC);

CREATE UNIQUE INDEX ux_sala_chat_comunidad ON public.sala_chat USING btree (comunidad_id)
  WHERE (tipo = 'comunidad'::public.tipo_sala_chat);

CREATE UNIQUE INDEX ux_sala_chat_salida ON public.sala_chat USING btree (salida_id)
  WHERE (tipo = 'salida'::public.tipo_sala_chat);

CREATE POLICY "mensaje_insert" ON "public"."mensaje"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (((usuario_id = auth.uid()) AND (sala_id IN ( SELECT sala_participante.sala_id
   FROM public.sala_participante
  WHERE (sala_participante.usuario_id = auth.uid())))));

CREATE POLICY "mensaje_select" ON "public"."mensaje"
  FOR SELECT
  TO "authenticated"
  USING ((sala_id IN ( SELECT sala_participante.sala_id
   FROM public.sala_participante
  WHERE (sala_participante.usuario_id = auth.uid()))));

CREATE POLICY "sala_chat_select" ON "public"."sala_chat"
  FOR SELECT
  TO "authenticated"
  USING ((id IN ( SELECT sala_participante.sala_id
   FROM public.sala_participante
  WHERE (sala_participante.usuario_id = auth.uid()))));

CREATE POLICY "sala_participante_select" ON "public"."sala_participante"
  FOR SELECT
  TO "authenticated"
  USING ((sala_id IN ( SELECT sala_participante_1.sala_id
   FROM public.sala_participante sala_participante_1
  WHERE (sala_participante_1.usuario_id = auth.uid()))));

ALTER PUBLICATION "supabase_realtime" ADD TABLE "public"."mensaje";

ALTER PUBLICATION "supabase_realtime" ADD TABLE "public"."sala_participante";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."mensaje" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."sala_chat" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."sala_participante" TO "anon", "authenticated", "postgres", "service_role";

GRANT USAGE ON TYPE "public"."tipo_mensaje_chat" TO "postgres";

GRANT USAGE ON TYPE "public"."tipo_sala_chat" TO "postgres";

