begin;

create extension if not exists pgtap with schema extensions;
set local search_path = extensions, public, auth;

select plan(23);

insert into auth.users (
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  is_sso_user,
  is_anonymous
)
values
  (
    '30000000-0000-0000-0000-000000000003',
    'authenticated',
    'authenticated',
    'propietario-lugares@haku.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"nombre_nick":"propietario_lugares","nombres":"Propietario","apellidos":"Lugares","nacionalidad_id":"1"}'::jsonb,
    now(),
    now(),
    false,
    false
  ),
  (
    '40000000-0000-0000-0000-000000000004',
    'authenticated',
    'authenticated',
    'tercero-lugares@haku.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"nombre_nick":"tercero_lugares","nombres":"Tercero","apellidos":"Lugares","nacionalidad_id":"1"}'::jsonb,
    now(),
    now(),
    false,
    false
  );

select set_config(
  'haku.prueba_lugar_distrito_id',
  (select min(id)::text from public.distrito),
  true
);
select set_config(
  'haku.prueba_lugar_categoria_id',
  (select min(id)::text from public.categoria),
  true
);

select set_config(
  'request.jwt.claims',
  '{"sub":"30000000-0000-0000-0000-000000000003","role":"authenticated"}',
  true
);
set local role authenticated;

select lives_ok(
  format(
    $$
      select public.guardar_lugar_propio(
        'Lugar RLS propietario',
        'Borrador creado durante pgTAP.',
        %s,
        array[%s]::integer[],
        null,
        -13.5167,
        -71.9788,
        3400,
        'borrador',
        null
      )
    $$,
    current_setting('haku.prueba_lugar_distrito_id'),
    current_setting('haku.prueba_lugar_categoria_id')
  ),
  'el propietario crea atomicamente un Lugar borrador'
);

select is(
  (
    select estado_editorial
    from public.lugar
    where nombre = 'Lugar RLS propietario'
  ),
  'borrador',
  'el Lugar nuevo conserva el estado borrador'
);

select is(
  (
    select estado
    from public.lugar
    where nombre = 'Lugar RLS propietario'
  ),
  false,
  'un borrador no queda activo en el catalogo'
);

select is(
  (
    select count(*)::integer
    from public.lugar_categoria lc
    inner join public.lugar l on l.id = lc.lugar_id
    where l.nombre = 'Lugar RLS propietario'
  ),
  1,
  'la categoria se guarda en la misma operacion'
);

select is(
  (
    select count(*)::integer
    from public.lugar
    where nombre = 'Lugar RLS propietario'
  ),
  1,
  'el propietario puede leer su borrador'
);

reset role;
select set_config(
  'haku.prueba_lugar_id',
  (
    select id::text
    from public.lugar
    where nombre = 'Lugar RLS propietario'
  ),
  true
);

select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;

select is(
  (
    select count(*)::integer
    from public.lugar
    where id = current_setting('haku.prueba_lugar_id')::bigint
  ),
  0,
  'anon no puede leer un borrador'
);

reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"40000000-0000-0000-0000-000000000004","role":"authenticated"}',
  true
);
set local role authenticated;

select is(
  (
    select count(*)::integer
    from public.lugar
    where id = current_setting('haku.prueba_lugar_id')::bigint
  ),
  0,
  'otro usuario no puede leer el borrador'
);

select is_empty(
  $$
    update public.lugar
    set nombre = 'Intrusion'
    where id = current_setting('haku.prueba_lugar_id')::bigint
    returning id
  $$,
  'otro usuario no puede editar el Lugar'
);

select is_empty(
  $$
    delete from public.lugar
    where id = current_setting('haku.prueba_lugar_id')::bigint
    returning id
  $$,
  'otro usuario no puede eliminar el Lugar'
);

reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"30000000-0000-0000-0000-000000000003","role":"authenticated"}',
  true
);
set local role authenticated;

select lives_ok(
  $$
    select public.cambiar_estado_lugar_propio(
      current_setting('haku.prueba_lugar_id')::bigint,
      'publicado'
    )
  $$,
  'el propietario publica su borrador'
);

select is(
  (
    select estado_editorial
    from public.lugar
    where id = current_setting('haku.prueba_lugar_id')::bigint
  ),
  'publicado',
  'la publicacion cambia el estado editorial'
);

select is(
  (
    select estado
    from public.lugar
    where id = current_setting('haku.prueba_lugar_id')::bigint
  ),
  true,
  'la publicacion activa el catalogo'
);

select is_empty(
  $$
    delete from public.lugar
    where id = current_setting('haku.prueba_lugar_id')::bigint
    returning id
  $$,
  'un Lugar publicado no se puede eliminar directamente'
);

reset role;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;

select is(
  (
    select count(*)::integer
    from public.lugar
    where id = current_setting('haku.prueba_lugar_id')::bigint
  ),
  1,
  'anon puede leer el Lugar publicado'
);

reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"30000000-0000-0000-0000-000000000003","role":"authenticated"}',
  true
);
set local role authenticated;

select lives_ok(
  $$
    select public.cambiar_estado_lugar_propio(
      current_setting('haku.prueba_lugar_id')::bigint,
      'archivado'
    )
  $$,
  'el propietario desactiva el Lugar publicado'
);

select is(
  (
    select estado_editorial
    from public.lugar
    where id = current_setting('haku.prueba_lugar_id')::bigint
  ),
  'archivado',
  'el Lugar queda archivado'
);

reset role;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;

select is(
  (
    select count(*)::integer
    from public.lugar
    where id = current_setting('haku.prueba_lugar_id')::bigint
  ),
  0,
  'anon deja de ver el Lugar desactivado'
);

reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"30000000-0000-0000-0000-000000000003","role":"authenticated"}',
  true
);
set local role authenticated;

select lives_ok(
  $$
    select public.cambiar_estado_lugar_propio(
      current_setting('haku.prueba_lugar_id')::bigint,
      'borrador'
    )
  $$,
  'el propietario restaura el Lugar como borrador'
);

select is(
  (
    select estado_editorial
    from public.lugar
    where id = current_setting('haku.prueba_lugar_id')::bigint
  ),
  'borrador',
  'restaurar no publica automaticamente'
);

select lives_ok(
  format(
    $$
      select public.guardar_lugar_propio(
        'Lugar RLS editado',
        'Ficha editada atomicamente.',
        %s,
        array[%s]::integer[],
        null,
        -13.5168,
        -71.9789,
        3410,
        'publicado',
        %s
      )
    $$,
    current_setting('haku.prueba_lugar_distrito_id'),
    current_setting('haku.prueba_lugar_categoria_id'),
    current_setting('haku.prueba_lugar_id')
  ),
  'el propietario edita su borrador atomicamente'
);

select is(
  (
    select nombre
    from public.lugar
    where id = current_setting('haku.prueba_lugar_id')::bigint
  ),
  'Lugar RLS editado',
  'la edicion actualiza la ficha'
);

select lives_ok(
  $$
    delete from public.lugar
    where id = current_setting('haku.prueba_lugar_id')::bigint
  $$,
  'el propietario elimina su borrador'
);

reset role;
select is(
  (
    select count(*)::integer
    from public.lugar
    where id = current_setting('haku.prueba_lugar_id')::bigint
  ),
  0,
  'el Lugar eliminado ya no existe'
);

select * from finish();
rollback;
