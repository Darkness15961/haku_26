-- HAKU / Rutas - diagnóstico previo a la primera migración incremental.
-- SOLO LECTURA: este archivo consulta catálogos de PostgreSQL. No crea,
-- modifica ni elimina objetos o datos.
--
-- Ejecute el archivo completo en el SQL Editor del Supabase alojado en el VPS
-- y exporte la única celda resultante: `diagnostico_rutas`.

with
objetivos(nombre) as (
  values
    ('ruta'::text),
    ('ruta_parada'::text),
    ('ruta_guardada'::text),
    ('ruta_valoracion'::text),
    ('publicacion_ruta'::text),
    ('rutas_publicadas_lista'::text),
    ('salida'::text),
    ('lugar'::text),
    ('usuario'::text)
),
relaciones as (
  select
    o.nombre,
    c.oid,
    case c.relkind
      when 'r' then 'table'
      when 'p' then 'partitioned_table'
      when 'v' then 'view'
      when 'm' then 'materialized_view'
      when 'f' then 'foreign_table'
      else c.relkind::text
    end as tipo,
    c.relrowsecurity as rls_habilitado,
    c.relforcerowsecurity as rls_forzado,
    pg_get_userbyid(c.relowner) as propietario,
    coalesce(to_jsonb(c.reloptions), '[]'::jsonb) as opciones,
    case
      when c.relkind in ('v', 'm') then pg_get_viewdef(c.oid, true)
      else null
    end as definicion_vista
  from objetivos o
  left join pg_namespace n
    on n.nspname = 'public'
  left join pg_class c
    on c.relnamespace = n.oid
   and c.relname = o.nombre
   and c.relkind in ('r', 'p', 'v', 'm', 'f')
),
columnas as (
  select
    c.relname as relacion,
    a.attnum as posicion,
    a.attname as columna,
    pg_catalog.format_type(a.atttypid, a.atttypmod) as tipo,
    a.attnotnull as no_nulo,
    case a.attidentity
      when 'a' then 'always'
      when 'd' then 'by_default'
      else null
    end as identidad,
    case a.attgenerated
      when 's' then 'stored'
      else null
    end as generada,
    pg_get_expr(ad.adbin, ad.adrelid) as valor_predeterminado,
    col_description(c.oid, a.attnum) as comentario
  from pg_class c
  join pg_namespace n
    on n.oid = c.relnamespace
  join objetivos o
    on o.nombre = c.relname
  join pg_attribute a
    on a.attrelid = c.oid
   and a.attnum > 0
   and not a.attisdropped
  left join pg_attrdef ad
    on ad.adrelid = a.attrelid
   and ad.adnum = a.attnum
  where n.nspname = 'public'
),
restricciones as (
  select
    c.relname as relacion,
    con.conname as restriccion,
    case con.contype
      when 'p' then 'primary_key'
      when 'f' then 'foreign_key'
      when 'u' then 'unique'
      when 'c' then 'check'
      when 'x' then 'exclusion'
      else con.contype::text
    end as tipo,
    con.convalidated as validada,
    case
      when con.confrelid <> 0 then con.confrelid::regclass::text
      else null
    end as referencia,
    pg_get_constraintdef(con.oid, true) as definicion
  from pg_constraint con
  join pg_class c
    on c.oid = con.conrelid
  join pg_namespace n
    on n.oid = c.relnamespace
  join objetivos o
    on o.nombre = c.relname
  where n.nspname = 'public'
),
indices as (
  select
    i.tablename as relacion,
    i.indexname as indice,
    i.indexdef as definicion
  from pg_indexes i
  join objetivos o
    on o.nombre = i.tablename
  where i.schemaname = 'public'
),
claves_foraneas_sin_indice as (
  select distinct
    c.relname as relacion,
    con.conname as clave_foranea,
    a.attname as columna_sin_indice
  from pg_constraint con
  join pg_class c
    on c.oid = con.conrelid
  join pg_namespace n
    on n.oid = c.relnamespace
  join objetivos o
    on o.nombre = c.relname
  join pg_attribute a
    on a.attrelid = con.conrelid
   and a.attnum = any (con.conkey)
  where n.nspname = 'public'
    and con.contype = 'f'
    and not exists (
      select 1
      from pg_index ix
      where ix.indrelid = con.conrelid
        and ix.indisvalid
        and ix.indisready
        and a.attnum = any (ix.indkey)
    )
),
disparadores as (
  select
    c.relname as relacion,
    t.tgname as disparador,
    t.tgenabled as estado,
    pg_get_triggerdef(t.oid, true) as definicion
  from pg_trigger t
  join pg_class c
    on c.oid = t.tgrelid
  join pg_namespace n
    on n.oid = c.relnamespace
  join objetivos o
    on o.nombre = c.relname
  where n.nspname = 'public'
    and not t.tgisinternal
),
politicas as (
  select
    p.tablename as relacion,
    p.policyname as politica,
    p.permissive,
    p.roles,
    p.cmd as comando,
    p.qual as usando,
    p.with_check as comprobacion
  from pg_policies p
  join objetivos o
    on o.nombre = p.tablename
  where p.schemaname = 'public'
),
permisos_relaciones as (
  select
    g.table_name as relacion,
    g.grantee,
    g.privilege_type as privilegio,
    g.is_grantable as delegable
  from information_schema.role_table_grants g
  join objetivos o
    on o.nombre = g.table_name
  where g.table_schema = 'public'
    and g.grantee in ('anon', 'authenticated', 'service_role')
),
funciones as (
  select
    p.oid,
    p.proname as funcion,
    pg_get_function_identity_arguments(p.oid) as argumentos,
    pg_get_function_result(p.oid) as retorno,
    l.lanname as lenguaje,
    p.provolatile as volatilidad,
    p.prosecdef as security_definer,
    p.proleakproof as leakproof,
    p.proconfig as configuracion,
    pg_get_userbyid(p.proowner) as propietario,
    pg_get_functiondef(p.oid) as definicion
  from pg_proc p
  join pg_namespace n
    on n.oid = p.pronamespace
  join pg_language l
    on l.oid = p.prolang
  where n.nspname = 'public'
    and (
      p.proname ilike '%ruta%'
      or p.proname in (
        'trg_actualizar_cantidad_paradas',
        'actualizar_cantidad_paradas'
      )
    )
),
permisos_funciones as (
  select
    rp.routine_name as funcion,
    rp.grantee,
    rp.privilege_type as privilegio,
    rp.is_grantable as delegable
  from information_schema.routine_privileges rp
  where rp.routine_schema = 'public'
    and rp.grantee in ('anon', 'authenticated', 'service_role', 'PUBLIC')
    and (
      rp.routine_name ilike '%ruta%'
      or rp.routine_name in (
        'trg_actualizar_cantidad_paradas',
        'actualizar_cantidad_paradas'
      )
    )
),
conteos_aproximados as (
  select
    s.relname as relacion,
    s.n_live_tup as filas_vivas_aproximadas,
    s.n_dead_tup as filas_muertas_aproximadas,
    s.last_analyze,
    s.last_autoanalyze
  from pg_stat_user_tables s
  join objetivos o
    on o.nombre = s.relname
  where s.schemaname = 'public'
),
extensiones as (
  select
    e.extname as extension,
    e.extversion as version,
    n.nspname as esquema
  from pg_extension e
  join pg_namespace n
    on n.oid = e.extnamespace
  where e.extname in ('postgis', 'pgcrypto', 'uuid-ossp')
)
select jsonb_pretty(
  jsonb_build_object(
    'metadatos', jsonb_build_object(
      'generado_en', clock_timestamp(),
      'base_de_datos', current_database(),
      'usuario_actual', current_user,
      'version_servidor', current_setting('server_version'),
      'version_numero_servidor', current_setting('server_version_num')
    ),
    'extensiones', coalesce((
      select jsonb_agg(to_jsonb(e) order by e.extension)
      from extensiones e
    ), '[]'::jsonb),
    'relaciones', coalesce((
      select jsonb_agg(to_jsonb(r) - 'oid' order by r.nombre)
      from relaciones r
    ), '[]'::jsonb),
    'columnas', coalesce((
      select jsonb_agg(to_jsonb(c) order by c.relacion, c.posicion)
      from columnas c
    ), '[]'::jsonb),
    'restricciones', coalesce((
      select jsonb_agg(to_jsonb(r) order by r.relacion, r.restriccion)
      from restricciones r
    ), '[]'::jsonb),
    'indices', coalesce((
      select jsonb_agg(to_jsonb(i) order by i.relacion, i.indice)
      from indices i
    ), '[]'::jsonb),
    'claves_foraneas_sin_indice', coalesce((
      select jsonb_agg(to_jsonb(f) order by f.relacion, f.clave_foranea, f.columna_sin_indice)
      from claves_foraneas_sin_indice f
    ), '[]'::jsonb),
    'disparadores', coalesce((
      select jsonb_agg(to_jsonb(d) order by d.relacion, d.disparador)
      from disparadores d
    ), '[]'::jsonb),
    'politicas_rls', coalesce((
      select jsonb_agg(to_jsonb(p) order by p.relacion, p.politica)
      from politicas p
    ), '[]'::jsonb),
    'permisos_relaciones', coalesce((
      select jsonb_agg(to_jsonb(p) order by p.relacion, p.grantee, p.privilegio)
      from permisos_relaciones p
    ), '[]'::jsonb),
    'funciones', coalesce((
      select jsonb_agg(to_jsonb(f) - 'oid' order by f.funcion, f.argumentos)
      from funciones f
    ), '[]'::jsonb),
    'permisos_funciones', coalesce((
      select jsonb_agg(to_jsonb(p) order by p.funcion, p.grantee, p.privilegio)
      from permisos_funciones p
    ), '[]'::jsonb),
    'conteos_aproximados', coalesce((
      select jsonb_agg(to_jsonb(c) order by c.relacion)
      from conteos_aproximados c
    ), '[]'::jsonb)
  )
) as diagnostico_rutas;
