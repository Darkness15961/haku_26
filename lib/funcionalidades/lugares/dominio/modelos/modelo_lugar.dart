import 'modelo_territorio.dart';

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
  final CategoriaLugar categoria;
  /// Todas las categorías remotas (N:N). Si vacío, se usa [categoria].
  final List<CategoriaLugar> categorias;
  /// Etiquetas remotas con faceta (temática / actividad).
  final List<EtiquetaCategoriaLugar> etiquetas;
  final String provincia;
  final String provinciaCodigo;
  final int? provinciaId;
  final String distrito;
  final int? distritoId;
  final double latitud;
  final double longitud;
  final double distanciaKm;
  final double calificacion;
  final NivelExploracion nivelExploracion;
  final String dificultad;
  final String tiempoEstimado;
  final String altitud;
  final String acceso;
  final DateTime? descubiertoEn;
  final bool creadoPorUsuario;
  final bool remoto;
  final bool guardadoPorMi;
  final String? usuarioCreadorId;

  const ModeloLugar({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    required this.categoria,
    this.categorias = const [],
    this.etiquetas = const [],
    required this.provincia,
    this.provinciaCodigo = '',
    this.provinciaId,
    this.distrito = '',
    this.distritoId,
    this.latitud = -13.5319,
    this.longitud = -71.9675,
    this.distanciaKm = 0,
    this.calificacion = 0,
    this.nivelExploracion = NivelExploracion.enCrecimiento,
    this.dificultad = 'Moderada',
    this.tiempoEstimado = '',
    this.altitud = '',
    this.acceso = '',
    this.descubiertoEn,
    this.creadoPorUsuario = false,
    this.remoto = false,
    this.guardadoPorMi = false,
    this.usuarioCreadorId,
  });

  List<CategoriaLugar> get categoriasEfectivas =>
      categorias.isNotEmpty ? categorias : <CategoriaLugar>[categoria];

  bool tieneCategoria(CategoriaLugar c) => categoriasEfectivas.contains(c);

  List<EtiquetaCategoriaLugar> get tematicas =>
      etiquetas.where((e) => e.esTematica).toList();

  List<EtiquetaCategoriaLugar> get actividades =>
      etiquetas.where((e) => e.esActividad).toList();

  bool tieneEtiquetaNombre(String nombre) {
    final key = nombre.trim().toLowerCase();
    if (key.isEmpty) return false;
    return etiquetas.any((e) => e.nombre.trim().toLowerCase() == key);
  }

  /// Línea corta para listados: temática · actividad (fallback enum legacy).
  String get subtituloClasificacion {
    final partes = <String>[];
    if (tematicas.isNotEmpty) partes.add(tematicas.first.nombre);
    if (actividades.isNotEmpty) partes.add(actividades.first.nombre);
    if (partes.isEmpty) partes.add(categoria.etiqueta);
    return partes.join(' · ');
  }

  ModeloLugar copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? imagenUrl,
    CategoriaLugar? categoria,
    List<CategoriaLugar>? categorias,
    List<EtiquetaCategoriaLugar>? etiquetas,
    String? provincia,
    String? provinciaCodigo,
    int? provinciaId,
    String? distrito,
    int? distritoId,
    double? latitud,
    double? longitud,
    double? distanciaKm,
    double? calificacion,
    NivelExploracion? nivelExploracion,
    String? dificultad,
    String? tiempoEstimado,
    String? altitud,
    String? acceso,
    DateTime? descubiertoEn,
    bool? creadoPorUsuario,
    bool? remoto,
    bool? guardadoPorMi,
    String? usuarioCreadorId,
  }) {
    return ModeloLugar(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      categoria: categoria ?? this.categoria,
      categorias: categorias ?? this.categorias,
      etiquetas: etiquetas ?? this.etiquetas,
      provincia: provincia ?? this.provincia,
      provinciaCodigo: provinciaCodigo ?? this.provinciaCodigo,
      provinciaId: provinciaId ?? this.provinciaId,
      distrito: distrito ?? this.distrito,
      distritoId: distritoId ?? this.distritoId,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      distanciaKm: distanciaKm ?? this.distanciaKm,
      calificacion: calificacion ?? this.calificacion,
      nivelExploracion: nivelExploracion ?? this.nivelExploracion,
      dificultad: dificultad ?? this.dificultad,
      tiempoEstimado: tiempoEstimado ?? this.tiempoEstimado,
      altitud: altitud ?? this.altitud,
      acceso: acceso ?? this.acceso,
      descubiertoEn: descubiertoEn ?? this.descubiertoEn,
      creadoPorUsuario: creadoPorUsuario ?? this.creadoPorUsuario,
      remoto: remoto ?? this.remoto,
      guardadoPorMi: guardadoPorMi ?? this.guardadoPorMi,
      usuarioCreadorId: usuarioCreadorId ?? this.usuarioCreadorId,
    );
  }

  Map<String, dynamic> aMapa() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'imagen_url': imagenUrl,
        'categoria_id': categoria.name,
        'provincia': provincia,
        'provincia_codigo': provinciaCodigo,
        'distrito': distrito,
        'latitud': latitud,
        'longitud': longitud,
        'distancia_km': distanciaKm,
        'calificacion': calificacion,
        'nivel_exploracion': nivelExploracion.name,
        'dificultad': dificultad,
        'tiempo_estimado': tiempoEstimado,
        'altitud': altitud,
        'acceso': acceso,
        'descubierto_en': descubiertoEn?.toIso8601String(),
        'creado_por_usuario': creadoPorUsuario,
        'remoto': remoto,
        'guardado_por_mi': guardadoPorMi,
        'usuario_creador_id': usuarioCreadorId,
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
      id: '${m['id'] ?? ''}',
      nombre: m['nombre'] as String? ?? '',
      descripcion: m['descripcion'] as String? ?? '',
      imagenUrl: m['imagen_url'] as String? ?? '',
      categoria: cat,
      provincia: m['provincia'] as String? ?? 'Cusco',
      provinciaCodigo: m['provincia_codigo'] as String? ?? '',
      distrito: m['distrito'] as String? ?? '',
      latitud: (m['latitud'] as num?)?.toDouble() ?? -13.5319,
      longitud: (m['longitud'] as num?)?.toDouble() ?? -71.9675,
      distanciaKm: (m['distancia_km'] as num?)?.toDouble() ?? 0,
      calificacion: (m['calificacion'] as num?)?.toDouble() ?? 0,
      nivelExploracion: nivel,
      dificultad: m['dificultad'] as String? ?? 'Moderada',
      tiempoEstimado: m['tiempo_estimado'] as String? ?? '',
      altitud: m['altitud'] is num
          ? '${m['altitud']} msnm'
          : (m['altitud'] as String? ?? ''),
      acceso: m['acceso'] as String? ?? '',
      descubiertoEn: DateTime.tryParse(m['descubierto_en'] as String? ?? ''),
      creadoPorUsuario: m['creado_por_usuario'] as bool? ?? false,
      remoto: m['remoto'] as bool? ?? false,
      guardadoPorMi: m['guardado_por_mi'] as bool? ?? false,
      usuarioCreadorId: m['usuario_id']?.toString(),
    );
  }

  /// Mapeo desde fila PostgREST de `lugar` (+ distrito → provincia).
  factory ModeloLugar.desdeFilaRemota(Map<String, dynamic> m) {
    final dist = m['distrito'];
    Map<String, dynamic>? distMap;
    if (dist is Map) distMap = Map<String, dynamic>.from(dist);

    Map<String, dynamic>? provMap;
    final provNested = distMap?['provincia'];
    if (provNested is Map) {
      provMap = Map<String, dynamic>.from(provNested);
    } else {
      // Compat: por si algún select legacy aún embebe provincia al raíz.
      final prov = m['provincia'];
      if (prov is Map) provMap = Map<String, dynamic>.from(prov);
    }

    final cats = <CategoriaLugar>[];
    final etiquetas = <EtiquetaCategoriaLugar>[];
    final lc = m['lugar_categoria'];
    if (lc is List) {
      for (final item in lc) {
        if (item is! Map) continue;
        final catRaw = item['categoria'];
        if (catRaw is! Map) continue;
        final nombre = (catRaw['nombre'] as String?)?.trim() ?? '';
        if (nombre.isEmpty) continue;
        final id = _asInt(catRaw['id']) ?? 0;
        final faceta = facetaCategoriaDesdeTipo(catRaw['tipo'] as String?);
        if (faceta != null) {
          final ya = etiquetas.any(
            (e) =>
                e.nombre.toLowerCase() == nombre.toLowerCase() &&
                e.faceta == faceta,
          );
          if (!ya) {
            etiquetas.add(
              EtiquetaCategoriaLugar(
                id: id,
                nombre: nombre,
                faceta: faceta,
              ),
            );
          }
        }
        final parsed = _categoriaDesdeNombre(nombre.toLowerCase());
        if (parsed != null && !cats.contains(parsed)) cats.add(parsed);
      }
    }

    final catPrincipal =
        cats.isNotEmpty ? cats.first : CategoriaLugar.naturaleza;

    final alt = m['altitud'];
    final altitudTxt = alt == null
        ? ''
        : alt is num
            ? '${alt.round()} msnm'
            : '$alt';

    final fecha = m['fecha_creacion'] as String?;
    final creado = DateTime.tryParse(fecha ?? '');

    return ModeloLugar(
      id: '${m['id'] ?? ''}',
      nombre: (m['nombre'] as String?)?.trim() ?? '',
      descripcion: (m['descripcion'] as String?)?.trim() ?? '',
      imagenUrl: (m['foto_portada'] as String?)?.trim() ?? '',
      categoria: catPrincipal,
      categorias: cats,
      etiquetas: etiquetas,
      provincia: (provMap?['nombre'] as String?)?.trim() ?? '',
      provinciaCodigo: (provMap?['codigo'] as String?)?.trim() ?? '',
      provinciaId: _asInt(provMap?['id'] ?? distMap?['provincia_id']),
      distrito: (distMap?['nombre'] as String?)?.trim() ?? '',
      distritoId: _asInt(m['distrito_id'] ?? distMap?['id']),
      latitud: (m['latitud'] as num?)?.toDouble() ?? -13.5319,
      longitud: (m['longitud'] as num?)?.toDouble() ?? -71.9675,
      dificultad: '',
      tiempoEstimado: '',
      altitud: altitudTxt,
      acceso: (m['acceso'] as String?)?.trim() ?? '',
      descubiertoEn: creado,
      creadoPorUsuario: true,
      nivelExploracion: NivelExploracion.nuevoEnHaku,
      calificacion: 0,
      remoto: true,
      guardadoPorMi: m['lugar_guardado_por_mi'] == true,
      usuarioCreadorId: m['usuario_id']?.toString(),
    );
  }

  static CategoriaLugar? _categoriaDesdeNombre(String nombre) {
    final key = nombre.trim().toLowerCase();
    for (final c in CategoriaLugar.values) {
      if (c.name == key) return c;
    }
    // Alias del catálogo nuevo → enum legacy (UI secundaria).
    switch (key) {
      case 'arqueológico':
      case 'arqueologico':
      case 'arquitectónico':
      case 'arquitectonico':
      case 'museos':
      case 'arte y pintura':
        return CategoriaLugar.cultura;
      case 'mirador':
        return CategoriaLugar.fotografia;
      case 'trekking / caminata':
      case 'trekking':
      case 'caminata':
        return CategoriaLugar.caminata;
      case 'relajación':
      case 'relajacion':
      case 'turismo vivencial':
        return CategoriaLugar.magico;
      case 'gastronomía':
      case 'gastronomia':
        return CategoriaLugar.gastronomia;
      case 'fotografía':
      case 'fotografia':
        return CategoriaLugar.fotografia;
      case 'aventura':
        return CategoriaLugar.aventura;
      case 'naturaleza':
        return CategoriaLugar.naturaleza;
      default:
        return null;
    }
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }
}
