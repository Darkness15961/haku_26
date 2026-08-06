import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../dominio/modelos/provincia.dart';

/// Widget individual para cada pieza SVG de una provincia.
///
/// Encaja con precisión milimétrica en el rompecabezas del mapa de Cusco.
class PiezaProvincia extends StatelessWidget {
  final Provincia provincia;
  final bool estaSeleccionada;
  final bool estaDestacada;
  final bool otraSeleccionada;
  final Animation<double> animacionEntrada;

  const PiezaProvincia({
    super.key,
    required this.provincia,
    required this.estaSeleccionada,
    required this.estaDestacada,
    required this.otraSeleccionada,
    required this.animacionEntrada,
  });

  /// Vector de dirección de vuelo inicial para animación de entrada.
  Offset _obtenerVectorEntrada(Offset centro) {
    final relX = (centro.dx - 0.5) * 500;
    final relY = (centro.dy - 0.5) * 500;

    if (relX.abs() < 40 && relY.abs() < 40) {
      return const Offset(0, -350);
    }

    return Offset(relX * 2.2, relY * 2.2);
  }

  @override
  Widget build(BuildContext context) {
    final vectorEntrada = _obtenerVectorEntrada(provincia.posicionCentro);

    return AnimatedBuilder(
      animation: animacionEntrada,
      builder: (context, child) {
        final val = animacionEntrada.value.clamp(0.0, 1.0);

        final tVueloRaw = (val / 0.72).clamp(0.0, 1.0);
        final tVuelo = const Cubic(0.05, 0.9, 0.1, 1.0).transform(tVueloRaw);

        final opacidad = tVueloRaw.clamp(0.0, 1.0);
        final escalaEntrada = 0.65 + (0.35 * tVuelo);

        double dxVuelo = (1.0 - tVuelo) * vectorEntrada.dx;
        double dyVuelo = (1.0 - tVuelo) * vectorEntrada.dy;

        double temblorX = 0.0;
        double temblorY = 0.0;
        double rotacionTemblor = 0.0;

        if (val > 0.72 && val < 1.0) {
          final tTemblor = ((val - 0.72) / 0.28).clamp(0.0, 1.0);
          final atenuacion = (1.0 - tTemblor);

          final angulo = tTemblor * math.pi * 8.0;
          temblorX = math.sin(angulo * 2.5) * 7.0 * atenuacion;
          temblorY = math.cos(angulo * 3.0) * 5.0 * atenuacion;
          rotacionTemblor = math.sin(angulo * 2.0) * 0.04 * atenuacion;
        }

        // Mantener escala exactísima de 1.0 al completar animación para alineación perfecta
        double escalaFinal = escalaEntrada;
        if (val >= 1.0) {
          if (estaSeleccionada) {
            escalaFinal = 1.04; // Elevación sutil solo al seleccionar
          } else {
            escalaFinal = 1.0; // Alineación exactísima con el rompecabezas
          }
        }

        double opacidadFinal = opacidad;
        if (otraSeleccionada && !estaSeleccionada) {
          opacidadFinal = opacidad * 0.5;
        }

        final offsetXTotal = (val >= 1.0) ? 0.0 : (dxVuelo + temblorX);
        final offsetYTotal = (val >= 1.0) ? 0.0 : (dyVuelo + temblorY);
        final rotacionFinal = (val >= 1.0) ? 0.0 : rotacionTemblor;

        return Transform.translate(
          offset: Offset(offsetXTotal, offsetYTotal),
          child: Transform.rotate(
            angle: rotacionFinal,
            child: Transform.scale(
              scale: escalaFinal,
              child: Opacity(
                opacity: opacidadFinal,
                child: child,
              ),
            ),
          ),
        );
      },
      child: SvgPicture.asset(
        provincia.rutaSvg,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(
          estaSeleccionada
              ? provincia.colorBase
              : estaDestacada
                  ? provincia.colorBase.withValues(alpha: 0.9)
                  : provincia.colorBase.withValues(alpha: 0.75),
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
