-- HAKU - Fase 1 del MVP de Rutas.
--
-- Esta migración es incremental: no reescribe ningún archivo histórico.
-- Consolida la propiedad de Rutas, deriva las paradas desde Lugares activos,
-- permite publicación directa y añade valoraciones comunitarias.

-- ---------------------------------------------------------------------------
-- 1. Estructura mínima y restricciones del dominio
-- ---------------------------------------------------------------------------

create schema if not exists privado;
revoke all on schema privado from public, anon, authenticated;

alter table public.ruta
  add column if not exists valoracion_promedio numeric(3,2) not null default 0,
  add column if not exists cantidad_valoraciones integer not null default 0;

alter table public.ruta
  drop constraint if exists ruta_valoracion_resumen_valido,
  add constraint ruta_valoracion_resumen_valido check (
    valoracion_promedio between 0 and 5
    and cantidad_valoraciones >= 0
    and (
      (cantidad_valoraciones = 0 and valoracion_promedio = 0)
      or cantidad_valoraciones > 0
    )
  );

do $$
begin
  if exists (
    select 1
    from public.ruta_parada
    where lugar_id is null
  ) then
    raise exception
      'No se puede activar el MVP: existen paradas sin lugar_id.'
      using errcode = '23502';
  end if;
end;
$$;

alter table public.ruta_parada
  alter column lugar_id set not null;

-- El índice histórico no era diferible. Convertirlo en constraint permite que
-- una operación atómica reordene dos paradas sin usar órdenes temporales.
drop index if exists public.uq_ruta_parada_orden;

alter table public.ruta_parada
  add constraint uq_ruta_parada_orden
  unique (ruta_id, orden)
  deferrable initially immediate;

create index if not exists idx_ruta_parada_lugar_id
  on public.ruta_parada (lugar_id);

create table public.ruta_valoracion (
  ruta_id bigint not null,
  usuario_id uuid not null,
  puntuacion smallint not null,
  fecha_creacion timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ruta_valoracion_pkey primary key (ruta_id, usuario_id),
  constraint ruta_valoracion_ruta_id_fkey
    foreign key (ruta_id)
    references public.ruta(id)
    on delete cascade,
  constraint ruta_valoracion_usuario_id_fkey
    foreign key (usuario_id)
    references public.usuario(id)
    on delete cascade,
  constraint ruta_valoracion_puntuacion_valida
    check (puntuacion between 1 and 5)
);

create index idx_ruta_valoracion_usuario_id
  on public.ruta_valoracion (usuario_id);

alter table public.ruta_valoracion enable row level security;

comment on table public.ruta_valoracion is
  'Una puntuación de 1 a 5 por usuario y Ruta. El creador no valora su propia Ruta.';
comment on column public.ruta.valoracion_promedio is
  'Resumen derivado de ruta_valoracion; no se escribe desde el cliente.';
comment on column public.ruta.cantidad_valoraciones is
  'Cantidad derivada de ruta_valoracion; no se escribe desde el cliente.';

-- ---------------------------------------------------------------------------
-- 2. Reglas automáticas de Ruta y de sus paradas
-- ---------------------------------------------------------------------------

create or replace function privado.preparar_ruta_mvp()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_usuario_id uuid := (select auth.uid());
  v_base_slug text;
  v_total_paradas integer;
  v_lugares_activos integer;
  v_orden_minimo integer;
  v_orden_maximo integer;
  v_inicios integer;
  v_destinos integer;
  v_tipo_primero text;
  v_tipo_ultimo text;
  v_cambio_contenido boolean;
begin
  new.nombre := btrim(new.nombre);

  if new.nombre = '' or char_length(new.nombre) > 120 then
    raise exception 'El nombre de la Ruta debe tener entre 1 y 120 caracteres.'
      using errcode = '22023';
  end if;

  if new.resumen is not null then
    new.resumen := nullif(btrim(new.resumen), '');
  end if;

  if new.resumen is not null and char_length(new.resumen) > 240 then
    raise exception 'El resumen de la Ruta no puede superar 240 caracteres.'
      using errcode = '22023';
  end if;

  v_base_slug := lower(translate(
    coalesce(nullif(btrim(new.slug), ''), new.nombre),
    'áéíóúüñÁÉÍÓÚÜÑ',
    'aeiouunAEIOUUN'
  ));
  v_base_slug := regexp_replace(v_base_slug, '[^a-z0-9]+', '-', 'g');
  v_base_slug := trim(both '-' from v_base_slug);

  if v_base_slug = '' then
    v_base_slug := 'ruta';
  end if;

  if new.slug is null or btrim(new.slug) = '' then
    new.slug := v_base_slug || '-' || new.id::text;
  else
    new.slug := v_base_slug;
  end if;

  if tg_op = 'INSERT' then
    if v_usuario_id is not null then
      new.usuario_creador_id := v_usuario_id;
    end if;

    new.version := 1;
    new.valoracion_promedio := 0;
    new.cantidad_valoraciones := 0;

    if v_usuario_id is not null and new.estado_editorial <> 'borrador' then
      raise exception 'Una Ruta nueva debe comenzar como borrador.'
        using errcode = '22023';
    end if;

    if new.estado_editorial = 'borrador' then
      new.publicada_en := null;
    end if;

    return new;
  end if;

  if new.usuario_creador_id is distinct from old.usuario_creador_id then
    raise exception 'No se puede cambiar el creador de una Ruta.'
      using errcode = '42501';
  end if;

  if v_usuario_id is not null then
    if new.estado_editorial not in ('borrador', 'publicado', 'archivado') then
      raise exception 'Estado de Ruta no permitido para el creador.'
        using errcode = '22023';
    end if;

    if old.estado_editorial = 'publicado'
       and new.estado_editorial = 'borrador' then
      raise exception 'Una Ruta publicada se archiva; no vuelve a borrador.'
        using errcode = '22023';
    end if;
  end if;

  if new.estado_editorial = 'publicado' then
    select
      count(*)::integer,
      count(*) filter (where l.estado = true)::integer,
      min(rp.orden),
      max(rp.orden),
      count(*) filter (where rp.tipo = 'inicio')::integer,
      count(*) filter (where rp.tipo = 'destino')::integer,
      (array_agg(rp.tipo order by rp.orden))[1],
      (array_agg(rp.tipo order by rp.orden desc))[1]
    into
      v_total_paradas,
      v_lugares_activos,
      v_orden_minimo,
      v_orden_maximo,
      v_inicios,
      v_destinos,
      v_tipo_primero,
      v_tipo_ultimo
    from public.ruta_parada rp
    join public.lugar l on l.id = rp.lugar_id
    where rp.ruta_id = new.id;

    if v_total_paradas < 2 then
      raise exception 'Una Ruta publicada necesita al menos dos Lugares.'
        using errcode = '23514';
    end if;

    if v_lugares_activos <> v_total_paradas then
      raise exception 'Todas las paradas deben corresponder a Lugares activos.'
        using errcode = '23514';
    end if;

    if v_orden_minimo <> 0 or v_orden_maximo <> v_total_paradas - 1 then
      raise exception 'Las paradas deben tener órdenes consecutivos desde cero.'
        using errcode = '23514';
    end if;

    if v_inicios <> 1 or v_destinos <> 1
       or v_tipo_primero <> 'inicio'
       or v_tipo_ultimo <> 'destino' then
      raise exception
        'La primera parada debe ser el único inicio y la última el único destino.'
        using errcode = '23514';
    end if;

    new.estado := true;
    new.publicada_en := coalesce(old.publicada_en, now());
  elsif new.estado_editorial = 'archivado' then
    new.estado := false;
    new.publicada_en := old.publicada_en;
  elsif new.estado_editorial = 'borrador' then
    new.publicada_en := null;
  end if;

  v_cambio_contenido :=
    (to_jsonb(new) - array[
      'version',
      'updated_at',
      'publicada_en',
      'valoracion_promedio',
      'cantidad_valoraciones'
    ])
    is distinct from
    (to_jsonb(old) - array[
      'version',
      'updated_at',
      'publicada_en',
      'valoracion_promedio',
      'cantidad_valoraciones'
    ]);

  if v_cambio_contenido then
    new.version := old.version + 1;
    new.updated_at := now();
  else
    new.version := old.version;
    new.updated_at := old.updated_at;
  end if;

  return new;
end;
$$;

create or replace function privado.preparar_ruta_parada_desde_lugar()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_lugar record;
begin
  select
    l.nombre,
    l.latitud,
    l.longitud,
    l.ubicacion,
    l.altitud
  into v_lugar
  from public.lugar l
  where l.id = new.lugar_id
    and l.estado = true;

  if not found then
    raise exception 'El Lugar seleccionado no existe o no está activo.'
      using errcode = '23503';
  end if;

  if v_lugar.latitud is null or v_lugar.longitud is null then
    raise exception 'El Lugar seleccionado no tiene coordenadas válidas.'
      using errcode = '23514';
  end if;

  new.nombre := v_lugar.nombre;
  new.latitud := v_lugar.latitud;
  new.longitud := v_lugar.longitud;
  new.ubicacion := coalesce(
    v_lugar.ubicacion,
    public.st_setsrid(
      public.st_makepoint(v_lugar.longitud, v_lugar.latitud),
      4326
    )::public.geography
  );
  new.altitud_m := v_lugar.altitud;

  return new;
end;
$$;

create or replace function privado.validar_paradas_de_ruta_publicada()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_ruta_id bigint;
  v_total integer;
  v_activas integer;
  v_orden_minimo integer;
  v_orden_maximo integer;
  v_inicios integer;
  v_destinos integer;
  v_tipo_primero text;
  v_tipo_ultimo text;
begin
  v_ruta_id := case when tg_op = 'DELETE' then old.ruta_id else new.ruta_id end;

  if not exists (
    select 1
    from public.ruta r
    where r.id = v_ruta_id
      and r.estado = true
      and r.estado_editorial = 'publicado'
  ) then
    if tg_op = 'DELETE' then
      return old;
    end if;
    return new;
  end if;

  select
    count(*)::integer,
    count(*) filter (where l.estado = true)::integer,
    min(rp.orden),
    max(rp.orden),
    count(*) filter (where rp.tipo = 'inicio')::integer,
    count(*) filter (where rp.tipo = 'destino')::integer,
    (array_agg(rp.tipo order by rp.orden))[1],
    (array_agg(rp.tipo order by rp.orden desc))[1]
  into
    v_total,
    v_activas,
    v_orden_minimo,
    v_orden_maximo,
    v_inicios,
    v_destinos,
    v_tipo_primero,
    v_tipo_ultimo
  from public.ruta_parada rp
  join public.lugar l on l.id = rp.lugar_id
  where rp.ruta_id = v_ruta_id;

  if v_total < 2
     or v_activas <> v_total
     or v_orden_minimo <> 0
     or v_orden_maximo <> v_total - 1
     or v_inicios <> 1
     or v_destinos <> 1
     or v_tipo_primero <> 'inicio'
     or v_tipo_ultimo <> 'destino' then
    raise exception
      'La edición dejaría una Ruta publicada con un itinerario inválido.'
      using errcode = '23514';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_ruta_updated_at on public.ruta;
drop trigger if exists trg_ruta_preparar_mvp on public.ruta;
create trigger trg_ruta_preparar_mvp
before insert or update on public.ruta
for each row
execute function privado.preparar_ruta_mvp();

drop trigger if exists trg_ruta_parada_desde_lugar on public.ruta_parada;
create trigger trg_ruta_parada_desde_lugar
before insert or update on public.ruta_parada
for each row
execute function privado.preparar_ruta_parada_desde_lugar();

drop trigger if exists trg_ruta_parada_validar_publicada on public.ruta_parada;
create constraint trigger trg_ruta_parada_validar_publicada
after insert or update or delete on public.ruta_parada
deferrable initially deferred
for each row
execute function privado.validar_paradas_de_ruta_publicada();

-- ---------------------------------------------------------------------------
-- 3. Valoraciones: identidad de sesión y resumen consistente
-- ---------------------------------------------------------------------------

create or replace function privado.preparar_ruta_valoracion()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_usuario_id uuid := (select auth.uid());
begin
  if tg_op = 'INSERT' and v_usuario_id is not null then
    new.usuario_id := v_usuario_id;
  elsif tg_op = 'UPDATE' then
    if new.ruta_id is distinct from old.ruta_id
       or new.usuario_id is distinct from old.usuario_id then
      raise exception 'No se puede cambiar el autor ni la Ruta de una valoración.'
        using errcode = '42501';
    end if;
    new.updated_at := now();
  end if;

  return new;
end;
$$;

create or replace function privado.recalcular_resumen_valoracion_ruta()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ruta_id bigint;
  v_usuario_id uuid;
  v_promedio numeric(3,2);
  v_cantidad integer;
begin
  v_ruta_id := case when tg_op = 'DELETE' then old.ruta_id else new.ruta_id end;
  v_usuario_id := case when tg_op = 'DELETE' then old.usuario_id else new.usuario_id end;

  if (select auth.uid()) is not null
     and v_usuario_id is distinct from (select auth.uid()) then
    raise exception 'No se puede recalcular una valoración ajena.'
      using errcode = '42501';
  end if;

  -- Serializa los recálculos de una misma Ruta. La consulta siguiente obtiene
  -- un snapshot posterior si otra valoración concurrente terminó primero.
  perform 1
  from public.ruta r
  where r.id = v_ruta_id
  for update;

  if not found then
    if tg_op = 'DELETE' then
      return old;
    end if;
    return new;
  end if;

  select
    coalesce(round(avg(rv.puntuacion)::numeric, 2), 0)::numeric(3,2),
    count(*)::integer
  into v_promedio, v_cantidad
  from public.ruta_valoracion rv
  where rv.ruta_id = v_ruta_id;

  update public.ruta
  set valoracion_promedio = v_promedio,
      cantidad_valoraciones = v_cantidad
  where id = v_ruta_id;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_ruta_valoracion_preparar on public.ruta_valoracion;
create trigger trg_ruta_valoracion_preparar
before insert or update on public.ruta_valoracion
for each row
execute function privado.preparar_ruta_valoracion();

drop trigger if exists trg_ruta_valoracion_resumen on public.ruta_valoracion;
create trigger trg_ruta_valoracion_resumen
after insert or update of puntuacion or delete on public.ruta_valoracion
for each row
execute function privado.recalcular_resumen_valoracion_ruta();

create or replace function public.valorar_ruta(
  p_ruta_id bigint,
  p_puntuacion smallint
)
returns void
language sql
volatile
security invoker
set search_path = ''
as $$
  insert into public.ruta_valoracion (ruta_id, puntuacion)
  values (p_ruta_id, p_puntuacion)
  on conflict (ruta_id, usuario_id)
  do update
  set puntuacion = excluded.puntuacion;
$$;

revoke all on function privado.preparar_ruta_mvp() from public, anon, authenticated;
revoke all on function privado.preparar_ruta_parada_desde_lugar()
  from public, anon, authenticated;
revoke all on function privado.validar_paradas_de_ruta_publicada()
  from public, anon, authenticated;
revoke all on function privado.preparar_ruta_valoracion()
  from public, anon, authenticated;
revoke all on function privado.recalcular_resumen_valoracion_ruta()
  from public, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 4. RLS: lectura pública, borradores privados y escritura del propietario
-- ---------------------------------------------------------------------------

alter table public.ruta enable row level security;
alter table public.ruta_parada enable row level security;

drop policy if exists ruta_select_publicada on public.ruta;
drop policy if exists ruta_select_propietario on public.ruta;
drop policy if exists ruta_select_visible on public.ruta;
create policy ruta_select_visible
on public.ruta
for select
to anon, authenticated
using (
  (estado = true and estado_editorial = 'publicado')
  or (
    (select auth.uid()) is not null
    and usuario_creador_id = (select auth.uid())
  )
);

drop policy if exists ruta_insert_propietario on public.ruta;
create policy ruta_insert_propietario
on public.ruta
for insert
to authenticated
with check (
  usuario_creador_id = (select auth.uid())
  and estado_editorial = 'borrador'
  and exists (
    select 1
    from public.usuario u
    where u.id = (select auth.uid())
      and u.estado = 'activo'
  )
);

drop policy if exists ruta_update_propietario on public.ruta;
create policy ruta_update_propietario
on public.ruta
for update
to authenticated
using (usuario_creador_id = (select auth.uid()))
with check (
  usuario_creador_id = (select auth.uid())
  and estado_editorial in ('borrador', 'publicado', 'archivado')
  and exists (
    select 1
    from public.usuario u
    where u.id = (select auth.uid())
      and u.estado = 'activo'
  )
);

drop policy if exists ruta_parada_select_publicada on public.ruta_parada;
drop policy if exists ruta_parada_select_propietario on public.ruta_parada;
drop policy if exists ruta_parada_select_visible on public.ruta_parada;
create policy ruta_parada_select_visible
on public.ruta_parada
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.ruta r
    where r.id = ruta_id
      and r.estado = true
      and r.estado_editorial = 'publicado'
  )
  or (
    (select auth.uid()) is not null
    and exists (
    select 1
    from public.ruta r
    where r.id = ruta_id
      and r.usuario_creador_id = (select auth.uid())
    )
  )
);

drop policy if exists ruta_parada_insert_propietario on public.ruta_parada;
create policy ruta_parada_insert_propietario
on public.ruta_parada
for insert
to authenticated
with check (
  exists (
    select 1
    from public.ruta r
    where r.id = ruta_id
      and r.usuario_creador_id = (select auth.uid())
      and r.estado_editorial in ('borrador', 'publicado', 'archivado')
  )
);

drop policy if exists ruta_parada_update_propietario on public.ruta_parada;
create policy ruta_parada_update_propietario
on public.ruta_parada
for update
to authenticated
using (
  exists (
    select 1
    from public.ruta r
    where r.id = ruta_id
      and r.usuario_creador_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.ruta r
    where r.id = ruta_id
      and r.usuario_creador_id = (select auth.uid())
      and r.estado_editorial in ('borrador', 'publicado', 'archivado')
  )
);

drop policy if exists ruta_parada_delete_propietario on public.ruta_parada;
create policy ruta_parada_delete_propietario
on public.ruta_parada
for delete
to authenticated
using (
  exists (
    select 1
    from public.ruta r
    where r.id = ruta_id
      and r.usuario_creador_id = (select auth.uid())
  )
);

drop policy if exists ruta_valoracion_select_propia on public.ruta_valoracion;
create policy ruta_valoracion_select_propia
on public.ruta_valoracion
for select
to authenticated
using (usuario_id = (select auth.uid()));

drop policy if exists ruta_valoracion_insert_propia on public.ruta_valoracion;
create policy ruta_valoracion_insert_propia
on public.ruta_valoracion
for insert
to authenticated
with check (
  usuario_id = (select auth.uid())
  and exists (
    select 1
    from public.usuario u
    where u.id = (select auth.uid())
      and u.estado = 'activo'
  )
  and exists (
    select 1
    from public.ruta r
    where r.id = ruta_id
      and r.estado = true
      and r.estado_editorial = 'publicado'
      and r.usuario_creador_id <> (select auth.uid())
  )
);

drop policy if exists ruta_valoracion_update_propia on public.ruta_valoracion;
create policy ruta_valoracion_update_propia
on public.ruta_valoracion
for update
to authenticated
using (usuario_id = (select auth.uid()))
with check (
  usuario_id = (select auth.uid())
  and exists (
    select 1
    from public.usuario u
    where u.id = (select auth.uid())
      and u.estado = 'activo'
  )
  and exists (
    select 1
    from public.ruta r
    where r.id = ruta_id
      and r.estado = true
      and r.estado_editorial = 'publicado'
      and r.usuario_creador_id <> (select auth.uid())
  )
);

drop policy if exists ruta_valoracion_delete_propia on public.ruta_valoracion;
create policy ruta_valoracion_delete_propia
on public.ruta_valoracion
for delete
to authenticated
using (usuario_id = (select auth.uid()));

-- La tabla de guardados ya existía. Se conservan sus operaciones actuales,
-- pero se eliminan privilegios innecesarios y se explicita el rol de la policy.
drop policy if exists "Usuarios solo pueden ver sus rutas guardadas"
  on public.ruta_guardada;
create policy ruta_guardada_select_propia
on public.ruta_guardada
for select
to authenticated
using (usuario_id = (select auth.uid()));

drop policy if exists "Usuarios pueden guardar rutas" on public.ruta_guardada;
create policy ruta_guardada_insert_propia
on public.ruta_guardada
for insert
to authenticated
with check (usuario_id = (select auth.uid()));

drop policy if exists "Usuarios pueden quitar rutas guardadas"
  on public.ruta_guardada;
create policy ruta_guardada_delete_propia
on public.ruta_guardada
for delete
to authenticated
using (usuario_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- 5. Grants mínimos para la Data API
-- ---------------------------------------------------------------------------

revoke all on table public.ruta from anon, authenticated;
grant select on table public.ruta to anon, authenticated;
grant insert (
  nombre,
  descripcion,
  foto_portada,
  dificultad,
  slug,
  tipo,
  hilo_cultural,
  resumen,
  zona,
  distancia_m,
  duracion_minutos,
  dias,
  altitud_min_m,
  altitud_max_m,
  desnivel_positivo_m,
  meses_recomendados,
  acceso,
  transporte,
  requisitos,
  advertencias,
  etiquetas,
  estado_editorial,
  trazado
) on public.ruta to authenticated;
grant update (
  nombre,
  descripcion,
  foto_portada,
  dificultad,
  slug,
  tipo,
  hilo_cultural,
  resumen,
  zona,
  distancia_m,
  duracion_minutos,
  dias,
  altitud_min_m,
  altitud_max_m,
  desnivel_positivo_m,
  meses_recomendados,
  acceso,
  transporte,
  requisitos,
  advertencias,
  etiquetas,
  estado_editorial,
  trazado
) on public.ruta to authenticated;
grant all privileges on table public.ruta to service_role;

revoke all on table public.ruta_parada from anon, authenticated;
grant select on table public.ruta_parada to anon, authenticated;
grant insert (
  ruta_id,
  lugar_id,
  orden,
  tipo,
  instrucciones,
  distancia_acumulada_m,
  tiempo_acumulado_minutos
) on public.ruta_parada to authenticated;
grant update (
  lugar_id,
  orden,
  tipo,
  instrucciones,
  distancia_acumulada_m,
  tiempo_acumulado_minutos
) on public.ruta_parada to authenticated;
grant delete on table public.ruta_parada to authenticated;
grant all privileges on table public.ruta_parada to service_role;

revoke all on table public.ruta_valoracion from anon, authenticated;
grant select on table public.ruta_valoracion to authenticated;
grant insert (ruta_id, puntuacion)
  on public.ruta_valoracion to authenticated;
grant update (puntuacion)
  on public.ruta_valoracion to authenticated;
grant delete on table public.ruta_valoracion to authenticated;
grant all privileges on table public.ruta_valoracion to service_role;

revoke all on function public.valorar_ruta(bigint, smallint)
  from public, anon, authenticated;
grant execute on function public.valorar_ruta(bigint, smallint)
  to authenticated, service_role;

revoke all on table public.ruta_guardada from anon, authenticated;
-- El SELECT de anon permite que el campo calculado de la vista devuelva false;
-- RLS no le permite observar ninguna fila de guardados.
grant select on table public.ruta_guardada to anon, authenticated;
grant insert, delete on table public.ruta_guardada to authenticated;
grant all privileges on table public.ruta_guardada to service_role;

revoke all on sequence public.ruta_id_seq from anon, authenticated;
grant usage, select on sequence public.ruta_id_seq to authenticated;
revoke all on sequence public.ruta_parada_id_seq from anon, authenticated;
grant usage, select on sequence public.ruta_parada_id_seq to authenticated;

-- ---------------------------------------------------------------------------
-- 6. Catálogo público compatible, con valoración agregada
-- ---------------------------------------------------------------------------

drop function if exists public.ruta_guardada_por_mi(public.ruta);
drop function if exists public.ruta_guardada_por_mi(public.rutas_publicadas_lista);
drop view if exists public.rutas_publicadas_lista;

create view public.rutas_publicadas_lista
with (security_invoker = true)
as
select
  r.id,
  r.slug,
  r.nombre,
  r.resumen,
  r.descripcion,
  r.foto_portada,
  r.tipo,
  r.hilo_cultural,
  r.zona,
  r.dificultad::text as dificultad,
  r.distancia_m,
  r.duracion_minutos,
  r.dias,
  r.altitud_min_m,
  r.altitud_max_m,
  r.desnivel_positivo_m,
  r.meses_recomendados,
  r.acceso,
  r.transporte,
  r.requisitos,
  r.advertencias,
  r.etiquetas,
  r.version,
  r.publicada_en,
  (
    select count(*)::integer
    from public.ruta_parada rp
    where rp.ruta_id = r.id
  ) as cantidad_paradas,
  r.usuario_creador_id,
  r.valoracion_promedio,
  r.cantidad_valoraciones,
  r.fecha_creacion,
  r.updated_at
from public.ruta r
where r.estado = true
  and r.estado_editorial = 'publicado';

create or replace function public.ruta_guardada_por_mi(
  ruta public.rutas_publicadas_lista
)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select exists (
    select 1
    from public.ruta_guardada rg
    where rg.ruta_id = ruta.id
      and rg.usuario_id = (select auth.uid())
  );
$$;

create or replace function public.ruta_publicada_detalle(p_ruta_id bigint)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select to_jsonb(v)
    || jsonb_build_object(
      'ruta_guardada_por_mi', public.ruta_guardada_por_mi(v),
      'trazado_geojson',
        case
          when r.trazado is null then null
          else public.st_asgeojson(r.trazado::public.geometry)::jsonb
        end,
      'paradas',
        coalesce(
          (
            select jsonb_agg(
              jsonb_build_object(
                'id', rp.id,
                'nombre', rp.nombre,
                'tipo', rp.tipo,
                'latitud', rp.latitud,
                'longitud', rp.longitud,
                'altitud_m', rp.altitud_m,
                'orden', rp.orden,
                'instrucciones', rp.instrucciones,
                'distancia_acumulada_m', rp.distancia_acumulada_m,
                'tiempo_acumulado_minutos', rp.tiempo_acumulado_minutos,
                'lugar_id', rp.lugar_id
              )
              order by rp.orden
            )
            from public.ruta_parada rp
            where rp.ruta_id = r.id
          ),
          '[]'::jsonb
        )
    )
  from public.ruta r
  join public.rutas_publicadas_lista v on v.id = r.id
  where r.id = p_ruta_id
    and r.estado = true
    and r.estado_editorial = 'publicado';
$$;

revoke all on table public.rutas_publicadas_lista from public, anon, authenticated;
grant select on table public.rutas_publicadas_lista
  to anon, authenticated, service_role;

revoke all on function public.ruta_guardada_por_mi(public.rutas_publicadas_lista)
  from public, anon, authenticated;
grant execute on function
  public.ruta_guardada_por_mi(public.rutas_publicadas_lista)
  to anon, authenticated, service_role;

revoke all on function public.ruta_publicada_detalle(bigint)
  from public, anon, authenticated;
grant execute on function public.ruta_publicada_detalle(bigint)
  to anon, authenticated, service_role;

comment on view public.rutas_publicadas_lista is
  'Catálogo de Rutas publicadas con conteo de paradas y valoración agregada.';
