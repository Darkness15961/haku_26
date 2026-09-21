import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Recorte inferior irregular (papel / foto “rota”), no un corte recto.
class ClipBordeRotoInferior extends StatelessWidget {
  final Widget child;
  final double amplitud;

  const ClipBordeRotoInferior({
    super.key,
    required this.child,
    this.amplitud = 14,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _ClipperBordeRotoInferior(amplitud: amplitud),
      child: child,
    );
  }
}

/// Recorte superior irregular para la ficha de contenido que cubre la foto.
class ClipBordeRotoSuperior extends StatelessWidget {
  final Widget child;
  final double amplitud;

  const ClipBordeRotoSuperior({
    super.key,
    required this.child,
    this.amplitud = 14,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _ClipperBordeRotoSuperior(amplitud: amplitud),
      child: child,
    );
  }
}

class _ClipperBordeRotoInferior extends CustomClipper<Path> {
  final double amplitud;

  _ClipperBordeRotoInferior({required this.amplitud});

  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, 0)..lineTo(size.width, 0);
    // Borde inferior dentado / desgarrado.
    const segmentos = 18;
    final paso = size.width / segmentos;
    final yBase = size.height - amplitud;

    path.lineTo(size.width, yBase);

    for (var i = segmentos; i >= 0; i--) {
      final x = paso * i;
      final onda = math.sin(i * 1.7) * amplitud * 0.45;
      final diente = (i.isEven ? 1.0 : -0.55) * amplitud * 0.55;
      path.lineTo(x, yBase + onda + diente);
    }

    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _ClipperBordeRotoInferior oldClipper) {
    return oldClipper.amplitud != amplitud;
  }
}

class _ClipperBordeRotoSuperior extends CustomClipper<Path> {
  final double amplitud;

  _ClipperBordeRotoSuperior({required this.amplitud});

  @override
  Path getClip(Size size) {
    final path = Path();
    const segmentos = 18;
    final paso = size.width / segmentos;

    path.moveTo(0, amplitud);
    for (var i = 0; i <= segmentos; i++) {
      final x = paso * i;
      final onda = math.sin(i * 1.7) * amplitud * 0.45;
      final diente = (i.isEven ? 1.0 : -0.55) * amplitud * 0.55;
      path.lineTo(x, amplitud + onda + diente);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _ClipperBordeRotoSuperior oldClipper) {
    return oldClipper.amplitud != amplitud;
  }
}
