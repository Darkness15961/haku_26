SET local check_function_bodies = off;

CREATE EXTENSION "pg_net" SCHEMA "extensions";

CREATE SEQUENCE "public"."nacionalidad_id_seq" AS integer INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1 NO CYCLE;

CREATE SEQUENCE "public"."tabla_de_prueba_id_seq" AS integer INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1 NO CYCLE;

CREATE TABLE "public"."nacionalidad" (
  "id"         integer                NOT NULL DEFAULT nextval('public.nacionalidad_id_seq'::regclass),
  "nombre"     character varying(100) NOT NULL,
  "codigo_iso" character varying(2)   NOT NULL,
  CONSTRAINT "nacionalidad_nombre_key" UNIQUE (nombre),
  CONSTRAINT "nacionalidad_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."nacionalidad"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."tabla_de_prueba" (
  "id"             integer                  NOT NULL DEFAULT nextval('public.tabla_de_prueba_id_seq'::regclass),
  "mensaje"        text                     NOT NULL,
  "fecha_creacion" timestamp with time zone DEFAULT now(),
  CONSTRAINT "tabla_de_prueba_pkey" PRIMARY KEY (id)
);

CREATE TABLE "public"."usuario" (
  "id"              uuid                     NOT NULL,
  "nombres"         character varying(100)   NOT NULL,
  "apellidos"       character varying(100)   NOT NULL,
  "nombre_nick"     character varying(50)    NOT NULL,
  "correo"          character varying(255)   NOT NULL,
  "foto_perfil"     text,
  "estado"          character varying(20)    DEFAULT 'activo'::character varying,
  "nacionalidad_id" integer                  NOT NULL,
  "fecha_registro"  timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT "usuario_correo_key" UNIQUE (correo),
  CONSTRAINT "usuario_nombre_nick_key" UNIQUE (nombre_nick),
  CONSTRAINT "usuario_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."usuario"
  ENABLE ROW LEVEL SECURITY;

ALTER SEQUENCE "public"."nacionalidad_id_seq" OWNED BY "public"."nacionalidad"."id";

ALTER SEQUENCE "public"."tabla_de_prueba_id_seq" OWNED BY "public"."tabla_de_prueba"."id";

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

CREATE OR REPLACE FUNCTION public.handle_new_user()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
declare
  v_nick text;
  v_nombres text;
  v_apellidos text;
  v_nacionalidad_id integer;
begin
  v_nick := nullif(trim(coalesce(new.raw_user_meta_data->>'nombre_nick', '')), '');
  if v_nick is null then
    v_nick := split_part(coalesce(new.email, 'usuario'), '@', 1);
  end if;
  -- nombre_nick max 50
  v_nick := left(v_nick, 50);

  v_nombres := nullif(trim(coalesce(new.raw_user_meta_data->>'nombres', '')), '');
  if v_nombres is null then
    v_nombres := v_nick;
  end if;
  v_nombres := left(v_nombres, 100);

  v_apellidos := nullif(trim(coalesce(new.raw_user_meta_data->>'apellidos', '')), '');
  if v_apellidos is null then
    v_apellidos := 'N/D';
  end if;
  v_apellidos := left(v_apellidos, 100);

  begin
    v_nacionalidad_id := nullif(trim(coalesce(new.raw_user_meta_data->>'nacionalidad_id', '')), '')::integer;
  exception
    when others then
      v_nacionalidad_id := null;
  end;

  if v_nacionalidad_id is null
     or not exists (select 1 from public.nacionalidad n where n.id = v_nacionalidad_id) then
    select n.id into v_nacionalidad_id
    from public.nacionalidad n
    order by n.id
    limit 1;
  end if;

  if v_nacionalidad_id is null then
    raise exception 'No hay filas en public.nacionalidad; ejecuta el seed antes del registro.';
  end if;

  insert into public.usuario (
    id,
    nombres,
    apellidos,
    nombre_nick,
    correo,
    foto_perfil,
    estado,
    nacionalidad_id
  ) values (
    new.id,
    v_nombres,
    v_apellidos,
    v_nick,
    coalesce(new.email, ''),
    nullif(trim(coalesce(new.raw_user_meta_data->>'avatar_url', '')), ''),
    'activo',
    v_nacionalidad_id
  );

  return new;
end;
$function$;

ALTER TABLE "public"."usuario"
  ADD CONSTRAINT "usuario_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE "public"."usuario"
  ADD CONSTRAINT "usuario_nacionalidad_id_fkey" FOREIGN KEY (nacionalidad_id) REFERENCES public.nacionalidad(id);

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

CREATE POLICY "nacionalidad_select_publico" ON "public"."nacionalidad"
  FOR SELECT
  TO "anon", "authenticated"
  USING (true);

CREATE POLICY "usuario_select_autenticado" ON "public"."usuario"
  FOR SELECT
  TO "authenticated"
  USING (true);

CREATE POLICY "usuario_update_propio" ON "public"."usuario"
  FOR UPDATE
  TO "authenticated"
  USING ((auth.uid() = id))
  WITH CHECK ((auth.uid() = id));

CREATE POLICY "Solo el dueño puede actualizar su archivo" ON "storage"."objects"
  FOR UPDATE
  TO PUBLIC
  USING (((bucket_id = 'haku-storage-produccion-2026'::text) AND (auth.uid() = OWNER)));

CREATE POLICY "Solo el dueño puede eliminar su archivo" ON "storage"."objects"
  FOR DELETE
  TO PUBLIC
  USING (((bucket_id = 'haku-storage-produccion-2026'::text) AND (auth.uid() = OWNER)));

CREATE POLICY "Solo usuarios autenticados pueden subir" ON "storage"."objects"
  FOR INSERT
  TO PUBLIC
  WITH CHECK (((bucket_id = 'haku-storage-produccion-2026'::text) AND (auth.role() = 'authenticated'::text)));

COMMENT ON EXTENSION "pg_net" IS 'Async HTTP';

REVOKE ALL ON FUNCTION "public"."create_bunny_video"(text) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "public"."create_bunny_video"(text) TO "anon", "authenticated", "postgres", "service_role";

REVOKE ALL ON FUNCTION "public"."get_bunny_video_result"(bigint) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "public"."get_bunny_video_result"(bigint) TO "anon", "authenticated", "postgres", "service_role";

REVOKE ALL ON FUNCTION "public"."handle_new_user"() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "public"."handle_new_user"() TO "anon", "authenticated", "postgres", "service_role";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."nacionalidad_id_seq" TO "anon", "authenticated", "postgres", "service_role";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."tabla_de_prueba_id_seq" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."nacionalidad" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."tabla_de_prueba" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."usuario" TO "anon", "authenticated", "postgres", "service_role";

