import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inicio/proveedores/proveedor_navegacion_inicio.dart';

/// Explora: islas por defecto; [mapa] pines remotos; [rutas] lista de rutas.
enum ModoExplora { islas, mapa, lugares, rutas }

final modoExploraProvider =
    StateProvider<ModoExplora>((ref) => ModoExplora.islas);

/// Abre el tab Explora. Respeta [islas], [mapa] y [rutas]; el resto → islas.
void irAExplora(WidgetRef ref, {ModoExplora modo = ModoExplora.islas}) {
  final efectivo = switch (modo) {
    ModoExplora.rutas => ModoExplora.rutas,
    ModoExplora.mapa => ModoExplora.mapa,
    _ => ModoExplora.islas,
  };
  ref.read(modoExploraProvider.notifier).state = efectivo;
  ref.read(pestaniaShellInicioProvider.notifier).state = 1;
}
