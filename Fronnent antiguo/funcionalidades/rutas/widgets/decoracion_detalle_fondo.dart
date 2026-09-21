import 'package:flutter/material.dart';

import 'estilos_rutas.dart';

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
      color: PaletaRutas.carbon,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: PaletaRutas.plomo.withValues(alpha: 0.25),
      ),
      boxShadow: [
        BoxShadow(
          color: PaletaRutas.ink.withValues(alpha: 0.12),
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
