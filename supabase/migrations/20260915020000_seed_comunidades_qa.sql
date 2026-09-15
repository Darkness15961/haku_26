-- Bloque 0.4 — Seed QA de comunidades (prueba).
-- Idempotente por nombre. Solo columnas reales del schema.
-- NO inventa provincia/categorías/dificultad. foto_portada = NULL (sin URLs fake).
-- NO inserta salidas ni mensajes (eso es Bloque C/D).
-- Creador = primer usuario real en public.usuario (FK obligatoria).

DO $$
DECLARE
  v_creador uuid;
  v_otro uuid;
  v_id bigint;
BEGIN
  SELECT id
  INTO v_creador
  FROM public.usuario
  ORDER BY fecha_registro NULLS LAST, id
  LIMIT 1;

  IF v_creador IS NULL THEN
    RAISE NOTICE 'Seed comunidad omitido: no hay filas en public.usuario.';
    RETURN;
  END IF;

  SELECT id
  INTO v_otro
  FROM public.usuario
  WHERE id <> v_creador
  ORDER BY fecha_registro NULLS LAST, id
  LIMIT 1;

  -- 1) Pública: trekking / altura (contexto Explora Cusco)
  IF NOT EXISTS (
    SELECT 1 FROM public.comunidad WHERE nombre = 'Trekkers Cusco'
  ) THEN
    INSERT INTO public.comunidad (
      nombre, descripcion, foto_portada, tipo, usuario_creador_id, estado
    ) VALUES (
      'Trekkers Cusco',
      'Salidas semanales, aclimatación y tips de altura en el Valle Sagrado y alrededores.',
      NULL,
      'publico'::public.tipo_comunidad,
      v_creador,
      true
    )
    RETURNING id INTO v_id;

    INSERT INTO public.comunidad_miembro (
      comunidad_id, usuario_id, rol, estado
    ) VALUES (
      v_id,
      v_creador,
      'admin'::public.rol_miembro,
      'aprobado'::public.estado_membresia
    );

    IF v_otro IS NOT NULL THEN
      INSERT INTO public.comunidad_miembro (
        comunidad_id, usuario_id, rol, estado
      ) VALUES (
        v_id,
        v_otro,
        'miembro'::public.rol_miembro,
        'aprobado'::public.estado_membresia
      );
    END IF;
  END IF;

  -- 2) Pública: fotografía andina
  IF NOT EXISTS (
    SELECT 1 FROM public.comunidad WHERE nombre = 'Fotógrafos Andinos'
  ) THEN
    INSERT INTO public.comunidad (
      nombre, descripcion, foto_portada, tipo, usuario_creador_id, estado
    ) VALUES (
      'Fotógrafos Andinos',
      'Amaneceres, niebla y color en miradores y sitios del departamento de Cusco.',
      NULL,
      'publico'::public.tipo_comunidad,
      v_creador,
      true
    )
    RETURNING id INTO v_id;

    INSERT INTO public.comunidad_miembro (
      comunidad_id, usuario_id, rol, estado
    ) VALUES (
      v_id,
      v_creador,
      'admin'::public.rol_miembro,
      'aprobado'::public.estado_membresia
    );
  END IF;

  -- 3) Privada: logística Camino Inca (para probar tipo=privado + membresía)
  IF NOT EXISTS (
    SELECT 1 FROM public.comunidad WHERE nombre = 'Ruta Inca Crew'
  ) THEN
    INSERT INTO public.comunidad (
      nombre, descripcion, foto_portada, tipo, usuario_creador_id, estado
    ) VALUES (
      'Ruta Inca Crew',
      'Preparación y logística del Camino Inca. Grupo cerrado de coordinadores.',
      NULL,
      'privado'::public.tipo_comunidad,
      v_creador,
      true
    )
    RETURNING id INTO v_id;

    INSERT INTO public.comunidad_miembro (
      comunidad_id, usuario_id, rol, estado
    ) VALUES (
      v_id,
      v_creador,
      'admin'::public.rol_miembro,
      'aprobado'::public.estado_membresia
    );
  END IF;
END $$;
