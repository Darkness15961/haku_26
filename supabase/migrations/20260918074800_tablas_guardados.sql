-- Tabla lugar_guardado
CREATE TABLE "public"."lugar_guardado" (
  "lugar_id" bigint NOT NULL,
  "usuario_id" uuid NOT NULL,
  "fecha_creacion" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "lugar_guardado_pkey" PRIMARY KEY (lugar_id, usuario_id)
);
ALTER TABLE "public"."lugar_guardado" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."lugar_guardado"
  ADD CONSTRAINT "lugar_guardado_lugar_id_fkey" FOREIGN KEY (lugar_id) REFERENCES public.lugar(id) ON DELETE CASCADE;
ALTER TABLE "public"."lugar_guardado"
  ADD CONSTRAINT "lugar_guardado_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE CASCADE;
CREATE INDEX idx_lugar_guardado_usuario_id ON public.lugar_guardado USING btree (usuario_id);
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."lugar_guardado" TO "anon", "authenticated", "postgres", "service_role";

CREATE POLICY "Usuarios solo pueden ver sus lugares guardados" ON public.lugar_guardado FOR SELECT USING (auth.uid() = usuario_id);
CREATE POLICY "Usuarios pueden guardar lugares" ON public.lugar_guardado FOR INSERT TO authenticated WITH CHECK (auth.uid() = usuario_id);
CREATE POLICY "Usuarios pueden quitar lugares guardados" ON public.lugar_guardado FOR DELETE TO authenticated USING (auth.uid() = usuario_id);

CREATE OR REPLACE FUNCTION public.lugar_guardado_por_mi(lugar public.lugar)
RETURNS boolean LANGUAGE sql STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.lugar_guardado
    WHERE lugar_id = lugar.id AND usuario_id = auth.uid()
  );
$$;

-- Tabla ruta_guardada
CREATE TABLE "public"."ruta_guardada" (
  "ruta_id" bigint NOT NULL,
  "usuario_id" uuid NOT NULL,
  "fecha_creacion" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "ruta_guardada_pkey" PRIMARY KEY (ruta_id, usuario_id)
);
ALTER TABLE "public"."ruta_guardada" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."ruta_guardada"
  ADD CONSTRAINT "ruta_guardada_ruta_id_fkey" FOREIGN KEY (ruta_id) REFERENCES public.ruta(id) ON DELETE CASCADE;
ALTER TABLE "public"."ruta_guardada"
  ADD CONSTRAINT "ruta_guardada_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE CASCADE;
CREATE INDEX idx_ruta_guardada_usuario_id ON public.ruta_guardada USING btree (usuario_id);
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."ruta_guardada" TO "anon", "authenticated", "postgres", "service_role";

CREATE POLICY "Usuarios solo pueden ver sus rutas guardadas" ON public.ruta_guardada FOR SELECT USING (auth.uid() = usuario_id);
CREATE POLICY "Usuarios pueden guardar rutas" ON public.ruta_guardada FOR INSERT TO authenticated WITH CHECK (auth.uid() = usuario_id);
CREATE POLICY "Usuarios pueden quitar rutas guardadas" ON public.ruta_guardada FOR DELETE TO authenticated USING (auth.uid() = usuario_id);

CREATE OR REPLACE FUNCTION public.ruta_guardada_por_mi(ruta public.ruta)
RETURNS boolean LANGUAGE sql STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.ruta_guardada
    WHERE ruta_id = ruta.id AND usuario_id = auth.uid()
  );
$$;

-- Tabla publicacion_guardada
CREATE TABLE "public"."publicacion_guardada" (
  "publicacion_id" bigint NOT NULL,
  "usuario_id" uuid NOT NULL,
  "fecha_creacion" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "publicacion_guardada_pkey" PRIMARY KEY (publicacion_id, usuario_id)
);
ALTER TABLE "public"."publicacion_guardada" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."publicacion_guardada"
  ADD CONSTRAINT "publicacion_guardada_publicacion_id_fkey" FOREIGN KEY (publicacion_id) REFERENCES public.publicacion(id) ON DELETE CASCADE;
ALTER TABLE "public"."publicacion_guardada"
  ADD CONSTRAINT "publicacion_guardada_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE CASCADE;
CREATE INDEX idx_publicacion_guardada_usuario_id ON public.publicacion_guardada USING btree (usuario_id);
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."publicacion_guardada" TO "anon", "authenticated", "postgres", "service_role";

CREATE POLICY "Usuarios solo pueden ver sus publicaciones guardadas" ON public.publicacion_guardada FOR SELECT USING (auth.uid() = usuario_id);
CREATE POLICY "Usuarios pueden guardar publicaciones" ON public.publicacion_guardada FOR INSERT TO authenticated WITH CHECK (auth.uid() = usuario_id);
CREATE POLICY "Usuarios pueden quitar publicaciones guardadas" ON public.publicacion_guardada FOR DELETE TO authenticated USING (auth.uid() = usuario_id);

CREATE OR REPLACE FUNCTION public.publicacion_guardada_por_mi(publicacion public.publicacion)
RETURNS boolean LANGUAGE sql STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.publicacion_guardada
    WHERE publicacion_id = publicacion.id AND usuario_id = auth.uid()
  );
$$;
