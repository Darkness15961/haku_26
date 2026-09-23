-- Fase 4: catalogo publico con autor visible y metadatos reales.
-- Mantiene la vista como SECURITY INVOKER para respetar RLS de ruta/usuario.

create or replace view public.rutas_publicadas_lista
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
  r.updated_at,
  nullif(btrim(u.nombre_nick::text), '') as usuario_creador_nombre,
  nullif(btrim(u.foto_perfil), '') as usuario_creador_foto
from public.ruta r
left join public.usuario u on u.id = r.usuario_creador_id
where r.estado = true
  and r.estado_editorial = 'publicado';

revoke all on table public.rutas_publicadas_lista from public, anon, authenticated;
grant select on table public.rutas_publicadas_lista
  to anon, authenticated, service_role;

comment on view public.rutas_publicadas_lista is
  'Catalogo de Rutas publicadas con conteo de paradas, valoracion agregada y autor publico cuando RLS lo permite.';
