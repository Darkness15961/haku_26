import 'package:flutter/material.dart';

/// Fondos intercalados para cards / paneles (detalle destino).
abstract final class FondosDetalleHaku {
  static const fondoA = 'public/image/FONDO_HAKU2.png';
  static const fondoB = 'public/image/detalle_ruta_b.jpg';
  static const opacidadDetalle = 0.34;

  static String porIndice(int indice) =>
      indice.isEven ? fondoA : fondoB;

  static BoxDecoration tarjeta({
    required int indice,
    double radius = 16,
    double opacity = opacidadDetalle,
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      image: DecorationImage(
        image: AssetImage(porIndice(indice)),
        fit: BoxFit.cover,
        opacity: opacity,
        alignment: Alignment.center,
      ),
    );
  }
}
