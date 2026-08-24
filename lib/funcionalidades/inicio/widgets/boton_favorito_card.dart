import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../proveedores/proveedor_almacen_feed.dart';

/// Corazón para guardar rutas/lugares en favoritos (esquina de cards grandes).
class BotonFavoritoCard extends ConsumerWidget {
  const BotonFavoritoCard({
    super.key,
    required this.rutaId,
  });

  final String rutaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorito =
        ref.watch(almacenFeedProvider).favoritosRutaIds.contains(rutaId);

    return Material(
      color: PaletaRutas.ink.withValues(alpha: 0.48),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ref
            .read(almacenFeedProvider.notifier)
            .toggleFavoritoRuta(rutaId),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(
            favorito
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: 22,
            color: favorito ? PaletaRutas.oro : PaletaRutas.piedra,
          ),
        ),
      ),
    );
  }
}
