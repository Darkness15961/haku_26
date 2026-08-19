-- Chat 1:1 y grupos de ruta (Fase 1).
create table if not exists grupos_ruta (
  id text primary key,
  nombre text not null,
  creador_id text not null references perfiles (id),
  ruta_id text,
  ruta_titulo text not null default '',
  ultimo_mensaje text not null default '',
  creado_en timestamptz not null default now()
);

create table if not exists miembros_grupo_ruta (
  grupo_id text not null references grupos_ruta (id) on delete cascade,
  usuario_id text not null references perfiles (id) on delete cascade,
  primary key (grupo_id, usuario_id)
);

create table if not exists mensajes_directos (
  id text primary key,
  conversacion_id text not null,
  autor_id text not null references perfiles (id),
  texto text not null,
  creado_en timestamptz not null default now()
);

create index if not exists idx_mensajes_conv
  on mensajes_directos (conversacion_id, creado_en);

alter table grupos_ruta enable row level security;
alter table miembros_grupo_ruta enable row level security;
alter table mensajes_directos enable row level security;

create policy "lectura_miembros_grupo" on grupos_ruta for select using (true);
create policy "lectura_miembros_grupo_m" on miembros_grupo_ruta for select using (true);
create policy "lectura_propia_chat" on mensajes_directos for select
  using (auth.uid()::text = autor_id or auth.uid()::text = conversacion_id);

create policy "escritura_grupo" on grupos_ruta for insert
  with check (auth.uid()::text = creador_id);
create policy "escritura_miembro_grupo" on miembros_grupo_ruta for all
  using (auth.uid()::text = usuario_id) with check (auth.uid()::text = usuario_id);
create policy "escritura_chat" on mensajes_directos for insert
  with check (auth.uid()::text = autor_id);
