import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inicio/proveedores/proveedor_navegacion_inicio.dart';

/// Vista activa en Explora: mapa · lugares · rutas.
enum ModoExplora { mapa, lugares, rutas }

final modoExploraProvider = StateProvider<ModoExplora>((ref) => ModoExplora.mapa);

void irAExplora(WidgetRef ref, {ModoExplora modo = ModoExplora.mapa}) {
  ref.read(modoExploraProvider.notifier).state = modo;
  ref.read(pestaniaShellInicioProvider.notifier).state = 1;
}
