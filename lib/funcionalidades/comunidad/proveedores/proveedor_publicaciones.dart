import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../datos/publicacion_datasource_supabase.dart';
import '../dominio/modelo_publicacion.dart';

final publicacionRemotoDataSourceProvider =
    Provider<PublicacionDataSourceSupabase>((ref) {
  return PublicacionDataSourceSupabase();
});

final publicacionesVersionProvider = StateProvider<int>((ref) => 0);

/// Tab «Para ti»: solo publicaciones remotas `estado = publico`.
final publicacionesRemotasProvider =
    FutureProvider<List<ModeloPublicacionRemota>>((ref) async {
  ref.watch(publicacionesVersionProvider);
  ref.watch(sesionProvider.select((s) => s.usuario?.id ?? ''));
  if (!supabaseListo) return const [];
  return ref.read(publicacionRemotoDataSourceProvider).listarPublicas();
});

void notificarPublicacionesCambiaron(WidgetRef ref) {
  ref.read(publicacionesVersionProvider.notifier).state++;
}
