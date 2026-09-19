import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        .select('*, ruta_guardada_por_mi')
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
        .select('*, ruta_guardada_por_mi')
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

  Future<void> guardarRuta(String rutaId) async {
    if (!supabaseListo) return;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión para guardar');
    }

    final idNum = int.tryParse(rutaId.trim());
    if (idNum == null) return;

    try {
      await clienteSupabase.from('ruta_guardada').insert({
        'ruta_id': idNum,
        'usuario_id': user.id,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') return;
      throw AuthException(
        e.message.trim().isEmpty ? 'No se pudo guardar la ruta' : e.message,
      );
    }
  }

  Future<void> quitarGuardadoRuta(String rutaId) async {
    if (!supabaseListo) return;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) return;

    final idNum = int.tryParse(rutaId.trim());
    if (idNum == null) return;

    await clienteSupabase
        .from('ruta_guardada')
        .delete()
        .eq('ruta_id', idNum)
        .eq('usuario_id', user.id);
  }

  Future<List<ModeloRuta>> listarRutasGuardadas() async {
    if (!supabaseListo) return const [];
    final user = clienteSupabase.auth.currentUser;
    if (user == null) return const [];

    final rows = await clienteSupabase
        .from('ruta_guardada')
        .select('ruta_id')
        .eq('usuario_id', user.id)
        .order('fecha_creacion', ascending: false);

    final ids = rows.map((r) => '${r['ruta_id']}').toList();
    if (ids.isEmpty) return const [];
    
    final rutas = await listarPublicadasPorIds(ids);
    // Preservar orden cronológico de guardado
    rutas.sort((a, b) {
      final indexA = ids.indexOf(a.id);
      final indexB = ids.indexOf(b.id);
      return indexA.compareTo(indexB);
    });
    return rutas;
  }
}
