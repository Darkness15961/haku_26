/// Nombres de colección = tablas de `supabase/001_fase1.sql`.
/// La app local (`haku_bd_local_v1`) usa las mismas claves.
class EsquemaHaku {
  EsquemaHaku._();

  static const version = 3;

  static const perfiles = 'perfiles';
  static const clips = 'clips';
  static const publicaciones = 'publicaciones';
  static const comentarios = 'comentarios';
  static const categoriasActividad = 'categorias_actividad';
  static const comunidades = 'comunidades';
  static const miembrosComunidad = 'miembros_comunidad';
  static const interacciones = 'interacciones';
  static const lugaresCreados = 'lugares_creados';
  static const metricasUsuario = 'metricas_usuario';
  static const lugares = 'lugares';
  static const multimedia = 'multimedia';
  static const seguimientos = 'seguimientos';
  static const likesPublicacion = 'likes_publicacion';
  static const likesClip = 'likes_clip';
  static const guardadosPublicacion = 'guardados_publicacion';
  static const favoritosClip = 'favoritos_clip';
  static const favoritosRuta = 'favoritos_ruta';
  static const rutas = 'rutas';
  static const puntosRuta = 'puntos_ruta';
  static const comunidadCategorias = 'comunidad_categorias';
  static const salidas = 'salidas';
  static const gruposRuta = 'grupos_ruta';
  static const mensajesDirectos = 'mensajes_directos';
  static const inscritosSalida = 'inscritos_salida';
  static const eventosMetrica = 'eventos_metrica';
}
