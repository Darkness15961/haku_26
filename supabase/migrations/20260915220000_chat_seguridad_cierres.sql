-- Hardening de Mensajes: privilegios mínimos, mutabilidad controlada,
-- lectura con reloj servidor, roster atómico y adjuntos privados.

REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- ---------------------------------------------------------------------------
-- 1) Sala usable: roster + entidad activa
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.puede_usar_sala(p_sala_id bigint)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.sala_chat s
    JOIN public.sala_participante sp
      ON sp.sala_id = s.id AND sp.usuario_id = auth.uid()
    WHERE s.id = p_sala_id
      AND s.estado = true
      AND (
        s.tipo = 'privado'::public.tipo_sala_chat
        OR (
          s.tipo = 'comunidad'::public.tipo_sala_chat
          AND EXISTS (
            SELECT 1 FROM public.comunidad c
            WHERE c.id = s.comunidad_id AND c.estado = true
          )
        )
        OR (
          s.tipo = 'salida'::public.tipo_sala_chat
          AND EXISTS (
            SELECT 1 FROM public.salida sa
            WHERE sa.id = s.salida_id
              AND sa.estado IS DISTINCT FROM 'cancelada'::public.estado_salida
          )
        )
      )
  );
$$;

REVOKE ALL ON FUNCTION public.puede_usar_sala(bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.puede_usar_sala(bigint)
  TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.fn_sala_chat_validar_contexto()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
BEGIN
  IF NEW.estado AND NEW.tipo = 'comunidad'::public.tipo_sala_chat
     AND NOT EXISTS (
       SELECT 1 FROM public.comunidad c
       WHERE c.id = NEW.comunidad_id AND c.estado = true
     ) THEN
    RAISE EXCEPTION 'La comunidad no está activa';
  END IF;
  IF NEW.estado AND NEW.tipo = 'salida'::public.tipo_sala_chat
     AND NOT EXISTS (
       SELECT 1 FROM public.salida s
       WHERE s.id = NEW.salida_id
         AND s.estado IS DISTINCT FROM 'cancelada'::public.estado_salida
     ) THEN
    RAISE EXCEPTION 'La salida no está disponible';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sala_chat_validar_contexto ON public.sala_chat;
CREATE TRIGGER trg_sala_chat_validar_contexto
  BEFORE INSERT OR UPDATE ON public.sala_chat
  FOR EACH ROW EXECUTE FUNCTION public.fn_sala_chat_validar_contexto();
REVOKE ALL ON FUNCTION public.fn_sala_chat_validar_contexto() FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.sala_comunidad_id_si_existe(
  p_comunidad_id bigint
)
RETURNS bigint
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT s.id
  FROM public.sala_chat s
  WHERE s.tipo = 'comunidad'::public.tipo_sala_chat
    AND s.comunidad_id = p_comunidad_id
    AND (
      public.es_admin_comunidad(p_comunidad_id)
      OR public.es_miembro_comunidad_aprobado(p_comunidad_id)
    )
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.sala_salida_id_si_existe(p_salida_id bigint)
RETURNS bigint
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT sc.id
  FROM public.sala_chat sc
  JOIN public.salida s ON s.id = sc.salida_id
  WHERE sc.tipo = 'salida'::public.tipo_sala_chat
    AND sc.salida_id = p_salida_id
    AND (
      s.organizador_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM public.salida_participante p
        WHERE p.salida_id = p_salida_id
          AND p.usuario_id = auth.uid()
          AND p.estado = 'confirmado'::public.estado_participante
      )
    )
  LIMIT 1;
$$;

DROP POLICY IF EXISTS sala_chat_select ON public.sala_chat;
CREATE POLICY sala_chat_select ON public.sala_chat
  FOR SELECT TO authenticated
  USING (public.puede_usar_sala(id));

DROP POLICY IF EXISTS sala_participante_select ON public.sala_participante;
CREATE POLICY sala_participante_select ON public.sala_participante
  FOR SELECT TO authenticated
  USING (public.puede_usar_sala(sala_id));

DROP POLICY IF EXISTS mensaje_select ON public.mensaje;
CREATE POLICY mensaje_select ON public.mensaje
  FOR SELECT TO authenticated
  USING (public.puede_usar_sala(sala_id));

DROP POLICY IF EXISTS mensaje_insert ON public.mensaje;
CREATE POLICY mensaje_insert ON public.mensaje
  FOR INSERT TO authenticated
  WITH CHECK (
    usuario_id = auth.uid()
    AND public.puede_usar_sala(sala_id)
  );

-- El cliente ya no actualiza filas de participación ni mensajes directamente.
DROP POLICY IF EXISTS sala_participante_update_propia
  ON public.sala_participante;
DROP POLICY IF EXISTS mensaje_update_propio ON public.mensaje;

-- ---------------------------------------------------------------------------
-- 2) Columnas de auditoría inmutables + RPC de edición/borrado
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_mensaje_proteger_columnas()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF auth.uid() IS NOT NULL THEN
      NEW.usuario_id := auth.uid();
    END IF;
    NEW.fecha_envio := now();
    NEW.editado_en := NULL;
    NEW.eliminado_en := NULL;
    RETURN NEW;
  END IF;

  IF NEW.sala_id IS DISTINCT FROM OLD.sala_id
     OR NEW.usuario_id IS DISTINCT FROM OLD.usuario_id
     OR NEW.fecha_envio IS DISTINCT FROM OLD.fecha_envio
     OR NEW.tipo_mensaje IS DISTINCT FROM OLD.tipo_mensaje THEN
    RAISE EXCEPTION 'No se pueden cambiar columnas de identidad del mensaje'
      USING ERRCODE = '42501';
  END IF;

  IF OLD.eliminado_en IS NOT NULL AND NEW.eliminado_en IS NULL THEN
    RAISE EXCEPTION 'Un mensaje eliminado no se puede restaurar'
      USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_mensaje_proteger_columnas ON public.mensaje;
CREATE TRIGGER trg_mensaje_proteger_columnas
  BEFORE INSERT OR UPDATE ON public.mensaje
  FOR EACH ROW EXECUTE FUNCTION public.fn_mensaje_proteger_columnas();
REVOKE ALL ON FUNCTION public.fn_mensaje_proteger_columnas() FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.editar_mensaje_chat(
  p_mensaje_id bigint,
  p_contenido text
)
RETURNS public.mensaje
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v public.mensaje;
BEGIN
  IF char_length(btrim(COALESCE(p_contenido, ''))) < 1
     OR char_length(btrim(p_contenido)) > 2000 THEN
    RAISE EXCEPTION 'Mensaje inválido';
  END IF;
  UPDATE public.mensaje m
  SET contenido = btrim(p_contenido), editado_en = now()
  WHERE m.id = p_mensaje_id
    AND m.usuario_id = auth.uid()
    AND m.tipo_mensaje = 'texto'::public.tipo_mensaje_chat
    AND m.eliminado_en IS NULL
    AND public.puede_usar_sala(m.sala_id)
  RETURNING m.* INTO v;
  IF v.id IS NULL THEN RAISE EXCEPTION 'Mensaje no editable'; END IF;
  RETURN v;
END;
$$;

CREATE OR REPLACE FUNCTION public.eliminar_mensaje_chat(p_mensaje_id bigint)
RETURNS public.mensaje
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v public.mensaje;
BEGIN
  UPDATE public.mensaje m
  SET eliminado_en = now(), contenido = '[eliminado]'
  WHERE m.id = p_mensaje_id
    AND m.usuario_id = auth.uid()
    AND m.eliminado_en IS NULL
    AND public.puede_usar_sala(m.sala_id)
  RETURNING m.* INTO v;
  IF v.id IS NULL THEN RAISE EXCEPTION 'Mensaje no eliminable'; END IF;
  RETURN v;
END;
$$;

CREATE OR REPLACE FUNCTION public.marcar_sala_leida(p_sala_id bigint)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
BEGIN
  UPDATE public.sala_participante sp
  SET ultima_lectura = now()
  WHERE sp.sala_id = p_sala_id
    AND sp.usuario_id = auth.uid()
    AND public.puede_usar_sala(sp.sala_id);
END;
$$;

-- ---------------------------------------------------------------------------
-- 3) Reacciones vivas y sala derivada siempre desde mensaje
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mensaje_reaccionable(
  p_mensaje_id bigint,
  p_sala_id bigint
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.mensaje m
    WHERE m.id = p_mensaje_id
      AND m.sala_id = p_sala_id
      AND m.eliminado_en IS NULL
      AND public.puede_usar_sala(m.sala_id)
  );
$$;

DROP TRIGGER IF EXISTS trg_mensaje_reaccion_set_sala
  ON public.mensaje_reaccion;
CREATE TRIGGER trg_mensaje_reaccion_set_sala
  BEFORE INSERT OR UPDATE ON public.mensaje_reaccion
  FOR EACH ROW EXECUTE FUNCTION public.fn_mensaje_reaccion_set_sala();

DROP POLICY IF EXISTS mensaje_reaccion_select ON public.mensaje_reaccion;
CREATE POLICY mensaje_reaccion_select ON public.mensaje_reaccion
  FOR SELECT TO authenticated
  USING (public.puede_usar_sala(sala_id));

DROP POLICY IF EXISTS mensaje_reaccion_insert ON public.mensaje_reaccion;
CREATE POLICY mensaje_reaccion_insert ON public.mensaje_reaccion
  FOR INSERT TO authenticated
  WITH CHECK (
    usuario_id = auth.uid()
    AND public.mensaje_reaccionable(mensaje_id, sala_id)
  );

DROP POLICY IF EXISTS mensaje_reaccion_update ON public.mensaje_reaccion;
CREATE POLICY mensaje_reaccion_update ON public.mensaje_reaccion
  FOR UPDATE TO authenticated
  USING (usuario_id = auth.uid())
  WITH CHECK (
    usuario_id = auth.uid()
    AND public.mensaje_reaccionable(mensaje_id, sala_id)
  );

DROP POLICY IF EXISTS mensaje_reaccion_delete ON public.mensaje_reaccion;
CREATE POLICY mensaje_reaccion_delete ON public.mensaje_reaccion
  FOR DELETE TO authenticated
  USING (
    usuario_id = auth.uid()
    AND public.puede_usar_sala(sala_id)
  );

-- ---------------------------------------------------------------------------
-- 4) Creación + selección de roster en una sola transacción RPC
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.crear_sala_comunidad_con_participantes(
  p_comunidad_id bigint,
  p_participantes uuid[]
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE v_sala bigint;
BEGIN
  v_sala := public.asegurar_sala_comunidad(p_comunidad_id, false);
  PERFORM public.sala_comunidad_set_participantes_batch(
    v_sala, COALESCE(p_participantes, ARRAY[]::uuid[]), ARRAY[]::uuid[]
  );
  RETURN v_sala;
END;
$$;

CREATE OR REPLACE FUNCTION public.crear_sala_salida_con_participantes(
  p_salida_id bigint,
  p_participantes uuid[]
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE v_sala bigint;
BEGIN
  v_sala := public.asegurar_sala_salida(p_salida_id, false);
  PERFORM public.sala_salida_set_participantes_batch(
    v_sala, COALESCE(p_participantes, ARRAY[]::uuid[]), ARRAY[]::uuid[]
  );
  RETURN v_sala;
END;
$$;

-- ---------------------------------------------------------------------------
-- 5) Evitar huérfanos privados: usuarios se dan de baja lógicamente
-- ---------------------------------------------------------------------------
ALTER TABLE public.sala_privada
  DROP CONSTRAINT IF EXISTS sala_privada_usuario_a_fkey,
  DROP CONSTRAINT IF EXISTS sala_privada_usuario_b_fkey;
ALTER TABLE public.sala_privada
  ADD CONSTRAINT sala_privada_usuario_a_fkey
    FOREIGN KEY (usuario_a) REFERENCES public.usuario(id) ON DELETE RESTRICT,
  ADD CONSTRAINT sala_privada_usuario_b_fkey
    FOREIGN KEY (usuario_b) REFERENCES public.usuario(id) ON DELETE RESTRICT;

-- ---------------------------------------------------------------------------
-- 6) Privilegios mínimos
-- ---------------------------------------------------------------------------
REVOKE ALL ON TABLE public.mensaje FROM anon, authenticated;
REVOKE ALL ON TABLE public.sala_chat FROM anon, authenticated;
REVOKE ALL ON TABLE public.sala_participante FROM anon, authenticated;
REVOKE ALL ON TABLE public.mensaje_reaccion FROM anon, authenticated;

GRANT SELECT, INSERT ON TABLE public.mensaje TO authenticated;
GRANT SELECT ON TABLE public.sala_chat TO authenticated;
GRANT SELECT ON TABLE public.sala_participante TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON TABLE public.mensaje_reaccion TO authenticated;

REVOKE ALL ON FUNCTION public.editar_mensaje_chat(bigint, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.eliminar_mensaje_chat(bigint) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.marcar_sala_leida(bigint) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.mensaje_reaccionable(bigint, bigint) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.crear_sala_comunidad_con_participantes(bigint, uuid[])
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.crear_sala_salida_con_participantes(bigint, uuid[])
  FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.editar_mensaje_chat(bigint, text),
  public.eliminar_mensaje_chat(bigint),
  public.marcar_sala_leida(bigint),
  public.mensaje_reaccionable(bigint, bigint),
  public.crear_sala_comunidad_con_participantes(bigint, uuid[]),
  public.crear_sala_salida_con_participantes(bigint, uuid[])
  TO authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 7) Bucket privado de adjuntos
-- ---------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('haku-chat-privado', 'haku-chat-privado', false)
ON CONFLICT (id) DO UPDATE SET public = false;

CREATE OR REPLACE FUNCTION public.puede_acceder_objeto_chat(p_name text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE v_sala_text text := split_part(p_name, '/', 2);
BEGIN
  IF v_sala_text !~ '^[0-9]+$' THEN RETURN false; END IF;
  RETURN public.puede_usar_sala(v_sala_text::bigint);
END;
$$;

REVOKE ALL ON FUNCTION public.puede_acceder_objeto_chat(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.puede_acceder_objeto_chat(text)
  TO authenticated, service_role;

DROP POLICY IF EXISTS chat_privado_select ON storage.objects;
CREATE POLICY chat_privado_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'haku-chat-privado'
    AND public.puede_acceder_objeto_chat(name)
  );

DROP POLICY IF EXISTS chat_privado_insert ON storage.objects;
CREATE POLICY chat_privado_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'haku-chat-privado'
    AND split_part(name, '/', 1) = auth.uid()::text
    AND public.puede_acceder_objeto_chat(name)
  );

DROP POLICY IF EXISTS chat_privado_delete ON storage.objects;
CREATE POLICY chat_privado_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'haku-chat-privado'
    AND split_part(name, '/', 1) = auth.uid()::text
    AND public.puede_acceder_objeto_chat(name)
  );
