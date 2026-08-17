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
        return 'En crecimiento';
      case NivelExploracion.pocoExplorado:
        return 'Poco explorado';
      case NivelExploracion.nuevoEnHaku:
        return 'Nuevo en HAKU';
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
}
