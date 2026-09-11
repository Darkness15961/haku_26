/// Fila de `public.nacionalidad`.
class ModeloNacionalidad {
  const ModeloNacionalidad({
    required this.id,
    required this.nombre,
    required this.codigoIso,
  });

  final int id;
  final String nombre;
  final String codigoIso;

  factory ModeloNacionalidad.desdeMapa(Map<String, dynamic> row) {
    return ModeloNacionalidad(
      id: row['id'] as int,
      nombre: (row['nombre'] as String?)?.trim() ?? '',
      codigoIso: ((row['codigo_iso'] as String?) ?? '').trim().toUpperCase(),
    );
  }

  /// Texto para lista / campo (ej. «Perú · PE»).
  String get etiqueta {
    if (codigoIso.isEmpty) return nombre;
    return '$nombre · $codigoIso';
  }
}
