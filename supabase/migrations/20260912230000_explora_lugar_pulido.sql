-- Pulido Explora (antes de integrar Flutter):
-- 1) lugar: provincia_id obligatorio + distrito_id opcional + ficha (dificultad/tiempo/acceso)
-- 2) códigos estables en geo (match assets frontend: urubamba, la_convencion, …)
-- 3) seed Cusco + 13 provincias + distritos + categorías tipo=lugar
-- 4) RLS lectura catálogo / lugares activos; escritura solo dueño
--
-- Categorías: una sola tabla `categoria` con columna `tipo`.
-- Ahora solo 'lugar'. Luego se pueden añadir 'ruta' / 'actividad' sin otra tabla de "tipos".

-- ---------------------------------------------------------------------------
-- 1. Códigos en catálogo geo
-- ---------------------------------------------------------------------------
ALTER TABLE public.departamento
  ADD COLUMN IF NOT EXISTS codigo character varying(32);

ALTER TABLE public.provincia
  ADD COLUMN IF NOT EXISTS codigo character varying(32);

ALTER TABLE public.distrito
  ADD COLUMN IF NOT EXISTS codigo character varying(64);

CREATE UNIQUE INDEX IF NOT EXISTS uq_departamento_codigo
  ON public.departamento (codigo)
  WHERE codigo IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_provincia_departamento_codigo
  ON public.provincia (departamento_id, codigo)
  WHERE codigo IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_distrito_provincia_codigo
  ON public.distrito (provincia_id, codigo)
  WHERE codigo IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_categoria_nombre_tipo
  ON public.categoria (nombre, tipo);

-- ---------------------------------------------------------------------------
-- 2. Lugar: territorio + ficha UI
-- ---------------------------------------------------------------------------
ALTER TABLE public.lugar
  ADD COLUMN IF NOT EXISTS provincia_id integer;

ALTER TABLE public.lugar
  ADD COLUMN IF NOT EXISTS dificultad public.dificultad_nivel NOT NULL DEFAULT 'moderado'::public.dificultad_nivel;

ALTER TABLE public.lugar
  ADD COLUMN IF NOT EXISTS tiempo_estimado character varying(80);

ALTER TABLE public.lugar
  ADD COLUMN IF NOT EXISTS acceso character varying(80);

-- distrito deja de ser obligatorio (registrar sin ubigeo exacto)
ALTER TABLE public.lugar
  ALTER COLUMN distrito_id DROP NOT NULL;

-- Si ya hubiera filas con distrito, rellenar provincia_id desde el distrito
UPDATE public.lugar l
SET provincia_id = d.provincia_id
FROM public.distrito d
WHERE l.distrito_id = d.id
  AND l.provincia_id IS NULL;

ALTER TABLE public.lugar
  DROP CONSTRAINT IF EXISTS lugar_provincia_id_fkey;

ALTER TABLE public.lugar
  ADD CONSTRAINT lugar_provincia_id_fkey
  FOREIGN KEY (provincia_id) REFERENCES public.provincia(id) ON DELETE RESTRICT;

-- provincia_id será NOT NULL tras el seed (si la tabla está vacía, ok ahora)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.lugar WHERE provincia_id IS NULL) THEN
    ALTER TABLE public.lugar ALTER COLUMN provincia_id SET NOT NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_lugar_provincia_id ON public.lugar (provincia_id);

-- Coherencia: si hay distrito, debe ser de la misma provincia
CREATE OR REPLACE FUNCTION public.fn_lugar_distrito_misma_provincia()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $function$
DECLARE
  v_provincia integer;
BEGIN
  IF NEW.distrito_id IS NULL THEN
    RETURN NEW;
  END IF;
  SELECT d.provincia_id INTO v_provincia
  FROM public.distrito d
  WHERE d.id = NEW.distrito_id;
  IF v_provincia IS NULL THEN
    RAISE EXCEPTION 'distrito_id % no existe', NEW.distrito_id;
  END IF;
  IF NEW.provincia_id IS DISTINCT FROM v_provincia THEN
    RAISE EXCEPTION 'El distrito no pertenece a la provincia del lugar';
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_lugar_distrito_misma_provincia ON public.lugar;
CREATE TRIGGER trg_lugar_distrito_misma_provincia
  BEFORE INSERT OR UPDATE OF provincia_id, distrito_id
  ON public.lugar
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_lugar_distrito_misma_provincia();

-- ---------------------------------------------------------------------------
-- 3. Seed departamento Cusco + 13 provincias (codigos = ids del frontend)
-- ---------------------------------------------------------------------------
INSERT INTO public.departamento (nombre, descripcion, codigo)
SELECT 'Cusco', 'Departamento de Cusco — MVP Haku', 'cusco'
WHERE NOT EXISTS (
  SELECT 1 FROM public.departamento d WHERE d.codigo = 'cusco'
);

INSERT INTO public.provincia (nombre, descripcion, departamento_id, codigo)
SELECT v.nombre, v.descripcion, d.id, v.codigo
FROM public.departamento d
CROSS JOIN (
  VALUES
    ('Cusco', 'Provincia de Cusco', 'cusco'),
    ('Urubamba', 'Provincia de Urubamba', 'urubamba'),
    ('Calca', 'Provincia de Calca', 'calca'),
    ('Anta', 'Provincia de Anta', 'anta'),
    ('Quispicanchi', 'Provincia de Quispicanchi', 'quispicanchi'),
    ('Paucartambo', 'Provincia de Paucartambo', 'paucartambo'),
    ('La Convención', 'Provincia de La Convención', 'la_convencion'),
    ('Canas', 'Provincia de Canas', 'canas'),
    ('Canchis', 'Provincia de Canchis', 'canchis'),
    ('Acomayo', 'Provincia de Acomayo', 'acomayo'),
    ('Paruro', 'Provincia de Paruro', 'paruro'),
    ('Chumbivilcas', 'Provincia de Chumbivilcas', 'chumbivilcas'),
    ('Espinar', 'Provincia de Espinar', 'espinar')
) AS v(nombre, descripcion, codigo)
WHERE d.codigo = 'cusco'
  AND NOT EXISTS (
    SELECT 1 FROM public.provincia p
    WHERE p.departamento_id = d.id AND p.codigo = v.codigo
  );

-- ---------------------------------------------------------------------------
-- 4. Seed distritos (ubigeo referencial Cusco; codigo = slug)
-- ---------------------------------------------------------------------------
INSERT INTO public.distrito (nombre, provincia_id, codigo)
SELECT v.nombre, p.id, v.codigo
FROM (
  VALUES
    -- Cusco
    ('cusco', 'Cusco', 'cusco'),
    ('cusco', 'Ccorca', 'ccorca'),
    ('cusco', 'Poroy', 'poroy'),
    ('cusco', 'San Jerónimo', 'san_jeronimo'),
    ('cusco', 'San Sebastián', 'san_sebastian'),
    ('cusco', 'Santiago', 'santiago'),
    ('cusco', 'Saylla', 'saylla'),
    ('cusco', 'Wanchaq', 'wanchaq'),
    -- Urubamba
    ('urubamba', 'Urubamba', 'urubamba'),
    ('urubamba', 'Chinchero', 'chinchero'),
    ('urubamba', 'Huayllabamba', 'huayllabamba'),
    ('urubamba', 'Machupicchu', 'machupicchu'),
    ('urubamba', 'Maras', 'maras'),
    ('urubamba', 'Ollantaytambo', 'ollantaytambo'),
    ('urubamba', 'Yucay', 'yucay'),
    -- Calca
    ('calca', 'Calca', 'calca'),
    ('calca', 'Coya', 'coya'),
    ('calca', 'Lamay', 'lamay'),
    ('calca', 'Lares', 'lares'),
    ('calca', 'Pisac', 'pisac'),
    ('calca', 'San Salvador', 'san_salvador'),
    ('calca', 'Taray', 'taray'),
    ('calca', 'Yanatile', 'yanatile'),
    -- Anta
    ('anta', 'Anta', 'anta'),
    ('anta', 'Ancahuasi', 'ancahuasi'),
    ('anta', 'Cachimayo', 'cachimayo'),
    ('anta', 'Chinchaypujio', 'chinchaypujio'),
    ('anta', 'Huarocondo', 'huarocondo'),
    ('anta', 'Limatambo', 'limatambo'),
    ('anta', 'Mollepata', 'mollepata'),
    ('anta', 'Pucyura', 'pucyura'),
    ('anta', 'Zurite', 'zurite'),
    -- Quispicanchi
    ('quispicanchi', 'Urcos', 'urcos'),
    ('quispicanchi', 'Andahuaylillas', 'andahuaylillas'),
    ('quispicanchi', 'Camanti', 'camanti'),
    ('quispicanchi', 'Ccarhuayo', 'ccarhuayo'),
    ('quispicanchi', 'Ccatca', 'ccatca'),
    ('quispicanchi', 'Cusipata', 'cusipata'),
    ('quispicanchi', 'Huaro', 'huaro'),
    ('quispicanchi', 'Lucre', 'lucre'),
    ('quispicanchi', 'Marcapata', 'marcapata'),
    ('quispicanchi', 'Ocongate', 'ocongate'),
    ('quispicanchi', 'Oropesa', 'oropesa'),
    ('quispicanchi', 'Quiquijana', 'quiquijana'),
    -- Paucartambo
    ('paucartambo', 'Paucartambo', 'paucartambo'),
    ('paucartambo', 'Caicay', 'caicay'),
    ('paucartambo', 'Challabamba', 'challabamba'),
    ('paucartambo', 'Colquepata', 'colquepata'),
    ('paucartambo', 'Huancarani', 'huancarani'),
    ('paucartambo', 'Kosñipata', 'kosnipata'),
    -- La Convención
    ('la_convencion', 'Santa Ana', 'santa_ana'),
    ('la_convencion', 'Echarate', 'echarate'),
    ('la_convencion', 'Huayopata', 'huayopata'),
    ('la_convencion', 'Maranura', 'maranura'),
    ('la_convencion', 'Ocobamba', 'ocobamba'),
    ('la_convencion', 'Quellouno', 'quellouno'),
    ('la_convencion', 'Kimbiri', 'kimbiri'),
    ('la_convencion', 'Santa Teresa', 'santa_teresa'),
    ('la_convencion', 'Vilcabamba', 'vilcabamba'),
    ('la_convencion', 'Pichari', 'pichari'),
    ('la_convencion', 'Inkawasi', 'inkawasi'),
    ('la_convencion', 'Villa Virgen', 'villa_virgen'),
    ('la_convencion', 'Villa Kintiarina', 'villa_kintiarina'),
    ('la_convencion', 'Megantoni', 'megantoni'),
    -- Canas
    ('canas', 'Yanaoca', 'yanaoca'),
    ('canas', 'Checca', 'checca'),
    ('canas', 'Kunturkanki', 'kunturkanki'),
    ('canas', 'Langui', 'langui'),
    ('canas', 'Layo', 'layo'),
    ('canas', 'Pampamarca', 'pampamarca'),
    ('canas', 'Quehue', 'quehue'),
    ('canas', 'Tupac Amaru', 'tupac_amaru'),
    -- Canchis
    ('canchis', 'Sicuani', 'sicuani'),
    ('canchis', 'Checacupe', 'checacupe'),
    ('canchis', 'Combapata', 'combapata'),
    ('canchis', 'Marangani', 'marangani'),
    ('canchis', 'Pitumarca', 'pitumarca'),
    ('canchis', 'San Pablo', 'san_pablo'),
    ('canchis', 'San Pedro', 'san_pedro'),
    ('canchis', 'Tinta', 'tinta'),
    -- Acomayo
    ('acomayo', 'Acomayo', 'acomayo'),
    ('acomayo', 'Acopia', 'acopia'),
    ('acomayo', 'Acos', 'acos'),
    ('acomayo', 'Mosoc Llacta', 'mosoc_llacta'),
    ('acomayo', 'Pomacanchi', 'pomacanchi'),
    ('acomayo', 'Rondocan', 'rondocan'),
    ('acomayo', 'Sangarara', 'sangarara'),
    -- Paruro
    ('paruro', 'Paruro', 'paruro'),
    ('paruro', 'Accha', 'accha'),
    ('paruro', 'Ccapi', 'ccapi'),
    ('paruro', 'Colcha', 'colcha'),
    ('paruro', 'Huanoquite', 'huanoquite'),
    ('paruro', 'Omacha', 'omacha'),
    ('paruro', 'Paccaritambo', 'paccaritambo'),
    ('paruro', 'Pillpinto', 'pillpinto'),
    ('paruro', 'Yaurisque', 'yaurisque'),
    -- Chumbivilcas
    ('chumbivilcas', 'Santo Tomás', 'santo_tomas'),
    ('chumbivilcas', 'Capacmarca', 'capacmarca'),
    ('chumbivilcas', 'Chamaca', 'chamaca'),
    ('chumbivilcas', 'Colquemarca', 'colquemarca'),
    ('chumbivilcas', 'Livitaca', 'livitaca'),
    ('chumbivilcas', 'Llusco', 'llusco'),
    ('chumbivilcas', 'Quiñota', 'quinota'),
    ('chumbivilcas', 'Velille', 'velille'),
    -- Espinar
    ('espinar', 'Espinar', 'espinar'),
    ('espinar', 'Condoroma', 'condoroma'),
    ('espinar', 'Coporaque', 'coporaque'),
    ('espinar', 'Ocoruro', 'ocoruro'),
    ('espinar', 'Pallpata', 'pallpata'),
    ('espinar', 'Pichigua', 'pichigua'),
    ('espinar', 'Suyckutambo', 'suyckutambo'),
    ('espinar', 'Alto Pichigua', 'alto_pichigua')
) AS v(provincia_codigo, nombre, codigo)
JOIN public.provincia p ON p.codigo = v.provincia_codigo
JOIN public.departamento dep ON dep.id = p.departamento_id AND dep.codigo = 'cusco'
WHERE NOT EXISTS (
  SELECT 1 FROM public.distrito di
  WHERE di.provincia_id = p.id AND di.codigo = v.codigo
);

-- ---------------------------------------------------------------------------
-- 5. Categorías de lugar (alineadas al enum Flutter CategoriaLugar)
-- ---------------------------------------------------------------------------
INSERT INTO public.categoria (nombre, tipo)
SELECT v.nombre, 'lugar'
FROM (
  VALUES
    ('naturaleza'),
    ('cultura'),
    ('gastronomia'),
    ('aventura'),
    ('caminata'),
    ('fotografia'),
    ('misterioso'),
    ('magico')
) AS v(nombre)
WHERE NOT EXISTS (
  SELECT 1 FROM public.categoria c
  WHERE c.nombre = v.nombre AND c.tipo = 'lugar'
);

-- ---------------------------------------------------------------------------
-- 6. Grants enums (cliente)
-- ---------------------------------------------------------------------------
GRANT USAGE ON TYPE public.dificultad_nivel TO anon, authenticated, service_role;
GRANT USAGE ON TYPE public.estado_membresia TO anon, authenticated, service_role;
GRANT USAGE ON TYPE public.estado_participante TO anon, authenticated, service_role;
GRANT USAGE ON TYPE public.estado_publicacion TO anon, authenticated, service_role;
GRANT USAGE ON TYPE public.estado_salida TO anon, authenticated, service_role;
GRANT USAGE ON TYPE public.estado_video TO anon, authenticated, service_role;
GRANT USAGE ON TYPE public.rol_miembro TO anon, authenticated, service_role;
GRANT USAGE ON TYPE public.tipo_comunidad TO anon, authenticated, service_role;
GRANT USAGE ON TYPE public.tipo_multimedia TO anon, authenticated, service_role;
GRANT USAGE ON TYPE public.tipo_salida TO anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 7. RLS Explora (catálogo + lugares)
-- ---------------------------------------------------------------------------

-- Catálogo geo / categorías: lectura abierta (Explora sin login)
DROP POLICY IF EXISTS departamento_select_publico ON public.departamento;
CREATE POLICY departamento_select_publico ON public.departamento
  FOR SELECT TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS provincia_select_publico ON public.provincia;
CREATE POLICY provincia_select_publico ON public.provincia
  FOR SELECT TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS distrito_select_publico ON public.distrito;
CREATE POLICY distrito_select_publico ON public.distrito
  FOR SELECT TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS categoria_select_publico ON public.categoria;
CREATE POLICY categoria_select_publico ON public.categoria
  FOR SELECT TO anon, authenticated
  USING (true);

-- Lugar: ver activos; dueño ve los suyos (aunque inactivos)
DROP POLICY IF EXISTS lugar_select_activos_o_propios ON public.lugar;
CREATE POLICY lugar_select_activos_o_propios ON public.lugar
  FOR SELECT TO anon, authenticated
  USING (
    estado = true
    OR (auth.uid() IS NOT NULL AND usuario_id = auth.uid())
  );

DROP POLICY IF EXISTS lugar_insert_propio ON public.lugar;
CREATE POLICY lugar_insert_propio ON public.lugar
  FOR INSERT TO authenticated
  WITH CHECK (usuario_id = auth.uid());

DROP POLICY IF EXISTS lugar_update_propio ON public.lugar;
CREATE POLICY lugar_update_propio ON public.lugar
  FOR UPDATE TO authenticated
  USING (usuario_id = auth.uid())
  WITH CHECK (usuario_id = auth.uid());

DROP POLICY IF EXISTS lugar_delete_propio ON public.lugar;
CREATE POLICY lugar_delete_propio ON public.lugar
  FOR DELETE TO authenticated
  USING (usuario_id = auth.uid());

-- Categorías del lugar: lectura si el lugar es visible; escritura si eres dueño
DROP POLICY IF EXISTS lugar_categoria_select_visible ON public.lugar_categoria;
CREATE POLICY lugar_categoria_select_visible ON public.lugar_categoria
  FOR SELECT TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.lugar l
      WHERE l.id = lugar_id
        AND (
          l.estado = true
          OR (auth.uid() IS NOT NULL AND l.usuario_id = auth.uid())
        )
    )
  );

DROP POLICY IF EXISTS lugar_categoria_insert_dueno ON public.lugar_categoria;
CREATE POLICY lugar_categoria_insert_dueno ON public.lugar_categoria
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.lugar l
      WHERE l.id = lugar_id AND l.usuario_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS lugar_categoria_delete_dueno ON public.lugar_categoria;
CREATE POLICY lugar_categoria_delete_dueno ON public.lugar_categoria
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.lugar l
      WHERE l.id = lugar_id AND l.usuario_id = auth.uid()
    )
  );

COMMENT ON COLUMN public.lugar.provincia_id IS
  'Obligatorio para listar Explora por provincia (islas).';
COMMENT ON COLUMN public.lugar.distrito_id IS
  'Opcional: filtro fino / etiqueta. Si es NULL, el lugar sigue listándose por provincia.';
COMMENT ON COLUMN public.categoria.tipo IS
  'Discriminador liviano: lugar | ruta | actividad (MVP usa lugar). Sin tabla extra de tipos.';
