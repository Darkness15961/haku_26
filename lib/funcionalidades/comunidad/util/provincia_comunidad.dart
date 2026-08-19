import '../../inicio/datos/provincias_datasource_local.dart';
import '../../inicio/dominio/modelos/provincia.dart';

/// Resuelve el id de provincia del mapa a partir del nombre en [ComunidadHaku].
String provinciaIdDeNombre(String nombreProvincia) {
  final n = nombreProvincia.toLowerCase().trim();
  final provincias = ProvinciasDataSourceLocal.obtenerProvincias();
  for (final p in provincias) {
    if (p.nombre.toLowerCase() == n) return p.id;
    if (p.nombreCorto.toLowerCase() == n) return p.id;
  }
  if (n.contains('convenc')) return 'la_convencion';
  if (n.contains('quispic')) return 'quispicanchi';
  if (n.contains('paucart')) return 'paucartambo';
  if (n.contains('chumbivil')) return 'chumbivilcas';
  for (final p in provincias) {
    final base = p.nombre.toLowerCase().split(' ').first;
    if (n.startsWith(base)) return p.id;
  }
  return 'cusco';
}

Provincia? provinciaPorId(String id) {
  for (final p in ProvinciasDataSourceLocal.obtenerProvincias()) {
    if (p.id == id) return p;
  }
  return null;
}

Provincia? provinciaPorNombre(String nombre) =>
    provinciaPorId(provinciaIdDeNombre(nombre));
