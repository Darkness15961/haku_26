-- HAKU - Fase 8.6 del MVP de Rutas.
--
-- Hardening forense del error remoto:
--   type "geography" does not exist
--
-- Causa probable: la escritura de Rutas seguia acoplada a funciones de
-- detalle que planificaban casts/funciones PostGIS. Esta migracion vuelve
-- idempotente el desacople y deja el procesamiento espacial encerrado en un
-- helper dinamico. Crear/guardar/archivar Rutas sin recorrido real no debe
-- depender de PostGIS.

create or replace function public.ruta_trazado_geojson(p_ruta_id bigint)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_geojson jsonb;
begin
  if to_regtype('public.geometry') is null
     or to_regtype('public.geography') is null then
    return null;
  end if;

  execute $sql$
    select
      case
        when r.trazado is null then null
        else public.st_asgeojson(r.trazado::public.geometry)::jsonb
      end
    from public.ruta r
    where r.id = $1
  $sql$
  using p_ruta_id
  into v_geojson;

  return v_geojson;
end;
$$;

create or replace function public.ruta_escritura_respuesta(p_ruta_id bigint)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'id', r.id,
    'slug', r.slug,
    'nombre', r.nombre,
    'resumen', r.resumen,
    'descripcion', r.descripcion,
    'foto_portada', r.foto_portada,
    'tipo', r.tipo,
    'hilo_cultural', r.hilo_cultural,
    'zona', r.zona,
    'dificultad', r.dificultad::text,
    'distancia_m', r.distancia_m,
    'duracion_minutos', r.duracion_minutos,
    'dias', r.dias,
    'altitud_min_m', r.altitud_min_m,
    'altitud_max_m', r.altitud_max_m,
    'desnivel_positivo_m', r.desnivel_positivo_m,
    'meses_recomendados', r.meses_recomendados,
    'acceso', r.acceso,
    'transporte', r.transporte,
    'requisitos', r.requisitos,
    'advertencias', r.advertencias,
    'etiquetas', r.etiquetas,
    'version', r.version,
    'publicada_en', r.publicada_en,
    'estado_editorial', r.estado_editorial,
    'cantidad_paradas',
      (
        select count(*)::integer
        from public.ruta_parada rp
        where rp.ruta_id = r.id
      ),
    'usuario_creador_id', r.usuario_creador_id,
    'usuario_creador_nombre', nullif(btrim(u.nombre_nick::text), ''),
    'usuario_creador_foto', nullif(btrim(u.foto_perfil), ''),
    'valoracion_promedio', r.valoracion_promedio,
    'cantidad_valoraciones', r.cantidad_valoraciones,
    'fecha_creacion', r.fecha_creacion,
    'updated_at', r.updated_at,
    'ruta_guardada_por_mi', false,
    'trazado_geojson', null,
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
  left join public.usuario u on u.id = r.usuario_creador_id
  where r.id = p_ruta_id
    and (
      r.usuario_creador_id = (select auth.uid())
      or (
        r.estado = true
        and r.estado_editorial = 'publicado'
      )
    );
$$;

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
      'trazado_geojson', public.ruta_trazado_geojson(r.id),
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

create or replace function public.ruta_propia_detalle(p_ruta_id bigint)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'id', r.id,
    'slug', r.slug,
    'nombre', r.nombre,
    'resumen', r.resumen,
    'descripcion', r.descripcion,
    'foto_portada', r.foto_portada,
    'tipo', r.tipo,
    'hilo_cultural', r.hilo_cultural,
    'zona', r.zona,
    'dificultad', r.dificultad::text,
    'distancia_m', r.distancia_m,
    'duracion_minutos', r.duracion_minutos,
    'dias', r.dias,
    'altitud_min_m', r.altitud_min_m,
    'altitud_max_m', r.altitud_max_m,
    'desnivel_positivo_m', r.desnivel_positivo_m,
    'meses_recomendados', r.meses_recomendados,
    'acceso', r.acceso,
    'transporte', r.transporte,
    'requisitos', r.requisitos,
    'advertencias', r.advertencias,
    'etiquetas', r.etiquetas,
    'version', r.version,
    'publicada_en', r.publicada_en,
    'estado_editorial', r.estado_editorial,
    'cantidad_paradas',
      (
        select count(*)::integer
        from public.ruta_parada rp
        where rp.ruta_id = r.id
      ),
    'usuario_creador_id', r.usuario_creador_id,
    'valoracion_promedio', r.valoracion_promedio,
    'cantidad_valoraciones', r.cantidad_valoraciones,
    'fecha_creacion', r.fecha_creacion,
    'updated_at', r.updated_at,
    'trazado_geojson', public.ruta_trazado_geojson(r.id),
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
  where r.id = p_ruta_id
    and r.usuario_creador_id = (select auth.uid());
$$;

create or replace function public.crear_ruta_publicada(
  p_nombre text,
  p_resumen text,
  p_descripcion text,
  p_foto_portada text,
  p_tipo text,
  p_dificultad text,
  p_hilo_cultural text,
  p_zona text,
  p_acceso text,
  p_transporte text,
  p_requisitos text[],
  p_advertencias text[],
  p_etiquetas text[],
  p_paradas jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_usuario_id uuid := (select auth.uid());
  v_ruta_id bigint;
  v_parada jsonb;
  v_index integer := 0;
  v_total integer;
  v_lugar_id bigint;
  v_instrucciones text;
begin
  if v_usuario_id is null then
    raise exception 'Inicia sesion para crear una Ruta.'
      using errcode = '28000';
  end if;

  if not exists (
    select 1
    from public.usuario u
    where u.id = v_usuario_id
      and u.estado = 'activo'
  ) then
    raise exception 'Tu usuario no esta activo para crear Rutas.'
      using errcode = '42501';
  end if;

  if jsonb_typeof(p_paradas) is distinct from 'array' then
    raise exception 'Las paradas de la Ruta deben enviarse como una lista.'
      using errcode = '22023';
  end if;

  v_total := jsonb_array_length(p_paradas);
  if v_total < 2 then
    raise exception 'Elige al menos dos Lugares para publicar una Ruta.'
      using errcode = '23514';
  end if;

  insert into public.ruta (
    nombre,
    resumen,
    descripcion,
    foto_portada,
    tipo,
    dificultad,
    hilo_cultural,
    zona,
    acceso,
    transporte,
    requisitos,
    advertencias,
    etiquetas,
    estado_editorial
  )
  values (
    p_nombre,
    nullif(btrim(coalesce(p_resumen, '')), ''),
    nullif(btrim(coalesce(p_descripcion, '')), ''),
    nullif(btrim(coalesce(p_foto_portada, '')), ''),
    coalesce(nullif(btrim(p_tipo), ''), 'senderismo'),
    coalesce(nullif(btrim(p_dificultad), ''), 'moderado')::public.dificultad_nivel,
    coalesce(nullif(btrim(p_hilo_cultural), ''), 'camino'),
    nullif(btrim(coalesce(p_zona, '')), ''),
    nullif(btrim(coalesce(p_acceso, '')), ''),
    nullif(btrim(coalesce(p_transporte, '')), ''),
    coalesce(p_requisitos, '{}'::text[]),
    coalesce(p_advertencias, '{}'::text[]),
    coalesce(p_etiquetas, '{}'::text[]),
    'borrador'
  )
  returning id into v_ruta_id;

  for v_parada in
    select value
    from jsonb_array_elements(p_paradas)
  loop
    v_lugar_id := nullif(btrim(v_parada ->> 'lugar_id'), '')::bigint;
    v_instrucciones := nullif(
      btrim(coalesce(v_parada ->> 'instrucciones', '')),
      ''
    );

    insert into public.ruta_parada (
      ruta_id,
      lugar_id,
      orden,
      tipo,
      instrucciones
    )
    values (
      v_ruta_id,
      v_lugar_id,
      v_index,
      case
        when v_index = 0 then 'inicio'
        when v_index = v_total - 1 then 'destino'
        else 'parada'
      end,
      v_instrucciones
    );

    v_index := v_index + 1;
  end loop;

  update public.ruta
  set estado_editorial = 'publicado'
  where id = v_ruta_id;

  return public.ruta_escritura_respuesta(v_ruta_id);
end;
$$;

create or replace function public.guardar_ruta_propia(
  p_ruta_id bigint,
  p_publicar boolean,
  p_nombre text,
  p_resumen text,
  p_descripcion text,
  p_foto_portada text,
  p_tipo text,
  p_dificultad text,
  p_hilo_cultural text,
  p_zona text,
  p_acceso text,
  p_transporte text,
  p_requisitos text[],
  p_advertencias text[],
  p_etiquetas text[],
  p_paradas jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_usuario_id uuid := (select auth.uid());
  v_ruta_id bigint;
  v_estado_actual text;
  v_estado_final text;
  v_parada jsonb;
  v_index integer := 0;
  v_total integer;
  v_lugar_id bigint;
  v_instrucciones text;
begin
  if v_usuario_id is null then
    raise exception 'Inicia sesion para editar una Ruta.'
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

  if jsonb_typeof(p_paradas) is distinct from 'array' then
    raise exception 'Las paradas de la Ruta deben enviarse como una lista.'
      using errcode = '22023';
  end if;

  v_total := jsonb_array_length(p_paradas);
  if p_publicar and v_total < 2 then
    raise exception 'Elige al menos dos Lugares para publicar una Ruta.'
      using errcode = '23514';
  end if;

  if p_ruta_id is null then
    insert into public.ruta (
      nombre,
      resumen,
      descripcion,
      foto_portada,
      tipo,
      dificultad,
      hilo_cultural,
      zona,
      acceso,
      transporte,
      requisitos,
      advertencias,
      etiquetas,
      estado_editorial
    )
    values (
      p_nombre,
      nullif(btrim(coalesce(p_resumen, '')), ''),
      nullif(btrim(coalesce(p_descripcion, '')), ''),
      nullif(btrim(coalesce(p_foto_portada, '')), ''),
      coalesce(nullif(btrim(p_tipo), ''), 'senderismo'),
      coalesce(nullif(btrim(p_dificultad), ''), 'moderado')::public.dificultad_nivel,
      coalesce(nullif(btrim(p_hilo_cultural), ''), 'camino'),
      nullif(btrim(coalesce(p_zona, '')), ''),
      nullif(btrim(coalesce(p_acceso, '')), ''),
      nullif(btrim(coalesce(p_transporte, '')), ''),
      coalesce(p_requisitos, '{}'::text[]),
      coalesce(p_advertencias, '{}'::text[]),
      coalesce(p_etiquetas, '{}'::text[]),
      'borrador'
    )
    returning id into v_ruta_id;
    v_estado_actual := 'borrador';
  else
    select r.id, r.estado_editorial
    into v_ruta_id, v_estado_actual
    from public.ruta r
    where r.id = p_ruta_id
      and r.usuario_creador_id = v_usuario_id
    for update;

    if v_ruta_id is null then
      raise exception 'Ruta no encontrada o sin permiso de edicion.'
        using errcode = '42501';
    end if;
  end if;

  v_estado_final := case
    when p_publicar then 'publicado'
    else coalesce(v_estado_actual, 'borrador')
  end;

  update public.ruta
  set
    nombre = p_nombre,
    resumen = nullif(btrim(coalesce(p_resumen, '')), ''),
    descripcion = nullif(btrim(coalesce(p_descripcion, '')), ''),
    foto_portada = nullif(btrim(coalesce(p_foto_portada, '')), ''),
    tipo = coalesce(nullif(btrim(p_tipo), ''), 'senderismo'),
    dificultad = coalesce(nullif(btrim(p_dificultad), ''), 'moderado')::public.dificultad_nivel,
    hilo_cultural = coalesce(nullif(btrim(p_hilo_cultural), ''), 'camino'),
    zona = nullif(btrim(coalesce(p_zona, '')), ''),
    acceso = nullif(btrim(coalesce(p_acceso, '')), ''),
    transporte = nullif(btrim(coalesce(p_transporte, '')), ''),
    requisitos = coalesce(p_requisitos, '{}'::text[]),
    advertencias = coalesce(p_advertencias, '{}'::text[]),
    etiquetas = coalesce(p_etiquetas, '{}'::text[]),
    estado_editorial = case
      when v_estado_actual = 'publicado' then 'publicado'
      else coalesce(v_estado_actual, 'borrador')
    end
  where id = v_ruta_id;

  delete from public.ruta_parada
  where ruta_id = v_ruta_id;

  for v_parada in
    select value
    from jsonb_array_elements(p_paradas)
  loop
    v_lugar_id := nullif(btrim(v_parada ->> 'lugar_id'), '')::bigint;
    v_instrucciones := nullif(
      btrim(coalesce(v_parada ->> 'instrucciones', '')),
      ''
    );

    insert into public.ruta_parada (
      ruta_id,
      lugar_id,
      orden,
      tipo,
      instrucciones
    )
    values (
      v_ruta_id,
      v_lugar_id,
      v_index,
      case
        when v_index = 0 then 'inicio'
        when v_index = v_total - 1 then 'destino'
        else 'parada'
      end,
      v_instrucciones
    );

    v_index := v_index + 1;
  end loop;

  update public.ruta
  set estado_editorial = v_estado_final
  where id = v_ruta_id;

  return public.ruta_escritura_respuesta(v_ruta_id);
end;
$$;

create or replace function public.archivar_ruta_propia(p_ruta_id bigint)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_usuario_id uuid := (select auth.uid());
begin
  if v_usuario_id is null then
    raise exception 'Inicia sesion para archivar una Ruta.'
      using errcode = '28000';
  end if;

  update public.ruta
  set estado_editorial = 'archivado'
  where id = p_ruta_id
    and usuario_creador_id = v_usuario_id;

  if not found then
    raise exception 'Ruta no encontrada o sin permiso de edicion.'
      using errcode = '42501';
  end if;

  return public.ruta_escritura_respuesta(p_ruta_id);
end;
$$;

revoke all on function public.ruta_trazado_geojson(bigint)
  from public, anon, authenticated;
grant execute on function public.ruta_trazado_geojson(bigint)
  to anon, authenticated, service_role;

revoke all on function public.ruta_escritura_respuesta(bigint)
  from public, anon, authenticated;
grant execute on function public.ruta_escritura_respuesta(bigint)
  to authenticated, service_role;

revoke all on function public.ruta_publicada_detalle(bigint)
  from public, anon, authenticated;
grant execute on function public.ruta_publicada_detalle(bigint)
  to anon, authenticated, service_role;

revoke all on function public.ruta_propia_detalle(bigint)
  from public, anon, authenticated;
grant execute on function public.ruta_propia_detalle(bigint)
  to authenticated, service_role;

revoke all on function public.ruta_guardada_por_mi(public.rutas_publicadas_lista)
  from public, anon, authenticated;
grant execute on function public.ruta_guardada_por_mi(public.rutas_publicadas_lista)
  to anon, authenticated, service_role;

revoke all on function public.crear_ruta_publicada(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text[],
  text[],
  text[],
  jsonb
) from public, anon, authenticated;
grant execute on function public.crear_ruta_publicada(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text[],
  text[],
  text[],
  jsonb
) to authenticated, service_role;

revoke all on function public.guardar_ruta_propia(
  bigint,
  boolean,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text[],
  text[],
  text[],
  jsonb
) from public, anon, authenticated;
grant execute on function public.guardar_ruta_propia(
  bigint,
  boolean,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text[],
  text[],
  text[],
  jsonb
) to authenticated, service_role;

revoke all on function public.archivar_ruta_propia(bigint)
  from public, anon, authenticated;
grant execute on function public.archivar_ruta_propia(bigint)
  to authenticated, service_role;

comment on function public.ruta_trazado_geojson(bigint) is
  'Devuelve trazado GeoJSON de Ruta con SQL dinamico para aislar dependencias PostGIS.';
comment on function public.ruta_escritura_respuesta(bigint) is
  'Respuesta liviana para escrituras de Rutas. No procesa trazado ni llama ST_AsGeoJSON.';

select pg_notify('pgrst', 'reload schema');
