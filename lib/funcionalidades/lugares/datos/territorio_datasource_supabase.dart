import '../../../nucleo/supabase/cliente_supabase.dart';
import '../dominio/modelos/modelo_territorio.dart';

/// Catálogo geo + categorías desde Supabase (Bloque A · Etapa 1).
class TerritorioDataSourceSupabase {
  Future<List<ModeloProvinciaDb>> listarProvinciasCusco() async {
    if (!supabaseListo) return const [];

    final rows = await clienteSupabase
        .from('provincia')
        .select('id, nombre, codigo, departamento_id, departamento:departamento_id!inner(codigo)')
        .eq('departamento.codigo', 'cusco')
        .order('nombre', ascending: true);

    return (rows as List<dynamic>)
        .map((e) => ModeloProvinciaDb.desdeMapa(Map<String, dynamic>.from(e as Map)))
        .where((p) => p.codigo.isNotEmpty)
        .toList();
  }

  Future<List<ModeloDistritoDb>> listarDistritos({required int provinciaId}) async {
    if (!supabaseListo) return const [];

    final rows = await clienteSupabase
        .from('distrito')
        .select('id, nombre, codigo, provincia_id')
        .eq('provincia_id', provinciaId)
        .order('nombre', ascending: true);

    return (rows as List<dynamic>)
        .map((e) => ModeloDistritoDb.desdeMapa(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Catálogo de lugar: facetas `tematica` y `actividad`.
  Future<List<ModeloCategoriaDb>> listarCategoriasLugar() async {
    if (!supabaseListo) return const [];

    final rows = await clienteSupabase
        .from('categoria')
        .select('id, nombre, tipo')
        .order('nombre', ascending: true);

    final lista = (rows as List<dynamic>)
        .map((e) => ModeloCategoriaDb.desdeMapa(Map<String, dynamic>.from(e as Map)))
        .where(_esCategoriaLugarCatalogo)
        .toList();
    lista.sort((a, b) {
      final fa = a.faceta == FacetaCategoriaLugar.tematica ? 0 : 1;
      final fb = b.faceta == FacetaCategoriaLugar.tematica ? 0 : 1;
      if (fa != fb) return fa.compareTo(fb);
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
    return lista;
  }
}

bool _esCategoriaLugarCatalogo(ModeloCategoriaDb c) {
  if (c.nombre.isEmpty || c.faceta == null) return false;
  final t = c.tipo
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
  return t == 'tematica' ||
      t.startsWith('temat') ||
      t == 'actividad' ||
      t.startsWith('activ') ||
      t.contains('interes') ||
      // Catálogo legacy / seed parcial: tipo genérico "lugar".
      t == 'lugar';
}
