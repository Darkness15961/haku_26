-- HAKU - Fase 6 del MVP de Rutas.
--
-- Guardado controlado de trazados reales importados desde GPX/GeoJSON ya
-- validados por el creador. La funcion recalcula distancia_m desde el
-- LineString y no acepta geometria excesiva para cliente movil.

create or replace function public.guardar_trazado_ruta_propia(
  p_ruta_id bigint,
  p_trazado_geojson jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_usuario_id uuid := (select auth.uid());
  v_geom public.geometry(LineString, 4326);
  v_puntos integer;
begin
  if v_usuario_id is null then
    raise exception 'Inicia sesion para editar el trazado de una Ruta.'
      using errcode = '28000';
  end if;

  if not exists (
    select 1
    from public.usuario u
    where u.id = v_usuario_id
      and u.estado = 'activo'
  ) then
    raise exception 'Tu usuario no esta activo para editar Rutas.'
      using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.ruta r
    where r.id = p_ruta_id
      and r.usuario_creador_id = v_usuario_id
      and r.estado_editorial in ('borrador', 'publicado')
    for update
  ) then
    raise exception 'Ruta no encontrada o sin permiso de edicion.'
      using errcode = '42501';
  end if;

  if p_trazado_geojson is null then
    update public.ruta
    set
      trazado = null,
      distancia_m = null
    where id = p_ruta_id
      and usuario_creador_id = v_usuario_id;

    return public.ruta_propia_detalle(p_ruta_id);
  end if;

  if jsonb_typeof(p_trazado_geojson) is distinct from 'object'
     or lower(coalesce(p_trazado_geojson ->> 'type', '')) <> 'linestring' then
    raise exception 'El trazado debe ser un GeoJSON LineString.'
      using errcode = '22023';
  end if;

  begin
    v_geom :=
      public.st_setsrid(
        public.st_geomfromgeojson(p_trazado_geojson::text),
        4326
      )::public.geometry(LineString, 4326);
  exception
    when others then
      raise exception 'El GeoJSON del trazado no es valido.'
        using errcode = '22023';
  end;

  if public.geometrytype(v_geom) <> 'LINESTRING' then
    raise exception 'El trazado debe ser un LineString.'
      using errcode = '22023';
  end if;

  if not public.st_isvalid(v_geom) then
    raise exception 'El trazado tiene geometria invalida.'
      using errcode = '22023';
  end if;

  v_puntos := public.st_npoints(v_geom);

  if v_puntos < 2 then
    raise exception 'El trazado necesita al menos dos puntos.'
      using errcode = '23514';
  end if;

  if v_puntos > 2000 then
    raise exception 'El trazado supera el limite de 2000 puntos.'
      using errcode = '54000';
  end if;

  update public.ruta
  set
    trazado = v_geom::public.geography,
    distancia_m = round(public.st_length(v_geom::public.geography))::integer
  where id = p_ruta_id
    and usuario_creador_id = v_usuario_id;

  return public.ruta_propia_detalle(p_ruta_id);
end;
$$;

revoke all on function public.guardar_trazado_ruta_propia(bigint, jsonb)
  from public, anon, authenticated;
grant execute on function public.guardar_trazado_ruta_propia(bigint, jsonb)
  to authenticated, service_role;

comment on function public.guardar_trazado_ruta_propia(bigint, jsonb) is
  'Guarda o limpia el LineString validado de una Ruta propia y recalcula distancia_m.';
