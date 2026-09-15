import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../datos/salida_datasource_supabase.dart';
import '../dominio/modelo_salida.dart';

final salidaRemotoDataSourceProvider = Provider<SalidaDataSourceSupabase>((ref) {
  return SalidaDataSourceSupabase();
});

final salidasVersionProvider = StateProvider<int>((ref) => 0);

/// Listado general (tab Salidas).
final salidasRemotasProvider =
    FutureProvider<List<ModeloSalidaRemota>>((ref) async {
  ref.watch(salidasVersionProvider);
  ref.watch(sesionProvider.select((s) => s.usuario?.id ?? ''));
  if (!supabaseListo) return const [];
  return ref.read(salidaRemotoDataSourceProvider).listarVisibles();
});

final salidasPorLugarProvider =
    FutureProvider.family<List<ModeloSalidaRemota>, String>((ref, lugarId) async {
  ref.watch(salidasVersionProvider);
  ref.watch(sesionProvider.select((s) => s.usuario?.id ?? ''));
  if (!supabaseListo || lugarId.trim().isEmpty) return const [];
  return ref
      .read(salidaRemotoDataSourceProvider)
      .listarVisibles(lugarId: lugarId);
});

final salidasPorComunidadProvider =
    FutureProvider.family<List<ModeloSalidaRemota>, String>(
        (ref, comunidadId) async {
  ref.watch(salidasVersionProvider);
  ref.watch(sesionProvider.select((s) => s.usuario?.id ?? ''));
  if (!supabaseListo || comunidadId.trim().isEmpty) return const [];
  return ref
      .read(salidaRemotoDataSourceProvider)
      .listarVisibles(comunidadId: comunidadId);
});

final salidaDetalleProvider =
    FutureProvider.family<ModeloSalidaRemota?, String>((ref, id) async {
  ref.watch(salidasVersionProvider);
  final lista = ref.watch(salidasRemotasProvider).valueOrNull ?? const [];
  for (final s in lista) {
    if (s.id == id) return s;
  }
  if (!supabaseListo) return null;
  return ref.read(salidaRemotoDataSourceProvider).porId(id);
});

void notificarSalidasCambiaron(WidgetRef ref) {
  // Solo tick: families/detalle ya watch-ean salidasVersionProvider.
  ref.read(salidasVersionProvider.notifier).state++;
}
