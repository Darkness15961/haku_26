import 'package:flutter/material.dart';

import 'estilos_rutas.dart';

/// Fondo de sección. Por defecto piedra clara; Inicio dark no lo usa.
class FondoSuaveSeccion extends StatelessWidget {
  static const asset = 'public/image/fondo_rutas.jpg';

  final Widget child;
  final double opacidadImagen;
  final double opacidadVelo;
  final Color? color;

  const FondoSuaveSeccion({
    super.key,
    required this.child,
    this.opacidadImagen = 0.28,
    this.opacidadVelo = 0.35,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? PaletaRutas.piedra;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: base),
        if (opacidadImagen > 0.01)
          IgnorePointer(
            child: Opacity(
              opacity: opacidadImagen,
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        if (opacidadVelo > 0.01)
          IgnorePointer(
            child: ColoredBox(
              color: base.withValues(alpha: opacidadVelo),
            ),
          ),
        child,
      ],
    );
  }
}
