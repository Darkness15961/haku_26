/// Categorías de filtrado de la lista de rutas (guía visual).
enum CategoriaRuta { recomendadas, populares, naturaleza, cultura }

/// Qué documenta la ruta: un camino o un hilo de cultura viva.
enum HiloCultura { camino, tejido, ceramica, comida, teatro, pintura }

extension HiloCulturaX on HiloCultura {
  String get etiqueta {
    switch (this) {
      case HiloCultura.camino:
        return 'Camino';
      case HiloCultura.tejido:
        return 'Tejido';
      case HiloCultura.ceramica:
        return 'Cerámica';
      case HiloCultura.comida:
        return 'Comida';
      case HiloCultura.teatro:
        return 'Teatro';
      case HiloCultura.pintura:
        return 'Pintura';
    }
  }
}

/// Coordenada del trazado real. No se deriva de las paradas.
class CoordenadaRuta {
  final double lat;
  final double lng;

  const CoordenadaRuta({required this.lat, required this.lng});
}

/// Parada / hito de una ruta (para mapa simulado y BD futura `puntos_ruta`).
class PuntoRuta {
  final String id;
  final String nombre;
  final String tipo;
  final double lat;
  final double lng;
  final String? nota;
  final String? lugarId;
  final int? altitudM;

  const PuntoRuta({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.lat,
    required this.lng,
    this.nota,
    this.lugarId,
    this.altitudM,
  });

  factory PuntoRuta.fromJson(Map<String, dynamic> json) {
    return PuntoRuta(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'parada',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      nota: json['nota'] as String?,
      lugarId: json['lugarId']?.toString(),
      altitudM: (json['altitudM'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'tipo': tipo,
    'lat': lat,
    'lng': lng,
    'nota': nota,
    'lugarId': lugarId,
    'altitudM': altitudM,
  };
}

/// Modelo de una ruta turística / caminata.
class ModeloRuta {
  final String id;
  final String slug;
  final String titulo;
  final String subtitulo;
  final String descripcion;
  final String imagenUrl;
  final CategoriaRuta categoria;
  final int cantidadLugares;
  final int dias;
  final String distancia;
  final int nivelDificultad;
  final String dificultadTexto;
  final String altitud;
  final String tiempoCaminata;
  final String mejorEpoca;
  final List<String> etiquetas;
  final double calificacion;
  final int cantidadResenas;
  final String textoBoton;
  final String? tipoSitio;
  final List<PuntoRuta> puntos;
  final String puntoPartida;
  final String comoLlegar;
  final String transporte;
  final List<String> tips;
  final List<String> requisitos;
  final List<String> advertencias;
  final List<CoordenadaRuta> trazado;
  final HiloCultura hilo;

  /// Provincia del Cusco a la que pertenece el lugar / experiencia.
  final String provincia;

  final bool guardadoPorMi;
  final String? usuarioCreadorId;
  final String? usuarioCreadorNombre;
  final String? usuarioCreadorFoto;
  final DateTime? publicadaEn;
  final DateTime? updatedAt;

  const ModeloRuta({
    required this.id,
    this.slug = '',
    required this.titulo,
    this.subtitulo = '',
    required this.descripcion,
    required this.imagenUrl,
    required this.categoria,
    this.cantidadLugares = 1,
    this.dias = 1,
    this.distancia = '',
    this.nivelDificultad = 2,
    this.dificultadTexto = 'Moderada',
    this.altitud = '',
    this.tiempoCaminata = '',
    this.mejorEpoca = '',
    this.etiquetas = const [],
    this.calificacion = 0,
    this.cantidadResenas = 0,
    this.textoBoton = 'Cómo llegar',
    this.tipoSitio,
    this.puntos = const [],
    this.puntoPartida = '',
    this.comoLlegar = '',
    this.transporte = '',
    this.tips = const [],
    this.requisitos = const [],
    this.advertencias = const [],
    this.trazado = const [],
    this.hilo = HiloCultura.camino,
    this.provincia = 'Cusco',
    this.guardadoPorMi = false,
    this.usuarioCreadorId,
    this.usuarioCreadorNombre,
    this.usuarioCreadorFoto,
    this.publicadaEn,
    this.updatedAt,
  });

  factory ModeloRuta.fromJson(Map<String, dynamic> json) {
    return ModeloRuta(
      id: json['id'] as String,
      slug: json['slug'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      subtitulo: json['subtitulo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      imagenUrl: json['imagenUrl'] as String? ?? '',
      categoria: CategoriaRuta.values.firstWhere(
        (c) => c.name == json['categoria'],
        orElse: () => CategoriaRuta.recomendadas,
      ),
      cantidadLugares: json['cantidadLugares'] as int? ?? 1,
      dias: json['dias'] as int? ?? 1,
      distancia: json['distancia'] as String? ?? '',
      nivelDificultad: json['nivelDificultad'] as int? ?? 2,
      dificultadTexto: json['dificultadTexto'] as String? ?? 'Moderada',
      altitud: json['altitud'] as String? ?? '',
      tiempoCaminata: json['tiempoCaminata'] as String? ?? '',
      mejorEpoca: json['mejorEpoca'] as String? ?? '',
      etiquetas:
          (json['etiquetas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      calificacion: (json['calificacion'] as num?)?.toDouble() ?? 0,
      cantidadResenas: json['cantidadResenas'] as int? ?? 0,
      textoBoton: json['textoBoton'] as String? ?? 'Cómo llegar',
      tipoSitio: json['tipoSitio'] as String?,
      puntos: (json['puntos'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => PuntoRuta.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      puntoPartida: json['puntoPartida'] as String? ?? '',
      comoLlegar: json['comoLlegar'] as String? ?? '',
      transporte: json['transporte'] as String? ?? '',
      tips:
          (json['tips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      requisitos:
          (json['requisitos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      advertencias:
          (json['advertencias'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      hilo: HiloCultura.values.firstWhere(
        (h) => h.name == json['hilo'],
        orElse: () => HiloCultura.camino,
      ),
      provincia: json['provincia'] as String? ?? 'Cusco',
      guardadoPorMi: json['guardadoPorMi'] as bool? ?? false,
      usuarioCreadorId: json['usuarioCreadorId'] as String?,
      usuarioCreadorNombre: json['usuarioCreadorNombre'] as String?,
      usuarioCreadorFoto: json['usuarioCreadorFoto'] as String?,
      publicadaEn: DateTime.tryParse('${json['publicadaEn'] ?? ''}'),
      updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}'),
    );
  }

  factory ModeloRuta.desdeFilaRemota(Map<String, dynamic> json) {
    final dificultad =
        (json['dificultad'] as String?)?.trim().toLowerCase() ?? 'moderado';
    final nivel = switch (dificultad) {
      'facil' => 1,
      'exigente' => 4,
      _ => 2,
    };
    final meses = (json['meses_recomendados'] as List<dynamic>? ?? const [])
        .whereType<num>()
        .map((e) => e.toInt())
        .where((e) => e >= 1 && e <= 12)
        .toList();
    final distanciaM = (json['distancia_m'] as num?)?.toInt();
    final duracionMin = (json['duracion_minutos'] as num?)?.toInt();
    final altitudMax = (json['altitud_max_m'] as num?)?.toInt();
    final paradas = <PuntoRuta>[];
    for (final raw in json['paradas'] as List<dynamic>? ?? const []) {
      if (raw is! Map) continue;
      final p = Map<String, dynamic>.from(raw);
      final id = '${p['id'] ?? ''}';
      final nombre = (p['nombre'] as String?)?.trim() ?? '';
      final lat = (p['latitud'] as num?)?.toDouble();
      final lng = (p['longitud'] as num?)?.toDouble();
      if (id.isEmpty ||
          nombre.isEmpty ||
          lat == null ||
          lng == null ||
          !lat.isFinite ||
          !lng.isFinite ||
          lat < -90 ||
          lat > 90 ||
          lng < -180 ||
          lng > 180) {
        continue;
      }
      paradas.add(
        PuntoRuta(
          id: id,
          nombre: nombre,
          tipo: (p['tipo'] as String?)?.trim() ?? 'parada',
          lat: lat,
          lng: lng,
          nota: (p['instrucciones'] as String?)?.trim(),
          lugarId: p['lugar_id']?.toString(),
          altitudM: (p['altitud_m'] as num?)?.toInt(),
        ),
      );
    }
    final trazado = <CoordenadaRuta>[];
    final geojson = json['trazado_geojson'];
    if (geojson is Map) {
      final coordinates = geojson['coordinates'];
      if (coordinates is List) {
        for (final raw in coordinates) {
          if (raw is! List || raw.length < 2) continue;
          final lng = raw[0];
          final lat = raw[1];
          if (lat is num && lng is num) {
            final latitud = lat.toDouble();
            final longitud = lng.toDouble();
            if (latitud.isFinite &&
                longitud.isFinite &&
                latitud >= -90 &&
                latitud <= 90 &&
                longitud >= -180 &&
                longitud <= 180) {
              trazado.add(CoordenadaRuta(lat: latitud, lng: longitud));
            }
          }
        }
      }
    }
    final requisitos = _listaTexto(json['requisitos']);
    final advertencias = _listaTexto(json['advertencias']);

    return ModeloRuta(
      id: '${json['id'] ?? ''}',
      slug: (json['slug'] as String?)?.trim() ?? '',
      titulo: (json['nombre'] as String?)?.trim() ?? '',
      subtitulo: (json['resumen'] as String?)?.trim() ?? '',
      descripcion: (json['descripcion'] as String?)?.trim() ?? '',
      imagenUrl: (json['foto_portada'] as String?)?.trim() ?? '',
      categoria: _categoriaRemota(json['tipo']),
      cantidadLugares:
          (json['cantidad_paradas'] as num?)?.toInt() ?? paradas.length,
      dias: (json['dias'] as num?)?.toInt() ?? 1,
      distancia: _distancia(distanciaM),
      nivelDificultad: nivel,
      dificultadTexto: switch (dificultad) {
        'facil' => 'Fácil',
        'exigente' => 'Exigente',
        _ => 'Moderada',
      },
      altitud: altitudMax == null ? '' : '$altitudMax m.s.n.m.',
      tiempoCaminata: _duracion(duracionMin),
      mejorEpoca: _meses(meses),
      etiquetas: _listaTexto(json['etiquetas']),
      calificacion: (json['valoracion_promedio'] as num?)?.toDouble() ?? 0,
      cantidadResenas: (json['cantidad_valoraciones'] as num?)?.toInt() ?? 0,
      tipoSitio: (json['tipo'] as String?)?.trim(),
      puntos: paradas,
      trazado: trazado,
      puntoPartida: paradas.isEmpty ? '' : paradas.first.nombre,
      comoLlegar: (json['acceso'] as String?)?.trim() ?? '',
      transporte: (json['transporte'] as String?)?.trim() ?? '',
      tips: [...requisitos, ...advertencias],
      requisitos: requisitos,
      advertencias: advertencias,
      hilo: _hiloRemoto(json['hilo_cultural']),
      provincia: (json['zona'] as String?)?.trim().isNotEmpty == true
          ? (json['zona'] as String).trim()
          : 'Cusco',
      guardadoPorMi: json['ruta_guardada_por_mi'] == true,
      usuarioCreadorId: json['usuario_creador_id']?.toString(),
      usuarioCreadorNombre: _textoNulo(json['usuario_creador_nombre']),
      usuarioCreadorFoto: _textoNulo(json['usuario_creador_foto']),
      publicadaEn: DateTime.tryParse('${json['publicada_en'] ?? ''}'),
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'titulo': titulo,
      'subtitulo': subtitulo,
      'descripcion': descripcion,
      'imagenUrl': imagenUrl,
      'categoria': categoria.name,
      'cantidadLugares': cantidadLugares,
      'dias': dias,
      'distancia': distancia,
      'nivelDificultad': nivelDificultad,
      'dificultadTexto': dificultadTexto,
      'altitud': altitud,
      'tiempoCaminata': tiempoCaminata,
      'mejorEpoca': mejorEpoca,
      'etiquetas': etiquetas,
      'calificacion': calificacion,
      'cantidadResenas': cantidadResenas,
      'textoBoton': textoBoton,
      'tipoSitio': tipoSitio,
      'puntos': puntos.map((p) => p.toJson()).toList(),
      'puntoPartida': puntoPartida,
      'comoLlegar': comoLlegar,
      'transporte': transporte,
      'tips': tips,
      'requisitos': requisitos,
      'advertencias': advertencias,
      'hilo': hilo.name,
      'provincia': provincia,
      'guardadoPorMi': guardadoPorMi,
      'usuarioCreadorId': usuarioCreadorId,
      'usuarioCreadorNombre': usuarioCreadorNombre,
      'usuarioCreadorFoto': usuarioCreadorFoto,
      'publicadaEn': publicadaEn?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ModeloRuta copyWith({
    String? id,
    String? slug,
    String? titulo,
    String? subtitulo,
    String? descripcion,
    String? imagenUrl,
    CategoriaRuta? categoria,
    int? cantidadLugares,
    int? dias,
    String? distancia,
    int? nivelDificultad,
    String? dificultadTexto,
    String? altitud,
    String? tiempoCaminata,
    String? mejorEpoca,
    List<String>? etiquetas,
    double? calificacion,
    int? cantidadResenas,
    String? textoBoton,
    String? tipoSitio,
    List<PuntoRuta>? puntos,
    String? puntoPartida,
    String? comoLlegar,
    String? transporte,
    List<String>? tips,
    List<String>? requisitos,
    List<String>? advertencias,
    List<CoordenadaRuta>? trazado,
    HiloCultura? hilo,
    String? provincia,
    bool? guardadoPorMi,
    String? usuarioCreadorId,
    String? usuarioCreadorNombre,
    String? usuarioCreadorFoto,
    DateTime? publicadaEn,
    DateTime? updatedAt,
  }) {
    return ModeloRuta(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      titulo: titulo ?? this.titulo,
      subtitulo: subtitulo ?? this.subtitulo,
      descripcion: descripcion ?? this.descripcion,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      categoria: categoria ?? this.categoria,
      cantidadLugares: cantidadLugares ?? this.cantidadLugares,
      dias: dias ?? this.dias,
      distancia: distancia ?? this.distancia,
      nivelDificultad: nivelDificultad ?? this.nivelDificultad,
      dificultadTexto: dificultadTexto ?? this.dificultadTexto,
      altitud: altitud ?? this.altitud,
      tiempoCaminata: tiempoCaminata ?? this.tiempoCaminata,
      mejorEpoca: mejorEpoca ?? this.mejorEpoca,
      etiquetas: etiquetas ?? this.etiquetas,
      calificacion: calificacion ?? this.calificacion,
      cantidadResenas: cantidadResenas ?? this.cantidadResenas,
      textoBoton: textoBoton ?? this.textoBoton,
      tipoSitio: tipoSitio ?? this.tipoSitio,
      puntos: puntos ?? this.puntos,
      puntoPartida: puntoPartida ?? this.puntoPartida,
      comoLlegar: comoLlegar ?? this.comoLlegar,
      transporte: transporte ?? this.transporte,
      tips: tips ?? this.tips,
      requisitos: requisitos ?? this.requisitos,
      advertencias: advertencias ?? this.advertencias,
      trazado: trazado ?? this.trazado,
      hilo: hilo ?? this.hilo,
      provincia: provincia ?? this.provincia,
      guardadoPorMi: guardadoPorMi ?? this.guardadoPorMi,
      usuarioCreadorId: usuarioCreadorId ?? this.usuarioCreadorId,
      usuarioCreadorNombre: usuarioCreadorNombre ?? this.usuarioCreadorNombre,
      usuarioCreadorFoto: usuarioCreadorFoto ?? this.usuarioCreadorFoto,
      publicadaEn: publicadaEn ?? this.publicadaEn,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

String? _textoNulo(Object? raw) {
  final texto = (raw as String?)?.trim();
  return texto == null || texto.isEmpty ? null : texto;
}

List<String> _listaTexto(Object? raw) {
  if (raw is! List) return const [];
  return raw.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();
}

CategoriaRuta _categoriaRemota(Object? raw) {
  return switch ('$raw'.toLowerCase()) {
    'cultural' || 'urbana' => CategoriaRuta.cultura,
    'senderismo' => CategoriaRuta.naturaleza,
    _ => CategoriaRuta.recomendadas,
  };
}

HiloCultura _hiloRemoto(Object? raw) {
  return HiloCultura.values.firstWhere(
    (hilo) => hilo.name == '$raw'.toLowerCase(),
    orElse: () => HiloCultura.camino,
  );
}

String _distancia(int? metros) {
  if (metros == null) return '';
  if (metros < 1000) return '$metros m';
  final km = metros / 1000;
  return '${km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toStringAsFixed(1)} km';
}

String _duracion(int? minutos) {
  if (minutos == null) return '';
  final horas = minutos ~/ 60;
  final resto = minutos % 60;
  if (horas == 0) return '$resto min';
  return resto == 0 ? '$horas h' : '$horas h $resto min';
}

String _meses(List<int> meses) {
  if (meses.isEmpty) return '';
  const nombres = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  return meses.map((m) => nombres[m - 1]).join(' · ');
}
