/// Categorías de filtrado de la lista de rutas (guía visual).
enum CategoriaRuta {
  recomendadas,
  populares,
  naturaleza,
  cultura,
}

/// Qué documenta la ruta: un camino o un hilo de cultura viva.
enum HiloCultura {
  camino,
  tejido,
  ceramica,
  comida,
  teatro,
  pintura,
}

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
        return 'Fogón';
      case HiloCultura.teatro:
        return 'Teatro';
      case HiloCultura.pintura:
        return 'Pintura';
    }
  }
}

/// Parada / hito de una ruta (para mapa simulado y BD futura `puntos_ruta`).
class PuntoRuta {
  final String id;
  final String nombre;
  final String tipo;
  final double lat;
  final double lng;
  final String? nota;

  const PuntoRuta({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.lat,
    required this.lng,
    this.nota,
  });

  factory PuntoRuta.fromJson(Map<String, dynamic> json) {
    return PuntoRuta(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'parada',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      nota: json['nota'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'tipo': tipo,
        'lat': lat,
        'lng': lng,
        'nota': nota,
      };
}

/// Modelo de una ruta turística / caminata.
class ModeloRuta {
  final String id;
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
  final HiloCultura hilo;

  const ModeloRuta({
    required this.id,
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
    this.hilo = HiloCultura.camino,
  });

  factory ModeloRuta.fromJson(Map<String, dynamic> json) {
    return ModeloRuta(
      id: json['id'] as String,
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
      etiquetas: (json['etiquetas'] as List<dynamic>?)
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
      tips: (json['tips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      hilo: HiloCultura.values.firstWhere(
        (h) => h.name == json['hilo'],
        orElse: () => HiloCultura.camino,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'hilo': hilo.name,
    };
  }

  ModeloRuta copyWith({
    String? id,
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
    HiloCultura? hilo,
  }) {
    return ModeloRuta(
      id: id ?? this.id,
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
      hilo: hilo ?? this.hilo,
    );
  }
}
