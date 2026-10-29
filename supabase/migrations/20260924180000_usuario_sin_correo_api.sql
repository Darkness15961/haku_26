-- Oculta correo de perfiles ajenos vía privilegios de columna.
-- Embebidos (nick/foto) siguen. Updates de ficha propios OK. No toca Bunny.

REVOKE ALL ON TABLE public.usuario FROM anon, authenticated;

GRANT SELECT (
  id,
  nombres,
  apellidos,
  nombre_nick,
  foto_perfil,
  estado,
  nacionalidad_id,
  fecha_registro
) ON TABLE public.usuario TO authenticated;

GRANT SELECT (
  id,
  nombre_nick,
  foto_perfil
) ON TABLE public.usuario TO anon;

GRANT UPDATE (
  nombres,
  apellidos,
  nombre_nick,
  foto_perfil,
  nacionalidad_id,
  estado
) ON TABLE public.usuario TO authenticated;

COMMENT ON TABLE public.usuario IS
  'Perfil. correo no otorgado a anon/authenticated; cliente usa auth.email.';
