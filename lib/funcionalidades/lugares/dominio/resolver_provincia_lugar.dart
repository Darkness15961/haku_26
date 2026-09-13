import '../datos/provincias_datasource_local.dart';
import 'modelos/modelo_territorio.dart';

/// Resuelve provincia remota desde nombre o código de isla.
abstract final class ResolverProvinciaLugar {
  static ModeloProvinciaDb? desdeInicial({
    required List<ModeloProvinciaDb> remotas,
    String? inicial,
  }) {
    if (inicial == null || inicial.trim().isEmpty || remotas.isEmpty) {
      return null;
    }
    final raw = inicial.trim();
    final cat = ProvinciasDataSourceLocal.porNombre(raw) ??
        ProvinciasDataSourceLocal.porCodigo(raw);
    if (cat != null) {
      for (final p in remotas) {
        if (p.codigo == cat.id) return p;
      }
    }
    final key = ProvinciasDataSourceLocal.normalizar(raw);
    for (final p in remotas) {
      if (p.codigo == key ||
          ProvinciasDataSourceLocal.normalizar(p.nombre) == key) {
        return p;
      }
    }
    return null;
  }
}
