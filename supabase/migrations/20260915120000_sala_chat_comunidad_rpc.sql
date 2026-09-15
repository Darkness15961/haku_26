-- Chat sostenible (comunidad): grants + RPC + sync participantes + CHECK texto.
-- Append-only. No DROP de datos de producto (sala/mensaje ya existen en 15094013).

-- ---------------------------------------------------------------------------
-- 1) Enums usables desde el cliente authenticated
-- ---------------------------------------------------------------------------

GRANT USAGE ON TYPE public.tipo_mensaje_chat TO authenticated, anon, service_role;
GRANT USAGE ON TYPE public.tipo_sala_chat TO authenticated, anon, service_role;

-- ---------------------------------------------------------------------------
-- 2) CHECK contenido mensaje (1..2000, trim no vacío)
-- ---------------------------------------------------------------------------

ALTER TABLE public.mensaje
  DROP CONSTRAINT IF EXISTS mensaje_contenido_valido;

ALTER TABLE public.mensaje
  ADD CONSTRAINT mensaje_contenido_valido
  CHECK (
    char_length(btrim(contenido)) >= 1
    AND char_length(contenido) <= 2000
  );

COMMENT ON CONSTRAINT mensaje_contenido_valido ON public.mensaje IS
  'Texto no vacío (trim) y máximo 2000 caracteres.';

-- ---------------------------------------------------------------------------
-- 3) UPDATE propia ultima_lectura en sala_participante
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS sala_participante_update_propia ON public.sala_participante;
CREATE POLICY sala_participante_update_propia ON public.sala_participante
  FOR UPDATE TO authenticated
  USING (usuario_id = auth.uid())
  WITH CHECK (usuario_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 4) RPC: crear/obtener sala de comunidad + sync miembros aprobados
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.asegurar_sala_comunidad(p_comunidad_id bigint)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_sala_id bigint;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No autenticado'
      USING ERRCODE = '42501';
  END IF;

  IF NOT (
    public.es_miembro_comunidad_aprobado(p_comunidad_id)
    OR public.es_admin_comunidad(p_comunidad_id)
  ) THEN
    RAISE EXCEPTION 'Sin acceso a esta comunidad'
      USING ERRCODE = '42501';
  END IF;

  SELECT s.id
    INTO v_sala_id
  FROM public.sala_chat s
  WHERE s.tipo = 'comunidad'::public.tipo_sala_chat
    AND s.comunidad_id = p_comunidad_id
  LIMIT 1;

  IF v_sala_id IS NULL THEN
    INSERT INTO public.sala_chat (comunidad_id, tipo, estado)
    VALUES (
      p_comunidad_id,
      'comunidad'::public.tipo_sala_chat,
      true
    )
    RETURNING id INTO v_sala_id;
  END IF;

  -- Sync miembros aprobados → participantes de la sala.
  INSERT INTO public.sala_participante (sala_id, usuario_id)
  SELECT v_sala_id, m.usuario_id
  FROM public.comunidad_miembro m
  WHERE m.comunidad_id = p_comunidad_id
    AND m.estado = 'aprobado'::public.estado_membresia
  ON CONFLICT DO NOTHING;

  -- Creador/admin sin fila miembro (edge): asegura al caller.
  INSERT INTO public.sala_participante (sala_id, usuario_id)
  VALUES (v_sala_id, auth.uid())
  ON CONFLICT DO NOTHING;

  RETURN v_sala_id;
END;
$$;

REVOKE ALL ON FUNCTION public.asegurar_sala_comunidad(bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.asegurar_sala_comunidad(bigint)
  TO authenticated, service_role;

COMMENT ON FUNCTION public.asegurar_sala_comunidad(bigint) IS
  'Idempotente: sala tipo=comunidad + sync sala_participante de miembros aprobados. Solo miembro/admin.';

-- ---------------------------------------------------------------------------
-- 5) Trigger: al aprobar membresía → entrar a sala (si ya existe)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_sala_on_miembro_aprobado()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_sala_id bigint;
BEGIN
  IF NEW.estado IS DISTINCT FROM 'aprobado'::public.estado_membresia THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'UPDATE'
     AND OLD.estado = 'aprobado'::public.estado_membresia THEN
    RETURN NEW;
  END IF;

  SELECT s.id
    INTO v_sala_id
  FROM public.sala_chat s
  WHERE s.tipo = 'comunidad'::public.tipo_sala_chat
    AND s.comunidad_id = NEW.comunidad_id
  LIMIT 1;

  IF v_sala_id IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.sala_participante (sala_id, usuario_id)
  VALUES (v_sala_id, NEW.usuario_id)
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sala_on_miembro_aprobado ON public.comunidad_miembro;
CREATE TRIGGER trg_sala_on_miembro_aprobado
  AFTER INSERT OR UPDATE OF estado ON public.comunidad_miembro
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_sala_on_miembro_aprobado();

REVOKE ALL ON FUNCTION public.fn_sala_on_miembro_aprobado() FROM PUBLIC;

-- ---------------------------------------------------------------------------
-- 6) Trigger: al salir / DELETE miembro → salir de sala comunidad
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_sala_on_miembro_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_sala_id bigint;
BEGIN
  SELECT s.id
    INTO v_sala_id
  FROM public.sala_chat s
  WHERE s.tipo = 'comunidad'::public.tipo_sala_chat
    AND s.comunidad_id = OLD.comunidad_id
  LIMIT 1;

  IF v_sala_id IS NULL THEN
    RETURN OLD;
  END IF;

  DELETE FROM public.sala_participante
  WHERE sala_id = v_sala_id
    AND usuario_id = OLD.usuario_id;

  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_sala_on_miembro_delete ON public.comunidad_miembro;
CREATE TRIGGER trg_sala_on_miembro_delete
  AFTER DELETE ON public.comunidad_miembro
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_sala_on_miembro_delete();

REVOKE ALL ON FUNCTION public.fn_sala_on_miembro_delete() FROM PUBLIC;
