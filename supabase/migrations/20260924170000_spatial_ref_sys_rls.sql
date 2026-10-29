-- PostGIS: spatial_ref_sys está en public y PostgREST lo expone.
-- Sin RLS el linter marca Critical. Solo lectura vía API; sin escrituras desde anon/authenticated.
-- Dueño de la tabla: supabase_admin (no postgres). Aplicar como ese rol.
-- No toca funciones Bunny ni media.

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
