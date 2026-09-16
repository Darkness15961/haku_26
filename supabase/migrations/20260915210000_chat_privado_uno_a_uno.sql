-- Chat privado 1:1 sobre la infraestructura existente de sala_chat/mensaje.
-- La pareja vive aparte para no alterar las salas grupales ya desplegadas.

CREATE TABLE IF NOT EXISTS public.sala_privada (
  sala_id bigint PRIMARY KEY
    REFERENCES public.sala_chat(id) ON DELETE CASCADE,
  usuario_a uuid NOT NULL
    REFERENCES public.usuario(id) ON DELETE CASCADE,
  usuario_b uuid NOT NULL
    REFERENCES public.usuario(id) ON DELETE CASCADE,
  CONSTRAINT sala_privada_usuarios_distintos CHECK (usuario_a <> usuario_b),
  CONSTRAINT sala_privada_pareja_unica UNIQUE (usuario_a, usuario_b)
);

ALTER TABLE public.sala_privada ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.sala_privada FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.asegurar_sala_privada(
  p_otro_usuario_id uuid,
  p_sala_origen bigint DEFAULT NULL
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_a uuid;
  v_b uuid;
  v_sala_id bigint;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Debes iniciar sesión';
  END IF;
  IF p_otro_usuario_id IS NULL OR p_otro_usuario_id = v_uid THEN
    RAISE EXCEPTION 'Usuario inválido';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.usuario u
    WHERE u.id = p_otro_usuario_id AND COALESCE(u.estado, 'activo') = 'activo'
  ) THEN
    RAISE EXCEPTION 'El usuario ya no está disponible';
  END IF;

  IF v_uid::text < p_otro_usuario_id::text THEN
    v_a := v_uid;
    v_b := p_otro_usuario_id;
  ELSE
    v_a := p_otro_usuario_id;
    v_b := v_uid;
  END IF;

  SELECT sp.sala_id INTO v_sala_id
  FROM public.sala_privada sp
  WHERE sp.usuario_a = v_a AND sp.usuario_b = v_b;

  IF v_sala_id IS NOT NULL THEN
    INSERT INTO public.sala_participante (sala_id, usuario_id)
    VALUES (v_sala_id, v_uid), (v_sala_id, p_otro_usuario_id)
    ON CONFLICT (sala_id, usuario_id) DO NOTHING;
    RETURN v_sala_id;
  END IF;

  -- Un DM nuevo solo nace desde una comunidad/salida compartida.
  IF p_sala_origen IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.sala_chat s
    JOIN public.sala_participante yo
      ON yo.sala_id = s.id AND yo.usuario_id = v_uid
    JOIN public.sala_participante otro
      ON otro.sala_id = s.id AND otro.usuario_id = p_otro_usuario_id
    WHERE s.id = p_sala_origen
      AND s.estado = true
      AND s.tipo IN (
        'comunidad'::public.tipo_sala_chat,
        'salida'::public.tipo_sala_chat
      )
  ) THEN
    RAISE EXCEPTION 'Solo puedes iniciar el chat con alguien de este grupo';
  END IF;

  BEGIN
    INSERT INTO public.sala_chat (tipo, comunidad_id, salida_id, estado)
    VALUES ('privado'::public.tipo_sala_chat, NULL, NULL, true)
    RETURNING id INTO v_sala_id;

    INSERT INTO public.sala_privada (sala_id, usuario_a, usuario_b)
    VALUES (v_sala_id, v_a, v_b);
  EXCEPTION WHEN unique_violation THEN
    SELECT sp.sala_id INTO v_sala_id
    FROM public.sala_privada sp
    WHERE sp.usuario_a = v_a AND sp.usuario_b = v_b;
  END;

  INSERT INTO public.sala_participante (sala_id, usuario_id)
  VALUES (v_sala_id, v_uid), (v_sala_id, p_otro_usuario_id)
  ON CONFLICT (sala_id, usuario_id) DO NOTHING;

  RETURN v_sala_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.listar_chats_privados()
RETURNS TABLE (
  sala_id bigint,
  otro_usuario_id uuid,
  nombres text,
  apellidos text,
  nombre_nick text,
  foto_perfil text,
  ultimo_id bigint,
  ultimo_contenido text,
  ultimo_tipo text,
  ultimo_fecha timestamptz,
  no_leidos bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
  SELECT
    sp.sala_id,
    u.id,
    u.nombres::text,
    u.apellidos::text,
    u.nombre_nick::text,
    u.foto_perfil,
    ult.id,
    ult.contenido,
    ult.tipo_mensaje::text,
    ult.fecha_envio,
    (
      SELECT count(*)
      FROM public.mensaje m
      WHERE m.sala_id = sp.sala_id
        AND m.usuario_id <> auth.uid()
        AND m.eliminado_en IS NULL
        AND (
          me.ultima_lectura IS NULL
          OR m.fecha_envio > me.ultima_lectura
        )
    )::bigint
  FROM public.sala_privada sp
  JOIN public.sala_participante me
    ON me.sala_id = sp.sala_id AND me.usuario_id = auth.uid()
  JOIN public.usuario u
    ON u.id = CASE
      WHEN sp.usuario_a = auth.uid() THEN sp.usuario_b
      ELSE sp.usuario_a
    END
  JOIN public.sala_chat s ON s.id = sp.sala_id AND s.estado = true
  LEFT JOIN LATERAL (
    SELECT m.id, m.contenido, m.tipo_mensaje, m.fecha_envio
    FROM public.mensaje m
    WHERE m.sala_id = sp.sala_id AND m.eliminado_en IS NULL
    ORDER BY m.fecha_envio DESC, m.id DESC
    LIMIT 1
  ) ult ON true
  WHERE auth.uid() IN (sp.usuario_a, sp.usuario_b)
  ORDER BY ult.fecha_envio DESC NULLS LAST, sp.sala_id DESC;
$$;

REVOKE ALL ON FUNCTION public.asegurar_sala_privada(uuid, bigint) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.listar_chats_privados() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.asegurar_sala_privada(uuid, bigint)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.listar_chats_privados()
  TO authenticated;

COMMENT ON FUNCTION public.asegurar_sala_privada(uuid, bigint) IS
  'Obtiene o crea un DM 1:1. Para crear exige una sala grupal compartida.';
