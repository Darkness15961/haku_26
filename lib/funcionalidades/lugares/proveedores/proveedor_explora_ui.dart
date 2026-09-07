import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inicio/proveedores/proveedor_navegacion_inicio.dart';

/// Explora es solo islas; [mapa]/[lugares]/[rutas] quedan como aliases
/// por compatibilidad con llamadas legacy a [irAExplora].
enum ModoExplora { islas, mapa, lugares, rutas }

final modoExploraProvider =
    StateProvider<ModoExplora>((ref) => ModoExplora.islas);

/// Abre el tab Explora (islas). El parámetro [modo] se ignora salvo documentación.
void irAExplora(WidgetRef ref, {ModoExplora modo = ModoExplora.islas}) {
  ref.read(modoExploraProvider.notifier).state = ModoExplora.islas;
  ref.read(pestaniaShellInicioProvider.notifier).state = 1;
}
