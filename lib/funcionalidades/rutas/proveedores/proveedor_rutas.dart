import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../datos/rutas_datasource_local.dart';
import '../datos/rutas_datasource_supabase.dart';
import '../dominio/dominio_rutas.dart';

final rutasDataSourceProvider = Provider<RutasDataSourceSupabase>((ref) {
  return RutasDataSourceSupabase();
});

final rutasVersionProvider = StateProvider<int>((ref) => 0);

/// En una instalación conectada, remoto es la única fuente de verdad.
/// El catálogo local solo mantiene operable la demo sin configuración.
final rutasPublicadasProvider = FutureProvider<List<ModeloRuta>>((ref) async {
  ref.watch(rutasVersionProvider);
  if (!supabaseListo) return RutasDataSourceLocal.obtenerTodas();
  return ref.read(rutasDataSourceProvider).listarPublicadas();
});

/// Resuelve exactamente los IDs guardados; no depende de la primera página.
final rutasGuardadasProvider = FutureProvider.autoDispose
    .family<List<ModeloRuta>, String>((ref, idsClave) async {
      final ids = idsClave
          .split(',')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
      if (ids.isEmpty) return const [];
      if (!supabaseListo) {
        return ids
            .map(RutasDataSourceLocal.obtenerPorId)
            .whereType<ModeloRuta>()
            .toList(growable: false);
      }
      return ref.read(rutasDataSourceProvider).listarPublicadasPorIds(ids);
    });

final rutaDetalleProvider = FutureProvider.autoDispose
    .family<ModeloRuta?, String>((ref, id) async {
      ref.watch(rutasVersionProvider);
      if (!supabaseListo) return RutasDataSourceLocal.obtenerPorId(id);
      return ref.read(rutasDataSourceProvider).detallePublicada(id);
    });

class ProveedorRutas {
  final RepositorioRutas repositorio;

  ProveedorRutas({required this.repositorio});

  bool estaCargando = false;
  String? mensajeError;
  List<ModeloRuta> rutas = [];

  Future<void> cargarElementos() async {
    estaCargando = true;
    mensajeError = null;

    try {
      rutas = await repositorio.obtenerTodos();
    } catch (error) {
      mensajeError = error.toString();
    } finally {
      estaCargando = false;
    }
  }
}
