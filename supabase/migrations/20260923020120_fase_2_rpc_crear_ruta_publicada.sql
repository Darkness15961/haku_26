-- HAKU - Fase 2 del MVP de Rutas.
--
-- RPC atomica para que Flutter pueda crear y publicar una Ruta sin dejar
-- filas parciales entre public.ruta y public.ruta_parada.

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
    raise exception 'Inicia sesión para crear una Ruta.'
      using errcode = '28000';
  end if;

  if not exists (
    select 1
    from public.usuario u
    where u.id = v_usuario_id
      and u.estado = 'activo'
  ) then
    raise exception 'Tu usuario no está activo para crear Rutas.'
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
    v_instrucciones := nullif(btrim(coalesce(v_parada ->> 'instrucciones', '')), '');

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

  return public.ruta_publicada_detalle(v_ruta_id);
end;
$$;

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

comment on function public.crear_ruta_publicada(
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
) is
  'Crea una Ruta publicada con paradas derivadas de Lugares activos en una sola transacción.';
