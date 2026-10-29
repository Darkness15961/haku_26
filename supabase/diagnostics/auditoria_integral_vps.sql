-- HAKU / Supabase self-hosted - auditoria integral de solo lectura.
--
-- Este diagnostico no crea ni modifica objetos o datos. La transaccion se
-- declara READ ONLY y termina con ROLLBACK como defensa adicional.
-- No recopila filas de negocio, secretos de Vault ni valores de variables.

BEGIN TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '45s';
SET LOCAL lock_timeout = '5s';

WITH
metadatos AS (
  SELECT jsonb_build_object(
    'generado_en', clock_timestamp(),
    'base_de_datos', current_database(),
    'usuario_actual', current_user,
    'solo_lectura', current_setting('transaction_read_only'),
    'version_servidor', current_setting('server_version'),
    'version_numero_servidor', current_setting('server_version_num')
  ) AS valor
),
migraciones AS (
  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object(
        'version', m.version,
        'nombre', m.name
      )
      ORDER BY m.version
    ),
    '[]'::jsonb
  ) AS valor
  FROM supabase_migrations.schema_migrations AS m
),
extensiones AS (
  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object(
        'extension', e.extname,
        'version', e.extversion,
        'esquema', n.nspname
      )
      ORDER BY e.extname
    ),
    '[]'::jsonb
  ) AS valor
  FROM pg_extension AS e
  JOIN pg_namespace AS n ON n.oid = e.extnamespace
),
relaciones AS (
  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object(
        'esquema', n.nspname,
        'relacion', c.relname,
        'tipo', CASE c.relkind
          WHEN 'r' THEN 'table'
          WHEN 'p' THEN 'partitioned_table'
          WHEN 'v' THEN 'view'
          WHEN 'm' THEN 'materialized_view'
          WHEN 'f' THEN 'foreign_table'
          ELSE c.relkind::text
        END,
        'propietario', pg_get_userbyid(c.relowner),
        'rls_habilitado', c.relrowsecurity,
        'rls_forzado', c.relforcerowsecurity,
        'opciones', coalesce(to_jsonb(c.reloptions), '[]'::jsonb)
      )
      ORDER BY n.nspname, c.relname
    ),
    '[]'::jsonb
  ) AS valor
  FROM pg_class AS c
  JOIN pg_namespace AS n ON n.oid = c.relnamespace
  WHERE n.nspname IN ('public', 'storage')
    AND c.relkind IN ('r', 'p', 'v', 'm', 'f')
),
politicas AS (
  SELECT coalesce(
    jsonb_agg(to_jsonb(p) ORDER BY p.schemaname, p.tablename, p.policyname),
    '[]'::jsonb
  ) AS valor
  FROM pg_policies AS p
  WHERE p.schemaname IN ('public', 'storage')
),
permisos_relaciones AS (
  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object(
        'esquema', g.table_schema,
        'relacion', g.table_name,
        'rol', g.grantee,
        'privilegio', g.privilege_type,
        'delegable', g.is_grantable
      )
      ORDER BY g.table_schema, g.table_name, g.grantee, g.privilege_type
    ),
    '[]'::jsonb
  ) AS valor
  FROM information_schema.role_table_grants AS g
  WHERE g.table_schema IN ('public', 'storage')
    AND g.grantee IN ('PUBLIC', 'anon', 'authenticated', 'service_role')
),
vistas AS (
  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object(
        'esquema', n.nspname,
        'vista', c.relname,
        'propietario', pg_get_userbyid(c.relowner),
        'opciones', coalesce(to_jsonb(c.reloptions), '[]'::jsonb),
        'security_invoker', coalesce(c.reloptions @> ARRAY['security_invoker=true'], false),
        'definicion', pg_get_viewdef(c.oid, true)
      )
      ORDER BY n.nspname, c.relname
    ),
    '[]'::jsonb
  ) AS valor
  FROM pg_class AS c
  JOIN pg_namespace AS n ON n.oid = c.relnamespace
  WHERE n.nspname IN ('public', 'storage')
    AND c.relkind IN ('v', 'm')
),
funciones AS (
  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object(
        'esquema', n.nspname,
        'funcion', p.proname,
        'argumentos', pg_get_function_identity_arguments(p.oid),
        'retorno', pg_get_function_result(p.oid),
        'propietario', pg_get_userbyid(p.proowner),
        'security_definer', p.prosecdef,
        'configuracion', coalesce(to_jsonb(p.proconfig), '[]'::jsonb),
        'ejecutable_public', EXISTS (
          SELECT 1
          FROM aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) AS a
          WHERE a.grantee = 0
            AND a.privilege_type = 'EXECUTE'
        ),
        'ejecutable_anon', has_function_privilege('anon', p.oid, 'EXECUTE'),
        'ejecutable_authenticated', has_function_privilege('authenticated', p.oid, 'EXECUTE'),
        'definicion', pg_get_functiondef(p.oid)
      )
      ORDER BY n.nspname, p.proname, pg_get_function_identity_arguments(p.oid)
    ),
    '[]'::jsonb
  ) AS valor
  FROM pg_proc AS p
  JOIN pg_namespace AS n ON n.oid = p.pronamespace
  WHERE p.prokind IN ('f', 'p')
    AND (
      n.nspname = 'public'
      OR (
        p.prosecdef
        AND n.nspname NOT IN ('pg_catalog', 'information_schema')
      )
    )
),
permisos_funciones AS (
  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object(
        'esquema', r.routine_schema,
        'funcion', r.routine_name,
        'rol', r.grantee,
        'privilegio', r.privilege_type,
        'delegable', r.is_grantable
      )
      ORDER BY r.routine_schema, r.routine_name, r.grantee
    ),
    '[]'::jsonb
  ) AS valor
  FROM information_schema.routine_privileges AS r
  WHERE r.routine_schema = 'public'
    AND r.grantee IN ('PUBLIC', 'anon', 'authenticated', 'service_role')
),
cron_catalogo AS (
  SELECT jsonb_build_object(
    'extension_instalada', EXISTS (
      SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
    ),
    'tabla_jobs_disponible', to_regclass('cron.job') IS NOT NULL,
    'tabla_historial_disponible', to_regclass('cron.job_run_details') IS NOT NULL
  ) AS valor
),
storage_catalogo AS (
  SELECT jsonb_build_object(
    'esquema_disponible', EXISTS (
      SELECT 1 FROM pg_namespace WHERE nspname = 'storage'
    ),
    'tabla_buckets_disponible', to_regclass('storage.buckets') IS NOT NULL,
    'tabla_objects_disponible', to_regclass('storage.objects') IS NOT NULL
  ) AS valor
)
SELECT jsonb_pretty(
  jsonb_build_object(
    'metadatos', (SELECT valor FROM metadatos),
    'migraciones', (SELECT valor FROM migraciones),
    'extensiones', (SELECT valor FROM extensiones),
    'relaciones', (SELECT valor FROM relaciones),
    'politicas_rls', (SELECT valor FROM politicas),
    'permisos_relaciones', (SELECT valor FROM permisos_relaciones),
    'vistas', (SELECT valor FROM vistas),
    'funciones', (SELECT valor FROM funciones),
    'permisos_funciones', (SELECT valor FROM permisos_funciones),
    'cron_catalogo', (SELECT valor FROM cron_catalogo),
    'storage_catalogo', (SELECT valor FROM storage_catalogo)
  )
) AS auditoria_integral_vps;

ROLLBACK;
