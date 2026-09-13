/// Fila remota de `public.provincia` (Explora).
class ModeloProvinciaDb {
  const ModeloProvinciaDb({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.departamentoId,
  });

  final int id;
  final String nombre;
  final String codigo;
  final int departamentoId;

  factory ModeloProvinciaDb.desdeMapa(Map<String, dynamic> m) {
    return ModeloProvinciaDb(
      id: _asInt(m['id']) ?? 0,
      nombre: (m['nombre'] as String?)?.trim() ?? '',
      codigo: (m['codigo'] as String?)?.trim() ?? '',
      departamentoId: _asInt(m['departamento_id']) ?? 0,
    );
  }
}

/// Fila remota de `public.distrito`.
class ModeloDistritoDb {
  const ModeloDistritoDb({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.provinciaId,
  });

  final int id;
  final String nombre;
  final String codigo;
  final int provinciaId;

  factory ModeloDistritoDb.desdeMapa(Map<String, dynamic> m) {
    return ModeloDistritoDb(
      id: _asInt(m['id']) ?? 0,
      nombre: (m['nombre'] as String?)?.trim() ?? '',
      codigo: (m['codigo'] as String?)?.trim() ?? '',
      provinciaId: _asInt(m['provincia_id']) ?? 0,
    );
  }
}

/// Faceta de categoría de lugar (columna `categoria.tipo`).
enum FacetaCategoriaLugar { tematica, actividad }

/// Normaliza `tematica` / `actividad` (acepta acentos y alias legacy).
FacetaCategoriaLugar? facetaCategoriaDesdeTipo(String? tipo) {
  final raw = (tipo ?? '').trim().toLowerCase();
  if (raw.isEmpty) return null;
  final t = raw
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
  if (t == 'actividad' || t.startsWith('activ')) {
    return FacetaCategoriaLugar.actividad;
  }
  if (t == 'tematica' ||
      t.startsWith('temat') ||
      t.contains('interes') ||
      t == 'lugar') {
    return FacetaCategoriaLugar.tematica;
  }
  return null;
}

/// Etiqueta N:N de un lugar (`lugar_categoria` → `categoria`).
class EtiquetaCategoriaLugar {
  const EtiquetaCategoriaLugar({
    required this.id,
    required this.nombre,
    required this.faceta,
  });

  final int id;
  final String nombre;
  final FacetaCategoriaLugar faceta;

  bool get esTematica => faceta == FacetaCategoriaLugar.tematica;
  bool get esActividad => faceta == FacetaCategoriaLugar.actividad;
}

/// Fila remota de `public.categoria` (temática | actividad).
class ModeloCategoriaDb {
  const ModeloCategoriaDb({
    required this.id,
    required this.nombre,
    required this.tipo,
  });

  final int id;
  final String nombre;
  final String tipo;

  FacetaCategoriaLugar? get faceta => facetaCategoriaDesdeTipo(tipo);

  factory ModeloCategoriaDb.desdeMapa(Map<String, dynamic> m) {
    return ModeloCategoriaDb(
      id: _asInt(m['id']) ?? 0,
      nombre: (m['nombre'] as String?)?.trim() ?? '',
      tipo: (m['tipo'] as String?)?.trim() ?? '',
    );
  }
}

int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v');
}
