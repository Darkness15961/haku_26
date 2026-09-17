-- Corrección append-only para instalaciones donde 160900 ya fue aplicada.
-- Limita el retry OAuth exclusivamente al índice de nickname.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_nick text;
  v_explicito boolean;
  v_nombres text;
  v_apellidos text;
  v_full text;
  v_nacionalidad_id integer;
  v_foto text;
  v_constraint text;
  v_uuid text := replace(NEW.id::text, '-', '');
  v_intento integer := 0;
  v_suffix text;
  v_reservados constant text[] := ARRAY[
    'haku', 'admin', 'administrator', 'administrador', 'soporte', 'support',
    'oficial', 'official', 'moderador', 'moderator', 'staff', 'sistema',
    'system', 'seguridad', 'security', 'root'
  ]::text[];
BEGIN
  v_nick := nullif(
    btrim(COALESCE(NEW.raw_user_meta_data->>'nombre_nick', '')),
    ''
  );
  v_explicito := v_nick IS NOT NULL;

  IF v_explicito THEN
    v_nick := lower(regexp_replace(v_nick, '^@+', ''));
    IF v_nick !~ '^[a-z0-9][a-z0-9_]{1,28}[a-z0-9]$' THEN
      RAISE EXCEPTION 'nickname_formato_invalido'
        USING
          ERRCODE = '23514',
          CONSTRAINT = 'usuario_nombre_nick_formato_check';
    END IF;
    IF v_nick = ANY (v_reservados) THEN
      RAISE EXCEPTION 'nickname_reservado'
        USING
          ERRCODE = '23514',
          CONSTRAINT = 'usuario_nombre_nick_reservado_check';
    END IF;
  ELSE
    v_nick := lower(split_part(COALESCE(NEW.email, 'usuario'), '@', 1));
    v_nick := regexp_replace(v_nick, '[^a-z0-9_]+', '_', 'g');
    v_nick := regexp_replace(v_nick, '_+', '_', 'g');
    v_nick := regexp_replace(left(btrim(v_nick, '_'), 30), '_+$', '');
    IF length(v_nick) < 3 OR v_nick = ANY (v_reservados) THEN
      v_nick := 'user_' || substr(v_uuid, 1, 8);
    END IF;
  END IF;

  v_full := nullif(btrim(COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    ''
  )), '');
  v_nombres := nullif(
    btrim(COALESCE(NEW.raw_user_meta_data->>'nombres', '')),
    ''
  );
  IF v_nombres IS NULL AND v_full IS NOT NULL THEN
    v_nombres := split_part(v_full, ' ', 1);
  END IF;
  v_nombres := left(COALESCE(v_nombres, v_nick), 100);

  v_apellidos := nullif(
    btrim(COALESCE(NEW.raw_user_meta_data->>'apellidos', '')),
    ''
  );
  IF v_apellidos IS NULL
     AND v_full IS NOT NULL
     AND position(' ' IN v_full) > 0 THEN
    v_apellidos :=
      nullif(btrim(substr(v_full, position(' ' IN v_full) + 1)), '');
  END IF;
  v_apellidos := left(COALESCE(v_apellidos, 'N/D'), 100);

  BEGIN
    v_nacionalidad_id := nullif(
      btrim(COALESCE(NEW.raw_user_meta_data->>'nacionalidad_id', '')),
      ''
    )::integer;
  EXCEPTION
    WHEN others THEN
      v_nacionalidad_id := NULL;
  END;

  IF v_nacionalidad_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.nacionalidad n WHERE n.id = v_nacionalidad_id
  ) THEN
    SELECT n.id
    INTO v_nacionalidad_id
    FROM public.nacionalidad n
    WHERE n.codigo_iso = 'PE'
    ORDER BY n.id
    LIMIT 1;
  END IF;
  IF v_nacionalidad_id IS NULL THEN
    SELECT n.id
    INTO v_nacionalidad_id
    FROM public.nacionalidad n
    ORDER BY n.nombre, n.id
    LIMIT 1;
  END IF;
  IF v_nacionalidad_id IS NULL THEN
    RAISE EXCEPTION 'Catálogo public.nacionalidad vacío';
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
        IF v_explicito THEN
          RAISE EXCEPTION 'nombre_nick_ya_en_uso'
            USING
              ERRCODE = '23505',
              CONSTRAINT = 'usuario_nombre_nick_lower_key';
        END IF;

        v_intento := v_intento + 1;
        IF v_intento > 7 THEN
          RAISE EXCEPTION 'No se pudo generar un nickname OAuth único';
        END IF;
        v_suffix := substr(v_uuid, 1, LEAST(8 + (v_intento * 3), 28));
        v_nick := left(v_nick, 29 - length(v_suffix)) || '_' || v_suffix;
    END;
  END LOOP;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_new_user() IS
  'Crea public.usuario; retry OAuth solo ante colisión real de nickname.';
