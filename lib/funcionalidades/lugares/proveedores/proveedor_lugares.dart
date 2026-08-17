import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datos/lugares_datasource_local.dart';
import '../dominio/modelos/modelo_lugar.dart';

final lugaresDataSourceProvider = Provider<LugaresDataSourceLocal>((ref) {
  return LugaresDataSourceLocal.instancia;
});

final lugaresListaProvider = Provider<List<ModeloLugar>>((ref) {
  // Escuchar tick para refrescar tras crear
  ref.watch(lugaresVersionProvider);
  return ref.watch(lugaresDataSourceProvider).todos();
});

final lugaresVersionProvider = StateProvider<int>((ref) => 0);

final interesesUsuarioProvider =
    StateProvider<Set<CategoriaLugar>>((ref) => {});

void notificarLugaresCambiaron(WidgetRef ref) {
  ref.read(lugaresVersionProvider.notifier).state++;
}
