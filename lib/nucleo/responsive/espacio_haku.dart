import 'package:flutter/material.dart';

/// Breakpoints y medidas adaptativas (teléfono / tablet / horizontal).
abstract final class EspacioHaku {
  EspacioHaku._();

  static const double anchoTelefono = 390;
  static const double umbralTablet = 600;
  static const double umbralTabletAncha = 840;
  static const double maxAnchoLienzo = 720;
  static const double maxAnchoLienzoLandscape = 1100;

  static Size sizeOf(BuildContext context) => MediaQuery.sizeOf(context);

  static double anchoOf(BuildContext context) => sizeOf(context).width;

  static double altoOf(BuildContext context) => sizeOf(context).height;

  static double shortestSideOf(BuildContext context) =>
      sizeOf(context).shortestSide;

  static bool esHorizontal(BuildContext context) =>
      anchoOf(context) > altoOf(context);

  static bool esAlturaCorta(BuildContext context) => altoOf(context) < 500;

  static bool esCompacto(BuildContext context) => shortestSideOf(context) < 360;

  static bool esTelefono(BuildContext context) =>
      shortestSideOf(context) < umbralTablet;

  static bool esTablet(BuildContext context) =>
      shortestSideOf(context) >= umbralTablet;

  static bool esTabletAncha(BuildContext context) =>
      shortestSideOf(context) >= umbralTabletAncha;

  static bool usarRielLateral(BuildContext context) =>
      esHorizontal(context);

  static double horizontal(BuildContext context) {
    if (esHorizontal(context) && esTelefono(context)) return 12;
    final w = anchoOf(context);
    if (w < 360) return 12;
    if (!esTablet(context)) return 16;
    if (!esTabletAncha(context)) return 22;
    return 28;
  }

  static double bottomNavClearance(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    if (usarRielLateral(context)) return inset + 16;
    final barra = esAlturaCorta(context)
        ? 48.0
        : (esTablet(context) ? 66.0 : 58.0);
    return inset + barra + (esAlturaCorta(context) ? 12 : 24);
  }

  static double altoHero(BuildContext context, {double base = 188}) {
    if (esAlturaCorta(context)) {
      return (altoOf(context) * 0.28).clamp(88.0, 120.0);
    }
    if (esTablet(context) && !esHorizontal(context)) return base + 24;
    if (esHorizontal(context)) return (base * 0.72).clamp(120.0, 150.0);
    return base;
  }

  static double escala(BuildContext context) {
    final s = shortestSideOf(context);
    if (esAlturaCorta(context)) return 0.94;
    if (s < 360) return 0.92;
    if (s < anchoTelefono) return 0.96;
    if (s < umbralTablet) return 1.0;
    if (s < umbralTabletAncha) return 1.04;
    return 1.08;
  }

  static double sp(BuildContext context, double base) =>
      base * escala(context);

  static int columnasGrilla(BuildContext context) {
    if (esHorizontal(context) && esTelefono(context)) return 3;
    if (esTablet(context)) return esHorizontal(context) ? 3 : 2;
    return 2;
  }

  static double maxAnchoContenido(BuildContext context) {
    if (!esTablet(context)) return double.infinity;
    return esHorizontal(context) ? maxAnchoLienzoLandscape : maxAnchoLienzo;
  }

  /// Card cuadrada destacada — un poco más generosa, sin crecer al ancho.
  static double ladoCardCuadrada(BuildContext context) {
    final disponible = anchoOf(context) - horizontal(context) * 2;
    if (esHorizontal(context)) {
      return (altoOf(context) * 0.68).clamp(200.0, 300.0);
    }
    return disponible.clamp(240.0, 380.0);
  }

  /// Publicaciones: landscape más ancho (menos alto), portrait clásico.
  static double aspectPublicacion(BuildContext context) =>
      esHorizontal(context) ? 1.15 : 0.82;

  static int columnasPublicaciones(BuildContext context) {
    if (esHorizontal(context)) return esTablet(context) ? 3 : 2;
    return 1;
  }

  /// Salidas / invitaciones en landscape: 2 columnas.
  static int columnasSalidas(BuildContext context) =>
      esHorizontal(context) ? 2 : 1;

  static double altoCarrusel(BuildContext context, {double base = 280}) {
    if (esAlturaCorta(context)) {
      return (altoOf(context) * 0.48).clamp(150.0, 200.0);
    }
    if (esHorizontal(context)) return 210;
    return base;
  }

  /// Carrusel “Recién en Haku”: un poco más aire, no tan apretado.
  static Size tarjetaReciente(BuildContext context) {
    if (esHorizontal(context)) return const Size(120, 136);
    return const Size(132, 148);
  }

  static double aspectInvitacionSalida(BuildContext context) =>
      esHorizontal(context) ? 2.2 : 1.6;

  static TextScaler textScalerAcotado(BuildContext context) {
    final actual = MediaQuery.textScalerOf(context).scale(1);
    return TextScaler.linear(actual.clamp(0.88, 1.15));
  }
}
