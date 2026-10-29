-- Los dos helpers son SECURITY DEFINER y sus cuerpos ya usan nombres de tabla
-- totalmente calificados. Fijar search_path vacio elimina el riesgo de que un
-- objeto homonimo intercepte referencias futuras.
ALTER FUNCTION public.fn_encolar_media_eliminada()
  SET search_path = '';
ALTER FUNCTION public.fn_publicacion_soft_delete_media()
  SET search_path = '';

-- Son funciones de trigger: no forman parte de la API RPC publica.
REVOKE ALL ON FUNCTION public.fn_encolar_media_eliminada()
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_publicacion_soft_delete_media()
  FROM PUBLIC, anon, authenticated;

COMMENT ON FUNCTION public.fn_encolar_media_eliminada() IS
  'Trigger interno del outbox de medios; search_path fijo y sin EXECUTE publico.';
COMMENT ON FUNCTION public.fn_publicacion_soft_delete_media() IS
  'Trigger interno de soft-delete; search_path fijo y sin EXECUTE publico.';
