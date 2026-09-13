SET local check_function_bodies = off;

CREATE EXTENSION "postgis" SCHEMA "public";

CREATE TABLE "public"."categoria" (
  "id"     integer           GENERATED ALWAYS AS IDENTITY NOT NULL,
  "nombre" character varying NOT NULL,
  "tipo"   character varying NOT NULL,
  CONSTRAINT "categoria_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."categoria"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."comunidad_mensaje" (
  "id"           bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "comunidad_id" bigint                   NOT NULL,
  "usuario_id"   uuid                     NOT NULL,
  "mensaje"      text                     NOT NULL,
  "fecha_envio"  timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "comunidad_mensaje_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."comunidad_mensaje"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."comunidad_miembro" (
  "comunidad_id" bigint                   NOT NULL,
  "usuario_id"   uuid                     NOT NULL,
  "fecha_union"  timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "comunidad_miembro_pkey" PRIMARY KEY (comunidad_id, usuario_id)
);

ALTER TABLE "public"."comunidad_miembro"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."comunidad" (
  "id"                 bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "nombre"             character varying        NOT NULL,
  "descripcion"        text,
  "foto_portada"       text,
  "usuario_creador_id" uuid                     NOT NULL,
  "estado"             boolean                  NOT NULL DEFAULT true,
  "fecha_creacion"     timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"         timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "comunidad_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."comunidad"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."departamento" (
  "id"           integer           GENERATED ALWAYS AS IDENTITY NOT NULL,
  "nombre"       character varying NOT NULL,
  "descripcion"  character varying,
  "foto_portada" text,
  CONSTRAINT "departamento_nombre_key" UNIQUE (nombre),
  CONSTRAINT "departamento_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."departamento"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."distrito" (
  "id"           integer           GENERATED ALWAYS AS IDENTITY NOT NULL,
  "nombre"       character varying NOT NULL,
  "descripcion"  character varying,
  "foto_portada" text,
  "provincia_id" integer           NOT NULL,
  CONSTRAINT "distrito_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."distrito"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."lugar_categoria" (
  "lugar_id"     bigint  NOT NULL,
  "categoria_id" integer NOT NULL,
  CONSTRAINT "lugar_categoria_pkey" PRIMARY KEY (lugar_id, categoria_id)
);

ALTER TABLE "public"."lugar_categoria"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."lugar" (
  "id"             bigint                       GENERATED ALWAYS AS IDENTITY NOT NULL,
  "nombre"         character varying            NOT NULL,
  "descripcion"    text,
  "altitud"        integer,
  "latitud"        numeric(9,6),
  "longitud"       numeric(9,6),
  "ubicacion"      public.geography(Point,4326),
  "estado"         boolean                      NOT NULL DEFAULT true,
  "foto_portada"   text,
  "usuario_id"     uuid                         NOT NULL,
  "distrito_id"    integer                      NOT NULL,
  "fecha_creacion" timestamp with time zone     NOT NULL DEFAULT now(),
  "updated_at"     timestamp with time zone     NOT NULL DEFAULT now(),
  CONSTRAINT "lugar_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."lugar"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."provincia" (
  "id"              integer           GENERATED ALWAYS AS IDENTITY NOT NULL,
  "nombre"          character varying NOT NULL,
  "descripcion"     character varying,
  "foto_portada"    text,
  "departamento_id" integer           NOT NULL,
  CONSTRAINT "provincia_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."provincia"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."publicacion_etiqueta_comunidad" (
  "publicacion_id"   bigint                   NOT NULL,
  "comunidad_id"     bigint                   NOT NULL,
  "fecha_etiquetado" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "publicacion_etiqueta_comunidad_pkey" PRIMARY KEY (publicacion_id, comunidad_id)
);

ALTER TABLE "public"."publicacion_etiqueta_comunidad"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."publicacion_lugar" (
  "publicacion_id"   bigint                   NOT NULL,
  "lugar_id"         bigint                   NOT NULL,
  "fecha_etiquetado" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "publicacion_lugar_pkey" PRIMARY KEY (publicacion_id, lugar_id)
);

ALTER TABLE "public"."publicacion_lugar"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."publicacion_multimedia" (
  "id"                 bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "publicacion_id"     bigint                   NOT NULL,
  "url_archivo"        text                     NOT NULL,
  "orden"              integer                  NOT NULL DEFAULT 1,
  "proveedor_video_id" character varying,
  "miniatura_url"      text,
  "fecha_registro"     timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "publicacion_multimedia_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."publicacion_multimedia"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."publicacion_usuario_etiqueta" (
  "publicacion_id"        bigint                   NOT NULL,
  "usuario_etiquetado_id" uuid                     NOT NULL,
  "fecha_etiquetado"      timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "publicacion_usuario_etiqueta_pkey" PRIMARY KEY (publicacion_id, usuario_etiquetado_id)
);

ALTER TABLE "public"."publicacion_usuario_etiqueta"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."publicacion" (
  "id"             bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "usuario_id"     uuid                     NOT NULL,
  "contenido"      text                     NOT NULL,
  "fecha_creacion" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"     timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "publicacion_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."publicacion"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."ruta_parada" (
  "id"            bigint                       GENERATED ALWAYS AS IDENTITY NOT NULL,
  "ruta_id"       bigint                       NOT NULL,
  "lugar_id"      bigint,
  "latitud"       numeric(9,6)                 NOT NULL,
  "longitud"      numeric(9,6)                 NOT NULL,
  "ubicacion"     public.geography(Point,4326),
  "orden"         integer                      NOT NULL,
  "instrucciones" text,
  CONSTRAINT "ruta_parada_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."ruta_parada"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."ruta" (
  "id"                 bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "nombre"             character varying        NOT NULL,
  "descripcion"        text,
  "foto_portada"       text,
  "usuario_creador_id" uuid                     NOT NULL,
  "estado"             boolean                  NOT NULL DEFAULT true,
  "fecha_creacion"     timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"         timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "ruta_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."ruta"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."salida_participante" (
  "salida_id"         bigint                   NOT NULL,
  "usuario_id"        uuid                     NOT NULL,
  "fecha_inscripcion" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "salida_participante_pkey" PRIMARY KEY (salida_id, usuario_id)
);

ALTER TABLE "public"."salida_participante"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."salida" (
  "id"                        bigint                       GENERATED ALWAYS AS IDENTITY NOT NULL,
  "titulo"                    character varying            NOT NULL,
  "organizador_id"            uuid                         NOT NULL,
  "comunidad_id"              bigint,
  "ruta_id"                   bigint,
  "fecha_hora_inicio"         timestamp with time zone     NOT NULL,
  "punto_encuentro_lat"       numeric(9,6)                 NOT NULL,
  "punto_encuentro_lon"       numeric(9,6)                 NOT NULL,
  "punto_encuentro_ubicacion" public.geography(Point,4326),
  "punto_encuentro_lugar_id"  bigint,
  "notas_grupales"            text,
  "cupos_totales"             integer                      NOT NULL,
  "minimo_para_salir"         integer                      DEFAULT 1,
  "fecha_creacion"            timestamp with time zone     NOT NULL DEFAULT now(),
  "updated_at"                timestamp with time zone     NOT NULL DEFAULT now(),
  CONSTRAINT "salida_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."salida"
  ENABLE ROW LEVEL SECURITY;

CREATE TYPE "public"."dificultad_nivel" AS ENUM (
  'facil',
  'moderado',
  'exigente'
);

ALTER TABLE "public"."ruta"
  ADD COLUMN "dificultad" public.dificultad_nivel NOT NULL DEFAULT 'moderado'::public.dificultad_nivel;

CREATE TYPE "public"."estado_membresia" AS ENUM (
  'pendiente',
  'aprobado',
  'rechazado',
  'bloqueado'
);

ALTER TABLE "public"."comunidad_miembro"
  ADD COLUMN "estado" public.estado_membresia NOT NULL DEFAULT 'aprobado'::public.estado_membresia;

CREATE TYPE "public"."estado_participante" AS ENUM (
  'confirmado',
  'cancelado'
);

ALTER TABLE "public"."salida_participante"
  ADD COLUMN "estado" public.estado_participante NOT NULL DEFAULT 'confirmado'::public.estado_participante;

CREATE TYPE "public"."estado_publicacion" AS ENUM (
  'publico',
  'privado',
  'eliminado'
);

ALTER TABLE "public"."publicacion"
  ADD COLUMN "estado" public.estado_publicacion NOT NULL DEFAULT 'publico'::public.estado_publicacion;

CREATE TYPE "public"."estado_salida" AS ENUM (
  'programada',
  'en_curso',
  'finalizada',
  'cancelada'
);

ALTER TABLE "public"."salida"
  ADD COLUMN "estado" public.estado_salida NOT NULL DEFAULT 'programada'::public.estado_salida;

CREATE TYPE "public"."estado_video" AS ENUM (
  'pending',
  'processing',
  'ready',
  'error'
);

ALTER TABLE "public"."publicacion_multimedia"
  ADD COLUMN "video_estado" public.estado_video DEFAULT 'pending'::public.estado_video;

CREATE TYPE "public"."rol_miembro" AS ENUM (
  'admin',
  'moderador',
  'miembro'
);

ALTER TABLE "public"."comunidad_miembro"
  ADD COLUMN "rol" public.rol_miembro NOT NULL DEFAULT 'miembro'::public.rol_miembro;

CREATE TYPE "public"."tipo_comunidad" AS ENUM (
  'publico',
  'privado'
);

ALTER TABLE "public"."comunidad"
  ADD COLUMN "tipo" public.tipo_comunidad NOT NULL DEFAULT 'publico'::public.tipo_comunidad;

CREATE TYPE "public"."tipo_multimedia" AS ENUM (
  'imagen',
  'video'
);

ALTER TABLE "public"."publicacion_multimedia"
  ADD COLUMN "tipo" public.tipo_multimedia NOT NULL;

CREATE TYPE "public"."tipo_salida" AS ENUM (
  'publica',
  'comunidad'
);

ALTER TABLE "public"."salida"
  ADD COLUMN "tipo" public.tipo_salida NOT NULL DEFAULT 'publica'::public.tipo_salida;

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

ALTER TABLE "public"."comunidad"
  ADD CONSTRAINT "comunidad_usuario_creador_id_fkey" FOREIGN KEY (usuario_creador_id) REFERENCES public.usuario(id) ON DELETE RESTRICT;

ALTER TABLE "public"."comunidad_mensaje"
  ADD CONSTRAINT "comunidad_mensaje_comunidad_id_fkey" FOREIGN KEY (comunidad_id) REFERENCES public.comunidad(id) ON DELETE CASCADE;

ALTER TABLE "public"."comunidad_mensaje"
  ADD CONSTRAINT "comunidad_mensaje_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE CASCADE;

ALTER TABLE "public"."comunidad_miembro"
  ADD CONSTRAINT "comunidad_miembro_comunidad_id_fkey" FOREIGN KEY (comunidad_id) REFERENCES public.comunidad(id) ON DELETE CASCADE;

ALTER TABLE "public"."comunidad_miembro"
  ADD CONSTRAINT "comunidad_miembro_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE CASCADE;

ALTER TABLE "public"."lugar"
  ADD CONSTRAINT "lugar_distrito_id_fkey" FOREIGN KEY (distrito_id) REFERENCES public.distrito(id) ON DELETE RESTRICT;

ALTER TABLE "public"."lugar"
  ADD CONSTRAINT "lugar_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE RESTRICT;

ALTER TABLE "public"."lugar_categoria"
  ADD CONSTRAINT "lugar_categoria_categoria_id_fkey" FOREIGN KEY (categoria_id) REFERENCES public.categoria(id) ON DELETE RESTRICT;

ALTER TABLE "public"."lugar_categoria"
  ADD CONSTRAINT "lugar_categoria_lugar_id_fkey" FOREIGN KEY (lugar_id) REFERENCES public.lugar(id) ON DELETE CASCADE;

ALTER TABLE "public"."provincia"
  ADD CONSTRAINT "provincia_departamento_id_fkey" FOREIGN KEY (departamento_id) REFERENCES public.departamento(id) ON DELETE RESTRICT;

ALTER TABLE "public"."distrito"
  ADD CONSTRAINT "distrito_provincia_id_fkey" FOREIGN KEY (provincia_id) REFERENCES public.provincia(id) ON DELETE RESTRICT;

ALTER TABLE "public"."publicacion"
  ADD CONSTRAINT "publicacion_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE RESTRICT;

ALTER TABLE "public"."publicacion_etiqueta_comunidad"
  ADD CONSTRAINT "publicacion_etiqueta_comunidad_comunidad_id_fkey" FOREIGN KEY (comunidad_id) REFERENCES public.comunidad(id) ON DELETE CASCADE;

ALTER TABLE "public"."publicacion_etiqueta_comunidad"
  ADD CONSTRAINT "publicacion_etiqueta_comunidad_publicacion_id_fkey" FOREIGN KEY (publicacion_id) REFERENCES public.publicacion(id) ON DELETE CASCADE;

ALTER TABLE "public"."publicacion_lugar"
  ADD CONSTRAINT "publicacion_lugar_lugar_id_fkey" FOREIGN KEY (lugar_id) REFERENCES public.lugar(id) ON DELETE RESTRICT;

ALTER TABLE "public"."publicacion_lugar"
  ADD CONSTRAINT "publicacion_lugar_publicacion_id_fkey" FOREIGN KEY (publicacion_id) REFERENCES public.publicacion(id) ON DELETE CASCADE;

ALTER TABLE "public"."publicacion_multimedia"
  ADD CONSTRAINT "publicacion_multimedia_publicacion_id_fkey" FOREIGN KEY (publicacion_id) REFERENCES public.publicacion(id) ON DELETE CASCADE;

ALTER TABLE "public"."publicacion_usuario_etiqueta"
  ADD CONSTRAINT "publicacion_usuario_etiqueta_publicacion_id_fkey" FOREIGN KEY (publicacion_id) REFERENCES public.publicacion(id) ON DELETE CASCADE;

ALTER TABLE "public"."publicacion_usuario_etiqueta"
  ADD CONSTRAINT "publicacion_usuario_etiqueta_usuario_etiquetado_id_fkey" FOREIGN KEY (usuario_etiquetado_id) REFERENCES public.usuario(id) ON DELETE CASCADE;

ALTER TABLE "public"."ruta"
  ADD CONSTRAINT "ruta_usuario_creador_id_fkey" FOREIGN KEY (usuario_creador_id) REFERENCES public.usuario(id) ON DELETE RESTRICT;

ALTER TABLE "public"."ruta_parada"
  ADD CONSTRAINT "ruta_parada_lugar_id_fkey" FOREIGN KEY (lugar_id) REFERENCES public.lugar(id) ON DELETE RESTRICT;

ALTER TABLE "public"."ruta_parada"
  ADD CONSTRAINT "ruta_parada_ruta_id_fkey" FOREIGN KEY (ruta_id) REFERENCES public.ruta(id) ON DELETE CASCADE;

ALTER TABLE "public"."salida"
  ADD CONSTRAINT "salida_comunidad_id_fkey" FOREIGN KEY (comunidad_id) REFERENCES public.comunidad(id) ON DELETE CASCADE;

ALTER TABLE "public"."salida"
  ADD CONSTRAINT "salida_organizador_id_fkey" FOREIGN KEY (organizador_id) REFERENCES public.usuario(id) ON DELETE RESTRICT;

ALTER TABLE "public"."salida"
  ADD CONSTRAINT "salida_punto_encuentro_lugar_id_fkey" FOREIGN KEY (punto_encuentro_lugar_id) REFERENCES public.lugar(id) ON DELETE RESTRICT;

ALTER TABLE "public"."salida"
  ADD CONSTRAINT "salida_ruta_id_fkey" FOREIGN KEY (ruta_id) REFERENCES public.ruta(id) ON DELETE RESTRICT;

ALTER TABLE "public"."salida_participante"
  ADD CONSTRAINT "salida_participante_salida_id_fkey" FOREIGN KEY (salida_id) REFERENCES public.salida(id) ON DELETE CASCADE;

ALTER TABLE "public"."salida_participante"
  ADD CONSTRAINT "salida_participante_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE CASCADE;

CREATE INDEX idx_comunidad_creador_id ON public.comunidad USING btree (usuario_creador_id);

CREATE INDEX idx_comunidad_mensaje_comunidad_id ON public.comunidad_mensaje USING btree (comunidad_id);

CREATE INDEX idx_comunidad_mensaje_fecha ON public.comunidad_mensaje USING btree (fecha_envio);

CREATE INDEX idx_comunidad_miembro_usuario_id ON public.comunidad_miembro USING btree (usuario_id);

CREATE INDEX idx_distrito_provincia_id ON public.distrito USING btree (provincia_id);

CREATE INDEX idx_lugar_categoria_categoria_id ON public.lugar_categoria USING btree (categoria_id);

CREATE INDEX idx_lugar_distrito_id ON public.lugar USING btree (distrito_id);

CREATE INDEX idx_lugar_ubicacion_gist ON public.lugar USING gist (ubicacion);

CREATE INDEX idx_lugar_usuario_id ON public.lugar USING btree (usuario_id);

CREATE INDEX idx_provincia_departamento_id ON public.provincia USING btree (departamento_id);

CREATE INDEX idx_publicacion_etiqueta_comunidad_id ON public.publicacion_etiqueta_comunidad USING btree (comunidad_id);

CREATE INDEX idx_publicacion_lugar_lugar_id ON public.publicacion_lugar USING btree (lugar_id);

CREATE INDEX idx_publicacion_multimedia_publicacion_id ON public.publicacion_multimedia USING btree (publicacion_id);

CREATE INDEX idx_publicacion_usuario_etiqueta_usuario_id ON public.publicacion_usuario_etiqueta USING btree (usuario_etiquetado_id);

CREATE INDEX idx_publicacion_usuario_id ON public.publicacion USING btree (usuario_id);

CREATE INDEX idx_ruta_creador_id ON public.ruta USING btree (usuario_creador_id);

CREATE INDEX idx_ruta_parada_ruta_id ON public.ruta_parada USING btree (ruta_id);

CREATE INDEX idx_ruta_parada_ubicacion_gist ON public.ruta_parada USING gist (ubicacion);

CREATE INDEX idx_salida_comunidad_id ON public.salida USING btree (comunidad_id);

CREATE INDEX idx_salida_fecha ON public.salida USING btree (fecha_hora_inicio);

CREATE INDEX idx_salida_organizador_id ON public.salida USING btree (organizador_id);

CREATE INDEX idx_salida_ubicacion_gist ON public.salida USING gist (punto_encuentro_ubicacion);

CREATE UNIQUE INDEX uq_publicacion_multimedia_orden ON public.publicacion_multimedia USING btree (publicacion_id, orden);

CREATE UNIQUE INDEX uq_ruta_parada_orden ON public.ruta_parada USING btree (ruta_id, orden);

CREATE TRIGGER trg_comunidad_updated_at
  BEFORE UPDATE ON public.comunidad
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_actualizar_updated_at();

CREATE TRIGGER trg_lugar_sync_ubicacion
  BEFORE INSERT OR UPDATE OF latitud, longitud ON public.lugar
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_sync_ubicacion();

CREATE TRIGGER trg_lugar_updated_at
  BEFORE UPDATE ON public.lugar
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_actualizar_updated_at();

CREATE TRIGGER trg_publicacion_updated_at
  BEFORE UPDATE ON public.publicacion
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_actualizar_updated_at();

CREATE TRIGGER trg_ruta_updated_at
  BEFORE UPDATE ON public.ruta
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_actualizar_updated_at();

CREATE TRIGGER trg_ruta_parada_sync_ubicacion
  BEFORE INSERT OR UPDATE OF latitud, longitud ON public.ruta_parada
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_sync_ubicacion();

CREATE TRIGGER trg_salida_sync_ubicacion
  BEFORE INSERT OR UPDATE OF punto_encuentro_lat, punto_encuentro_lon ON public.salida
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_sync_ubicacion();

CREATE TRIGGER trg_salida_updated_at
  BEFORE UPDATE ON public.salida
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_actualizar_updated_at();

COMMENT ON EXTENSION "postgis" IS 'PostGIS geometry and geography spatial types and functions';

GRANT EXECUTE ON FUNCTION "public"."fn_actualizar_updated_at"() TO PUBLIC, "anon", "authenticated", "postgres", "service_role";

GRANT EXECUTE ON FUNCTION "public"."fn_sync_ubicacion"() TO PUBLIC, "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."categoria" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."comunidad" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."comunidad_mensaje" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."comunidad_miembro" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."departamento" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."distrito" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."lugar" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."lugar_categoria" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."provincia" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."publicacion" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE
  ON TABLE "public"."publicacion_etiqueta_comunidad"
  TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."publicacion_lugar" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."publicacion_multimedia" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE
  ON TABLE "public"."publicacion_usuario_etiqueta"
  TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."ruta" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."ruta_parada" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."salida" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."salida_participante" TO "anon", "authenticated", "postgres", "service_role";

GRANT USAGE ON TYPE "public"."dificultad_nivel" TO "postgres";

GRANT USAGE ON TYPE "public"."estado_membresia" TO "postgres";

GRANT USAGE ON TYPE "public"."estado_participante" TO "postgres";

GRANT USAGE ON TYPE "public"."estado_publicacion" TO "postgres";

GRANT USAGE ON TYPE "public"."estado_salida" TO "postgres";

GRANT USAGE ON TYPE "public"."estado_video" TO "postgres";

GRANT USAGE ON TYPE "public"."rol_miembro" TO "postgres";

GRANT USAGE ON TYPE "public"."tipo_comunidad" TO "postgres";

GRANT USAGE ON TYPE "public"."tipo_multimedia" TO "postgres";

GRANT USAGE ON TYPE "public"."tipo_salida" TO "postgres";

