begin;

create extension if not exists pgtap with schema extensions;
set local search_path = extensions, public, auth;

select plan(22);

-- Usuarios reales de Auth para que auth.uid(), la FK y public.usuario trabajen
-- igual que en una petición de Supabase. Todo se revierte al final.
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
    '10000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'propietario-rutas@haku.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"nombre_nick":"propietario_rutas","nombres":"Propietario","apellidos":"Rutas","nacionalidad_id":"1"}'::jsonb,
    now(),
    now(),
    false,
    false
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'tercero-rutas@haku.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"nombre_nick":"tercero_rutas","nombres":"Tercero","apellidos":"Rutas","nacionalidad_id":"1"}'::jsonb,
    now(),
    now(),
    false,
    false
  );

insert into public.lugar (
  id,
  nombre,
  descripcion,
  altitud,
  latitud,
  longitud,
  estado,
  usuario_id,
  distrito_id
)
overriding system value
values
  (
    900000001,
    'Inicio de prueba',
    'Lugar inicial de la prueba de Rutas.',
    3350,
    -13.516000,
    -71.978000,
    true,
    '10000000-0000-0000-0000-000000000001',
    1
  ),
  (
    900000002,
    'Destino de prueba',
    'Lugar final de la prueba de Rutas.',
    3450,
    -13.510000,
    -71.970000,
    true,
    '10000000-0000-0000-0000-000000000001',
    1
  );

-- Contexto del propietario.
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

select lives_ok(
  $$
    insert into public.ruta (nombre, descripcion, estado_editorial)
    values ('Ruta RLS principal', 'Ruta creada durante pgTAP.', 'borrador')
  $$,
  'el usuario autenticado crea su borrador'
);

select is(
  (
    select r.usuario_creador_id
    from public.ruta r
    where r.nombre = 'Ruta RLS principal'
  ),
  '10000000-0000-0000-0000-000000000001'::uuid,
  'el creador se obtiene de auth.uid()'
);

select is(
  (
    select count(*)::integer
    from public.ruta r
    where r.nombre = 'Ruta RLS principal'
  ),
  1,
  'el propietario puede leer su borrador'
);

reset role;
select set_config(
  'haku.prueba_ruta_id',
  (select r.id::text from public.ruta r where r.nombre = 'Ruta RLS principal'),
  true
);

-- Contexto de un usuario distinto.
select set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-0000-0000-000000000002","role":"authenticated"}',
  true
);
set local role authenticated;

select is(
  (
    select count(*)::integer
    from public.ruta r
    where r.id = current_setting('haku.prueba_ruta_id')::bigint
  ),
  0,
  'un tercero no puede leer el borrador'
);

select is_empty(
  $$
    update public.ruta
    set nombre = 'Intrusión'
    where id = current_setting('haku.prueba_ruta_id')::bigint
    returning id
  $$,
  'un tercero no puede modificar el borrador'
);

-- El propietario agrega los dos Lugares. Los datos geográficos se derivan del
-- Lugar; el cliente solo envía relación, orden y tipo narrativo.
reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

select lives_ok(
  $$
    insert into public.ruta_parada (ruta_id, lugar_id, orden, tipo)
    values
      (current_setting('haku.prueba_ruta_id')::bigint, 900000001, 0, 'inicio'),
      (current_setting('haku.prueba_ruta_id')::bigint, 900000002, 1, 'destino')
  $$,
  'el propietario agrega paradas ordenadas'
);

select is(
  (
    select rp.nombre
    from public.ruta_parada rp
    where rp.ruta_id = current_setting('haku.prueba_ruta_id')::bigint
      and rp.orden = 0
  ),
  'Inicio de prueba',
  'el nombre de la parada se deriva del Lugar'
);

select is(
  (
    select rp.latitud
    from public.ruta_parada rp
    where rp.ruta_id = current_setting('haku.prueba_ruta_id')::bigint
      and rp.orden = 0
  ),
  -13.516000::numeric,
  'las coordenadas de la parada se derivan del Lugar'
);

select lives_ok(
  $$
    update public.ruta
    set estado_editorial = 'publicado'
    where id = current_setting('haku.prueba_ruta_id')::bigint
  $$,
  'el propietario publica directamente una Ruta válida'
);

select is(
  (
    select r.version
    from public.ruta r
    where r.id = current_setting('haku.prueba_ruta_id')::bigint
  ),
  2::smallint,
  'publicar incrementa la versión de la Ruta'
);

-- Lectura anónima únicamente después de publicar.
reset role;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;

select is(
  (
    select count(*)::integer
    from public.rutas_publicadas_lista r
    where r.id = current_setting('haku.prueba_ruta_id')::bigint
  ),
  1,
  'anon puede leer la Ruta publicada en el catálogo'
);

-- El tercero sigue sin poder editar, pero sí puede valorar.
reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-0000-0000-000000000002","role":"authenticated"}',
  true
);
set local role authenticated;

select is_empty(
  $$
    update public.ruta
    set nombre = 'Intrusión publicada'
    where id = current_setting('haku.prueba_ruta_id')::bigint
    returning id
  $$,
  'un tercero no puede modificar una Ruta publicada'
);

select lives_ok(
  $$
    select public.valorar_ruta(
      current_setting('haku.prueba_ruta_id')::bigint,
      5::smallint
    )
  $$,
  'un tercero puede valorar la Ruta publicada'
);

select is(
  (
    select r.valoracion_promedio
    from public.ruta r
    where r.id = current_setting('haku.prueba_ruta_id')::bigint
  ),
  5.00::numeric,
  'la valoración media se recalcula'
);

select is(
  (
    select r.cantidad_valoraciones
    from public.ruta r
    where r.id = current_setting('haku.prueba_ruta_id')::bigint
  ),
  1,
  'la primera valoración incrementa el contador'
);

select lives_ok(
  $$
    select public.valorar_ruta(
      current_setting('haku.prueba_ruta_id')::bigint,
      3::smallint
    )
  $$,
  'el mismo usuario puede cambiar su valoración'
);

select is(
  (
    select r.valoracion_promedio
    from public.ruta r
    where r.id = current_setting('haku.prueba_ruta_id')::bigint
  ),
  3.00::numeric,
  'cambiar la valoración actualiza la media'
);

select is(
  (
    select r.cantidad_valoraciones
    from public.ruta r
    where r.id = current_setting('haku.prueba_ruta_id')::bigint
  ),
  1,
  'cambiar la valoración no crea una segunda fila'
);

-- El propietario no puede valorar su propia Ruta.
reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

select throws_ok(
  $$
    select public.valorar_ruta(
      current_setting('haku.prueba_ruta_id')::bigint,
      4::smallint
    )
  $$,
  '42501'
);

-- Una Ruta publicada no puede quedar con una sola parada.
select throws_ok(
  $$
    delete from public.ruta_parada
    where ruta_id = current_setting('haku.prueba_ruta_id')::bigint
      and orden = 1;
    set constraints trg_ruta_parada_validar_publicada immediate
  $$,
  '23514',
  'La edición dejaría una Ruta publicada con un itinerario inválido.',
  'no se puede romper el itinerario mínimo de una Ruta publicada'
);

-- Con una sola parada tampoco se puede publicar un borrador nuevo.
select lives_ok(
  $$
    insert into public.ruta (nombre, estado_editorial)
    values ('Ruta RLS incompleta', 'borrador')
  $$,
  'se puede guardar un segundo borrador incompleto'
);

reset role;
select set_config(
  'haku.prueba_ruta_incompleta_id',
  (select r.id::text from public.ruta r where r.nombre = 'Ruta RLS incompleta'),
  true
);
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

insert into public.ruta_parada (ruta_id, lugar_id, orden, tipo)
values (
  current_setting('haku.prueba_ruta_incompleta_id')::bigint,
  900000001,
  0,
  'inicio'
);

select throws_ok(
  $$
    update public.ruta
    set estado_editorial = 'publicado'
    where id = current_setting('haku.prueba_ruta_incompleta_id')::bigint
  $$,
  '23514',
  'Una Ruta publicada necesita al menos dos Lugares.',
  'un borrador con una parada no puede publicarse'
);

select * from finish();
rollback;
