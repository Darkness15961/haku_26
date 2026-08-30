/// Voz HAKU — cercana, cusqueña, sin brochure turístico.
/// Evitar: «descubre», «redescubre», «inspírate», «aventura única».
abstract final class CopyHaku {
  // —— Shell / inicio ——
  static const tabInicio = 'Hoy';
  static const tabExplora = 'Explora';
  static const tabComunidad = 'Comunidad';
  static const tabPerfil = 'Perfil';

  static const tituloInicio = 'Hola, ¿qué se mueve hoy?';
  static const subtituloInicio =
      'Lo que cuenta tu gente: rutas, fogones y recuerdos de acá';

  static const buscarHint = 'Busca un lugar, ruta o persona…';

  static const mapaAccesoTitulo = 'El mapa de la gente';
  static const mapaAccesoSubtitulo = 'Rincones que ya caminan contigo';

  // —— Carruseles inicio ——
  static const carruselSenderosTitulo = 'Caminos que siguen vivos';
  static const carruselSenderosSub =
      'Trekking, río y altura — como los haces tú';

  static const carruselFogonesTitulo = 'Fogones de barrio';
  static const carruselFogonesSub =
      'Donde comes, donde aprendes, donde hacen a mano';

  static const carruselExperienciasTitulo = 'Lo que no se olvida';
  static const carruselExperienciasSub =
      'Rituales, fotos y silencios de acá';

  static const comunidadDestacadaTitulo = 'Lo que dejó la gente';

  static const badgeComunidad1 = 'Lo contó alguien de acá';
  static const badgeComunidad2 = 'Recién en el feed';
  static const badgeComunidad3 = 'Todavía sin nombre';

  // —— Explora ——
  static const exploraHeroTitulo = 'Tu mapa';
  static const exploraHeroSubtitulo =
      'Rincones con nombre y los que aún esperan el tuyo';

  static String huecosSinNombre(int n) =>
      n == 1 ? '1 hueco sin nombre todavía' : '$n huecos sin nombre todavía';

  static String lugaresEnMapa(int n) =>
      n == 1 ? '1 lugar en el mapa' : '$n lugares en el mapa';

  static const leyendaMapaPorExplorar = 'Sin nombre todavía';
  static const leyendaMapaConFotos = 'Con fotos de la gente';

  // —— Onboarding ——
  static const onboarding1Titulo = 'Tu mapa, tu gente';
  static const onboarding1Texto =
      'Rutas y lugares que viven contigo en el celular. '
      'Nada de postal turística — lo de verdad, lo de acá.';

  static const onboarding2Titulo = 'Deja tu recuerdo';
  static const onboarding2Texto =
      'Sube la foto, ponle nombre al lugar y suma tu voz. '
      'Así crece lo que compartimos entre vecinos.';

  static const onboarding3Titulo = 'Entre nosotros';
  static const onboarding3Texto =
      'Salidas, mensajes y publicaciones de gente como tú. '
      'Todo queda en tu teléfono mientras armamos lo que sigue.';

  // —— Splash / auth ——
  static const splashPie = 'Hecho en Cusco, para cusqueños';
  static const loginSubtitulo = 'Entra y suma tu voz';
  static const nombreDefault = 'Vecino de acá';
  static const bioDefault = 'De acá.';

  // —— Detalle / compartir ——
  static String lugarSinDescripcion(String provincia) =>
      'Un rincón de $provincia que aún guarda silencio.';

  static String compartirLugar(String nombre, String categoria, String provincia) =>
      'Te paso $nombre en HAKU — $categoria, $provincia. Míralo.';

  static String compartirRuta(String titulo, String detalle) =>
      '$titulo en HAKU — $detalle. Te lo mando.';

  static const portadaCta = 'Ver más';
  static const cardComunidadCta = 'Ver ficha';

  static const experienciasVacias =
      'Nadie dejó su historia aún. Sé el primero de tu cuadrilla.';

  static const portadaTituloFallback = 'Cuando baja el ruido';
  static const portadaSubtituloFallback = 'Calles que ya caminaste de noche';

  static const tipoLugarFallback = 'De acá';
  static const carruselPieExperiencia = 'Caminata larga';

  // —— Perfil / publicar ——
  static const perfilSinPublicaciones = 'Todavía no cuentas nada';
  static const perfilSinPublicacionesSub =
      'Toca + y deja lo que viviste — foto, ruta o fogón';

  static const etiquetarCompanerosSub = 'Gente de acá en el demo';

  static const insigniaVecinoMapa = 'Vecino del mapa';
  static const insigniaVecinoMapaDesc = 'Primeros pasos en el mapa';

  static const seccionExperienciasSub =
      'Lo que contó la gente — sola o en cuadrilla';

  static String compartirPerfil(String usuario) =>
      'Te paso el perfil de $usuario en HAKU — échale un ojo.';

  static String etiquetaVecinos(int cantidad) {
    if (cantidad <= 0) return '';
    return cantidad == 1 ? '1 vecino' : '$cantidad vecinos';
  }
}
