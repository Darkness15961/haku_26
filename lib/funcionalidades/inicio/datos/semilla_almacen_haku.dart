import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
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
        avatar: CatalogoImagenesHaku.avatar,
        bioCorta: 'Amaneceres en piedra',
        bio: 'Salgo al amanecer. Sacsayhuamán, mercados y el silencio del apu.',
        portada: CatalogoImagenesHaku.encabezadoRutas,
        provincia: 'Cusco',
      ),
      _perfil(
        id: 'diegoandes',
        nombre: 'Diego Andes',
        usuario: '@diegoandes',
        avatar: CatalogoImagenesHaku.avatar,
        bioCorta: 'Tips de trekking',
        bio: 'Humantay, bastones y ritmo. Comparo rutas para no sufrir de más.',
        portada: CatalogoImagenesHaku.ausangate,
        provincia: 'Anta',
      ),
      _perfil(
        id: 'sofiatrek',
        nombre: 'Sofía Trek',
        usuario: '@sofiatrek',
        avatar: CatalogoImagenesHaku.avatar,
        bioCorta: 'Montaña de colores',
        bio: 'Vinicunca cuando la niebla deja ver. Armo grupos para la próxima.',
        portada: CatalogoImagenesHaku.machuPicchu,
        provincia: 'Canchis',
      ),
      _perfil(
        id: 'haku',
        nombre: 'Haku Community',
        usuario: '@haku',
        avatar: CatalogoImagenesHaku.avatar,
        bioCorta: 'La comunidad HAKU',
        bio: 'Rutas, historias y paisajes de Cusco. El mapa lo armamos juntos.',
        portada: CatalogoImagenesHaku.fondoHaku,
        provincia: 'Cusco',
      ),
      _perfil(
        id: 'camilarios',
        nombre: 'Camila Ríos',
        usuario: '@camilarios',
        avatar: CatalogoImagenesHaku.avatar,
        bioCorta: 'Turismo lento',
        bio: 'Pisac al mediodía: choclo, queso y charla con artesanos.',
        portada: CatalogoImagenesHaku.moray,
        provincia: 'Calca',
      ),
      _perfil(
        id: 'yo',
        nombre: 'Camila Quispe',
        usuario: '@camila.haku',
        avatar: CatalogoImagenesHaku.avatar,
        bioCorta: 'Mapa vivo de Cusco',
        bio: 'Cusco.',
        portada: CatalogoImagenesHaku.fondoPublicaciones,
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
        avatarUrl: CatalogoImagenesHaku.avatar,
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
            'Telar en Chinchero. Lana cardada, cochinilla y un aguayo que aún huele a humo de fogón.',
        imagen: CatalogoImagenesHaku.tejido,
        likes: 128,
        comentarios: 24,
        creadoEn: DateTime.now().subtract(const Duration(hours: 2)),
        lugarId: 'chinchero',
        lugarNombre: 'Chinchero',
        categoria: 'Tejido',
      ),
      _post(
        id: 'p2',
        autorId: 'diegoandes',
        texto:
            'Barro en San Blas. Platos, qeros y el horno que tarda tres días en enfriarse.',
        imagen: CatalogoImagenesHaku.ceramica,
        likes: 86,
        comentarios: 31,
        creadoEn: DateTime.now().subtract(const Duration(hours: 5)),
        lugarId: 'san_blas',
        lugarNombre: 'San Blas',
        categoria: 'Cerámica',
      ),
      _post(
        id: 'p3',
        autorId: 'sofiatrek',
        texto:
            'Caldo en San Pedro. Choclo, queso y la mesa que no cierra hasta mediodía.',
        imagen: CatalogoImagenesHaku.comida,
        likes: 412,
        comentarios: 67,
        creadoEn: DateTime.now().subtract(const Duration(days: 1)),
        lugarId: 'san_pedro',
        lugarNombre: 'San Pedro',
        categoria: 'Fogón',
      ),
      _post(
        id: 'p4',
        autorId: 'haku',
        texto:
            'Inti Raymi en escena. Danza, traje y sol sobre Sacsayhuamán — teatro vivo, no postal.',
        imagen: CatalogoImagenesHaku.teatro,
        likes: 540,
        comentarios: 92,
        creadoEn: DateTime.now().subtract(const Duration(days: 1)),
        lugarId: 'machu_picchu',
        lugarNombre: 'Sacsayhuamán',
        categoria: 'Teatro',
      ),
      _post(
        id: 'p5',
        autorId: 'camilarios',
        texto:
            'Taller en San Blas. Apus en lienzo y mano que no tiembla — pintura que documenta, no decora.',
        imagen: CatalogoImagenesHaku.pintura,
        likes: 73,
        comentarios: 18,
        creadoEn: DateTime.now().subtract(const Duration(days: 2)),
        lugarId: 'san_blas',
        lugarNombre: 'San Blas',
        categoria: 'Pintura',
      ),
      ..._postsUsuarioLocal(),
    ];

    return {
      'version': 3,
      'perfiles': perfiles,
      'clips': clips,
      'publicaciones': publicaciones,
      'categorias_actividad': _categoriasActividad(),
      'comunidades': _comunidades(),
      'miembros_comunidad': _miembrosComunidad(),
      'interacciones': _interaccionesDemo(),
      'metricas_usuario': _metricasDemo(),
      'comentarios': _comentariosDemo(),
      'lugares_creados': <Map<String, dynamic>>[],
      'salidas': _salidasSemilla(),
      'grupos_ruta': _gruposSemilla(),
      'mensajes_directos': _mensajesSemilla(),
    };
  }

  static List<Map<String, dynamic>> _postsUsuarioLocal() {
    return [
      _post(
        id: 'yo_p1',
        autorId: 'yo',
        texto:
            'Aprendí a urdir en Chinchero. Tres horas y todavía no entiendo cómo leen el patrón de memoria.',
        imagen: CatalogoImagenesHaku.tejido,
        likes: 64,
        comentarios: 11,
        creadoEn: DateTime.now().subtract(const Duration(hours: 8)),
        lugarId: 'chinchero',
        lugarNombre: 'Chinchero',
        categoria: 'Tejido',
      ),
      _post(
        id: 'yo_p2',
        autorId: 'yo',
        texto:
            'Primera vez modelando barro. San Blas, horno compartido y manos negras de arcilla.',
        imagen: CatalogoImagenesHaku.ceramica,
        likes: 91,
        comentarios: 19,
        creadoEn: DateTime.now().subtract(const Duration(days: 2)),
        lugarNombre: 'San Blas',
        categoria: 'Cerámica',
      ),
      _post(
        id: 'yo_p3',
        autorId: 'yo',
        texto:
            'Fogón en San Pedro: choclo, queso y caldo. Turismo lento, el que más me gusta.',
        imagen: CatalogoImagenesHaku.comida,
        likes: 203,
        comentarios: 34,
        creadoEn: DateTime.now().subtract(const Duration(days: 4)),
        lugarNombre: 'San Pedro',
        categoria: 'Fogón',
      ),
      _post(
        id: 'yo_p4',
        autorId: 'yo',
        texto:
            'Fogón en el mercado: choclo + queso. Turismo lento, el que más me gusta.',
        imagen: CatalogoImagenesHaku.comida,
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

  static List<Map<String, dynamic>> _comentariosDemo() {
    final ahora = DateTime.now();
    return [
      {
        'id': 'cm_p1_1',
        'publicacion_id': 'p1',
        'autor_id': 'diegoandes',
        'texto': 'Anotado. Salgo temprano.',
        'creado_en': ahora.subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 'cm_p1_2',
        'publicacion_id': 'p1',
        'autor_id': 's1',
        'texto': 'Lleva protector. El sol pega fuerte.',
        'creado_en': ahora.subtract(const Duration(hours: 5)).toIso8601String(),
      },
      {
        'id': 'cm_yo1_1',
        'publicacion_id': 'yo_p1',
        'autor_id': 'mariaq',
        'texto': 'Moray a esa hora está vacío. Buen tip.',
        'creado_en': ahora.subtract(const Duration(hours: 3)).toIso8601String(),
      },
    ];
  }

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
    var pubsTocadas = false;
    if (!pubs.any((p) => p['autor_id'] == 'yo')) {
      pubs.addAll(_postsUsuarioLocal());
      pubsTocadas = true;
    }
    const lugaresSemilla = {
      'yo_p1': ('chinchero', 'Chinchero'),
      'yo_p2': ('san_blas', 'San Blas'),
      'yo_p3': ('san_pedro', 'San Pedro'),
    };
    for (final p in pubs) {
      final id = p['id']?.toString();
      final lugar = lugaresSemilla[id];
      if (lugar == null) continue;
      if ((p['lugar_nombre'] as String?)?.trim().isNotEmpty == true) continue;
      p['lugar_id'] = lugar.$1;
      p['lugar_nombre'] = lugar.$2;
      pubsTocadas = true;
    }
    if (pubsTocadas) {
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
    if (inter['cultura_feed_v3'] != true) {
      const culturaFeed = {
        'p1': {
          'texto':
              'Telar en Chinchero. Lana cardada, cochinilla y un aguayo que aún huele a humo de fogón.',
          'imagen_url': CatalogoImagenesHaku.tejido,
          'lugar_id': 'chinchero',
          'lugar_nombre': 'Chinchero',
          'categoria': 'Tejido',
        },
        'p2': {
          'texto':
              'Barro en San Blas. Platos, qeros y el horno que tarda tres días en enfriarse.',
          'imagen_url': CatalogoImagenesHaku.ceramica,
          'lugar_id': 'san_blas',
          'lugar_nombre': 'San Blas',
          'categoria': 'Cerámica',
        },
        'p3': {
          'texto':
              'Caldo en San Pedro. Choclo, queso y la mesa que no cierra hasta mediodía.',
          'imagen_url': CatalogoImagenesHaku.comida,
          'lugar_id': 'san_pedro',
          'lugar_nombre': 'San Pedro',
          'categoria': 'Fogón',
        },
        'p4': {
          'texto':
              'Inti Raymi en escena. Danza, traje y sol sobre Sacsayhuamán — teatro vivo, no postal.',
          'imagen_url': CatalogoImagenesHaku.teatro,
          'lugar_id': 'machu_picchu',
          'lugar_nombre': 'Sacsayhuamán',
          'categoria': 'Teatro',
        },
        'p5': {
          'texto':
              'Taller en San Blas. Apus en lienzo y mano que no tiembla — pintura que documenta, no decora.',
          'imagen_url': CatalogoImagenesHaku.pintura,
          'lugar_id': 'san_blas',
          'lugar_nombre': 'San Blas',
          'categoria': 'Pintura',
        },
      };
      final pubsPatch = [
        for (final e in (doc['publicaciones'] as List<dynamic>? ?? []))
          if (e is Map) Map<String, dynamic>.from(e),
      ];
      var tocadas = false;
      for (final p in pubsPatch) {
        final patch = culturaFeed[p['id']?.toString()];
        if (patch == null) continue;
        p.addAll(patch);
        tocadas = true;
      }
      if (tocadas) doc['publicaciones'] = pubsPatch;
      inter['cultura_feed_v2'] = true;
      inter['cultura_feed_v3'] = true;
    }
    if (inter['comunidades_imagenes_v1'] != true) {
      const imagenesCom = {
        'com_trekkers': CatalogoImagenesHaku.ausangate,
        'com_fotos': CatalogoImagenesHaku.moray,
        'com_inca': CatalogoImagenesHaku.machuPicchu,
        'com_fogon': CatalogoImagenesHaku.comida,
        'com_misterios': CatalogoImagenesHaku.huacachina,
        'com_naturaleza': CatalogoImagenesHaku.ausangate,
        'com_magia': CatalogoImagenesHaku.llamaMachu,
        'com_urbano': CatalogoImagenesHaku.encabezadoRutas,
        'com_ciencia': CatalogoImagenesHaku.ausangate,
        'com_relatos': CatalogoImagenesHaku.machuPicchu,
      };
      final coms = [
        for (final e in (doc['comunidades'] as List<dynamic>? ?? []))
          if (e is Map) Map<String, dynamic>.from(e),
      ];
      for (final c in coms) {
        final id = c['id']?.toString();
        final img = imagenesCom[id];
        if (img != null) c['imagen_url'] = img;
      }
      if (coms.isNotEmpty) doc['comunidades'] = coms;
      inter['comunidades_imagenes_v1'] = true;
    }
    if (inter['avatares_locales_v1'] != true) {
      final avatarLocal = CatalogoImagenesHaku.avatar;
      final perfilesPatch = [
        for (final e in (doc['perfiles'] as List<dynamic>? ?? []))
          if (e is Map) Map<String, dynamic>.from(e),
      ];
      for (final p in perfilesPatch) {
        final av = p['avatar_url']?.toString() ?? '';
        if (av.isEmpty || av.startsWith('http')) {
          p['avatar_url'] = avatarLocal;
        }
      }
      if (perfilesPatch.isNotEmpty) doc['perfiles'] = perfilesPatch;
      inter['avatares_locales_v1'] = true;
    }
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
    doc['comentarios'] ??= _comentariosDemo();
    doc['lugares_creados'] ??= <Map<String, dynamic>>[];
    if (doc['salidas'] is! List || (doc['salidas'] as List).isEmpty) {
      doc['salidas'] = seed['salidas'];
    } else {
      final salidas = [
        for (final e in doc['salidas'] as List)
          if (e is Map) Map<String, dynamic>.from(e),
      ];
      var tocadas = false;
      for (final s in salidas) {
        final ids = s['inscrito_ids'];
        if (ids is List && ids.isNotEmpty) continue;
        final seedMatch = (seed['salidas'] as List)
            .whereType<Map>()
            .cast<Map<String, dynamic>>()
            .where((x) => x['id'] == s['id']);
        if (seedMatch.isEmpty) continue;
        s['inscrito_ids'] = seedMatch.first['inscrito_ids'];
        s['checkin_ids'] ??= seedMatch.first['checkin_ids'];
        tocadas = true;
      }
      if (tocadas) doc['salidas'] = salidas;
    }
    if (doc['grupos_ruta'] is! List || (doc['grupos_ruta'] as List).isEmpty) {
      doc['grupos_ruta'] = seed['grupos_ruta'];
    }
    if (doc['mensajes_directos'] is! List ||
        (doc['mensajes_directos'] as List).isEmpty) {
      doc['mensajes_directos'] = seed['mensajes_directos'];
    }
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
        imagen: CatalogoImagenesHaku.ausangate,
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
        imagen: CatalogoImagenesHaku.moray,
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
        imagen: CatalogoImagenesHaku.machuPicchu,
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
        imagen: CatalogoImagenesHaku.comida,
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
        imagen: CatalogoImagenesHaku.huacachina,
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
        imagen: CatalogoImagenesHaku.ausangate,
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
        imagen: CatalogoImagenesHaku.llamaMachu,
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
        imagen: CatalogoImagenesHaku.encabezadoRutas,
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
        imagen: CatalogoImagenesHaku.fondoExplora,
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
        imagen: CatalogoImagenesHaku.machuPicchu,
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
    String? lugarId,
    String? lugarNombre,
    String? categoria,
  }) {
    return {
      'id': id,
      'autor_id': autorId,
      'texto': texto,
      'imagen_url': imagen,
      'likes': likes,
      'comentarios': comentarios,
      'creado_en': creadoEn.toIso8601String(),
      'lugar_id': lugarId,
      'lugar_nombre': lugarNombre,
      'categoria': categoria,
    };
  }

  static List<Map<String, dynamic>> _salidasSemilla() {
    return [
      {
        'id': 's1',
        'lugar_id': 'laguna_humantay',
        'lugar_nombre': 'Laguna Humantay',
        'organizador_nombre': 'Carlos',
        'fecha': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'hora': '5:30 AM',
        'punto_encuentro': 'Plaza de Armas',
        'cupos': 10,
        'inscritos': 3,
        'minimo': 4,
        'dificultad': 'Moderada',
        'grupo': 'Trekkers Cusco',
        'comunidad_id': 'com_trekkers',
        'inscrito_ids': ['s1', 's2', 'diegoandes'],
        'checkin_ids': ['s1'],
      },
      {
        'id': 's2',
        'lugar_id': 'moray',
        'lugar_nombre': 'Moray',
        'organizador_nombre': 'Ana',
        'fecha': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        'hora': '7:00 AM',
        'punto_encuentro': 'Cristo Blanco',
        'cupos': 8,
        'inscritos': 2,
        'minimo': 3,
        'dificultad': 'Fácil',
        'grupo': 'Fotógrafos Andinos',
        'comunidad_id': 'com_fotos',
        'inscrito_ids': ['s2', 'sofiatrek'],
        'checkin_ids': <String>[],
      },
    ];
  }

  static List<Map<String, dynamic>> _gruposSemilla() {
    return [
      {
        'id': 'g_demo',
        'nombre': 'Humantay Team',
        'creador_id': 'yo',
        'es_creador': true,
        'ruta_id': 'laguna_humantay',
        'ruta_titulo': 'Laguna Humantay',
        'miembro_ids': ['s1', 's2'],
        'ultimo_mensaje': 'Nos vemos a las 5 am en el punto.',
        'hace': '40m',
      },
    ];
  }

  static List<Map<String, dynamic>> _mensajesSemilla() {
    return [
      {
        'id': 'md_seed_1',
        'conversacion_id': 'mariaq',
        'autor_id': 'mariaq',
        'texto': '¿Salimos mañana a Sacsayhuamán?',
        'creado_en':
            DateTime.now().subtract(const Duration(minutes: 12)).toIso8601String(),
      },
      {
        'id': 'md_seed_2',
        'conversacion_id': 'diegoandes',
        'autor_id': 'diegoandes',
        'texto': 'Lleva bastones para Humantay.',
        'creado_en':
            DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
    ];
  }
}
