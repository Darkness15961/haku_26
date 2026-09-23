-- HAKU - Fase 8.8 del MVP de Rutas.
--
-- Estados pensados para usuario:
--   borrador   -> trabajo privado, editable y eliminable
--   publicado  -> visible en Explora, se puede desactivar
--   archivado  -> desactivado para el publico, restaurable o eliminable
--
-- Se mantiene el valor interno "archivado" para no romper datos existentes,
-- pero la UI lo presenta como "Desactivada".

drop policy if exists ruta_delete_propietario on public.ruta;
create policy ruta_delete_propietario
on public.ruta
for delete
to authenticated
using (
  usuario_creador_id = (select auth.uid())
  and estado_editorial in ('borrador', 'archivado')
);

grant delete on table public.ruta to authenticated;

create or replace function public.publicar_ruta_propia(p_ruta_id bigint)
returns jsonb
language plpgsql
security invoker
set search_path = public, extensions
as $$
declare
  v_usuario_id uuid := (select auth.uid());
begin
  if v_usuario_id is null then
    raise exception 'Inicia sesion para publicar una Ruta.'
      using errcode = '28000';
  end if;

  update public.ruta
  set estado_editorial = 'publicado'
  where id = p_ruta_id
    and usuario_creador_id = v_usuario_id
    and estado_editorial in ('borrador', 'archivado');

  if not found then
    raise exception 'Ruta no encontrada, ya publicada o sin permiso de edicion.'
      using errcode = '42501';
  end if;

  return public.ruta_propia_detalle(p_ruta_id);
end;
$$;

create or replace function public.restaurar_ruta_propia(p_ruta_id bigint)
returns jsonb
language plpgsql
security invoker
set search_path = public, extensions
as $$
declare
  v_usuario_id uuid := (select auth.uid());
begin
  if v_usuario_id is null then
    raise exception 'Inicia sesion para restaurar una Ruta.'
      using errcode = '28000';
  end if;

  update public.ruta
  set estado_editorial = 'borrador'
  where id = p_ruta_id
    and usuario_creador_id = v_usuario_id
    and estado_editorial = 'archivado';

  if not found then
    raise exception 'Ruta no encontrada, no desactivada o sin permiso de edicion.'
      using errcode = '42501';
  end if;

  return public.ruta_propia_detalle(p_ruta_id);
end;
$$;

create or replace function public.eliminar_ruta_propia(p_ruta_id bigint)
returns jsonb
language plpgsql
security invoker
set search_path = public, extensions
as $$
declare
  v_usuario_id uuid := (select auth.uid());
  v_estado text;
  v_deleted bigint;
begin
  if v_usuario_id is null then
    raise exception 'Inicia sesion para eliminar una Ruta.'
      using errcode = '28000';
  end if;

  select r.estado_editorial
  into v_estado
  from public.ruta r
  where r.id = p_ruta_id
    and r.usuario_creador_id = v_usuario_id
  for update;

  if v_estado is null then
    raise exception 'Ruta no encontrada o sin permiso de edicion.'
      using errcode = '42501';
  end if;

  if v_estado = 'publicado' then
    raise exception 'Desactiva la Ruta antes de eliminarla definitivamente.'
      using errcode = '23514';
  end if;

  delete from public.ruta
  where id = p_ruta_id
    and usuario_creador_id = v_usuario_id
    and estado_editorial in ('borrador', 'archivado')
  returning id into v_deleted;

  if v_deleted is null then
    raise exception 'No se pudo eliminar la Ruta.'
      using errcode = '42501';
  end if;

  return jsonb_build_object('id', v_deleted, 'eliminada', true);
exception
  when foreign_key_violation then
    raise exception
      'Esta Ruta ya esta enlazada a publicaciones o salidas. Desactivala para ocultarla del publico.'
      using errcode = '23503';
end;
$$;

revoke all on function public.publicar_ruta_propia(bigint)
  from public, anon, authenticated;
grant execute on function public.publicar_ruta_propia(bigint)
  to authenticated, service_role;

revoke all on function public.restaurar_ruta_propia(bigint)
  from public, anon, authenticated;
grant execute on function public.restaurar_ruta_propia(bigint)
  to authenticated, service_role;

revoke all on function public.eliminar_ruta_propia(bigint)
  from public, anon, authenticated;
grant execute on function public.eliminar_ruta_propia(bigint)
  to authenticated, service_role;

comment on function public.publicar_ruta_propia(bigint) is
  'Publica una Ruta propia desde borrador o desactivada; los triggers validan paradas activas.';
comment on function public.restaurar_ruta_propia(bigint) is
  'Devuelve una Ruta propia desactivada al estado borrador para revisarla antes de publicarla.';
comment on function public.eliminar_ruta_propia(bigint) is
  'Elimina definitivamente una Ruta propia solo si no esta publicada ni bloqueada por relaciones externas.';

select pg_notify('pgrst', 'reload schema');
