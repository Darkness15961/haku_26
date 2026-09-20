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

  static const islasTitulo = 'Tus provincias';
  static const islasSubtitulo =
      'Desliza la isla · toca el terreno para ver rincones · toca la foto para entrar';
  static const islasSegmento = 'Islas';
  static const sheetProvinciaVerTodo = 'Rincones de acá';
  static const sheetProvinciaVacia =
      'Todavía no hay rincones aquí. Sé el primero en crear uno.';
  /// Contexto territorial (Explora = Cusco). Evita confundir capital ≠ provincia.
  static const sheetProvinciaContexto = 'Provincia del Cusco';
  static const sheetProvinciaCapitalPrefijo = 'Capital';
  static const sheetFiltroTematica = 'Temática';
  static const sheetFiltroActividad = 'Actividad';
  static const sheetFiltroDistritoOpcional = 'Filtrar por distrito';
  static const sheetFiltroVacio = 'No hay lugares con ese filtro.';
  static const sheetCtaRegistrar = 'Crear un lugar';

  static String islaLugares(int n) =>
      n == 0 ? 'Sin rincones aún' : (n == 1 ? '1 lugar' : '$n lugares');

  static String islaNuevos(int n) =>
      n == 1 ? '1 nuevo' : '$n nuevos';

  static String sheetSalidas(int n) =>
      n == 0 ? 'Sin salidas abiertas' : (n == 1 ? '1 salida' : '$n salidas');

  static String huecosSinNombre(int n) =>
      n == 1 ? '1 hueco sin nombre todavía' : '$n huecos sin nombre todavía';

  static String lugaresEnMapa(int n) =>
      n == 1 ? '1 lugar en el mapa' : '$n lugares en el mapa';

  static const leyendaMapaPorExplorar = 'Sin nombre todavía';
  static const leyendaMapaConFotos = 'Con fotos de la gente';

  // —— Mapa Explora (GPS + PostGIS 50 km + contorno Cusco) ——
  static const mapaTitulo = 'Mapa';
  static const mapaChipCerca = 'Cerca 50 km';
  static const mapaCercaDeTi = 'Lugares a 50 km o menos de ti';
  static const mapaCercaBuscandoGps = 'Buscando tu ubicación…';
  static const mapaCercaSinGps =
      'Activa tu ubicación para ver rincones cerca de ti';
  static const mapaTodosActivos = 'Todos los lugares activos del Cusco';
  static const mapaActivarUbicacionCta = 'Activar mi ubicación';
  static const mapaCercaError =
      'No se pudo consultar la cercanía. Intenta de nuevo.';
  static const mapaGpsApagadoTitulo = 'GPS apagado';
  static const mapaGpsApagadoMensaje =
      'Activa la ubicación del teléfono para ver lugares cerca de ti.';
  static const mapaPermisoTitulo = 'Permiso de ubicación';
  static const mapaPermisoPermanenteMensaje =
      'Antes se negó el permiso. Ábrelo en Ajustes de la app '
      '(Ubicación → Permitir) y vuelve a intentar.';
  static const mapaPermisoDenegado =
      'Sin permiso no podemos mostrar lugares cerca de ti.';
  static const mapaGpsError =
      'No se pudo obtener tu ubicación. Revisa el GPS e intenta de nuevo.';
  static const mapaAbrirAjustes = 'Abrir ajustes';

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
      'Nadie dejó su historia aún. Sé el primero en compartir tu experiencia.';

  static const portadaTituloFallback = 'Cuando baja el ruido';
  static const portadaSubtituloFallback = 'Calles que ya caminaste de noche';

  static const tipoLugarFallback = 'De acá';
  static const carruselPieExperiencia = 'Caminata larga';

  // —— Perfil / publicar ——
  static const perfilSinPublicaciones = 'Tu álbum está vacío';
  static const perfilSinPublicacionesSub =
      'Cuando publiques un recuerdo, aparece acá como un mosaico.';

  static const etiquetarCompanerosSub = 'Gente de acá en el demo';

  static const insigniaVecinoMapa = 'Vecino del mapa';
  static const insigniaVecinoMapaDesc = 'Primeros pasos en el mapa';

  static const seccionExperienciasSub =
      'Publicaciones de las personas';

  static String compartirPerfil(String usuario) =>
      'Te paso el perfil de $usuario en HAKU — échale un ojo.';

  static String etiquetaVecinos(int cantidad) {
    if (cantidad <= 0) return '';
    return cantidad == 1 ? '1 vecino' : '$cantidad vecinos';
  }
}
