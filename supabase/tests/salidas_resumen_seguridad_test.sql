begin;

create extension if not exists pgtap with schema extensions;
set local search_path = extensions, public, auth;

select plan(14);

select ok(
  (
    select p.prosecdef
    from pg_proc as p
    join pg_namespace as n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'listar_salidas_resumen'
      and pg_get_function_identity_arguments(p.oid) =
        'p_lugar_id bigint, p_ruta_id bigint, p_comunidad_id bigint'
  ),
  'el RPC declara SECURITY DEFINER de forma explicita'
);

select isnt(
  (
    select coalesce(bool_or(a.grantee = 0), false)
    from pg_proc as p
    join pg_namespace as n on n.oid = p.pronamespace
    cross join lateral aclexplode(
      coalesce(p.proacl, acldefault('f', p.proowner))
    ) as a
    where n.nspname = 'public'
      and p.proname = 'listar_salidas_resumen'
      and pg_get_function_identity_arguments(p.oid) =
        'p_lugar_id bigint, p_ruta_id bigint, p_comunidad_id bigint'
  ),
  true,
  'PUBLIC no puede ejecutar el RPC'
);

select ok(
  has_function_privilege(
    'anon',
    'public.listar_salidas_resumen(bigint,bigint,bigint)',
    'EXECUTE'
  ),
  'anon conserva acceso al listado filtrado'
);

select ok(
  (
    select p.proconfig @> array['search_path=""']
    from pg_proc as p
    join pg_namespace as n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'fn_encolar_media_eliminada'
  ),
  'el trigger de outbox tiene search_path vacio'
);

select ok(
  (
    select p.proconfig @> array['search_path=""']
    from pg_proc as p
    join pg_namespace as n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'fn_publicacion_soft_delete_media'
  ),
  'el trigger de soft-delete tiene search_path vacio'
);

select isnt(
  (
    select coalesce(bool_or(a.grantee = 0), false)
    from pg_proc as p
    join pg_namespace as n on n.oid = p.pronamespace
    cross join lateral aclexplode(
      coalesce(p.proacl, acldefault('f', p.proowner))
    ) as a
    where n.nspname = 'public'
      and p.proname = 'fn_encolar_media_eliminada'
  ),
  true,
  'PUBLIC no puede ejecutar directamente el trigger de outbox'
);

select isnt(
  (
    select coalesce(bool_or(a.grantee = 0), false)
    from pg_proc as p
    join pg_namespace as n on n.oid = p.pronamespace
    cross join lateral aclexplode(
      coalesce(p.proacl, acldefault('f', p.proowner))
    ) as a
    where n.nspname = 'public'
      and p.proname = 'fn_publicacion_soft_delete_media'
  ),
  true,
  'PUBLIC no puede ejecutar directamente el trigger de soft-delete'
);

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
    'propietario-salidas@haku.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"nombre_nick":"propietario_salidas","nombres":"Propietario","apellidos":"Salidas","nacionalidad_id":"1"}'::jsonb,
    now(),
    now(),
    false,
    false
  ),
  (
    '10000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'usuario-a-salidas@haku.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"nombre_nick":"usuario_a_salidas","nombres":"Usuario","apellidos":"A","nacionalidad_id":"1"}'::jsonb,
    now(),
    now(),
    false,
    false
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'usuario-b-salidas@haku.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"nombre_nick":"usuario_b_salidas","nombres":"Usuario","apellidos":"B","nacionalidad_id":"1"}'::jsonb,
    now(),
    now(),
    false,
    false
  );

insert into public.comunidad (
  id,
  nombre,
  descripcion,
  usuario_creador_id,
  estado,
  tipo
)
overriding system value
values (
  920000001,
  'Comunidad privada de prueba',
  'Fixture transaccional para probar el RPC.',
  '30000000-0000-0000-0000-000000000003',
  true,
  'privado'
);

insert into public.comunidad_miembro (
  comunidad_id,
  usuario_id,
  estado,
  rol
)
values (
  920000001,
  '10000000-0000-0000-0000-000000000001',
  'aprobado',
  'miembro'
);

insert into public.salida (
  id,
  titulo,
  organizador_id,
  comunidad_id,
  fecha_hora_inicio,
  punto_encuentro_lat,
  punto_encuentro_lon,
  cupos_totales,
  minimo_para_salir,
  estado,
  tipo,
  inscripcion_abierta
)
overriding system value
values
  (
    910000001,
    'Salida publica visible',
    '30000000-0000-0000-0000-000000000003',
    null,
    now() + interval '10 days',
    -13.516000,
    -71.978000,
    10,
    1,
    'programada',
    'publica',
    true
  ),
  (
    910000002,
    'Salida privada de comunidad',
    '30000000-0000-0000-0000-000000000003',
    920000001,
    now() + interval '11 days',
    -13.516000,
    -71.978000,
    10,
    1,
    'programada',
    'comunidad',
    true
  ),
  (
    910000003,
    'Salida cancelada del propietario',
    '30000000-0000-0000-0000-000000000003',
    920000001,
    now() + interval '12 days',
    -13.516000,
    -71.978000,
    10,
    1,
    'cancelada',
    'comunidad',
    false
  );

select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;

select is(
  (select count(*)::integer from public.listar_salidas_resumen(null, null, null)),
  1,
  'anon solo ve la salida publica activa'
);

select is(
  (
    select count(*)::integer
    from public.listar_salidas_resumen(null, null, null)
    where id = 910000002
  ),
  0,
  'anon no ve la salida de comunidad privada'
);

reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

select is(
  (select count(*)::integer from public.listar_salidas_resumen(null, null, null)),
  2,
  'usuario A ve la publica y la privada por ser miembro'
);

select is(
  (
    select count(*)::integer
    from public.listar_salidas_resumen(null, null, null)
    where id = 910000003
  ),
  0,
  'usuario A no ve una salida cancelada ajena'
);

reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-0000-0000-000000000002","role":"authenticated"}',
  true
);
set local role authenticated;

select is(
  (select count(*)::integer from public.listar_salidas_resumen(null, null, null)),
  1,
  'usuario B no puede cruzar la frontera de la comunidad privada'
);

select is_empty(
  $$
    update public.salida
    set titulo = 'Intrusion de usuario B'
    where id = 910000002
    returning id
  $$,
  'usuario B no puede modificar la salida ajena'
);

reset role;
select set_config(
  'request.jwt.claims',
  '{"sub":"30000000-0000-0000-0000-000000000003","role":"authenticated"}',
  true
);
set local role authenticated;

select is(
  (select count(*)::integer from public.listar_salidas_resumen(null, null, null)),
  3,
  'el propietario ve tambien su salida cancelada'
);

select * from finish();
rollback;
