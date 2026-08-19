-- HAKU Fase 1 — captura colaborativa
-- IDs TEXT para coincidir con la app local (`yo`, `p1`, `laguna_humantay`).
-- En producción: reemplazar perfiles.id por uuid = auth.users.id.

create extension if not exists pgcrypto;

create table if not exists categorias_actividad (
  id text primary key,
  nombre text not null,
  descripcion text not null default ''
);

create table if not exists perfiles (
  id text primary key,
  nombre text not null,
  usuario text not null unique,
  correo text,
  avatar_url text,
  portada_url text,
  bio_corta text not null default '',
  bio text not null default '',
  provincia text not null default 'Cusco',
  documento text,
  tipo_documento text,
  seguidores integer not null default 0,
  siguiendo integer not null default 0,
  me_gusta integer not null default 0,
  rutas integer not null default 0,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create table if not exists lugares (
  id text primary key,
  nombre text not null,
  descripcion text not null default '',
  imagen_url text not null default '',
  galeria jsonb not null default '[]'::jsonb,
  categoria_id text not null references categorias_actividad (id),
  provincia text not null default 'Cusco',
  distrito text not null default '',
  latitud double precision not null default -13.5319,
  longitud double precision not null default -71.9675,
  distancia_km double precision not null default 0,
  calificacion double precision not null default 0,
  exploradores integer not null default 0,
  fotos integer not null default 0,
  nivel_exploracion text not null default 'enCrecimiento',
  dificultad text not null default 'Moderada',
  tiempo_estimado text not null default '',
  altitud text not null default '',
  acceso text not null default '',
  descubierto_en timestamptz,
  creado_por_usuario boolean not null default false,
  creador_id text references perfiles (id),
  creado_en timestamptz not null default now()
);

create table if not exists publicaciones (
  id text primary key,
  autor_id text not null references perfiles (id),
  texto text not null default '',
  imagen_url text,
  likes integer not null default 0,
  comentarios integer not null default 0,
  lugar_id text references lugares (id),
  lugar_nombre text,
  categoria text,
  creado_en timestamptz not null default now()
);

create table if not exists clips (
  id text primary key,
  autor_id text not null references perfiles (id),
  imagen_url text not null,
  texto text not null default '',
  vistas integer not null default 0,
  likes integer not null default 0,
  comentarios integer not null default 0,
  creado_en timestamptz not null default now()
);

create table if not exists comentarios (
  id text primary key,
  publicacion_id text not null references publicaciones (id) on delete cascade,
  autor_id text not null references perfiles (id),
  texto text not null,
  creado_en timestamptz not null default now()
);

create table if not exists multimedia (
  id text primary key,
  url text not null,
  tipo text not null check (tipo in ('foto', 'video')),
  publicacion_id text references publicaciones (id) on delete cascade,
  clip_id text references clips (id) on delete cascade,
  lugar_id text references lugares (id) on delete set null,
  autor_id text references perfiles (id),
  creado_en timestamptz not null default now()
);

create table if not exists seguimientos (
  seguidor_id text not null references perfiles (id) on delete cascade,
  seguido_id text not null references perfiles (id) on delete cascade,
  creado_en timestamptz not null default now(),
  primary key (seguidor_id, seguido_id),
  check (seguidor_id <> seguido_id)
);

create table if not exists likes_publicacion (
  usuario_id text not null references perfiles (id) on delete cascade,
  publicacion_id text not null references publicaciones (id) on delete cascade,
  creado_en timestamptz not null default now(),
  primary key (usuario_id, publicacion_id)
);

create table if not exists likes_clip (
  usuario_id text not null references perfiles (id) on delete cascade,
  clip_id text not null references clips (id) on delete cascade,
  creado_en timestamptz not null default now(),
  primary key (usuario_id, clip_id)
);

create table if not exists guardados_publicacion (
  usuario_id text not null references perfiles (id) on delete cascade,
  publicacion_id text not null references publicaciones (id) on delete cascade,
  creado_en timestamptz not null default now(),
  primary key (usuario_id, publicacion_id)
);

create table if not exists favoritos_clip (
  usuario_id text not null references perfiles (id) on delete cascade,
  clip_id text not null references clips (id) on delete cascade,
  creado_en timestamptz not null default now(),
  primary key (usuario_id, clip_id)
);

create table if not exists rutas (
  id text primary key,
  titulo text not null,
  subtitulo text not null default '',
  descripcion text not null default '',
  imagen_url text not null default '',
  categoria text not null default 'recomendadas',
  cantidad_lugares integer not null default 0,
  dias integer not null default 1,
  distancia text not null default '',
  nivel_dificultad integer not null default 1,
  dificultad_texto text not null default '',
  altitud text not null default '',
  tiempo_caminata text not null default '',
  mejor_epoca text not null default '',
  etiquetas jsonb not null default '[]'::jsonb,
  calificacion double precision not null default 0,
  cantidad_resenas integer not null default 0,
  punto_partida text not null default '',
  como_llegar text not null default '',
  transporte text not null default '',
  tips jsonb not null default '[]'::jsonb,
  texto_boton text not null default 'Mapa'
);

create table if not exists puntos_ruta (
  id text primary key,
  ruta_id text not null references rutas (id) on delete cascade,
  nombre text not null,
  tipo text not null default 'parada',
  lat double precision not null,
  lng double precision not null,
  nota text,
  orden integer not null default 0
);

create table if not exists favoritos_ruta (
  usuario_id text not null references perfiles (id) on delete cascade,
  ruta_id text not null references rutas (id) on delete cascade,
  creado_en timestamptz not null default now(),
  primary key (usuario_id, ruta_id)
);

create table if not exists comunidades (
  id text primary key,
  nombre text not null,
  descripcion text not null default '',
  imagen_url text not null default '',
  creador_id text not null references perfiles (id),
  provincia text not null default 'Cusco',
  estado text not null default 'activa',
  fecha_creacion timestamptz not null default now()
);

create table if not exists comunidad_categorias (
  comunidad_id text not null references comunidades (id) on delete cascade,
  categoria_id text not null references categorias_actividad (id),
  primary key (comunidad_id, categoria_id)
);

create table if not exists miembros_comunidad (
  id text primary key,
  comunidad_id text not null references comunidades (id) on delete cascade,
  usuario_id text not null references perfiles (id) on delete cascade,
  rol text not null default 'miembro',
  fecha_union timestamptz not null default now(),
  unique (comunidad_id, usuario_id)
);

create table if not exists salidas (
  id text primary key,
  lugar_id text not null references lugares (id),
  organizador_id text references perfiles (id),
  organizador_nombre text not null default '',
  fecha date not null,
  hora text not null,
  punto_encuentro text not null default '',
  cupos integer not null default 10,
  inscritos integer not null default 0,
  minimo integer not null default 4,
  dificultad text not null default 'Moderada',
  comunidad_id text references comunidades (id),
  creado_en timestamptz not null default now()
);

create table if not exists inscritos_salida (
  salida_id text not null references salidas (id) on delete cascade,
  usuario_id text not null references perfiles (id) on delete cascade,
  creado_en timestamptz not null default now(),
  primary key (salida_id, usuario_id)
);

create table if not exists metricas_usuario (
  usuario_id text primary key references perfiles (id) on delete cascade,
  documentados integer not null default 0,
  experiencias_publicadas integer not null default 0,
  salidas_enroladas integer not null default 0,
  actualizado_en timestamptz not null default now()
);

create table if not exists eventos_metrica (
  id text primary key,
  usuario_id text not null references perfiles (id) on delete cascade,
  tipo text not null,
  entidad_id text,
  fuente text,
  creado_en timestamptz not null default now()
);

create index if not exists idx_publicaciones_autor on publicaciones (autor_id, creado_en desc);
create index if not exists idx_publicaciones_lugar on publicaciones (lugar_id);
create index if not exists idx_comentarios_pub on comentarios (publicacion_id, creado_en desc);
create index if not exists idx_clips_autor on clips (autor_id);
create index if not exists idx_lugares_categoria on lugares (categoria_id);
create index if not exists idx_lugares_provincia on lugares (provincia);
create index if not exists idx_salidas_lugar on salidas (lugar_id, fecha);
create index if not exists idx_puntos_ruta on puntos_ruta (ruta_id, orden);

alter table perfiles enable row level security;
alter table lugares enable row level security;
alter table publicaciones enable row level security;
alter table clips enable row level security;
alter table comentarios enable row level security;
alter table multimedia enable row level security;
alter table seguimientos enable row level security;
alter table likes_publicacion enable row level security;
alter table likes_clip enable row level security;
alter table guardados_publicacion enable row level security;
alter table favoritos_clip enable row level security;
alter table favoritos_ruta enable row level security;
alter table rutas enable row level security;
alter table puntos_ruta enable row level security;
alter table comunidades enable row level security;
alter table comunidad_categorias enable row level security;
alter table miembros_comunidad enable row level security;
alter table salidas enable row level security;
alter table inscritos_salida enable row level security;
alter table metricas_usuario enable row level security;
alter table eventos_metrica enable row level security;
alter table categorias_actividad enable row level security;

-- Lectura pública (Fase 1: el mapa y el feed alimentan la base).
create policy "lectura_publica_categorias" on categorias_actividad for select using (true);
create policy "lectura_publica_perfiles" on perfiles for select using (true);
create policy "lectura_publica_lugares" on lugares for select using (true);
create policy "lectura_publica_publicaciones" on publicaciones for select using (true);
create policy "lectura_publica_clips" on clips for select using (true);
create policy "lectura_publica_comentarios" on comentarios for select using (true);
create policy "lectura_publica_multimedia" on multimedia for select using (true);
create policy "lectura_publica_rutas" on rutas for select using (true);
create policy "lectura_publica_puntos" on puntos_ruta for select using (true);
create policy "lectura_publica_comunidades" on comunidades for select using (true);
create policy "lectura_publica_com_cat" on comunidad_categorias for select using (true);
create policy "lectura_publica_miembros" on miembros_comunidad for select using (true);
create policy "lectura_publica_salidas" on salidas for select using (true);
create policy "lectura_publica_seguimientos" on seguimientos for select using (true);

-- Escritura: autenticado. Mientras IDs locales existan, el cliente local sigue siendo la fuente.
create policy "escritura_auth_perfiles" on perfiles for all
  using (auth.uid()::text = id) with check (auth.uid()::text = id);
create policy "escritura_auth_publicaciones" on publicaciones for insert
  with check (auth.uid()::text = autor_id);
create policy "escritura_auth_publicaciones_upd" on publicaciones for update
  using (auth.uid()::text = autor_id);
create policy "escritura_auth_clips" on clips for insert
  with check (auth.uid()::text = autor_id);
create policy "escritura_auth_comentarios" on comentarios for insert
  with check (auth.uid()::text = autor_id);
create policy "escritura_auth_lugares" on lugares for insert
  with check (creador_id is null or auth.uid()::text = creador_id);
create policy "escritura_auth_likes_pub" on likes_publicacion for all
  using (auth.uid()::text = usuario_id) with check (auth.uid()::text = usuario_id);
create policy "escritura_auth_likes_clip" on likes_clip for all
  using (auth.uid()::text = usuario_id) with check (auth.uid()::text = usuario_id);
create policy "escritura_auth_guardados" on guardados_publicacion for all
  using (auth.uid()::text = usuario_id) with check (auth.uid()::text = usuario_id);
create policy "escritura_auth_fav_clip" on favoritos_clip for all
  using (auth.uid()::text = usuario_id) with check (auth.uid()::text = usuario_id);
create policy "escritura_auth_fav_ruta" on favoritos_ruta for all
  using (auth.uid()::text = usuario_id) with check (auth.uid()::text = usuario_id);
create policy "escritura_auth_seguir" on seguimientos for all
  using (auth.uid()::text = seguidor_id) with check (auth.uid()::text = seguidor_id);
create policy "escritura_auth_comunidades" on comunidades for insert
  with check (auth.uid()::text = creador_id);
create policy "escritura_auth_miembros" on miembros_comunidad for all
  using (auth.uid()::text = usuario_id) with check (auth.uid()::text = usuario_id);
create policy "escritura_auth_inscritos" on inscritos_salida for all
  using (auth.uid()::text = usuario_id) with check (auth.uid()::text = usuario_id);
create policy "escritura_auth_metricas" on metricas_usuario for all
  using (auth.uid()::text = usuario_id) with check (auth.uid()::text = usuario_id);
create policy "escritura_auth_eventos" on eventos_metrica for insert
  with check (auth.uid()::text = usuario_id);

insert into categorias_actividad (id, nombre, descripcion) values
  ('naturaleza', 'Naturaleza', 'Lagunas, bosques y apus.'),
  ('cultura', 'Cultura', 'Sitios, fiestas y saberes.'),
  ('gastronomia', 'Comida', 'Mercados, fogón y sabor local.'),
  ('aventura', 'Aventura', 'Treks exigentes y altura.'),
  ('caminata', 'Caminata', 'Caminos, andinismo y ritmo.'),
  ('fotografia', 'Fotografía', 'Luz, niebla y retrato andino.'),
  ('misterioso', 'Misterioso', 'Puentes vivos y relatos ocultos.'),
  ('magico', 'Mágico', 'Apu, ofrenda y paisaje sagrado.')
on conflict (id) do update set
  nombre = excluded.nombre,
  descripcion = excluded.descripcion;
