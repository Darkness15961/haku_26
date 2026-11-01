-- Administracion de Lugares por propietario.
-- Mantiene compatibilidad con clientes anteriores: un INSERT que no indique
-- estado_editorial continua publicando el Lugar como ocurria con estado=true.

alter table public.lugar
  add column if not exists estado_editorial text;

update public.lugar
set estado_editorial = case
  when estado then 'publicado'
  else 'archivado'
end
where estado_editorial is null
   or estado_editorial not in ('borrador', 'publicado', 'archivado');

update public.lugar
set estado = (estado_editorial = 'publicado')
where estado is distinct from (estado_editorial = 'publicado');

alter table public.lugar
  alter column estado_editorial set default 'publicado',
  alter column estado_editorial set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'lugar_estado_editorial_check'
      and conrelid = 'public.lugar'::regclass
  ) then
    alter table public.lugar
      add constraint lugar_estado_editorial_check
      check (estado_editorial in ('borrador', 'publicado', 'archivado'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'lugar_estado_editorial_coherente_check'
      and conrelid = 'public.lugar'::regclass
  ) then
    alter table public.lugar
      add constraint lugar_estado_editorial_coherente_check
      check (estado = (estado_editorial = 'publicado'));
  end if;
end
$$;

create index if not exists idx_lugar_propietario_estado_actualizado
  on public.lugar (usuario_id, estado_editorial, updated_at desc);

comment on column public.lugar.estado_editorial is
  'Ciclo editorial del Lugar: borrador, publicado o archivado. estado=true solo cuando esta publicado.';

-- Catalogo publico: un tercero solo ve Lugares publicados. El propietario
-- conserva acceso a todos sus estados para poder administrarlos.
drop policy if exists lugar_select_activos_o_propios on public.lugar;
create policy lugar_select_activos_o_propios
  on public.lugar
  for select
  to anon, authenticated
  using (
    (estado = true and estado_editorial = 'publicado')
    or usuario_id = (select auth.uid())
  );

drop policy if exists lugar_insert_propio on public.lugar;
create policy lugar_insert_propio
  on public.lugar
  for insert
  to authenticated
  with check (usuario_id = (select auth.uid()));

drop policy if exists lugar_update_propio on public.lugar;
create policy lugar_update_propio
  on public.lugar
  for update
  to authenticated
  using (usuario_id = (select auth.uid()))
  with check (usuario_id = (select auth.uid()));

drop policy if exists lugar_delete_propio on public.lugar;
create policy lugar_delete_propio
  on public.lugar
  for delete
  to authenticated
  using (
    usuario_id = (select auth.uid())
    and estado_editorial in ('borrador', 'archivado')
  );

drop policy if exists lugar_categoria_select_visible on public.lugar_categoria;
create policy lugar_categoria_select_visible
  on public.lugar_categoria
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.lugar l
      where l.id = lugar_id
        and (
          (l.estado = true and l.estado_editorial = 'publicado')
          or l.usuario_id = (select auth.uid())
        )
    )
  );

drop policy if exists lugar_categoria_insert_dueno on public.lugar_categoria;
create policy lugar_categoria_insert_dueno
  on public.lugar_categoria
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.lugar l
      where l.id = lugar_id
        and l.usuario_id = (select auth.uid())
    )
  );

drop policy if exists lugar_categoria_delete_dueno on public.lugar_categoria;
create policy lugar_categoria_delete_dueno
  on public.lugar_categoria
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.lugar l
      where l.id = lugar_id
        and l.usuario_id = (select auth.uid())
    )
  );

-- Alta y edicion atomicas. Las categorias se reemplazan dentro de la misma
-- transaccion que la ficha, evitando Lugares creados o editados a medias.
create or replace function public.guardar_lugar_propio(
  p_nombre text,
  p_descripcion text,
  p_distrito_id integer,
  p_categoria_ids integer[],
  p_foto_portada text,
  p_latitud numeric,
  p_longitud numeric,
  p_altitud integer,
  p_estado_editorial text,
  p_lugar_id bigint
)
returns bigint
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_usuario_id uuid := (select auth.uid());
  v_lugar_id bigint;
  v_estado_editorial text;
begin
  if v_usuario_id is null then
    raise exception using
      errcode = '42501',
      message = 'Inicia sesion para administrar Lugares.';
  end if;

  if nullif(btrim(p_nombre), '') is null then
    raise exception using
      errcode = '23514',
      message = 'El nombre del Lugar es obligatorio.';
  end if;

  if p_distrito_id is null or p_distrito_id <= 0 then
    raise exception using
      errcode = '23514',
      message = 'El distrito del Lugar es obligatorio.';
  end if;

  if p_latitud is null
     or p_longitud is null
     or p_latitud not between -90 and 90
     or p_longitud not between -180 and 180
     or (p_latitud = 0 and p_longitud = 0) then
    raise exception using
      errcode = '23514',
      message = 'La ubicacion del Lugar no es valida.';
  end if;

  if coalesce(cardinality(p_categoria_ids), 0) = 0 then
    raise exception using
      errcode = '23514',
      message = 'Elige al menos una categoria para el Lugar.';
  end if;

  if p_lugar_id is null then
    v_estado_editorial := lower(coalesce(nullif(btrim(p_estado_editorial), ''), 'publicado'));
    if v_estado_editorial not in ('borrador', 'publicado') then
      raise exception using
        errcode = '23514',
        message = 'Un Lugar nuevo solo puede guardarse como borrador o publicado.';
    end if;

    insert into public.lugar (
      nombre,
      descripcion,
      distrito_id,
      usuario_id,
      latitud,
      longitud,
      altitud,
      foto_portada,
      estado,
      estado_editorial
    )
    values (
      btrim(p_nombre),
      nullif(btrim(p_descripcion), ''),
      p_distrito_id,
      v_usuario_id,
      p_latitud,
      p_longitud,
      p_altitud,
      nullif(btrim(p_foto_portada), ''),
      v_estado_editorial = 'publicado',
      v_estado_editorial
    )
    returning id into v_lugar_id;
  else
    update public.lugar
    set nombre = btrim(p_nombre),
        descripcion = nullif(btrim(p_descripcion), ''),
        distrito_id = p_distrito_id,
        latitud = p_latitud,
        longitud = p_longitud,
        altitud = p_altitud,
        foto_portada = coalesce(
          nullif(btrim(p_foto_portada), ''),
          foto_portada
        )
    where id = p_lugar_id
      and usuario_id = v_usuario_id
    returning id into v_lugar_id;

    if v_lugar_id is null then
      raise exception using
        errcode = '42501',
        message = 'No puedes editar este Lugar.';
    end if;
  end if;

  delete from public.lugar_categoria
  where lugar_id = v_lugar_id;

  insert into public.lugar_categoria (lugar_id, categoria_id)
  select v_lugar_id, categorias.categoria_id
  from (
    select distinct unnest(p_categoria_ids) as categoria_id
  ) categorias
  where categorias.categoria_id > 0;

  return v_lugar_id;
end;
$$;

create or replace function public.cambiar_estado_lugar_propio(
  p_lugar_id bigint,
  p_estado_editorial text
)
returns bigint
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_usuario_id uuid := (select auth.uid());
  v_estado_destino text := lower(coalesce(btrim(p_estado_editorial), ''));
  v_lugar_id bigint;
begin
  if v_usuario_id is null then
    raise exception using
      errcode = '42501',
      message = 'Inicia sesion para administrar Lugares.';
  end if;

  if v_estado_destino not in ('borrador', 'publicado', 'archivado') then
    raise exception using
      errcode = '23514',
      message = 'Estado editorial de Lugar no valido.';
  end if;

  update public.lugar
  set estado_editorial = v_estado_destino,
      estado = (v_estado_destino = 'publicado')
  where id = p_lugar_id
    and usuario_id = v_usuario_id
    and (
      (estado_editorial = 'borrador' and v_estado_destino = 'publicado')
      or (estado_editorial = 'publicado' and v_estado_destino = 'archivado')
      or (estado_editorial = 'archivado' and v_estado_destino = 'borrador')
    )
  returning id into v_lugar_id;

  if v_lugar_id is null then
    raise exception using
      errcode = '23514',
      message = 'El cambio de estado solicitado no esta permitido.';
  end if;

  return v_lugar_id;
end;
$$;

revoke all on function public.guardar_lugar_propio(
  text, text, integer, integer[], text, numeric, numeric, integer, text, bigint
) from public, anon;
grant execute on function public.guardar_lugar_propio(
  text, text, integer, integer[], text, numeric, numeric, integer, text, bigint
) to authenticated;

revoke all on function public.cambiar_estado_lugar_propio(bigint, text)
  from public, anon;
grant execute on function public.cambiar_estado_lugar_propio(bigint, text)
  to authenticated;

comment on function public.guardar_lugar_propio(
  text, text, integer, integer[], text, numeric, numeric, integer, text, bigint
) is 'Crea o edita atomicamente un Lugar del usuario autenticado y sus categorias.';

comment on function public.cambiar_estado_lugar_propio(bigint, text) is
  'Aplica transiciones controladas borrador -> publicado -> archivado -> borrador.';

-- La consulta geografica debe respetar el mismo catalogo publico.
create or replace function public.lugares_cerca(
  p_lat double precision,
  p_lon double precision,
  p_radio_m double precision default 50000
)
returns table (
  id bigint,
  nombre character varying,
  latitud numeric,
  longitud numeric,
  distancia_m double precision,
  foto_portada text,
  provincia_id integer,
  distrito_id integer
)
language sql
stable
security invoker
set search_path to public, extensions
as $$
  select
    l.id,
    l.nombre,
    l.latitud,
    l.longitud,
    st_distance(
      l.ubicacion,
      st_setsrid(st_makepoint(p_lon, p_lat), 4326)::geography
    ) as distancia_m,
    l.foto_portada,
    d.provincia_id,
    l.distrito_id
  from public.lugar l
  inner join public.distrito d on d.id = l.distrito_id
  where l.estado = true
    and l.estado_editorial = 'publicado'
    and l.ubicacion is not null
    and st_dwithin(
      l.ubicacion,
      st_setsrid(st_makepoint(p_lon, p_lat), 4326)::geography,
      p_radio_m
    )
  order by 5 asc
  limit 200;
$$;
