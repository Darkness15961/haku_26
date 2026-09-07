import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';

import '../datos/coordenadas_lugares_cusco.dart';
import '../dominio/modelos/modelo_lugar.dart';

/// Catálogo local + lugares creados en sesión (mutables).
class LugaresDataSourceLocal {
  LugaresDataSourceLocal._();
  static final instancia = LugaresDataSourceLocal._();

  final List<ModeloLugar> _creados = [];

  static const _seed = <ModeloLugar>[
    ModeloLugar(
      id: 'laguna_humantay',
      nombre: 'Laguna Humantay',
      descripcion:
          'Laguna turquesa al pie del nevado Humantay. Fotos y relatos de vecinos en HAKU.',
      imagenUrl: CatalogoImagenesHaku.u15,
      categoria: CategoriaLugar.naturaleza,
      provincia: 'Anta',
      distrito: 'Mollepata',
      distanciaKm: 24,
      calificacion: 4.8,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Moderada',
      tiempoEstimado: '5–6 h',
      altitud: '4200 msnm',
      acceso: 'Caminata desde Soraypampa',
    ),
    ModeloLugar(
      id: 'canon_qeswachaka',
      nombre: 'Cañón Q’eswachaka',
      descripcion:
          'Puente inca vivo y cañón profundo. Lo sumó alguien de acá en HAKU.',
      imagenUrl: CatalogoImagenesHaku.detalleRutaB,
      categoria: CategoriaLugar.misterioso,
      provincia: 'Canas',
      distrito: 'Quehue',
      distanciaKm: 78,
      calificacion: 4.8,
      nivelExploracion: NivelExploracion.nuevoEnHaku,
      dificultad: 'Fácil',
      tiempoEstimado: '3 h',
      altitud: '3700 msnm',
      acceso: 'Transporte + corto tramo a pie',
      descubiertoEn: null, // set relative in getter
    ),
    ModeloLugar(
      id: 'moray',
      nombre: 'Moray',
      descripcion: 'Anfiteatro agrícola inca con microclimas únicos.',
      imagenUrl: CatalogoImagenesHaku.u28,
      categoria: CategoriaLugar.cultura,
      provincia: 'Urubamba',
      distrito: 'Maras',
      distanciaKm: 38,
      calificacion: 4.7,
      nivelExploracion: NivelExploracion.muyConocido,
      dificultad: 'Fácil',
      tiempoEstimado: '2 h',
      altitud: '3500 msnm',
      acceso: 'Auto o tour',
    ),
    ModeloLugar(
      id: 'ausangate_vista',
      nombre: 'Mirador Ausangate',
      descripcion: 'Vistas al nevado sagrado. Zona en crecimiento en HAKU.',
      imagenUrl: CatalogoImagenesHaku.u17,
      categoria: CategoriaLugar.caminata,
      provincia: 'Quispicanchi',
      distrito: 'Ocongate',
      distanciaKm: 95,
      calificacion: 4.9,
      nivelExploracion: NivelExploracion.pocoExplorado,
      dificultad: 'Difícil',
      tiempoEstimado: '1 día',
      altitud: '4800 msnm',
      acceso: 'Trekking',
    ),
    ModeloLugar(
      id: 'machu_picchu',
      nombre: 'Machu Picchu',
      descripcion: 'Ciudadela inca. Muy visitada — siempre hay un ángulo nuevo.',
      imagenUrl: CatalogoImagenesHaku.u27,
      categoria: CategoriaLugar.cultura,
      provincia: 'Urubamba',
      distrito: 'Machupicchu',
      distanciaKm: 110,
      calificacion: 4.9,
      nivelExploracion: NivelExploracion.muyConocido,
      dificultad: 'Moderada',
      tiempoEstimado: '1 día',
      altitud: '2430 msnm',
      acceso: 'Tren + bus',
    ),
    ModeloLugar(
      id: 'laguna_oculta',
      nombre: 'Laguna Escondida de Calca',
      descripcion: 'Poco explorada. Ideal para tu primera publicación.',
      imagenUrl: CatalogoImagenesHaku.fondoExplora,
      categoria: CategoriaLugar.magico,
      provincia: 'Calca',
      distrito: 'Lares',
      distanciaKm: 52,
      calificacion: 4.5,
      nivelExploracion: NivelExploracion.pocoExplorado,
      dificultad: 'Moderada',
      tiempoEstimado: '4 h',
      altitud: '3900 msnm',
      acceso: 'Caminata',
      descubiertoEn: null,
    ),
    ModeloLugar(
      id: 'fogon_chinchero',
      nombre: 'Fogón familiar Chinchero',
      descripcion: 'Almuerzo andino en casa: chuño, quinoa y mate de coca.',
      imagenUrl: CatalogoImagenesHaku.u01,
      categoria: CategoriaLugar.gastronomia,
      provincia: 'Urubamba',
      distrito: 'Chinchero',
      distanciaKm: 28,
      calificacion: 4.8,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Fácil',
      tiempoEstimado: '2 h',
      altitud: '3760 msnm',
      acceso: 'Taxi o colectivo',
    ),
    ModeloLugar(
      id: 'mercado_san_pedro',
      nombre: 'Comedores San Pedro',
      descripcion: 'Sopas, jugos y platos del día en el corazón del mercado.',
      imagenUrl: CatalogoImagenesHaku.u02,
      categoria: CategoriaLugar.gastronomia,
      provincia: 'Cusco',
      distrito: 'Cusco',
      distanciaKm: 1,
      calificacion: 4.6,
      nivelExploracion: NivelExploracion.muyConocido,
      dificultad: 'Fácil',
      tiempoEstimado: '1 h',
      altitud: '3400 msnm',
      acceso: 'A pie',
    ),
    ModeloLugar(
      id: 'picanteria_san_jeronimo',
      nombre: 'Picantería San Jerónimo',
      descripcion: 'Chicharrón, rocoto relleno y chicha de jora.',
      imagenUrl: CatalogoImagenesHaku.u03,
      categoria: CategoriaLugar.gastronomia,
      provincia: 'Cusco',
      distrito: 'San Jerónimo',
      distanciaKm: 8,
      calificacion: 4.7,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Fácil',
      tiempoEstimado: '1–2 h',
      altitud: '3240 msnm',
      acceso: 'Colectivo',
    ),
    ModeloLugar(
      id: 'cafe_cacao_quellouno',
      nombre: 'Cacao y café Quellouno',
      descripcion: 'Degustación de cacao nativo y café de selva alta.',
      imagenUrl: CatalogoImagenesHaku.u04,
      categoria: CategoriaLugar.gastronomia,
      provincia: 'La Convención',
      distrito: 'Quellouno',
      distanciaKm: 160,
      calificacion: 4.9,
      nivelExploracion: NivelExploracion.pocoExplorado,
      dificultad: 'Fácil',
      tiempoEstimado: '2 h',
      altitud: '900 msnm',
      acceso: 'Tour o auto',
    ),
    ModeloLugar(
      id: 'taller_ceramica_blas',
      nombre: 'Taller cerámica San Blas',
      descripcion: 'Tornear, pintar y hornear con artesanos del barrio.',
      imagenUrl: CatalogoImagenesHaku.u05,
      categoria: CategoriaLugar.cultura,
      provincia: 'Cusco',
      distrito: 'San Blas',
      distanciaKm: 1,
      calificacion: 4.8,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Fácil',
      tiempoEstimado: '3 h',
      altitud: '3450 msnm',
      acceso: 'A pie',
    ),
    ModeloLugar(
      id: 'museo_inkariy',
      nombre: 'Museo Inkariy',
      descripcion: 'Historia andina en salas inmersivas cerca de Calca.',
      imagenUrl: CatalogoImagenesHaku.u21,
      categoria: CategoriaLugar.cultura,
      provincia: 'Calca',
      distrito: 'Calca',
      distanciaKm: 45,
      calificacion: 4.7,
      nivelExploracion: NivelExploracion.muyConocido,
      dificultad: 'Fácil',
      tiempoEstimado: '2 h',
      altitud: '2926 msnm',
      acceso: 'Auto o tour',
    ),
    ModeloLugar(
      id: 'ofrenda_despacho_ausangate',
      nombre: 'Despacho a los Apus',
      descripcion: 'Ceremonia mística de ofrenda con paqo local en altura.',
      imagenUrl: CatalogoImagenesHaku.ausangate,
      categoria: CategoriaLugar.misterioso,
      provincia: 'Quispicanchi',
      distrito: 'Ocongate',
      distanciaKm: 100,
      calificacion: 4.9,
      nivelExploracion: NivelExploracion.pocoExplorado,
      dificultad: 'Moderada',
      tiempoEstimado: 'Medio día',
      altitud: '4200 msnm',
      acceso: 'Tour con guía',
    ),
    ModeloLugar(
      id: 'temazcal_valle',
      nombre: 'Temazcal del Valle',
      descripcion: 'Baño de vapor ritual y limpieza energética.',
      imagenUrl: CatalogoImagenesHaku.u11,
      categoria: CategoriaLugar.magico,
      provincia: 'Urubamba',
      distrito: 'Urubamba',
      distanciaKm: 60,
      calificacion: 4.8,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Fácil',
      tiempoEstimado: '3 h',
      altitud: '2870 msnm',
      acceso: 'Reserva previa',
    ),
    ModeloLugar(
      id: 'ayahuasca_retiro_no',
      nombre: 'Círculo de ikaros (sonido)',
      descripcion: 'Experiencia sonora mística con cantos andinos — sin sustancias.',
      imagenUrl: CatalogoImagenesHaku.encabezadoRutas,
      categoria: CategoriaLugar.misterioso,
      provincia: 'Cusco',
      distrito: 'Cusco',
      distanciaKm: 3,
      calificacion: 4.5,
      nivelExploracion: NivelExploracion.nuevoEnHaku,
      dificultad: 'Fácil',
      tiempoEstimado: '2 h',
      altitud: '3400 msnm',
      acceso: 'Reserva',
    ),
    ModeloLugar(
      id: 'rafting_vilcanota',
      nombre: 'Rafting río Vilcanota',
      descripcion: 'Agua viva clase II–III entre cañones del valle.',
      imagenUrl: CatalogoImagenesHaku.u12,
      categoria: CategoriaLugar.aventura,
      provincia: 'Urubamba',
      distrito: 'Ollantaytambo',
      distanciaKm: 70,
      calificacion: 4.8,
      nivelExploracion: NivelExploracion.muyConocido,
      dificultad: 'Moderada',
      tiempoEstimado: 'Medio día',
      altitud: '2800 msnm',
      acceso: 'Operador local',
    ),
    ModeloLugar(
      id: 'via_ferrata_sacred',
      nombre: 'Vía ferrata Valle Sagrado',
      descripcion: 'Escalada asegurada en pared de roca con vista al valle.',
      imagenUrl: CatalogoImagenesHaku.u13,
      categoria: CategoriaLugar.aventura,
      provincia: 'Urubamba',
      distrito: 'Ollantaytambo',
      distanciaKm: 75,
      calificacion: 4.7,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Difícil',
      tiempoEstimado: '4–5 h',
      altitud: '2900 msnm',
      acceso: 'Tour especializado',
    ),
    ModeloLugar(
      id: 'casa_ollanta',
      nombre: 'Casa patio Ollantaytambo',
      descripcion: 'Refugio con patio de piedra. Ideal tras un día de ruta.',
      imagenUrl: CatalogoImagenesHaku.u20,
      categoria: CategoriaLugar.cultura,
      provincia: 'Urubamba',
      distrito: 'Ollantaytambo',
      distanciaKm: 72,
      calificacion: 4.7,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Fácil',
      tiempoEstimado: 'Noche',
      altitud: '2792 msnm',
      acceso: 'Tren o auto',
    ),
    ModeloLugar(
      id: 'mirador_foto_pisac',
      nombre: 'Sesión foto amanecer Pisac',
      descripcion: 'Ruta fotográfica guiada al amanecer sobre el valle.',
      imagenUrl: CatalogoImagenesHaku.machuPicchu,
      categoria: CategoriaLugar.fotografia,
      provincia: 'Calca',
      distrito: 'Pisac',
      distanciaKm: 32,
      calificacion: 4.8,
      nivelExploracion: NivelExploracion.pocoExplorado,
      dificultad: 'Fácil',
      tiempoEstimado: '1–2 h',
      altitud: '2972 msnm',
      acceso: 'Caminata corta',
    ),
    ModeloLugar(
      id: 'astro_foto_maras',
      nombre: 'Astrofotografía Maras',
      descripcion: 'Vía Láctea sobre salineras. Experiencia nocturna.',
      imagenUrl: CatalogoImagenesHaku.moray,
      categoria: CategoriaLugar.fotografia,
      provincia: 'Urubamba',
      distrito: 'Maras',
      distanciaKm: 40,
      calificacion: 4.9,
      nivelExploracion: NivelExploracion.nuevoEnHaku,
      dificultad: 'Fácil',
      tiempoEstimado: 'Noche',
      altitud: '3300 msnm',
      acceso: 'Tour nocturno',
    ),
    ModeloLugar(
      id: 'catarata_quellouno',
      nombre: 'Catarata Quellouno',
      descripcion: 'Selva alta y agua fría. Ideal para una escapada de fin de semana.',
      imagenUrl: CatalogoImagenesHaku.fondoExplora,
      categoria: CategoriaLugar.naturaleza,
      provincia: 'La Convención',
      distrito: 'Quellouno',
      distanciaKm: 160,
      calificacion: 4.7,
      nivelExploracion: NivelExploracion.pocoExplorado,
      dificultad: 'Moderada',
      tiempoEstimado: 'Fin de semana',
      altitud: '900 msnm',
      acceso: 'Auto + caminata',
    ),
    ModeloLugar(
      id: 'laguna_sibinacocha',
      nombre: 'Laguna Sibinacocha',
      descripcion: 'Altiplano y silencio. Escapada de altura cerca de Ausangate.',
      imagenUrl: CatalogoImagenesHaku.ausangate,
      categoria: CategoriaLugar.naturaleza,
      provincia: 'Quispicanchi',
      distrito: 'Ccarhuayo',
      distanciaKm: 120,
      calificacion: 4.8,
      nivelExploracion: NivelExploracion.nuevoEnHaku,
      dificultad: 'Difícil',
      tiempoEstimado: '2 días',
      altitud: '4860 msnm',
      acceso: 'Trekking / tour',
    ),
    ModeloLugar(
      id: 'plaza_paucartambo',
      nombre: 'Fiesta Virgen del Carmen',
      descripcion: 'Danza, máscaras y pueblo en fiesta. Cultura viva.',
      imagenUrl: CatalogoImagenesHaku.u22,
      categoria: CategoriaLugar.cultura,
      provincia: 'Paucartambo',
      distrito: 'Paucartambo',
      distanciaKm: 110,
      calificacion: 4.6,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Fácil',
      tiempoEstimado: 'Fin de semana',
      altitud: '2950 msnm',
      acceso: 'Bus o auto',
    ),
    ModeloLugar(
      id: 'puente_qeswa_canas',
      nombre: 'Tejido del puente Q’eswachaka',
      descripcion: 'Participa en la renovación ritual del puente de ichu.',
      imagenUrl: CatalogoImagenesHaku.u33,
      categoria: CategoriaLugar.cultura,
      provincia: 'Canas',
      distrito: 'Quehue',
      distanciaKm: 78,
      calificacion: 4.9,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Fácil',
      tiempoEstimado: '1 día',
      altitud: '3700 msnm',
      acceso: 'Tour o auto',
    ),
    ModeloLugar(
      id: 'cementerio_almudena_noche',
      nombre: 'Tour nocturno Cementerio Almudena',
      descripcion:
          'Paseo guiado entre mausoleos, historias y el silencio de Almudena. Uno de los tours más curiosos de Cusco.',
      imagenUrl: CatalogoImagenesHaku.u46,
      categoria: CategoriaLugar.misterioso,
      provincia: 'Cusco',
      distrito: 'Cusco',
      distanciaKm: 2,
      calificacion: 4.8,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Fácil',
      tiempoEstimado: '2 h de noche',
      altitud: '3400 msnm',
      acceso: 'Tour guiado nocturno',
    ),
    ModeloLugar(
      id: 'qoricancha_noche',
      nombre: 'Qorikancha bajo la luna',
      descripcion:
          'Templo del Sol al caer la noche: piedra, sombra y el eco inca en el centro.',
      imagenUrl: CatalogoImagenesHaku.u47,
      categoria: CategoriaLugar.misterioso,
      provincia: 'Cusco',
      distrito: 'Cusco',
      distanciaKm: 1,
      calificacion: 4.9,
      nivelExploracion: NivelExploracion.muyConocido,
      dificultad: 'Fácil',
      tiempoEstimado: '1–2 h',
      altitud: '3400 msnm',
      acceso: 'Entrada + guía',
    ),
    ModeloLugar(
      id: 'calles_brujas_noche',
      nombre: 'Calles de brujas (noche)',
      descripcion:
          'Recorrido por callejones estrechos, leyendas urbanas y piedras que “hablan”.',
      imagenUrl: CatalogoImagenesHaku.u48,
      categoria: CategoriaLugar.misterioso,
      provincia: 'Cusco',
      distrito: 'Cusco',
      distanciaKm: 1,
      calificacion: 4.6,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Fácil',
      tiempoEstimado: '2 h',
      altitud: '3400 msnm',
      acceso: 'Caminata guiada',
    ),
    ModeloLugar(
      id: 'wakas_sacsay_amanecer',
      nombre: 'Wak’as de Sacsayhuamán',
      descripcion:
          'Visita a huacas y piedras sagradas al amanecer, cuando la ciudad aún duerme.',
      imagenUrl: CatalogoImagenesHaku.u49,
      categoria: CategoriaLugar.magico,
      provincia: 'Cusco',
      distrito: 'Cusco',
      distanciaKm: 4,
      calificacion: 4.7,
      nivelExploracion: NivelExploracion.pocoExplorado,
      dificultad: 'Fácil',
      tiempoEstimado: '3 h',
      altitud: '3700 msnm',
      acceso: 'Taxi + caminata',
    ),
    ModeloLugar(
      id: 'salineras_luna_llena',
      nombre: 'Salineras en luna llena',
      descripcion:
          'Maras iluminado por la luna: espejos de sal y silencio andino.',
      imagenUrl: CatalogoImagenesHaku.u50,
      categoria: CategoriaLugar.magico,
      provincia: 'Urubamba',
      distrito: 'Maras',
      distanciaKm: 40,
      calificacion: 4.9,
      nivelExploracion: NivelExploracion.nuevoEnHaku,
      dificultad: 'Fácil',
      tiempoEstimado: 'Noche',
      altitud: '3300 msnm',
      acceso: 'Tour nocturno',
    ),
    ModeloLugar(
      id: 'cruz_cristal_noche',
      nombre: 'Paseo Cruz de Cristal',
      descripcion:
          'Subida corta al mirador cuando Cusco se enciende: ciudad, apus y frío limpio.',
      imagenUrl: CatalogoImagenesHaku.u51,
      categoria: CategoriaLugar.misterioso,
      provincia: 'Cusco',
      distrito: 'Cusco',
      distanciaKm: 3,
      calificacion: 4.5,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Moderada',
      tiempoEstimado: '2 h',
      altitud: '3600 msnm',
      acceso: 'Caminata',
    ),
    ModeloLugar(
      id: 'baile_diablada_noche',
      nombre: 'Máscaras y diablada (ensayo)',
      descripcion:
          'Ensayo nocturno de danzas con máscaras: fuego, ritmo y misterio del altiplano.',
      imagenUrl: CatalogoImagenesHaku.u52,
      categoria: CategoriaLugar.misterioso,
      provincia: 'Paucartambo',
      distrito: 'Paucartambo',
      distanciaKm: 110,
      calificacion: 4.8,
      nivelExploracion: NivelExploracion.pocoExplorado,
      dificultad: 'Fácil',
      tiempoEstimado: 'Noche',
      altitud: '2950 msnm',
      acceso: 'Tour / fiesta local',
    ),
    // —— Provincias que faltaban en el path de islas ——
    ModeloLugar(
      id: 'termoas_laresa',
      nombre: 'Termas de Lares',
      descripcion:
          'Pozas calientes entre cerros: agua mineral, niebla y silencio de valle.',
      imagenUrl: CatalogoImagenesHaku.u20,
      categoria: CategoriaLugar.naturaleza,
      provincia: 'Calca',
      distrito: 'Lares',
      distanciaKm: 62,
      calificacion: 4.6,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Fácil',
      tiempoEstimado: 'Medio día',
      altitud: '3200 msnm',
      acceso: 'Combi + caminata corta',
    ),
    ModeloLugar(
      id: 'mirador_zurite',
      nombre: 'Mirador de Zurite',
      descripcion:
          'Andenes y vista al valle de Anta al atardecer. Poco visitado entre semana.',
      imagenUrl: CatalogoImagenesHaku.u21,
      categoria: CategoriaLugar.fotografia,
      provincia: 'Anta',
      distrito: 'Zurite',
      distanciaKm: 35,
      calificacion: 4.4,
      nivelExploracion: NivelExploracion.pocoExplorado,
      dificultad: 'Fácil',
      tiempoEstimado: '2 h',
      altitud: '3400 msnm',
      acceso: 'Taxi / combi',
    ),
    ModeloLugar(
      id: 'rumicolca',
      nombre: 'Rumicolca',
      descripcion:
          'Portal inca de piedra en Quispicanchi: el paso antiguo hacia el Collasuyo.',
      imagenUrl: CatalogoImagenesHaku.u22,
      categoria: CategoriaLugar.cultura,
      provincia: 'Quispicanchi',
      distrito: 'Lucre',
      distanciaKm: 32,
      calificacion: 4.5,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Fácil',
      tiempoEstimado: '1–2 h',
      altitud: '3150 msnm',
      acceso: 'Carretera Cusco–Puno',
    ),
    ModeloLugar(
      id: 'rausana_canchis',
      nombre: 'Rausana (Sicuani)',
      descripcion:
          'Cerro sagrado cerca de Sicuani: ritual, altura y vista al valle del Vilcanota.',
      imagenUrl: CatalogoImagenesHaku.u23,
      categoria: CategoriaLugar.misterioso,
      provincia: 'Canchis',
      distrito: 'Sicuani',
      distanciaKm: 138,
      calificacion: 4.3,
      nivelExploracion: NivelExploracion.pocoExplorado,
      dificultad: 'Moderada',
      tiempoEstimado: '3–4 h',
      altitud: '3800 msnm',
      acceso: 'Taxi desde Sicuani',
    ),
    ModeloLugar(
      id: 'aguas_calientes_canchis',
      nombre: 'Aguas termales Combapata',
      descripcion:
          'Pozas familiares en Canchis: agua tibia, río cerca y poca gente fuera de feriado.',
      imagenUrl: CatalogoImagenesHaku.u24,
      categoria: CategoriaLugar.naturaleza,
      provincia: 'Canchis',
      distrito: 'Combapata',
      distanciaKm: 115,
      calificacion: 4.2,
      nivelExploracion: NivelExploracion.nuevoEnHaku,
      dificultad: 'Fácil',
      tiempoEstimado: 'Medio día',
      altitud: '3480 msnm',
      acceso: 'Combi Sicuani–Combapata',
    ),
    ModeloLugar(
      id: 'laguna_pomacanchi',
      nombre: 'Laguna de Pomacanchi',
      descripcion:
          'Espejo de agua en Acomayo: pesca, viento y atardeceres largos.',
      imagenUrl: CatalogoImagenesHaku.u25,
      categoria: CategoriaLugar.naturaleza,
      provincia: 'Acomayo',
      distrito: 'Pomacanchi',
      distanciaKm: 98,
      calificacion: 4.4,
      nivelExploracion: NivelExploracion.pocoExplorado,
      dificultad: 'Fácil',
      tiempoEstimado: 'Día',
      altitud: '3670 msnm',
      acceso: 'Combi desde Cusco',
    ),
    ModeloLugar(
      id: 'templo_acomayo',
      nombre: 'Iglesia de Acomayo',
      descripcion:
          'Pueblo tranquilo y templo colonial: piedra, campanas y plaza sin apuro.',
      imagenUrl: CatalogoImagenesHaku.u26,
      categoria: CategoriaLugar.cultura,
      provincia: 'Acomayo',
      distrito: 'Acomayo',
      distanciaKm: 105,
      calificacion: 4.1,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Fácil',
      tiempoEstimado: '2 h',
      altitud: '3200 msnm',
      acceso: 'Combi',
    ),
    ModeloLugar(
      id: 'huanca_paruro',
      nombre: 'Santuario del Señor de Huanca',
      descripcion:
          'Peregrinación viva en Paruro: fe, comida de feria y cerros que guardan silencio.',
      imagenUrl: CatalogoImagenesHaku.u27,
      categoria: CategoriaLugar.cultura,
      provincia: 'Paruro',
      distrito: 'San Salvador',
      distanciaKm: 28,
      calificacion: 4.7,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Fácil',
      tiempoEstimado: 'Medio día',
      altitud: '3100 msnm',
      acceso: 'Combi / taxi',
    ),
    ModeloLugar(
      id: 'yacila_paruro',
      nombre: 'Yacila (andenes)',
      descripcion:
          'Andenes poco visitados en Paruro: tierra labrada y vista al valle.',
      imagenUrl: CatalogoImagenesHaku.u28,
      categoria: CategoriaLugar.caminata,
      provincia: 'Paruro',
      distrito: 'Paruro',
      distanciaKm: 72,
      calificacion: 4.0,
      nivelExploracion: NivelExploracion.nuevoEnHaku,
      dificultad: 'Moderada',
      tiempoEstimado: '3 h',
      altitud: '3300 msnm',
      acceso: 'Caminata',
    ),
    ModeloLugar(
      id: 'qoyllur_rito_chumbivilcas',
      nombre: 'Qoyllur Rit’i (camino alto)',
      descripcion:
          'Tramo alto hacia el santuario: frío, velas y fe andina. Solo con guía local.',
      imagenUrl: CatalogoImagenesHaku.u29,
      categoria: CategoriaLugar.misterioso,
      provincia: 'Chumbivilcas',
      distrito: 'Santo Tomás',
      distanciaKm: 180,
      calificacion: 4.9,
      nivelExploracion: NivelExploracion.pocoExplorado,
      dificultad: 'Difícil',
      tiempoEstimado: '2–3 días',
      altitud: '4600+ msnm',
      acceso: 'Expedición / guía',
    ),
    ModeloLugar(
      id: 'toro_pueblo_chumbivilcas',
      nombre: 'Toropukllay (ensayo)',
      descripcion:
          'Ensayo de toros a pie en Chumbivilcas: fuerza, música y orgullo de pueblo.',
      imagenUrl: CatalogoImagenesHaku.u30,
      categoria: CategoriaLugar.magico,
      provincia: 'Chumbivilcas',
      distrito: 'Santo Tomás',
      distanciaKm: 185,
      calificacion: 4.6,
      nivelExploracion: NivelExploracion.nuevoEnHaku,
      dificultad: 'Fácil',
      tiempoEstimado: 'Tarde',
      altitud: '3700 msnm',
      acceso: 'Fiesta local',
    ),
    ModeloLugar(
      id: 'sillustani_espinar',
      nombre: 'Chullpas de Espinar',
      descripcion:
          'Torres funerarias y viento de puna. Altura real: anda despacio.',
      imagenUrl: CatalogoImagenesHaku.u31,
      categoria: CategoriaLugar.cultura,
      provincia: 'Espinar',
      distrito: 'Yauri',
      distanciaKm: 250,
      calificacion: 4.5,
      nivelExploracion: NivelExploracion.pocoExplorado,
      dificultad: 'Moderada',
      tiempoEstimado: 'Medio día',
      altitud: '4000 msnm',
      acceso: 'Taxi desde Yauri',
    ),
    ModeloLugar(
      id: 'laguna_langui_layo',
      nombre: 'Laguna Langui–Layo',
      descripcion:
          'Espejo alto entre Canas y Espinar: trucha, viento y cielo abierto.',
      imagenUrl: CatalogoImagenesHaku.u32,
      categoria: CategoriaLugar.naturaleza,
      provincia: 'Espinar',
      distrito: 'Yauri',
      distanciaKm: 220,
      calificacion: 4.4,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Fácil',
      tiempoEstimado: 'Día',
      altitud: '3950 msnm',
      acceso: 'Carretera Sicuani–Yauri',
    ),
  ];

  List<ModeloLugar> todos() {
    final ahora = DateTime.now();
    return [
      ..._seed.map((l) => _enriquecer(l, ahora)),
      ..._creados.map((l) => _enriquecer(l, ahora)),
    ];
  }

  static ModeloLugar _enriquecer(ModeloLugar l, DateTime ahora) {
    var out = l;
    if (l.id == 'canon_qeswachaka') {
      out = out.copyWith(
        descubiertoEn: ahora.subtract(const Duration(days: 2)),
      );
    } else if (l.id == 'laguna_oculta') {
      out = out.copyWith(
        descubiertoEn: ahora.subtract(const Duration(days: 5)),
      );
    } else if (l.id == 'salineras_luna_llena') {
      out = out.copyWith(
        descubiertoEn: ahora.subtract(const Duration(days: 1)),
      );
    }
    out = CoordenadasLugaresCusco.aplicar(out);
    return out.copyWith(
      imagenUrl: CatalogoImagenesHaku.imagenParaLugar(
        lugarId: out.id,
        provincia: out.provincia,
        categoria: out.categoria,
        fallback: out.imagenUrl,
      ),
    );
  }

  ModeloLugar? porId(String id) {
    for (final l in todos()) {
      if (l.id == id) return l;
    }
    return null;
  }

  List<ModeloLugar> porIntereses(Set<CategoriaLugar> intereses) {
    final lista = todos();
    if (intereses.isEmpty) return lista;
    return lista.where((l) => intereses.contains(l.categoria)).toList();
  }

  List<ModeloLugar> pocoExplorados() {
    return todos()
        .where(
          (l) =>
              l.nivelExploracion == NivelExploracion.pocoExplorado ||
              l.nivelExploracion == NivelExploracion.nuevoEnHaku,
        )
        .toList();
  }

  List<ModeloLugar> recientes() {
    final conFecha = todos().where((l) => l.descubiertoEn != null).toList()
      ..sort((a, b) => b.descubiertoEn!.compareTo(a.descubiertoEn!));
    return conFecha;
  }

  ModeloLugar sorpresa({
    Set<CategoriaLugar> intereses = const {},
    String? evitarId,
    String? preferirProvincia,
  }) {
    var pool = intereses.isEmpty ? pocoExplorados() : porIntereses(intereses);
    if (pool.isEmpty) pool = todos();
    if (preferirProvincia != null && preferirProvincia.isNotEmpty) {
      final enProv = pool
          .where((l) => l.provincia == preferirProvincia)
          .toList();
      if (enProv.isNotEmpty) pool = enProv;
    }
    if (evitarId != null && pool.length > 1) {
      pool = pool.where((l) => l.id != evitarId).toList();
    }
    // Prefiere provincias con pocas fichas (simula “hueco” real).
    pool = [...pool]..sort((a, b) {
      final ca = todos().where((l) => l.provincia == a.provincia).length;
      final cb = todos().where((l) => l.provincia == b.provincia).length;
      return ca.compareTo(cb);
    });
    final top = pool.take((pool.length / 2).ceil().clamp(1, pool.length));
    final elegibles = top.toList()..shuffle();
    return elegibles.first;
  }

  void agregar(ModeloLugar lugar) {
    _creados.insert(0, lugar);
  }

  List<ModeloLugar> get creados => List.unmodifiable(_creados);

  void reemplazarCreados(List<ModeloLugar> lugares) {
    _creados
      ..clear()
      ..addAll(lugares);
  }
}
