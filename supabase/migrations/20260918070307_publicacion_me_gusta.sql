CREATE TABLE "public"."publicacion_me_gusta" (
  "publicacion_id" bigint NOT NULL,
  "usuario_id" uuid NOT NULL,
  "fecha_creacion" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "publicacion_me_gusta_pkey" PRIMARY KEY (publicacion_id, usuario_id)
);

ALTER TABLE "public"."publicacion_me_gusta" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."publicacion_me_gusta"
  ADD CONSTRAINT "publicacion_me_gusta_publicacion_id_fkey" FOREIGN KEY (publicacion_id) REFERENCES public.publicacion(id) ON DELETE CASCADE;

ALTER TABLE "public"."publicacion_me_gusta"
  ADD CONSTRAINT "publicacion_me_gusta_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE CASCADE;

CREATE INDEX idx_publicacion_me_gusta_publicacion_id ON public.publicacion_me_gusta USING btree (publicacion_id);
CREATE INDEX idx_publicacion_me_gusta_usuario_id ON public.publicacion_me_gusta USING btree (usuario_id);

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."publicacion_me_gusta" TO "anon", "authenticated", "postgres", "service_role";

-- Policies
CREATE POLICY "Los me gusta son publicos"
ON public.publicacion_me_gusta FOR SELECT
USING (true);

CREATE POLICY "Usuarios autenticados pueden dar me gusta"
ON public.publicacion_me_gusta FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "Usuarios pueden quitar su propio me gusta"
ON public.publicacion_me_gusta FOR DELETE
TO authenticated
USING (auth.uid() = usuario_id);
