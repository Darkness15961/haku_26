import '../../lugares/dominio/modelos/modelo_lugar.dart';
import 'feed_inicio_datasource_local.dart';

/// Semilla de la BD provisional. IDs compartidos entre tablas para concordancia.
class SemillaAlmacenHaku {
  static Map<String, dynamic> documento() {
    final perfiles = <Map<String, dynamic>>[
      ...FeedInicioDataSourceLocal.sugerencias.map(_perfilDeExplorador),
      _perfil(
        id: 'mariaq',
        nombre: 'María Quispe',
        usuario: '@mariaq',
        avatar:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&q=80',
        bioCorta: 'Amaneceres en piedra',
        bio: 'Salgo al amanecer. Sacsayhuamán, mercados y el silencio del apu.',
        portada:
            'https://images.unsplash.com/photo-1589802829985-817e51171b92?w=900&q=80',
        provincia: 'Cusco',
      ),
      _perfil(
        id: 'diegoandes',
        nombre: 'Diego Andes',
        usuario: '@diegoandes',
        avatar:
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&q=80',
        bioCorta: 'Tips de trekking',
        bio: 'Humantay, bastones y ritmo. Comparo rutas para no sufrir de más.',
        portada:
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=900&q=80',
        provincia: 'Anta',
      ),
      _perfil(
        id: 'sofiatrek',
        nombre: 'Sofía Trek',
        usuario: '@sofiatrek',
        avatar:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
        bioCorta: 'Montaña de colores',
        bio: 'Vinicunca cuando la niebla deja ver. Armo grupos para la próxima.',
        portada:
            'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=900&q=80',
        provincia: 'Canchis',
      ),
      _perfil(
        id: 'haku',
        nombre: 'Haku Community',
        usuario: '@haku',
        avatar:
            'https://images.unsplash.com/photo-1551632811-561732d1e306?w=400&q=80',
        bioCorta: 'La comunidad HAKU',
        bio: 'Rutas, historias y paisajes de Cusco. El mapa lo armamos juntos.',
        portada:
            'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=900&q=80',
        provincia: 'Cusco',
      ),
      _perfil(
        id: 'camilarios',
        nombre: 'Camila Ríos',
        usuario: '@camilarios',
        avatar:
            'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400&q=80',
        bioCorta: 'Turismo lento',
        bio: 'Pisac al mediodía: choclo, queso y charla con artesanos.',
        portada:
            'https://images.unsplash.com/photo-1555881403-96d4f9e83f0c?w=900&q=80',
        provincia: 'Calca',
      ),
      _perfil(
        id: 'yo',
        nombre: 'Camila Quispe',
        usuario: '@camila.haku',
        avatar:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80',
        bioCorta: 'Mapa vivo de Cusco',
        bio: 'Documentando Cusco: mercados, apus y rutas poco exploradas.',
        portada:
            'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=900&q=80',
        provincia: 'Cusco',
        seguidores: 1280,
        siguiendo: 86,
        meGusta: 9420,
        rutas: 8,
      ),
    ];

    final clips = <Map<String, dynamic>>[];
    for (final p in FeedInicioDataSourceLocal.sugerencias) {
      for (final c in p.publicaciones) {
        clips.add(_clip(c, p.id));
      }
    }
    for (final extra in [
      'mariaq',
      'diegoandes',
      'sofiatrek',
      'haku',
      'camilarios',
      'yo',
    ]) {
      final pubs = SugerenciaSeguimiento.demo(
        id: extra,
        nombre: extra,
        usuario: '@$extra',
        avatarUrl: '',
      ).publicaciones.take(6);
      for (final c in pubs) {
        clips.add(_clip(c, extra));
      }
    }

    final publicaciones = [
      _post(
        id: 'p1',
        autorId: 'mariaq',
        texto:
            'Salida al amanecer en Sacsayhuamán. El silencio de la piedra y la ciudad abajo… ¿alguien más madruga por estas vistas?',
        imagen:
            'https://images.unsplash.com/photo-1589802829985-817e51171b92?w=800&q=80',
        likes: 128,
        comentarios: 24,
        creadoEn: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      _post(
        id: 'p2',
        autorId: 'diegoandes',
        texto:
            'Tip rápido: si vas a Humantay, lleva bastones. El último tramo se siente, pero la laguna lo vale todo.',
        imagen:
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=900&q=80',
        likes: 86,
        comentarios: 31,
        creadoEn: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      _post(
        id: 'p3',
        autorId: 'sofiatrek',
        texto:
            'Vinicunca con poca niebla. Colores absurdos. Si alguien quiere armar grupo para la próxima, avisen acá.',
        imagen:
            'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&q=80',
        likes: 412,
        comentarios: 67,
        creadoEn: DateTime.now().subtract(const Duration(days: 1)),
      ),
      _post(
        id: 'p4',
        autorId: 'haku',
        texto:
            'Nuevas rutas recomendadas esta semana en el Valle Sagrado. ¿Cuál es tu próxima caminata?',
        imagen:
            'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=800&q=80',
        likes: 540,
        comentarios: 92,
        creadoEn: DateTime.now().subtract(const Duration(days: 1)),
      ),
      _post(
        id: 'p5',
        autorId: 'camilarios',
        texto:
            'Mercado de Pisac al mediodía: choclo, queso y una charla con artesanos. Turismo lento, el mejor.',
        imagen:
            'https://images.unsplash.com/photo-1555881403-96d4f9e83f0c?w=900&q=80',
        likes: 73,
        comentarios: 18,
        creadoEn: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ..._postsUsuarioLocal(),
    ];

    return {
      'version': 1,
      'perfiles': perfiles,
      'clips': clips,
      'publicaciones': publicaciones,
      'categorias_actividad': _categoriasActividad(),
      'comunidades': _comunidades(),
      'miembros_comunidad': _miembrosComunidad(),
      'interacciones': _interaccionesDemo(),
      'metricas_usuario': _metricasDemo(),
    };
  }

  static List<Map<String, dynamic>> _postsUsuarioLocal() {
    return [
      _post(
        id: 'yo_p1',
        autorId: 'yo',
        texto:
            'Primera vez en Moray. Las terrazas parecen un anfiteatro natural — anoté tip de horario para la próxima.',
        imagen:
            'https://images.unsplash.com/photo-1587595431973-160d0d94add1?w=800&q=80',
        likes: 64,
        comentarios: 11,
        creadoEn: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      _post(
        id: 'yo_p2',
        autorId: 'yo',
        texto:
            'Documenté un mirador poco marcado cerca de Chinchero. Si van, lleven agua y salgan temprano.',
        imagen:
            'https://images.unsplash.com/photo-1548013146-72479768bada?w=800&q=80',
        likes: 91,
        comentarios: 19,
        creadoEn: DateTime.now().subtract(const Duration(days: 2)),
      ),
      _post(
        id: 'yo_p3',
        autorId: 'yo',
        texto:
            'Humantay con cielo limpio. El esfuerzo del último tramo se olvida al instante.',
        imagen:
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
        likes: 203,
        comentarios: 34,
        creadoEn: DateTime.now().subtract(const Duration(days: 4)),
      ),
      _post(
        id: 'yo_p4',
        autorId: 'yo',
        texto:
            'Fogón en el mercado: choclo + queso. Turismo lento, el que más me gusta.',
        imagen:
            'https://images.unsplash.com/photo-1555881403-96d4f9e83f0c?w=800&q=80',
        likes: 47,
        comentarios: 8,
        creadoEn: DateTime.now().subtract(const Duration(days: 6)),
      ),
    ];
  }

  static Map<String, dynamic> _interaccionesDemo() {
    return {
      'demo_usuario_v1': true,
      'siguiendo_ids': <String>[
        's1',
        's2',
        's3',
        'mariaq',
        'diegoandes',
        'sofiatrek',
      ],
      'likes_publicacion_ids': <String>['p1', 'p3', 'p4'],
      'likes_clip_ids': <String>[],
      'guardados_publicacion_ids': <String>['p2', 'p5', 'yo_p1'],
      'favoritos_clip_ids': <String>[],
      'favoritos_ruta_ids': <String>[
        'machu_picchu',
        'laguna_humantay',
        'vinicunca',
        'maras_moray',
        'valle_sagrado',
      ],
      'comunidad_ids': <String>['com_trekkers', 'com_fotos', 'com_fogon'],
    };
  }

  static Map<String, dynamic> _metricasDemo() => {
        'documentados': 14,
        'experiencias_publicadas': 8,
        'salidas_enroladas': 3,
      };

  /// Completa colecciones nuevas sin borrar follows / likes ya guardados.
  static Map<String, dynamic> fusionar(Map<String, dynamic> doc) {
    final seed = documento();
    final comunidades = doc['comunidades'];
    if (comunidades is! List || comunidades.isEmpty) {
      doc['categorias_actividad'] = seed['categorias_actividad'];
      doc['comunidades'] = seed['comunidades'];
      doc['miembros_comunidad'] = seed['miembros_comunidad'];
    }
    doc['categorias_actividad'] ??= seed['categorias_actividad'];

    // Perfil + posts del usuario local (yo).
    final perfiles = [
      for (final e in (doc['perfiles'] as List<dynamic>? ?? []))
        if (e is Map) Map<String, dynamic>.from(e),
    ];
    if (!perfiles.any((p) => p['id'] == 'yo')) {
      final yo = (seed['perfiles'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .firstWhere((p) => p['id'] == 'yo');
      perfiles.add(yo);
      doc['perfiles'] = perfiles;
    }

    final pubs = [
      for (final e in (doc['publicaciones'] as List<dynamic>? ?? []))
        if (e is Map) Map<String, dynamic>.from(e),
    ];
    if (!pubs.any((p) => p['autor_id'] == 'yo')) {
      pubs.addAll(_postsUsuarioLocal());
      doc['publicaciones'] = pubs;
    }

    final clips = [
      for (final e in (doc['clips'] as List<dynamic>? ?? []))
        if (e is Map) Map<String, dynamic>.from(e),
    ];
    if (!clips.any((c) => c['autor_id'] == 'yo')) {
      final seedClips = (seed['clips'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((c) => c['autor_id'] == 'yo');
      clips.addAll(seedClips);
      doc['clips'] = clips;
    }

    final inter = Map<String, dynamic>.from(
      doc['interacciones'] as Map? ?? const {},
    );
    inter.putIfAbsent('comunidad_ids', () => <String>[]);
    inter.putIfAbsent('favoritos_ruta_ids', () => <String>[]);
    if (inter['demo_usuario_v1'] != true) {
      final demo = _interaccionesDemo();
      for (final e in demo.entries) {
        if (e.key == 'demo_usuario_v1') continue;
        final actual = inter[e.key];
        final vacio = actual is! List || actual.isEmpty;
        if (vacio) inter[e.key] = e.value;
      }
      inter['demo_usuario_v1'] = true;
    }
    doc['interacciones'] = inter;
    doc['metricas_usuario'] ??= _metricasDemo();
    return doc;
  }

  static List<Map<String, dynamic>> _categoriasActividad() {
    const desc = {
      CategoriaLugar.naturaleza: 'Lagunas, bosques y apus.',
      CategoriaLugar.cultura: 'Sitios, fiestas y saberes.',
      CategoriaLugar.gastronomia: 'Mercados, fogón y sabor local.',
      CategoriaLugar.aventura: 'Treks exigentes y altura.',
      CategoriaLugar.caminata: 'Caminos, andinismo y ritmo.',
      CategoriaLugar.fotografia: 'Luz, niebla y retrato andino.',
      CategoriaLugar.misterioso: 'Puentes vivos y relatos ocultos.',
      CategoriaLugar.magico: 'Apu, ofrenda y paisaje sagrado.',
    };
    return [
      for (final c in CategoriaLugar.values)
        {
          'id': c.name,
          'nombre': c.etiqueta,
          'descripcion': desc[c] ?? '',
        },
    ];
  }

  static List<Map<String, dynamic>> _comunidades() {
    return [
      _comunidad(
        id: 'com_trekkers',
        nombre: 'Trekkers Cusco',
        descripcion: 'Salidas semanales, aclimatación y tips de altura.',
        imagen:
            'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&q=80',
        creadorId: 's1',
        provincia: 'Anta',
        categorias: const [
          CategoriaLugar.caminata,
          CategoriaLugar.aventura,
        ],
      ),
      _comunidad(
        id: 'com_fotos',
        nombre: 'Fotógrafos Andinos',
        descripcion: 'Amaneceres, niebla y color. Workshops los fines.',
        imagen:
            'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=800&q=80',
        creadorId: 's2',
        provincia: 'Cusco',
        categorias: const [
          CategoriaLugar.fotografia,
          CategoriaLugar.naturaleza,
        ],
      ),
      _comunidad(
        id: 'com_inca',
        nombre: 'Ruta Inca Crew',
        descripcion: 'Preparación y logística del Camino Inca.',
        imagen:
            'https://images.unsplash.com/photo-1587595431973-160d0d94add1?w=800&q=80',
        creadorId: 'sofiatrek',
        provincia: 'Urubamba',
        categorias: const [
          CategoriaLugar.caminata,
          CategoriaLugar.cultura,
        ],
      ),
      _comunidad(
        id: 'com_fogon',
        nombre: 'Fogón Andino',
        descripcion: 'Mercados, choclo, queso y fogón de barrio.',
        imagen:
            'https://images.unsplash.com/photo-1555881403-96d4f9e83f0c?w=800&q=80',
        creadorId: 'camilarios',
        provincia: 'Calca',
        categorias: const [
          CategoriaLugar.gastronomia,
          CategoriaLugar.cultura,
        ],
      ),
      _comunidad(
        id: 'com_misterios',
        nombre: 'Apus y misterios',
        descripcion: 'Puentes vivos, relatos y sitios poco explorados.',
        imagen:
            'https://images.unsplash.com/photo-1548013146-72479768bada?w=800&q=80',
        creadorId: 's5',
        provincia: 'Canas',
        categorias: const [
          CategoriaLugar.misterioso,
          CategoriaLugar.magico,
          CategoriaLugar.cultura,
        ],
      ),
      _comunidad(
        id: 'com_naturaleza',
        nombre: 'Naturaleza Viva',
        descripcion: 'Lagunas, glaciares y bosque de nubes.',
        imagen:
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
        creadorId: 's4',
        provincia: 'Quispicanchi',
        categorias: const [
          CategoriaLugar.naturaleza,
          CategoriaLugar.fotografia,
        ],
      ),
      _comunidad(
        id: 'com_magia',
        nombre: 'Magia de los Apus',
        descripcion: 'Caminatas con ofrenda y paisaje sagrado.',
        imagen:
            'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?w=800&q=80',
        creadorId: 'sofiatrek',
        provincia: 'Canchis',
        categorias: const [
          CategoriaLugar.magico,
          CategoriaLugar.caminata,
        ],
      ),
      _comunidad(
        id: 'com_urbano',
        nombre: 'Cusco a pie',
        descripcion: 'Miradores, callejones y comida de barrio.',
        imagen:
            'https://images.unsplash.com/photo-1548013146-72479768bada?w=700&q=80',
        creadorId: 's3',
        provincia: 'Cusco',
        categorias: const [
          CategoriaLugar.cultura,
          CategoriaLugar.gastronomia,
        ],
      ),
      _comunidad(
        id: 'com_ciencia',
        nombre: 'Ciencia de altura',
        descripcion: 'Glaciares, ciencia ciudadana y nevados.',
        imagen:
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=700&q=80',
        creadorId: 's4',
        provincia: 'Quispicanchi',
        categorias: const [
          CategoriaLugar.naturaleza,
          CategoriaLugar.aventura,
        ],
      ),
      _comunidad(
        id: 'com_relatos',
        nombre: 'Relatos Pacha',
        descripcion: 'Historias de mercados, fiestas y caminos.',
        imagen:
            'https://images.unsplash.com/photo-1477587458883-47145ed94245?w=800&q=80',
        creadorId: 's5',
        provincia: 'Calca',
        categorias: const [
          CategoriaLugar.cultura,
          CategoriaLugar.misterioso,
        ],
      ),
    ];
  }

  static List<Map<String, dynamic>> _miembrosComunidad() {
    const mapa = <String, List<String>>{
      'com_trekkers': ['s1', 'diegoandes', 'sofiatrek', 'mariaq'],
      'com_fotos': ['s2', 'camilarios', 's4'],
      'com_inca': ['sofiatrek', 's1', 's3', 'diegoandes'],
      'com_fogon': ['camilarios', 'mariaq', 's5', 's3'],
      'com_misterios': ['s5', 's4', 'haku'],
      'com_naturaleza': ['s4', 's2', 'diegoandes'],
      'com_magia': ['sofiatrek', 's5', 'mariaq'],
      'com_urbano': ['s3', 'mariaq', 'camilarios', 'haku'],
      'com_ciencia': ['s4', 'diegoandes', 's1'],
      'com_relatos': ['s5', 'mariaq', 'haku', 's2'],
    };
    final out = <Map<String, dynamic>>[];
    var n = 0;
    mapa.forEach((comId, usuarios) {
      for (var i = 0; i < usuarios.length; i++) {
        n++;
        out.add({
          'id': 'mc_$n',
          'comunidad_id': comId,
          'usuario_id': usuarios[i],
          'rol': i == 0 ? 'admin' : 'miembro',
          'fecha_union': DateTime.now()
              .subtract(Duration(days: 40 - i * 3))
              .toIso8601String(),
        });
      }
    });
    return out;
  }

  static Map<String, dynamic> _comunidad({
    required String id,
    required String nombre,
    required String descripcion,
    required String imagen,
    required String creadorId,
    required String provincia,
    required List<CategoriaLugar> categorias,
  }) {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'imagen_url': imagen,
      'creador_id': creadorId,
      'provincia': provincia,
      'estado': 'activa',
      'categoria_ids': categorias.map((c) => c.name).toList(),
      'fecha_creacion': DateTime.now()
          .subtract(Duration(days: 20 + id.hashCode.abs() % 80))
          .toIso8601String(),
    };
  }

  static Map<String, dynamic> _perfilDeExplorador(SugerenciaSeguimiento p) {
    return _perfil(
      id: p.id,
      nombre: p.nombre,
      usuario: p.usuario,
      avatar: p.avatarUrl,
      bioCorta: p.bioCorta,
      bio: p.bio,
      portada: p.portadaUrl,
      provincia: p.provincia,
      seguidores: p.seguidores,
      siguiendo: p.siguiendo,
      meGusta: p.meGusta,
      rutas: p.rutas,
      favoritoIds: p.favoritos.map((c) => c.id).toList(),
    );
  }

  static Map<String, dynamic> _perfil({
    required String id,
    required String nombre,
    required String usuario,
    required String avatar,
    required String bioCorta,
    required String bio,
    required String portada,
    required String provincia,
    int? seguidores,
    int? siguiendo,
    int? meGusta,
    int? rutas,
    List<String>? favoritoIds,
  }) {
    final h = id.hashCode.abs();
    return {
      'id': id,
      'nombre': nombre,
      'usuario': usuario,
      'avatar_url': avatar,
      'bio_corta': bioCorta,
      'bio': bio,
      'portada_url': portada,
      'provincia': provincia,
      'seguidores': seguidores ?? 800 + (h % 9000),
      'siguiendo': siguiendo ?? 120 + (h % 400),
      'me_gusta': meGusta ?? 2400 + (h % 40000),
      'rutas': rutas ?? 4 + (h % 18),
      'favorito_ids': favoritoIds ?? <String>[],
    };
  }

  static Map<String, dynamic> _clip(ClipPerfil c, String autorId) {
    return {
      'id': c.id,
      'autor_id': autorId,
      'imagen_url': c.imagenUrl,
      'texto': c.texto,
      'vistas': c.vistas,
      'likes': c.likes,
      'comentarios': c.comentarios,
    };
  }

  static Map<String, dynamic> _post({
    required String id,
    required String autorId,
    required String texto,
    required String imagen,
    required int likes,
    required int comentarios,
    required DateTime creadoEn,
  }) {
    return {
      'id': id,
      'autor_id': autorId,
      'texto': texto,
      'imagen_url': imagen,
      'likes': likes,
      'comentarios': comentarios,
      'creado_en': creadoEn.toIso8601String(),
    };
  }
}
