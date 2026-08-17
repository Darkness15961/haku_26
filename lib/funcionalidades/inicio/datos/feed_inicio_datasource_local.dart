/// Datos de demo para el feed de Inicio (sugerencias + publicaciones).
class FeedInicioDataSourceLocal {
  static final List<SugerenciaSeguimiento> sugerencias = [
    SugerenciaSeguimiento.demo(
      id: 's1',
      nombre: 'Andina Trek',
      usuario: '@andinatrek',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
      bioCorta: 'Guías del Valle Sagrado',
      bio:
          'Guío treks en el Valle Sagrado hace 8 años. Rutas lentas, buen ritmo y respeto por las comunidades.',
      portadaUrl:
          'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=900&q=80',
      provincia: 'Urubamba',
    ),
    SugerenciaSeguimiento.demo(
      id: 's2',
      nombre: 'Luna Quechua',
      usuario: '@lunaquechua',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80',
      bioCorta: 'Fotografía de altura',
      bio:
          'Fotógrafa de altura. Busco niebla, color y rostros en los apus. Workshops los fines de semana.',
      portadaUrl:
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=900&q=80',
      provincia: 'Cusco',
    ),
    SugerenciaSeguimiento.demo(
      id: 's3',
      nombre: 'Cusco Walks',
      usuario: '@cuscowalks',
      avatarUrl:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&q=80',
      bioCorta: 'Rutas urbanas y miradores',
      bio:
          'Caminatas urbanas, miradores y comida de barrio. Si llegas a Cusco, te armo un recorrido a pie.',
      portadaUrl:
          'https://images.unsplash.com/photo-1548013146-72479768bada?w=900&q=80',
      provincia: 'Cusco',
    ),
    SugerenciaSeguimiento.demo(
      id: 's4',
      nombre: 'Nevado Lab',
      usuario: '@nevadolab',
      avatarUrl:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&q=80',
      bioCorta: 'Ciencia y montaña',
      bio:
          'Glaciares, ciencia ciudadana y salidas a nevados. Documentamos lo que el hielo todavía nos deja ver.',
      portadaUrl:
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=900&q=80',
      provincia: 'Quispicanchi',
    ),
    SugerenciaSeguimiento.demo(
      id: 's5',
      nombre: 'Pacha Stories',
      usuario: '@pachastories',
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&q=80',
      bioCorta: 'Relatos del Ande',
      bio:
          'Relatos orales del Ande. Recojo historias de mercados, fiestas y caminos que no salen en la guía.',
      portadaUrl:
          'https://images.unsplash.com/photo-1587595431973-160d0d94add1?w=900&q=80',
      provincia: 'Calca',
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
      imagenUrl:
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=900&q=80',
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
      imagenUrl:
          'https://images.unsplash.com/photo-1555881403-96d4f9e83f0c?w=900&q=80',
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

class ClipPerfil {
  final String id;
  final String autorId;
  final String imagenUrl;
  final int vistas;
  final int likes;
  final int comentarios;
  final String texto;

  const ClipPerfil({
    required this.id,
    this.autorId = '',
    required this.imagenUrl,
    required this.vistas,
    required this.likes,
    required this.comentarios,
    required this.texto,
  });

  ClipPerfil copyWith({int? vistas, int? likes}) {
    return ClipPerfil(
      id: id,
      autorId: autorId,
      imagenUrl: imagenUrl,
      vistas: vistas ?? this.vistas,
      likes: likes ?? this.likes,
      comentarios: comentarios,
      texto: texto,
    );
  }

  factory ClipPerfil.desdeMapa(Map<String, dynamic> m) {
    return ClipPerfil(
      id: m['id'] as String? ?? '',
      autorId: m['autor_id'] as String? ?? '',
      imagenUrl: m['imagen_url'] as String? ?? '',
      vistas: (m['vistas'] as num?)?.toInt() ?? 0,
      likes: (m['likes'] as num?)?.toInt() ?? 0,
      comentarios: (m['comentarios'] as num?)?.toInt() ?? 0,
      texto: m['texto'] as String? ?? '',
    );
  }

  Map<String, dynamic> aMapa() => {
        'id': id,
        'autor_id': autorId,
        'imagen_url': imagenUrl,
        'texto': texto,
        'vistas': vistas,
        'likes': likes,
        'comentarios': comentarios,
      };
}

class SugerenciaSeguimiento {
  final String id;
  final String nombre;
  final String usuario;
  final String avatarUrl;
  final String bioCorta;
  final String bio;
  final String portadaUrl;
  final String provincia;
  final int seguidores;
  final int siguiendo;
  final int meGusta;
  final int rutas;
  final List<ClipPerfil> publicaciones;
  final List<ClipPerfil> favoritos;

  const SugerenciaSeguimiento({
    required this.id,
    required this.nombre,
    required this.usuario,
    required this.avatarUrl,
    required this.bioCorta,
    this.bio = '',
    this.portadaUrl = '',
    this.provincia = 'Cusco',
    this.seguidores = 0,
    this.siguiendo = 0,
    this.meGusta = 0,
    this.rutas = 0,
    this.publicaciones = const [],
    this.favoritos = const [],
  });

  SugerenciaSeguimiento copyWith({
    int? seguidores,
    int? meGusta,
    List<ClipPerfil>? publicaciones,
    List<ClipPerfil>? favoritos,
  }) {
    return SugerenciaSeguimiento(
      id: id,
      nombre: nombre,
      usuario: usuario,
      avatarUrl: avatarUrl,
      bioCorta: bioCorta,
      bio: bio,
      portadaUrl: portadaUrl,
      provincia: provincia,
      seguidores: seguidores ?? this.seguidores,
      siguiendo: siguiendo,
      meGusta: meGusta ?? this.meGusta,
      rutas: rutas,
      publicaciones: publicaciones ?? this.publicaciones,
      favoritos: favoritos ?? this.favoritos,
    );
  }

  factory SugerenciaSeguimiento.desdeMapa(
    Map<String, dynamic> m, {
    List<ClipPerfil> publicaciones = const [],
    List<ClipPerfil> favoritos = const [],
  }) {
    return SugerenciaSeguimiento(
      id: m['id'] as String? ?? '',
      nombre: m['nombre'] as String? ?? '',
      usuario: m['usuario'] as String? ?? '',
      avatarUrl: m['avatar_url'] as String? ?? '',
      bioCorta: m['bio_corta'] as String? ?? '',
      bio: m['bio'] as String? ?? '',
      portadaUrl: m['portada_url'] as String? ?? '',
      provincia: m['provincia'] as String? ?? 'Cusco',
      seguidores: (m['seguidores'] as num?)?.toInt() ?? 0,
      siguiendo: (m['siguiendo'] as num?)?.toInt() ?? 0,
      meGusta: (m['me_gusta'] as num?)?.toInt() ?? 0,
      rutas: (m['rutas'] as num?)?.toInt() ?? 0,
      publicaciones: publicaciones,
      favoritos: favoritos,
    );
  }

  Map<String, dynamic> aMapa() => {
        'id': id,
        'nombre': nombre,
        'usuario': usuario,
        'avatar_url': avatarUrl,
        'bio_corta': bioCorta,
        'bio': bio,
        'portada_url': portadaUrl,
        'provincia': provincia,
        'seguidores': seguidores,
        'siguiendo': siguiendo,
        'me_gusta': meGusta,
        'rutas': rutas,
        'favorito_ids': favoritos.map((c) => c.id).toList(),
      };

  factory SugerenciaSeguimiento.demo({
    required String id,
    required String nombre,
    required String usuario,
    required String avatarUrl,
    String bioCorta = '',
    String bio = '',
    String portadaUrl = '',
    String provincia = 'Cusco',
  }) {
    final pubs = _clipsDe(id);
    return SugerenciaSeguimiento(
      id: id,
      nombre: nombre,
      usuario: usuario,
      avatarUrl: avatarUrl,
      bioCorta: bioCorta,
      bio: bio,
      portadaUrl: portadaUrl,
      provincia: provincia,
      seguidores: 800 + (id.hashCode.abs() % 9000),
      siguiendo: 120 + (id.hashCode.abs() % 400),
      meGusta: 2400 + (id.hashCode.abs() % 40000),
      rutas: 4 + (id.hashCode.abs() % 18),
      publicaciones: pubs,
      favoritos: pubs.reversed.take(6).toList(),
    );
  }
}

const _fotosClips = [
  'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=700&q=80',
  'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=700&q=80',
  'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=700&q=80',
  'https://images.unsplash.com/photo-1587595431973-160d0d94add1?w=700&q=80',
  'https://images.unsplash.com/photo-1548013146-72479768bada?w=700&q=80',
  'https://images.unsplash.com/photo-1589802829985-817e51171b92?w=700&q=80',
  'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?w=700&q=80',
  'https://images.unsplash.com/photo-1477587458883-47145ed94245?w=700&q=80',
  'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=700&q=70',
];

const _textosClips = [
  'Amanecer en el Apu',
  'Niebla en el valle',
  'Laguna de altura',
  'Camino de piedra',
  'Mercado de Pisac',
  'Cusco desde arriba',
  'Ruta con llamas',
  'Atardecer andino',
  'Bosque de nubes',
];

List<ClipPerfil> _clipsDe(String seed) {
  final h = seed.hashCode.abs();
  return List.generate(9, (i) {
    return ClipPerfil(
      id: '$seed-$i',
      autorId: seed,
      imagenUrl: _fotosClips[(h + i) % _fotosClips.length],
      vistas: 1800 + ((h + i * 7919) % 48000),
      likes: 90 + ((h + i * 313) % 2400),
      comentarios: 6 + ((h + i * 17) % 180),
      texto: _textosClips[i % _textosClips.length],
    );
  });
}

String formatearConteo(int n) {
  if (n >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
  }
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
  }
  return '$n';
}

class PublicacionFeed {
  final String id;
  final String autorId;
  final String autor;
  final String usuario;
  final String avatarUrl;
  final String hace;
  final String texto;
  final String? imagenUrl;
  final int likes;
  final int comentarios;
  final EstiloFondoPublicacion estiloFondo;
  final DateTime? creadoEn;
  final String? lugarId;
  final String? lugarNombre;
  final String? categoria;

  const PublicacionFeed({
    required this.id,
    this.autorId = '',
    required this.autor,
    required this.usuario,
    required this.avatarUrl,
    required this.hace,
    required this.texto,
    required this.imagenUrl,
    required this.likes,
    required this.comentarios,
    required this.estiloFondo,
    this.creadoEn,
    this.lugarId,
    this.lugarNombre,
    this.categoria,
  });

  PublicacionFeed copyWith({int? likes, int? comentarios}) {
    return PublicacionFeed(
      id: id,
      autorId: autorId,
      autor: autor,
      usuario: usuario,
      avatarUrl: avatarUrl,
      hace: hace,
      texto: texto,
      imagenUrl: imagenUrl,
      likes: likes ?? this.likes,
      comentarios: comentarios ?? this.comentarios,
      estiloFondo: estiloFondo,
      creadoEn: creadoEn,
      lugarId: lugarId,
      lugarNombre: lugarNombre,
      categoria: categoria,
    );
  }

  Map<String, dynamic> aMapa() => {
        'id': id,
        'autor_id': autorId,
        'texto': texto,
        'imagen_url': imagenUrl,
        'likes': likes,
        'comentarios': comentarios,
        'creado_en': creadoEn?.toIso8601String(),
        'lugar_id': lugarId,
        'lugar_nombre': lugarNombre,
        'categoria': categoria,
      };
}
