/// Imágenes empaquetadas en la app — siempre cargan sin red.
abstract final class CatalogoImagenesHaku {
  static const machuPicchu = 'assets/destinos/machu_picchu.jpg';
  static const moray = 'assets/destinos/moray.jpg';
  static const ausangate = 'assets/destinos/ausangate.jpg';
  static const llamaMachu = 'assets/destinos/llama_machu.jpg';
  static const huacachina = 'assets/destinos/huacachina.jpg';

  static const fondoExplora = 'public/image/fondo_explora.jpg';
  static const fondoPublicaciones = 'public/image/fondo_publicaciones.jpg';
  static const fondoRutas = 'public/image/fondo_rutas.jpg';
  static const encabezadoRutas = 'public/image/encabezado_rutas.jpg';
  static const adornoRutas = 'public/image/adorno_rutas.jpg';
  static const detalleRutaB = 'public/image/detalle_ruta_b.jpg';
  static const fondoHaku = 'public/image/fondoHaku.png';
  static const logo = 'public/image/logo_haku_encabezado.jpeg';

  /// Avatar por defecto (logo empaquetado).
  static const avatar = logo;

  static const tejido = llamaMachu;
  static const ceramica = moray;
  static const comida = fondoPublicaciones;
  static const teatro = machuPicchu;
  static const pintura = ausangate;

  static const respaldo = machuPicchu;

  static const portadasExploradores = [
    encabezadoRutas,
    fondoExplora,
    ausangate,
    machuPicchu,
    moray,
  ];

  static const destinos = [
    machuPicchu,
    moray,
    ausangate,
    llamaMachu,
    huacachina,
  ];

  static String porIndice(int i) => destinos[i % destinos.length];

  static bool esLocal(String url) =>
      url.startsWith('assets/') || url.startsWith('public/');

  /// Fuerza avatar local si viene vacío o de red (Unsplash, etc.).
  static String resolverAvatar(String? url) {
    if (url == null || url.isEmpty) return avatar;
    if (url.startsWith('http')) return avatar;
    return url;
  }

  /// Portadas de comunidad / tarjetas: local por defecto si viene de red.
  static String resolverImagen(String? url, {String respaldo = encabezadoRutas}) {
    if (url == null || url.isEmpty) return respaldo;
    if (url.startsWith('http')) return respaldo;
    return url;
  }
}
