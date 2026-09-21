/// Modelo que representa un destino turístico destacado dentro de una provincia.
///
/// Se usa para el ranking mensual y para mostrar los destinos principales
/// de cada provincia en el panel informativo.
class DestinoDestacado {
  final String id;
  final String nombre;
  final String provinciaId;
  final String? imagenUrl;
  final String descripcion;
  final int visitas;
  final int favoritos;
  final double crecimientoMensual;
  final int posicion;

  const DestinoDestacado({
    required this.id,
    required this.nombre,
    required this.provinciaId,
    this.imagenUrl,
    required this.descripcion,
    required this.visitas,
    required this.favoritos,
    required this.crecimientoMensual,
    required this.posicion,
  });

  DestinoDestacado copyWith({
    String? id,
    String? nombre,
    String? provinciaId,
    String? imagenUrl,
    String? descripcion,
    int? visitas,
    int? favoritos,
    double? crecimientoMensual,
    int? posicion,
  }) {
    return DestinoDestacado(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      provinciaId: provinciaId ?? this.provinciaId,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      descripcion: descripcion ?? this.descripcion,
      visitas: visitas ?? this.visitas,
      favoritos: favoritos ?? this.favoritos,
      crecimientoMensual: crecimientoMensual ?? this.crecimientoMensual,
      posicion: posicion ?? this.posicion,
    );
  }

  /// Indica si el destino tiene tendencia positiva.
  bool get tendenciaPositiva => crecimientoMensual > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DestinoDestacado &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
