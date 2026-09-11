-- Bloque B: trigger amigable con Google OAuth.
-- Sin pantalla extra: rellena NOT NULL con defaults sensatos.
-- Nick = parte local del correo (sanitizada). Nacionalidad = PE si falta.
-- Foto = avatar_url / picture de Google si viene.
-- El usuario puede editar nick/nacionalidad después en Configuración.

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
  v_foto text;
  v_full text;
begin
  -- Nickname: metadata → si no, local-part del correo (sanitizado).
  v_nick := nullif(trim(coalesce(new.raw_user_meta_data->>'nombre_nick', '')), '');
  if v_nick is null then
    v_nick := split_part(coalesce(new.email, 'usuario'), '@', 1);
  end if;
  -- Solo letras, números y _; el resto → _
  v_nick := regexp_replace(v_nick, '[^A-Za-z0-9_]', '_', 'g');
  v_nick := regexp_replace(v_nick, '_+', '_', 'g');
  v_nick := trim(both '_' from v_nick);
  if v_nick is null or length(v_nick) < 3 then
    v_nick := 'user_' || substr(replace(new.id::text, '-', ''), 1, 8);
  end if;
  v_nick := left(v_nick, 50);

  -- Nombres: metadata → full_name/name de Google → nick
  v_nombres := nullif(trim(coalesce(new.raw_user_meta_data->>'nombres', '')), '');
  if v_nombres is null then
    v_full := nullif(trim(coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      ''
    )), '');
    if v_full is not null then
      v_nombres := split_part(v_full, ' ', 1);
    end if;
  end if;
  if v_nombres is null then
    v_nombres := v_nick;
  end if;
  v_nombres := left(v_nombres, 100);

  -- Apellidos: metadata → resto del full_name → N/D (editable después)
  v_apellidos := nullif(trim(coalesce(new.raw_user_meta_data->>'apellidos', '')), '');
  if v_apellidos is null then
    v_full := nullif(trim(coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      ''
    )), '');
    if v_full is not null and position(' ' in v_full) > 0 then
      v_apellidos := nullif(trim(substr(v_full, position(' ' in v_full) + 1)), '');
    end if;
  end if;
  if v_apellidos is null then
    v_apellidos := 'N/D';
  end if;
  v_apellidos := left(v_apellidos, 100);

  -- Nacionalidad: metadata → PE → cualquiera (Google no trae país)
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
    where n.codigo_iso = 'PE'
    limit 1;
  end if;

  if v_nacionalidad_id is null then
    select n.id into v_nacionalidad_id
    from public.nacionalidad n
    order by n.nombre
    limit 1;
  end if;

  if v_nacionalidad_id is null then
    raise exception
      'Catálogo public.nacionalidad vacío. Aplica la migración de seed de nacionalidades.';
  end if;

  v_foto := nullif(trim(coalesce(
    new.raw_user_meta_data->>'avatar_url',
    new.raw_user_meta_data->>'picture',
    ''
  )), '');

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
    v_foto,
    'activo',
    v_nacionalidad_id
  );

  return new;
end;
$function$;

COMMENT ON FUNCTION public.handle_new_user() IS
  'Tras auth.users INSERT: crea public.usuario. Google: correo, foto, nombre si viene; nick del correo; PE por defecto. Editable en Configuración.';
