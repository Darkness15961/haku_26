import '../../../nucleo/supabase/cliente_supabase.dart';
import '../dominio/modelos/modelo_nacionalidad.dart';

/// Catálogo `public.nacionalidad` (RLS: select anónimo).
class NacionalidadDataSource {
  NacionalidadDataSource();

  Future<List<ModeloNacionalidad>> listar() async {
    if (!supabaseListo) {
      throw StateError('Supabase no listo');
    }

    final rows = await clienteSupabase
        .from('nacionalidad')
        .select('id, nombre, codigo_iso')
        .order('nombre', ascending: true);

    final lista = (rows as List<dynamic>)
        .map((e) => ModeloNacionalidad.desdeMapa(Map<String, dynamic>.from(e as Map)))
        .where((n) => n.nombre.isNotEmpty)
        .toList();

    return lista;
  }

  /// Prefiere Perú (PE) o [Config] default; si no, la primera fila.
  static ModeloNacionalidad? sugerida(
    List<ModeloNacionalidad> todas, {
    int? preferirId,
  }) {
    if (todas.isEmpty) return null;
    final pe = todas.where((n) => n.codigoIso == 'PE').toList();
    if (pe.isNotEmpty) return pe.first;
    if (preferirId != null) {
      for (final n in todas) {
        if (n.id == preferirId) return n;
      }
    }
    final porNombre = todas.where(
      (n) => n.nombre.toLowerCase().contains('perú') ||
          n.nombre.toLowerCase().contains('peru'),
    );
    if (porNombre.isNotEmpty) return porNombre.first;
    return todas.first;
  }
}
