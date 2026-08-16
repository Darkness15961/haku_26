/// Datos de demo para el feed de Inicio (sugerencias + publicaciones).
class FeedInicioDataSourceLocal {
  static const List<SugerenciaSeguimiento> sugerencias = [
    SugerenciaSeguimiento(
      id: 's1',
      nombre: 'Andina Trek',
      usuario: '@andinatrek',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
      bioCorta: 'Guías del Valle Sagrado',
    ),
    SugerenciaSeguimiento(
      id: 's2',
      nombre: 'Luna Quechua',
      usuario: '@lunaquechua',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
      bioCorta: 'Fotografía de altura',
    ),
    SugerenciaSeguimiento(
      id: 's3',
      nombre: 'Cusco Walks',
      usuario: '@cuscowalks',
      avatarUrl:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&q=80',
      bioCorta: 'Rutas urbanas y miradores',
    ),
    SugerenciaSeguimiento(
      id: 's4',
      nombre: 'Nevado Lab',
      usuario: '@nevadolab',
      avatarUrl:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&q=80',
      bioCorta: 'Ciencia y montaña',
    ),
    SugerenciaSeguimiento(
      id: 's5',
      nombre: 'Pacha Stories',
      usuario: '@pachastories',
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
      bioCorta: 'Relatos del Ande',
    ),
  ];

  static const List<PublicacionFeed> publicaciones = [
    PublicacionFeed(
      id: 'p1',
      autor: 'María Quispe',
      usuario: '@mariaq',
      avatarUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&q=80',
      hace: '2h',
      texto:
          'Salida al amanecer en Sacsayhuamán. El silencio de la piedra y la ciudad abajo… ¿alguien más madruga por estas vistas?',
      imagenUrl:
          'https://images.unsplash.com/photo-1589802829985-817e51171b92?w=800&q=80',
      likes: 128,
      comentarios: 24,
      estiloFondo: EstiloFondoPublicacion.veloNegro,
    ),
    PublicacionFeed(
      id: 'p2',
      autor: 'Diego Andes',
      usuario: '@diegoandes',
      avatarUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&q=80',
      hace: '5h',
      texto:
          'Tip rápido: si vas a Humantay, lleva bastones. El último tramo se siente, pero la laguna lo vale todo.',
      imagenUrl: null,
      likes: 86,
      comentarios: 31,
      estiloFondo: EstiloFondoPublicacion.veloBlanco,
    ),
    PublicacionFeed(
      id: 'p3',
      autor: 'Sofía Trek',
      usuario: '@sofiatrek',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
      hace: 'Yesterday',
      texto:
          'Vinicunca con poca niebla. Colores absurdos. Si alguien quiere armar grupo para la próxima, avisen acá.',
      imagenUrl:
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&q=80',
      likes: 412,
      comentarios: 67,
      estiloFondo: EstiloFondoPublicacion.sinVelo,
    ),
    PublicacionFeed(
      id: 'p4',
      autor: 'Haku Community',
      usuario: '@haku',
      avatarUrl:
          'https://images.unsplash.com/photo-1551632811-561732d1e306?w=200&q=80',
      hace: '1d',
      texto:
          'Nuevas rutas recomendadas esta semana en el Valle Sagrado. ¿Cuál es tu próxima caminata?',
      imagenUrl:
          'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=800&q=80',
      likes: 540,
      comentarios: 92,
      estiloFondo: EstiloFondoPublicacion.veloNegroSuave,
    ),
    PublicacionFeed(
      id: 'p5',
      autor: 'Camila Ríos',
      usuario: '@camilarios',
      avatarUrl:
          'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=200&q=80',
      hace: '2d',
      texto:
          'Mercado de Pisac al mediodía: choclo, queso y una charla con artesanos. Turismo lento, el mejor.',
      imagenUrl: null,
      likes: 73,
      comentarios: 18,
      estiloFondo: EstiloFondoPublicacion.veloBlanco,
    ),
  ];
}

enum EstiloFondoPublicacion {
  veloNegro,
  veloNegroSuave,
  veloBlanco,
  sinVelo,
}

class SugerenciaSeguimiento {
  final String id;
  final String nombre;
  final String usuario;
  final String avatarUrl;
  final String bioCorta;

  const SugerenciaSeguimiento({
    required this.id,
    required this.nombre,
    required this.usuario,
    required this.avatarUrl,
    required this.bioCorta,
  });
}

class PublicacionFeed {
  final String id;
  final String autor;
  final String usuario;
  final String avatarUrl;
  final String hace;
  final String texto;
  final String? imagenUrl;
  final int likes;
  final int comentarios;
  final EstiloFondoPublicacion estiloFondo;

  const PublicacionFeed({
    required this.id,
    required this.autor,
    required this.usuario,
    required this.avatarUrl,
    required this.hace,
    required this.texto,
    required this.imagenUrl,
    required this.likes,
    required this.comentarios,
    required this.estiloFondo,
  });
}
