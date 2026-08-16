import 'package:flutter/material.dart';

/// Fondo ilustrado suave (mismo que Rutas), debajo del encabezado.
class FondoSuaveSeccion extends StatelessWidget {
  static const asset = 'public/image/fondo_rutas.jpg';

  final Widget child;
  final double opacidadImagen;
  final double opacidadVelo;

  const FondoSuaveSeccion({
    super.key,
    required this.child,
    this.opacidadImagen = 0.42,
    this.opacidadVelo = 0.22,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
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
        IgnorePointer(
          child: ColoredBox(
            color: Colors.white.withValues(alpha: opacidadVelo),
          ),
        ),
        child,
      ],
    );
  }
}
