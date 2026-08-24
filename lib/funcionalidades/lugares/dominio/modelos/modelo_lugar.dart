/// Nivel de exploración territorial (dato estratégico HAKU).
enum NivelExploracion {
  muyConocido,
  enCrecimiento,
  pocoExplorado,
  nuevoEnHaku,
}

/// Categoría de lugar para filtros e intereses.
enum CategoriaLugar {
  naturaleza,
  cultura,
  gastronomia,
  aventura,
  caminata,
  fotografia,
  misterioso,
  magico,
}

extension CategoriaLugarX on CategoriaLugar {
  String get etiqueta {
    switch (this) {
      case CategoriaLugar.naturaleza:
        return 'Naturaleza';
      case CategoriaLugar.cultura:
        return 'Cultura';
      case CategoriaLugar.gastronomia:
        return 'Comida';
      case CategoriaLugar.aventura:
        return 'Aventura';
      case CategoriaLugar.caminata:
        return 'Caminata';
      case CategoriaLugar.fotografia:
        return 'Fotografía';
      case CategoriaLugar.misterioso:
        return 'Misterioso';
      case CategoriaLugar.magico:
        return 'Mágico';
    }
  }

  String get emoji {
    switch (this) {
      case CategoriaLugar.naturaleza:
        return 'Naturaleza';
      case CategoriaLugar.cultura:
        return 'Cultura';
      case CategoriaLugar.gastronomia:
        return 'Comida';
      case CategoriaLugar.aventura:
        return 'Aventura';
      case CategoriaLugar.caminata:
        return 'Caminata';
      case CategoriaLugar.fotografia:
        return 'Fotografía';
      case CategoriaLugar.misterioso:
        return 'Misterioso';
      case CategoriaLugar.magico:
        return 'Mágico';
    }
  }
}

extension NivelExploracionX on NivelExploracion {
  String get etiqueta {
    switch (this) {
      case NivelExploracion.muyConocido:
        return 'Muy conocido';
      case NivelExploracion.enCrecimiento:
        return 'Con más fotos';
      case NivelExploracion.pocoExplorado:
        return 'Poco explorado';
      case NivelExploracion.nuevoEnHaku:
        return 'Nuevo';
    }
  }
}

/// Lugar: activo central de conocimiento territorial.
class ModeloLugar {
  final String id;
  final String nombre;
  final String descripcion;
  final String imagenUrl;
  final List<String> galeria;
  final CategoriaLugar categoria;
  final String provincia;
  final String distrito;
  final double latitud;
  final double longitud;
  final double distanciaKm;
  final double calificacion;
  final int exploradores;
  final int fotos;
  final NivelExploracion nivelExploracion;
  final String dificultad;
  final String tiempoEstimado;
  final String altitud;
  final String acceso;
  final DateTime? descubiertoEn;
  final bool creadoPorUsuario;

  const ModeloLugar({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    this.galeria = const [],
    required this.categoria,
    required this.provincia,
    this.distrito = '',
    this.latitud = -13.5319,
    this.longitud = -71.9675,
    this.distanciaKm = 0,
    this.calificacion = 0,
    this.exploradores = 0,
    this.fotos = 0,
    this.nivelExploracion = NivelExploracion.enCrecimiento,
    this.dificultad = 'Moderada',
    this.tiempoEstimado = '',
    this.altitud = '',
    this.acceso = '',
    this.descubiertoEn,
    this.creadoPorUsuario = false,
  });

  ModeloLugar copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? imagenUrl,
    List<String>? galeria,
    CategoriaLugar? categoria,
    String? provincia,
    String? distrito,
    double? latitud,
    double? longitud,
    double? distanciaKm,
    double? calificacion,
    int? exploradores,
    int? fotos,
    NivelExploracion? nivelExploracion,
    String? dificultad,
    String? tiempoEstimado,
    String? altitud,
    String? acceso,
    DateTime? descubiertoEn,
    bool? creadoPorUsuario,
  }) {
    return ModeloLugar(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      galeria: galeria ?? this.galeria,
      categoria: categoria ?? this.categoria,
      provincia: provincia ?? this.provincia,
      distrito: distrito ?? this.distrito,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      distanciaKm: distanciaKm ?? this.distanciaKm,
      calificacion: calificacion ?? this.calificacion,
      exploradores: exploradores ?? this.exploradores,
      fotos: fotos ?? this.fotos,
      nivelExploracion: nivelExploracion ?? this.nivelExploracion,
      dificultad: dificultad ?? this.dificultad,
      tiempoEstimado: tiempoEstimado ?? this.tiempoEstimado,
      altitud: altitud ?? this.altitud,
      acceso: acceso ?? this.acceso,
      descubiertoEn: descubiertoEn ?? this.descubiertoEn,
      creadoPorUsuario: creadoPorUsuario ?? this.creadoPorUsuario,
    );
  }

  Map<String, dynamic> aMapa() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'imagen_url': imagenUrl,
        'galeria': galeria,
        'categoria_id': categoria.name,
        'provincia': provincia,
        'distrito': distrito,
        'latitud': latitud,
        'longitud': longitud,
        'distancia_km': distanciaKm,
        'calificacion': calificacion,
        'exploradores': exploradores,
        'fotos': fotos,
        'nivel_exploracion': nivelExploracion.name,
        'dificultad': dificultad,
        'tiempo_estimado': tiempoEstimado,
        'altitud': altitud,
        'acceso': acceso,
        'descubierto_en': descubiertoEn?.toIso8601String(),
        'creado_por_usuario': creadoPorUsuario,
      };

  factory ModeloLugar.desdeMapa(Map<String, dynamic> m) {
    CategoriaLugar cat = CategoriaLugar.naturaleza;
    final catId = m['categoria_id'] as String? ?? m['categoria'] as String?;
    for (final c in CategoriaLugar.values) {
      if (c.name == catId) cat = c;
    }
    NivelExploracion nivel = NivelExploracion.enCrecimiento;
    final nivId = m['nivel_exploracion'] as String?;
    for (final n in NivelExploracion.values) {
      if (n.name == nivId) nivel = n;
    }
    return ModeloLugar(
      id: m['id'] as String? ?? '',
      nombre: m['nombre'] as String? ?? '',
      descripcion: m['descripcion'] as String? ?? '',
      imagenUrl: m['imagen_url'] as String? ?? '',
      galeria: [
        for (final x in (m['galeria'] as List<dynamic>? ?? [])) x.toString(),
      ],
      categoria: cat,
      provincia: m['provincia'] as String? ?? 'Cusco',
      distrito: m['distrito'] as String? ?? '',
      latitud: (m['latitud'] as num?)?.toDouble() ?? -13.5319,
      longitud: (m['longitud'] as num?)?.toDouble() ?? -71.9675,
      distanciaKm: (m['distancia_km'] as num?)?.toDouble() ?? 0,
      calificacion: (m['calificacion'] as num?)?.toDouble() ?? 0,
      exploradores: (m['exploradores'] as num?)?.toInt() ?? 0,
      fotos: (m['fotos'] as num?)?.toInt() ?? 0,
      nivelExploracion: nivel,
      dificultad: m['dificultad'] as String? ?? 'Moderada',
      tiempoEstimado: m['tiempo_estimado'] as String? ?? '',
      altitud: m['altitud'] as String? ?? '',
      acceso: m['acceso'] as String? ?? '',
      descubiertoEn: DateTime.tryParse(m['descubierto_en'] as String? ?? ''),
      creadoPorUsuario: m['creado_por_usuario'] as bool? ?? false,
    );
  }
}
