#!/bin/bash
set -euo pipefail
# Solo Haku: contenedor supabase-db (NO yachaiya)
docker exec -i supabase-db bash <<'INNER'
set -euo pipefail
export PGHOST=127.0.0.1
export PGUSER=supabase_admin
# PGPASSWORD ya viene en el entorno del contenedor
psql -d postgres -v ON_ERROR_STOP=1 <<'SQL'
ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "spatial_ref_sys_select" ON public.spatial_ref_sys;
CREATE POLICY "spatial_ref_sys_select"
ON public.spatial_ref_sys
FOR SELECT
TO anon, authenticated, service_role
USING (true);

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON TABLE public.spatial_ref_sys
  FROM anon, authenticated;

COMMENT ON TABLE public.spatial_ref_sys IS
  'Catálogo PostGIS. RLS ON; SELECT para API; sin writes desde anon/authenticated.';

SELECT c.relrowsecurity AS rls
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relname = 'spatial_ref_sys';

SELECT polname FROM pg_policy WHERE polrelid = 'public.spatial_ref_sys'::regclass;

SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name = 'spatial_ref_sys'
  AND grantee IN ('anon', 'authenticated')
ORDER BY 1, 2;
SQL
INNER
