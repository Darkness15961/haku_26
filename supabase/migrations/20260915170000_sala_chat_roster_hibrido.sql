-- Roster híbrido coherente + privacidad soft-delete + reacciones filtrables.
-- Append-only sobre 15160000.
-- Modelo: membresía ≠ roster. Opt-in al chat (picker / sync SOLO al crear sala).

-- ---------------------------------------------------------------------------
-- 1) asegurar_sala_comunidad: sync masivo SOLO en creación; luego no re-seed
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.asegurar_sala_comunidad(p_comunidad_id bigint)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_sala_id bigint;
  v_es_admin boolean;
  v_es_miembro boolean;
  v_ya_participa boolean;
  v_creada boolean := false;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No autenticado'
      USING ERRCODE = '42501';
  END IF;

  v_es_admin := public.es_admin_comunidad(p_comunidad_id);
  v_es_miembro := public.es_miembro_comunidad_aprobado(p_comunidad_id);

  IF NOT (v_es_admin OR v_es_miembro) THEN
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
    IF NOT v_es_admin THEN
      RAISE EXCEPTION 'Solo admin puede crear el chat de la comunidad'
        USING ERRCODE = '42501';
    END IF;
    INSERT INTO public.sala_chat (comunidad_id, tipo, estado)
    VALUES (
      p_comunidad_id,
      'comunidad'::public.tipo_sala_chat,
      true
    )
    RETURNING id INTO v_sala_id;
    v_creada := true;
  END IF;

  IF v_es_admin THEN
    -- Solo al CREAR: seed inicial de aprobados. Después el roster es del picker.
    IF v_creada THEN
      INSERT INTO public.sala_participante (sala_id, usuario_id)
      SELECT v_sala_id, m.usuario_id
      FROM public.comunidad_miembro m
      WHERE m.comunidad_id = p_comunidad_id
        AND m.estado = 'aprobado'::public.estado_membresia
      ON CONFLICT DO NOTHING;
    END IF;

    -- Admin siempre puede entrar (sin reintroducir a quienes sacó).
    INSERT INTO public.sala_participante (sala_id, usuario_id)
    VALUES (v_sala_id, auth.uid())
    ON CONFLICT DO NOTHING;

    RETURN v_sala_id;
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM public.sala_participante sp
    WHERE sp.sala_id = v_sala_id
      AND sp.usuario_id = auth.uid()
  ) INTO v_ya_participa;

  IF NOT v_ya_participa THEN
    RAISE EXCEPTION 'No estás en el chat de esta comunidad'
      USING ERRCODE = '42501';
  END IF;

  RETURN v_sala_id;
END;
$$;

COMMENT ON FUNCTION public.asegurar_sala_comunidad(bigint) IS
  'Admin crea sala (seed aprobados solo al crear). Abrir luego no re-syncéa roster. Miembro solo si está en sala_participante.';

-- ---------------------------------------------------------------------------
-- 2) Membresía deja de ser aprobada → sale del chat (bloqueado/rechazado/…)
--    Aprobar ya NO mete solo al chat (opt-in / picker).
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_sala_on_miembro_estado_chat()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_sala_id bigint;
BEGIN
  IF TG_OP = 'UPDATE'
     AND OLD.estado = 'aprobado'::public.estado_membresia
     AND NEW.estado IS DISTINCT FROM 'aprobado'::public.estado_membresia THEN
    SELECT s.id
      INTO v_sala_id
    FROM public.sala_chat s
    WHERE s.tipo = 'comunidad'::public.tipo_sala_chat
      AND s.comunidad_id = NEW.comunidad_id
    LIMIT 1;

    IF v_sala_id IS NOT NULL THEN
      DELETE FROM public.sala_participante
      WHERE sala_id = v_sala_id
        AND usuario_id = NEW.usuario_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sala_on_miembro_aprobado ON public.comunidad_miembro;
DROP TRIGGER IF EXISTS trg_sala_on_miembro_estado_chat ON public.comunidad_miembro;

CREATE TRIGGER trg_sala_on_miembro_estado_chat
  AFTER UPDATE OF estado ON public.comunidad_miembro
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_sala_on_miembro_estado_chat();

REVOKE ALL ON FUNCTION public.fn_sala_on_miembro_estado_chat() FROM PUBLIC;

COMMENT ON FUNCTION public.fn_sala_on_miembro_estado_chat() IS
  'Si deja de estar aprobado → sale de sala_participante. No auto-alta al aprobar (roster híbrido).';

-- Función vieja queda no-op por si quedó referenciada en entornos intermedios.
CREATE OR REPLACE FUNCTION public.fn_sala_on_miembro_aprobado()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
BEGIN
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- 3) set_participante / batch: creador elegible; no auto-quitar al caller
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.sala_comunidad_set_participante(
  p_sala_id bigint,
  p_usuario_id uuid,
  p_activo boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_comunidad_id bigint;
  v_creador uuid;
  v_elegible boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No autenticado'
      USING ERRCODE = '42501';
  END IF;

  SELECT s.comunidad_id
    INTO v_comunidad_id
  FROM public.sala_chat s
  WHERE s.id = p_sala_id
    AND s.tipo = 'comunidad'::public.tipo_sala_chat
    AND s.estado = true;

  IF v_comunidad_id IS NULL THEN
    RAISE EXCEPTION 'Sala de comunidad no encontrada'
      USING ERRCODE = 'P0002';
  END IF;

  IF NOT public.es_admin_comunidad(v_comunidad_id) THEN
    RAISE EXCEPTION 'Solo admin puede gestionar el chat'
      USING ERRCODE = '42501';
  END IF;

  IF p_activo THEN
    SELECT c.usuario_creador_id
      INTO v_creador
    FROM public.comunidad c
    WHERE c.id = v_comunidad_id;

    v_elegible := (v_creador IS NOT NULL AND v_creador = p_usuario_id)
      OR EXISTS (
        SELECT 1
        FROM public.comunidad_miembro m
        WHERE m.comunidad_id = v_comunidad_id
          AND m.usuario_id = p_usuario_id
          AND m.estado = 'aprobado'::public.estado_membresia
      );

    IF NOT v_elegible THEN
      RAISE EXCEPTION 'El usuario debe ser miembro aprobado o el creador'
        USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO public.sala_participante (sala_id, usuario_id)
    VALUES (p_sala_id, p_usuario_id)
    ON CONFLICT DO NOTHING;
  ELSE
    IF p_usuario_id = auth.uid() THEN
      RAISE EXCEPTION 'No podés quitarte del chat'
        USING ERRCODE = 'P0001';
    END IF;

    DELETE FROM public.sala_participante
    WHERE sala_id = p_sala_id
      AND usuario_id = p_usuario_id;
  END IF;
END;
$$;

COMMENT ON FUNCTION public.sala_comunidad_set_participante(bigint, uuid, boolean) IS
  'Admin alta/baja roster. Creador elegible sin fila miembro. No auto-quita al caller.';

CREATE OR REPLACE FUNCTION public.sala_comunidad_set_participantes_batch(
  p_sala_id bigint,
  p_agregar uuid[],
  p_quitar uuid[]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_comunidad_id bigint;
  v_creador uuid;
  v_uid uuid;
  v_elegible boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No autenticado'
      USING ERRCODE = '42501';
  END IF;

  SELECT s.comunidad_id
    INTO v_comunidad_id
  FROM public.sala_chat s
  WHERE s.id = p_sala_id
    AND s.tipo = 'comunidad'::public.tipo_sala_chat
    AND s.estado = true;

  IF v_comunidad_id IS NULL THEN
    RAISE EXCEPTION 'Sala de comunidad no encontrada'
      USING ERRCODE = 'P0002';
  END IF;

  IF NOT public.es_admin_comunidad(v_comunidad_id) THEN
    RAISE EXCEPTION 'Solo admin puede gestionar el chat'
      USING ERRCODE = '42501';
  END IF;

  SELECT c.usuario_creador_id
    INTO v_creador
  FROM public.comunidad c
  WHERE c.id = v_comunidad_id;

  IF p_agregar IS NOT NULL THEN
    FOREACH v_uid IN ARRAY p_agregar
    LOOP
      v_elegible := (v_creador IS NOT NULL AND v_creador = v_uid)
        OR EXISTS (
          SELECT 1
          FROM public.comunidad_miembro m
          WHERE m.comunidad_id = v_comunidad_id
            AND m.usuario_id = v_uid
            AND m.estado = 'aprobado'::public.estado_membresia
        );
      IF v_elegible THEN
        INSERT INTO public.sala_participante (sala_id, usuario_id)
        VALUES (p_sala_id, v_uid)
        ON CONFLICT DO NOTHING;
      END IF;
    END LOOP;
  END IF;

  IF p_quitar IS NOT NULL THEN
    FOREACH v_uid IN ARRAY p_quitar
    LOOP
      IF v_uid = auth.uid() THEN
        CONTINUE;
      END IF;
      DELETE FROM public.sala_participante
      WHERE sala_id = p_sala_id
        AND usuario_id = v_uid;
    END LOOP;
  END IF;
END;
$$;

COMMENT ON FUNCTION public.sala_comunidad_set_participantes_batch(bigint, uuid[], uuid[]) IS
  'Admin batch roster. Creador elegible. No auto-quita al admin caller.';

-- ---------------------------------------------------------------------------
-- 4) Soft-delete: redactar contenido en el mismo UPDATE (no solo flag)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_mensaje_soft_delete_redact()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
BEGIN
  IF NEW.eliminado_en IS NOT NULL
     AND (OLD.eliminado_en IS NULL)
  THEN
    NEW.contenido := '[eliminado]';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_mensaje_soft_delete_redact ON public.mensaje;
CREATE TRIGGER trg_mensaje_soft_delete_redact
  BEFORE UPDATE OF eliminado_en ON public.mensaje
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_mensaje_soft_delete_redact();

REVOKE ALL ON FUNCTION public.fn_mensaje_soft_delete_redact() FROM PUBLIC;

COMMENT ON FUNCTION public.fn_mensaje_soft_delete_redact() IS
  'Al marcar eliminado_en, redacta contenido a [eliminado] (texto/url/json).';

-- ---------------------------------------------------------------------------
-- 5) mensaje_reaccion.sala_id denormalizado → Realtime filtrable por sala
-- ---------------------------------------------------------------------------

ALTER TABLE public.mensaje_reaccion
  ADD COLUMN IF NOT EXISTS sala_id bigint;

UPDATE public.mensaje_reaccion r
SET sala_id = m.sala_id
FROM public.mensaje m
WHERE r.mensaje_id = m.id
  AND (r.sala_id IS NULL OR r.sala_id IS DISTINCT FROM m.sala_id);

ALTER TABLE public.mensaje_reaccion
  DROP CONSTRAINT IF EXISTS mensaje_reaccion_sala_id_fkey;

ALTER TABLE public.mensaje_reaccion
  ADD CONSTRAINT mensaje_reaccion_sala_id_fkey
  FOREIGN KEY (sala_id) REFERENCES public.sala_chat(id) ON DELETE CASCADE;

-- Filas huérfanas no deberían existir; si quedan null, borrarlas.
DELETE FROM public.mensaje_reaccion WHERE sala_id IS NULL;

ALTER TABLE public.mensaje_reaccion
  ALTER COLUMN sala_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_mensaje_reaccion_sala
  ON public.mensaje_reaccion (sala_id);

CREATE OR REPLACE FUNCTION public.fn_mensaje_reaccion_set_sala()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
BEGIN
  SELECT m.sala_id
    INTO NEW.sala_id
  FROM public.mensaje m
  WHERE m.id = NEW.mensaje_id;

  IF NEW.sala_id IS NULL THEN
    RAISE EXCEPTION 'Mensaje no encontrado para reacción'
      USING ERRCODE = 'P0002';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_mensaje_reaccion_set_sala ON public.mensaje_reaccion;
CREATE TRIGGER trg_mensaje_reaccion_set_sala
  BEFORE INSERT OR UPDATE OF mensaje_id ON public.mensaje_reaccion
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_mensaje_reaccion_set_sala();

REVOKE ALL ON FUNCTION public.fn_mensaje_reaccion_set_sala() FROM PUBLIC;

COMMENT ON COLUMN public.mensaje_reaccion.sala_id IS
  'Denormalizado desde mensaje.sala_id para filtrar Realtime por sala.';
