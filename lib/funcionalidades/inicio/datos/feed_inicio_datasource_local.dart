import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';

/// Datos de demo para el feed de Inicio (sugerencias + publicaciones).
class FeedInicioDataSourceLocal {
  static final List<SugerenciaSeguimiento> sugerencias = [
    SugerenciaSeguimiento.demo(
      id: 's1',
      nombre: 'Andina Trek',
      usuario: '@andinatrek',
      avatarUrl: CatalogoImagenesHaku.avatar,
      bioCorta: 'Guías del Valle Sagrado',
      bio:
          'Guío treks en el Valle Sagrado hace 8 años. Rutas lentas, buen ritmo y respeto por las comunidades.',
      portadaUrl: CatalogoImagenesHaku.portadasExploradores[0],
      provincia: 'Urubamba',
    ),
    SugerenciaSeguimiento.demo(
      id: 's2',
      nombre: 'Luna Quechua',
      usuario: '@lunaquechua',
      avatarUrl: CatalogoImagenesHaku.avatar,
      bioCorta: 'Fotografía de altura',
      bio:
          'Fotógrafa de altura. Busco niebla, color y rostros en los apus. Workshops los fines de semana.',
      portadaUrl: CatalogoImagenesHaku.portadasExploradores[1],
      provincia: 'Cusco',
    ),
    SugerenciaSeguimiento.demo(
      id: 's3',
      nombre: 'Cusco Walks',
      usuario: '@cuscowalks',
      avatarUrl: CatalogoImagenesHaku.avatar,
      bioCorta: 'Rutas urbanas y miradores',
      bio:
          'Caminatas urbanas, miradores y comida de barrio. Si llegas a Cusco, te armo un recorrido a pie.',
      portadaUrl: CatalogoImagenesHaku.portadasExploradores[2],
      provincia: 'Cusco',
    ),
    SugerenciaSeguimiento.demo(
      id: 's4',
      nombre: 'Nevado Lab',
      usuario: '@nevadolab',
      avatarUrl: CatalogoImagenesHaku.avatar,
      bioCorta: 'Ciencia y montaña',
      bio:
          'Glaciares, ciencia ciudadana y salidas a nevados. Documentamos lo que el hielo todavía nos deja ver.',
      portadaUrl: CatalogoImagenesHaku.portadasExploradores[3],
      provincia: 'Quispicanchi',
    ),
    SugerenciaSeguimiento.demo(
      id: 's5',
      nombre: 'Pacha Stories',
      usuario: '@pachastories',
      avatarUrl: CatalogoImagenesHaku.avatar,
      bioCorta: 'Relatos del Ande',
      bio:
          'Relatos orales del Ande. Recojo historias de mercados, fiestas y caminos que no salen en la guía.',
      portadaUrl: CatalogoImagenesHaku.portadasExploradores[4],
      provincia: 'Calca',
    ),
  ];

  static const List<PublicacionFeed> publicaciones = [
    PublicacionFeed(
      id: 'p1',
      autor: 'María Quispe',
      usuario: '@mariaq',
      avatarUrl: CatalogoImagenesHaku.avatar,
      hace: '2h',
      texto:
          'Telar en Chinchero. Lana cardada, cochinilla y un aguayo que aún huele a humo de fogón.',
      imagenUrl: CatalogoImagenesHaku.tejido,
      likes: 128,
      comentarios: 24,
      estiloFondo: EstiloFondoPublicacion.veloNegro,
      lugarNombre: 'Chinchero',
      categoria: 'Tejido',
    ),
    PublicacionFeed(
      id: 'p2',
      autor: 'Diego Andes',
      usuario: '@diegoandes',
      avatarUrl: CatalogoImagenesHaku.avatar,
      hace: '5h',
      texto:
          'Barro en San Blas. Platos, qeros y el horno que tarda tres días en enfriarse.',
      imagenUrl: CatalogoImagenesHaku.ceramica,
      likes: 86,
      comentarios: 31,
      estiloFondo: EstiloFondoPublicacion.veloBlanco,
      lugarNombre: 'San Blas',
      categoria: 'Cerámica',
    ),
    PublicacionFeed(
      id: 'p3',
      autor: 'Sofía Trek',
      usuario: '@sofiatrek',
      avatarUrl: CatalogoImagenesHaku.avatar,
      hace: 'Ayer',
      texto:
          'Caldo en San Pedro. Choclo, queso y la mesa que no cierra hasta mediodía.',
      imagenUrl: CatalogoImagenesHaku.comida,
      likes: 412,
      comentarios: 67,
      estiloFondo: EstiloFondoPublicacion.sinVelo,
      lugarNombre: 'San Pedro',
      categoria: 'Fogón',
    ),
    PublicacionFeed(
      id: 'p4',
      autor: 'Haku Community',
      usuario: '@haku',
      avatarUrl: CatalogoImagenesHaku.avatar,
      hace: '1d',
      texto:
          'Inti Raymi en escena. Danza, traje y sol sobre Sacsayhuamán — teatro vivo, no postal.',
      imagenUrl: CatalogoImagenesHaku.teatro,
      likes: 540,
      comentarios: 92,
      estiloFondo: EstiloFondoPublicacion.veloNegroSuave,
      lugarNombre: 'Sacsayhuamán',
      categoria: 'Teatro',
    ),
    PublicacionFeed(
      id: 'p5',
      autor: 'Camila Ríos',
      usuario: '@camilarios',
      avatarUrl: CatalogoImagenesHaku.avatar,
      hace: '2d',
      texto:
          'Taller en San Blas. Apus en lienzo y mano que no tiembla — pintura que documenta, no decora.',
      imagenUrl: CatalogoImagenesHaku.pintura,
      likes: 73,
      comentarios: 18,
      estiloFondo: EstiloFondoPublicacion.veloBlanco,
      lugarNombre: 'San Blas',
      categoria: 'Pintura',
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
      avatarUrl: CatalogoImagenesHaku.resolverAvatar(
        m['avatar_url'] as String?,
      ),
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

class ComentarioPublicacion {
  final String id;
  final String publicacionId;
  final String autorId;
  final String texto;
  final DateTime creadoEn;

  const ComentarioPublicacion({
    required this.id,
    required this.publicacionId,
    required this.autorId,
    required this.texto,
    required this.creadoEn,
  });

  factory ComentarioPublicacion.desdeMapa(Map<String, dynamic> m) {
    return ComentarioPublicacion(
      id: m['id'] as String? ?? '',
      publicacionId: m['publicacion_id'] as String? ?? '',
      autorId: m['autor_id'] as String? ?? '',
      texto: m['texto'] as String? ?? '',
      creadoEn: DateTime.tryParse(m['creado_en'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> aMapa() => {
        'id': id,
        'publicacion_id': publicacionId,
        'autor_id': autorId,
        'texto': texto,
        'creado_en': creadoEn.toIso8601String(),
      };
}

class MensajeDirecto {
  final String id;
  final String conversacionId;
  final String autorId;
  final String texto;
  final DateTime creadoEn;

  const MensajeDirecto({
    required this.id,
    required this.conversacionId,
    required this.autorId,
    required this.texto,
    required this.creadoEn,
  });

  factory MensajeDirecto.desdeMapa(Map<String, dynamic> m) {
    return MensajeDirecto(
      id: m['id'] as String? ?? '',
      conversacionId: m['conversacion_id'] as String? ?? '',
      autorId: m['autor_id'] as String? ?? '',
      texto: m['texto'] as String? ?? '',
      creadoEn: DateTime.tryParse(m['creado_en'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> aMapa() => {
        'id': id,
        'conversacion_id': conversacionId,
        'autor_id': autorId,
        'texto': texto,
        'creado_en': creadoEn.toIso8601String(),
      };
}
