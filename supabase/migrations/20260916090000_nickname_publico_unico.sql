-- Nickname público HAKU:
-- - único global sin distinguir mayúsculas;
-- - almacenado en minúsculas;
-- - 3..30 caracteres;
-- - letras ASCII, números y "_" únicamente;
-- - comienza y termina con letra o número;
-- - nombres operativos reservados.

BEGIN;

-- 1) Normalizar de forma determinista las cuentas existentes.
-- Se guardan los valores previos antes de usar placeholders únicos para que
-- "Ana" y "ana" puedan migrarse sin chocar con el UNIQUE antiguo.
-- El bloqueo dura toda la transacción de migración: ningún alta/UPDATE puede
-- quedar fuera del snapshot ni conservar un placeholder intermedio.
-- `auth.users` se bloquea primero para que ninguna alta conserve la versión
-- anterior de handle_new_user mientras cambia el contrato de public.usuario.
LOCK TABLE auth.users IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.usuario IN ACCESS EXCLUSIVE MODE;

ALTER TABLE public.usuario
  DROP CONSTRAINT IF EXISTS usuario_nombre_nick_key,
  DROP CONSTRAINT IF EXISTS usuario_nombre_nick_formato_check,
  DROP CONSTRAINT IF EXISTS usuario_nombre_nick_reservado_check;

DROP INDEX IF EXISTS public.usuario_nombre_nick_lower_key;

CREATE TEMP TABLE haku_nickname_previo
ON COMMIT DROP
AS
SELECT id, nombre_nick
FROM public.usuario;

UPDATE public.usuario
SET nombre_nick = 'tmp_' || replace(id::text, '-', '');

DO $$
DECLARE
  r record;
  v_base text;
  v_nick text;
  v_suffix text;
  v_intento integer;
BEGIN
  FOR r IN
    SELECT p.id, p.nombre_nick
    FROM haku_nickname_previo p
    ORDER BY p.id
  LOOP
    v_base := lower(btrim(COALESCE(r.nombre_nick, '')));
    v_base := regexp_replace(v_base, '^@+', '');
    v_base := regexp_replace(v_base, '[^a-z0-9_]+', '_', 'g');
    v_base := regexp_replace(v_base, '_+', '_', 'g');
    v_base := btrim(v_base, '_');
    v_base := left(v_base, 30);
    v_base := regexp_replace(v_base, '_+$', '');

    IF length(v_base) < 3 THEN
      v_base := 'user_' || substr(replace(r.id::text, '-', ''), 1, 8);
    END IF;

    IF v_base = ANY (
      ARRAY[
        'haku',
        'admin',
        'administrator',
        'administrador',
        'soporte',
        'support',
        'oficial',
        'official',
        'moderador',
        'moderator',
        'staff',
        'sistema',
        'system',
        'seguridad',
        'security',
        'root'
      ]::text[]
    ) THEN
      v_base := left(v_base, 21) || '_' ||
        substr(replace(r.id::text, '-', ''), 1, 8);
    END IF;

    v_nick := v_base;
    v_intento := 0;
    WHILE EXISTS (
      SELECT 1
      FROM public.usuario u
      WHERE lower(u.nombre_nick) = v_nick
        AND u.id <> r.id
    ) LOOP
      v_intento := v_intento + 1;
      IF v_intento > 7 THEN
        RAISE EXCEPTION 'No se pudo migrar un nickname único para %', r.id;
      END IF;
      v_suffix := substr(
        replace(r.id::text, '-', ''),
        1,
        LEAST(8 + ((v_intento - 1) * 3), 28)
      );
      v_nick := left(v_base, 29 - length(v_suffix)) || '_' || v_suffix;
    END LOOP;

    UPDATE public.usuario
    SET nombre_nick = v_nick
    WHERE id = r.id;
  END LOOP;
END;
$$;

-- 2) La base es la autoridad final del formato y de la unicidad.
CREATE UNIQUE INDEX usuario_nombre_nick_lower_key
  ON public.usuario (lower(nombre_nick));

ALTER TABLE public.usuario
  ADD CONSTRAINT usuario_nombre_nick_formato_check CHECK (
    nombre_nick ~ '^[a-z0-9][a-z0-9_]{1,28}[a-z0-9]$'
  ),
  ADD CONSTRAINT usuario_nombre_nick_reservado_check CHECK (
    nombre_nick <> ALL (
      ARRAY[
        'haku',
        'admin',
        'administrator',
        'administrador',
        'soporte',
        'support',
        'oficial',
        'official',
        'moderador',
        'moderator',
        'staff',
        'sistema',
        'system',
        'seguridad',
        'security',
        'root'
      ]::text[]
    )
  );

CREATE OR REPLACE FUNCTION public.normalizar_nickname_usuario()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO public
AS $$
DECLARE
  v_nick text;
BEGIN
  v_nick := lower(btrim(COALESCE(NEW.nombre_nick, '')));
  v_nick := regexp_replace(v_nick, '^@+', '');
  NEW.nombre_nick := v_nick;

  IF v_nick !~ '^[a-z0-9][a-z0-9_]{1,28}[a-z0-9]$' THEN
    RAISE EXCEPTION 'nickname_formato_invalido'
      USING
        ERRCODE = '23514',
        CONSTRAINT = 'usuario_nombre_nick_formato_check';
  END IF;

  IF v_nick = ANY (
    ARRAY[
      'haku',
      'admin',
      'administrator',
      'administrador',
      'soporte',
      'support',
      'oficial',
      'official',
      'moderador',
      'moderator',
      'staff',
      'sistema',
      'system',
      'seguridad',
      'security',
      'root'
    ]::text[]
  ) THEN
    RAISE EXCEPTION 'nickname_reservado'
      USING
        ERRCODE = '23514',
        CONSTRAINT = 'usuario_nombre_nick_reservado_check';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_normalizar_nickname_usuario ON public.usuario;
CREATE TRIGGER trg_normalizar_nickname_usuario
  BEFORE INSERT OR UPDATE OF nombre_nick
  ON public.usuario
  FOR EACH ROW
  EXECUTE FUNCTION public.normalizar_nickname_usuario();

-- 3) Comprobación amigable. Es ayuda de UX; el índice UNIQUE sigue siendo la
-- protección ante dos solicitudes simultáneas.
CREATE OR REPLACE FUNCTION public.nickname_disponible(
  p_nickname text,
  p_excluir_usuario uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT
    lower(regexp_replace(btrim(COALESCE(p_nickname, '')), '^@+', ''))
      ~ '^[a-z0-9][a-z0-9_]{1,28}[a-z0-9]$'
    AND lower(regexp_replace(btrim(COALESCE(p_nickname, '')), '^@+', ''))
      <> ALL (
        ARRAY[
          'haku',
          'admin',
          'administrator',
          'administrador',
          'soporte',
          'support',
          'oficial',
          'official',
          'moderador',
          'moderator',
          'staff',
          'sistema',
          'system',
          'seguridad',
          'security',
          'root'
        ]::text[]
      )
    AND NOT EXISTS (
      SELECT 1
      FROM public.usuario u
      WHERE lower(u.nombre_nick) =
        lower(regexp_replace(btrim(COALESCE(p_nickname, '')), '^@+', ''))
        -- Solo una sesión autenticada puede excluir su propio usuario.
        AND NOT COALESCE(
          p_excluir_usuario = auth.uid() AND u.id = auth.uid(),
          false
        )
    );
$$;

REVOKE ALL ON FUNCTION public.nickname_disponible(text, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.nickname_disponible(text, uuid)
  TO anon, authenticated, service_role;

-- 4) Nuevas cuentas: un nickname solicitado se respeta o se rechaza.
-- Google, cuando no recibe nickname explícito, genera una alternativa estable.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_nick text;
  v_nick_solicitado text;
  v_nick_explicito boolean;
  v_nombres text;
  v_apellidos text;
  v_nacionalidad_id integer;
  v_foto text;
  v_full text;
  v_suffix text;
  v_constraint text;
  v_intento integer := 0;
BEGIN
  v_nick_solicitado :=
    nullif(btrim(COALESCE(NEW.raw_user_meta_data->>'nombre_nick', '')), '');
  v_nick_explicito := v_nick_solicitado IS NOT NULL;

  IF v_nick_explicito THEN
    v_nick := lower(regexp_replace(v_nick_solicitado, '^@+', ''));
    IF v_nick !~ '^[a-z0-9][a-z0-9_]{1,28}[a-z0-9]$' THEN
      RAISE EXCEPTION 'nickname_formato_invalido'
        USING
          ERRCODE = '23514',
          CONSTRAINT = 'usuario_nombre_nick_formato_check';
    END IF;
    IF v_nick = ANY (
      ARRAY[
        'haku',
        'admin',
        'administrator',
        'administrador',
        'soporte',
        'support',
        'oficial',
        'official',
        'moderador',
        'moderator',
        'staff',
        'sistema',
        'system',
        'seguridad',
        'security',
        'root'
      ]::text[]
    ) THEN
      RAISE EXCEPTION 'nickname_reservado'
        USING
          ERRCODE = '23514',
          CONSTRAINT = 'usuario_nombre_nick_reservado_check';
    END IF;
  ELSE
    v_nick := lower(split_part(COALESCE(NEW.email, 'usuario'), '@', 1));
    v_nick := regexp_replace(v_nick, '[^a-z0-9_]+', '_', 'g');
    v_nick := regexp_replace(v_nick, '_+', '_', 'g');
    v_nick := btrim(v_nick, '_');
    v_nick := left(v_nick, 30);
    v_nick := regexp_replace(v_nick, '_+$', '');

    IF length(v_nick) < 3 OR v_nick = ANY (
      ARRAY[
        'haku',
        'admin',
        'administrator',
        'administrador',
        'soporte',
        'support',
        'oficial',
        'official',
        'moderador',
        'moderator',
        'staff',
        'sistema',
        'system',
        'seguridad',
        'security',
        'root'
      ]::text[]
    ) THEN
      v_nick := 'user_' || substr(replace(NEW.id::text, '-', ''), 1, 8);
    END IF;

    IF EXISTS (
      SELECT 1 FROM public.usuario u WHERE lower(u.nombre_nick) = v_nick
    ) THEN
      v_suffix := substr(replace(NEW.id::text, '-', ''), 1, 8);
      v_nick := left(v_nick, 21) || '_' || v_suffix;
    END IF;
  END IF;

  v_nombres :=
    nullif(btrim(COALESCE(NEW.raw_user_meta_data->>'nombres', '')), '');
  IF v_nombres IS NULL THEN
    v_full := nullif(btrim(COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      ''
    )), '');
    IF v_full IS NOT NULL THEN
      v_nombres := split_part(v_full, ' ', 1);
    END IF;
  END IF;
  IF v_nombres IS NULL THEN
    v_nombres := v_nick;
  END IF;
  v_nombres := left(v_nombres, 100);

  v_apellidos :=
    nullif(btrim(COALESCE(NEW.raw_user_meta_data->>'apellidos', '')), '');
  IF v_apellidos IS NULL THEN
    v_full := nullif(btrim(COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      ''
    )), '');
    IF v_full IS NOT NULL AND position(' ' IN v_full) > 0 THEN
      v_apellidos :=
        nullif(btrim(substr(v_full, position(' ' IN v_full) + 1)), '');
    END IF;
  END IF;
  IF v_apellidos IS NULL THEN
    v_apellidos := 'N/D';
  END IF;
  v_apellidos := left(v_apellidos, 100);

  BEGIN
    v_nacionalidad_id :=
      nullif(btrim(COALESCE(
        NEW.raw_user_meta_data->>'nacionalidad_id',
        ''
      )), '')::integer;
  EXCEPTION
    WHEN others THEN
      v_nacionalidad_id := NULL;
  END;

  IF v_nacionalidad_id IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.nacionalidad n
    WHERE n.id = v_nacionalidad_id
  ) THEN
    SELECT n.id
      INTO v_nacionalidad_id
    FROM public.nacionalidad n
    WHERE n.codigo_iso = 'PE'
    LIMIT 1;
  END IF;

  IF v_nacionalidad_id IS NULL THEN
    SELECT n.id
      INTO v_nacionalidad_id
    FROM public.nacionalidad n
    ORDER BY n.nombre
    LIMIT 1;
  END IF;

  IF v_nacionalidad_id IS NULL THEN
    RAISE EXCEPTION
      'Catálogo public.nacionalidad vacío. Aplica el seed de nacionalidades.';
  END IF;

  v_foto := nullif(btrim(COALESCE(
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.raw_user_meta_data->>'picture',
    ''
  )), '');

  LOOP
    BEGIN
      INSERT INTO public.usuario (
        id,
        nombres,
        apellidos,
        nombre_nick,
        correo,
        foto_perfil,
        estado,
        nacionalidad_id
      ) VALUES (
        NEW.id,
        v_nombres,
        v_apellidos,
        v_nick,
        COALESCE(NEW.email, ''),
        v_foto,
        'activo',
        v_nacionalidad_id
      );
      EXIT;
    EXCEPTION
      WHEN unique_violation THEN
        GET STACKED DIAGNOSTICS v_constraint = CONSTRAINT_NAME;
        IF v_constraint <> 'usuario_nombre_nick_lower_key' THEN
          RAISE;
        END IF;
        IF v_nick_explicito THEN
          RAISE EXCEPTION 'nombre_nick_ya_en_uso'
            USING
              ERRCODE = '23505',
              CONSTRAINT = 'usuario_nombre_nick_lower_key';
        END IF;

        -- Aumenta el sufijo en cada colisión. El índice sigue siendo la
        -- autoridad incluso ante altas OAuth concurrentes.
        v_intento := v_intento + 1;
        IF v_intento > 7 THEN
          RAISE EXCEPTION 'No se pudo generar un nickname OAuth único';
        END IF;
        v_suffix := substr(
          replace(NEW.id::text, '-', ''),
          1,
          LEAST(8 + (v_intento * 3), 28)
        );
        v_nick := left(v_nick, 29 - length(v_suffix)) || '_' || v_suffix;
    END;
  END LOOP;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.nickname_disponible(text, uuid) IS
  'Valida formato, reserva y disponibilidad case-insensitive del nickname.';
COMMENT ON FUNCTION public.handle_new_user() IS
  'Crea public.usuario; respeta nickname explícito único o genera uno para OAuth.';

COMMIT;
