import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';

/// Comunidad / grupo (tabla `grupos` + categorías N:N).
class ComunidadHaku {
  final String id;
  final String nombre;
  final String descripcion;
  final String imagenUrl;
  final String creadorId;
  final String provincia;
  final String estado;
  final List<CategoriaLugar> categorias;
  final List<String> miembroIds;
  final DateTime? fechaCreacion;

  const ComunidadHaku({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    required this.creadorId,
    this.provincia = 'Cusco',
    this.estado = 'activa',
    this.categorias = const [],
    this.miembroIds = const [],
    this.fechaCreacion,
  });

  int get miembros => miembroIds.length;

  /// Compatibilidad con el formulario anterior.
  List<String> get invitadosIds => miembroIds;

  bool tieneCategoria(CategoriaLugar c) => categorias.contains(c);

  ComunidadHaku copyWith({
    List<String>? miembroIds,
    List<CategoriaLugar>? categorias,
  }) {
    return ComunidadHaku(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      imagenUrl: imagenUrl,
      creadorId: creadorId,
      provincia: provincia,
      estado: estado,
      categorias: categorias ?? this.categorias,
      miembroIds: miembroIds ?? this.miembroIds,
      fechaCreacion: fechaCreacion,
    );
  }

  factory ComunidadHaku.desdeMapa(
    Map<String, dynamic> m, {
    List<String> miembroIds = const [],
  }) {
    final cats = (m['categoria_ids'] as List<dynamic>? ?? [])
        .map((x) => x.toString())
        .map(_categoriaDe)
        .whereType<CategoriaLugar>()
        .toList();
    return ComunidadHaku(
      id: m['id'] as String? ?? '',
      nombre: m['nombre'] as String? ?? '',
      descripcion: m['descripcion'] as String? ?? '',
      imagenUrl: CatalogoImagenesHaku.resolverImagen(
        m['imagen_url'] as String?,
      ),
      creadorId: m['creador_id'] as String? ?? '',
      provincia: m['provincia'] as String? ?? 'Cusco',
      estado: m['estado'] as String? ?? 'activa',
      categorias: cats,
      miembroIds: miembroIds,
      fechaCreacion: DateTime.tryParse(m['fecha_creacion'] as String? ?? ''),
    );
  }

  Map<String, dynamic> aMapa() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'imagen_url': imagenUrl,
        'creador_id': creadorId,
        'provincia': provincia,
        'estado': estado,
        'categoria_ids': categorias.map((c) => c.name).toList(),
        'fecha_creacion':
            (fechaCreacion ?? DateTime.now()).toIso8601String(),
      };

  static CategoriaLugar? _categoriaDe(String id) {
    for (final c in CategoriaLugar.values) {
      if (c.name == id) return c;
    }
    return null;
  }
}

class MiembroComunidad {
  final String id;
  final String comunidadId;
  final String usuarioId;
  final String rol;
  final DateTime? fechaUnion;

  const MiembroComunidad({
    required this.id,
    required this.comunidadId,
    required this.usuarioId,
    this.rol = 'miembro',
    this.fechaUnion,
  });

  Map<String, dynamic> aMapa() => {
        'id': id,
        'comunidad_id': comunidadId,
        'usuario_id': usuarioId,
        'rol': rol,
        'fecha_union': (fechaUnion ?? DateTime.now()).toIso8601String(),
      };
}
