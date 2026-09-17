import 'package:flutter/foundation.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../dominio/modelos/modelo_ruta.dart';

/// Lectura pública del catálogo remoto. La escritura oficial queda fuera
/// de la app móvil hasta existir un panel administrativo.
class RutasDataSourceSupabase {
  Future<List<ModeloRuta>> listarPublicadas({int limite = 50}) async {
    if (!supabaseListo) return const [];
    final reloj = Stopwatch()..start();
    final rows = await clienteSupabase
        .from('rutas_publicadas_lista')
        .select()
        .order('publicada_en', ascending: false)
        .limit(limite);
    reloj.stop();
    _medir('rutas.listado', reloj.elapsed);

    return _mapearListado(rows);
  }

  Future<List<ModeloRuta>> listarPublicadasPorIds(Iterable<String> ids) async {
    if (!supabaseListo) return const [];
    final numericos = ids
        .map((id) => int.tryParse(id.trim()))
        .whereType<int>()
        .toSet()
        .toList(growable: false);
    if (numericos.isEmpty) return const [];

    final rows = await clienteSupabase
        .from('rutas_publicadas_lista')
        .select()
        .inFilter('id', numericos);
    return _mapearListado(rows);
  }

  List<ModeloRuta> _mapearListado(List<dynamic> rows) {
    return rows
        .whereType<Map>()
        .map(
          (row) => ModeloRuta.desdeFilaRemota(Map<String, dynamic>.from(row)),
        )
        .where((ruta) => ruta.id.isNotEmpty && ruta.titulo.isNotEmpty)
        .toList(growable: false);
  }

  Future<ModeloRuta?> detallePublicada(String id) async {
    if (!supabaseListo) return null;
    final idNumerico = int.tryParse(id.trim());
    if (idNumerico == null) return null;

    final reloj = Stopwatch()..start();
    final raw = await clienteSupabase.rpc(
      'ruta_publicada_detalle',
      params: {'p_ruta_id': idNumerico},
    );
    reloj.stop();
    _medir('rutas.detalle', reloj.elapsed);

    if (raw is! Map) return null;
    final ruta = ModeloRuta.desdeFilaRemota(Map<String, dynamic>.from(raw));
    return ruta.id.isEmpty ? null : ruta;
  }

  void _medir(String operacion, Duration duracion) {
    assert(() {
      debugPrint('[rendimiento] $operacion ${duracion.inMilliseconds} ms');
      return true;
    }());
  }
}
