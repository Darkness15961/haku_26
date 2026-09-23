-- HAKU - Fase 8.7 del MVP de Rutas.
--
-- Correccion forense del error remoto:
--   PostgREST 42704: type "geography" does not exist
--
-- La publicacion de una Ruta inserta filas en public.ruta_parada. Esa tabla
-- conservaba el trigger historico public.fn_sync_ubicacion(), cuyo cuerpo usaba
-- ST_SetSRID/ST_MakePoint y ::geography sin calificar. Al ejecutarse desde los
-- RPC de Rutas con search_path = '', el trigger no podia resolver geography.
--
-- La solucion duradera es calificar PostGIS en el trigger compartido y dar a
-- los RPC de Rutas un search_path explicito compatible con Supabase/PostGIS.

create extension if not exists postgis with schema public;

do $$
begin
  if to_regtype('public.geometry') is null
     or to_regtype('public.geography') is null then
    raise exception
      'PostGIS no esta disponible como public.geometry/public.geography. No se pueden publicar Rutas con paradas geograficas.'
      using errcode = '42704';
  end if;
end;
$$;

create or replace function public.fn_sync_ubicacion()
returns trigger
language plpgsql
security invoker
set search_path = public, extensions
as $$
begin
  if TG_TABLE_NAME = 'salida' then
    if NEW.punto_encuentro_lat is not null
       and NEW.punto_encuentro_lon is not null then
      NEW.punto_encuentro_ubicacion =
        public.st_setsrid(
          public.st_makepoint(NEW.punto_encuentro_lon, NEW.punto_encuentro_lat),
          4326
        )::public.geography;
    end if;
  else
    if NEW.latitud is not null and NEW.longitud is not null then
      NEW.ubicacion =
        public.st_setsrid(
          public.st_makepoint(NEW.longitud, NEW.latitud),
          4326
        )::public.geography;
    end if;
  end if;

  return NEW;
end;
$$;

alter table public.ruta
  drop constraint if exists ruta_trazado_valido;

alter table public.ruta
  add constraint ruta_trazado_valido check (
    trazado is null
    or public.st_npoints(trazado::public.geometry) >= 2
  );

alter function public.ruta_trazado_geojson(bigint)
  set search_path = public, extensions;

alter function public.ruta_escritura_respuesta(bigint)
  set search_path = public, extensions;

alter function public.ruta_publicada_detalle(bigint)
  set search_path = public, extensions;

alter function public.ruta_propia_detalle(bigint)
  set search_path = public, extensions;

alter function public.crear_ruta_publicada(
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
)
  set search_path = public, extensions;

alter function public.guardar_ruta_propia(
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
)
  set search_path = public, extensions;

alter function public.guardar_trazado_ruta_propia(bigint, jsonb)
  set search_path = public, extensions;

alter function public.archivar_ruta_propia(bigint)
  set search_path = public, extensions;

alter function privado.preparar_ruta_mvp()
  set search_path = public, extensions;

alter function privado.preparar_ruta_parada_desde_lugar()
  set search_path = public, extensions;

alter function privado.validar_paradas_de_ruta_publicada()
  set search_path = public, extensions;

revoke all on function public.fn_sync_ubicacion()
  from public, anon, authenticated;
grant execute on function public.fn_sync_ubicacion()
  to anon, authenticated, service_role;

comment on function public.fn_sync_ubicacion() is
  'Sincroniza columnas geography de lugar, ruta_parada y salida con PostGIS calificado; fase 8.7 corrige ejecucion desde RPCs con search_path restringido.';

comment on constraint ruta_trazado_valido on public.ruta is
  'Valida que un trazado LineString tenga al menos dos puntos usando tipos PostGIS calificados.';

select pg_notify('pgrst', 'reload schema');
