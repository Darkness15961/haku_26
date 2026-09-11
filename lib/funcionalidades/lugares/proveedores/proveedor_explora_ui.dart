import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inicio/proveedores/proveedor_navegacion_inicio.dart';

/// Explora es islas por defecto.
/// [mapa]/[lugares] se normalizan a islas; [rutas] abre la lista de rutas.
enum ModoExplora { islas, mapa, lugares, rutas }

final modoExploraProvider =
    StateProvider<ModoExplora>((ref) => ModoExplora.islas);

/// Abre el tab Explora. [modo] `rutas` muestra rutas; el resto cae en islas.
void irAExplora(WidgetRef ref, {ModoExplora modo = ModoExplora.islas}) {
  final efectivo =
      modo == ModoExplora.rutas ? ModoExplora.rutas : ModoExplora.islas;
  ref.read(modoExploraProvider.notifier).state = efectivo;
  ref.read(pestaniaShellInicioProvider.notifier).state = 1;
}
