import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta visual-oro-piedra-minimal.
///
/// Oro Cusco + plomo de piedra + negro cálido — tonos mates, nunca puros.
abstract final class PaletaRutas {
  // —— Núcleo (oro / plomo / negro) ——
  /// Oro Cusco mate (acento; no dorado brillante).
  static const oro = Color(0xFFB8953F);
  static const oroSuave = Color(0xFFC9B07A);
  static const oroOscuro = Color(0xFF8A6F38);

  /// Piedra / plomo andino.
  static const piedra = Color(0xFFF0EDE8);
  static const plomoClaro = Color(0xFFC8C2B8);
  static const plomo = Color(0xFF7A746C);
  static const plomoOscuro = Color(0xFF4A4640);

  /// Negro cálido (no negro puro).
  static const ink = Color(0xFF141210);
  static const carbon = Color(0xFF1F1C18);

  // —— Alias legacy (misma familia, la app no se rompe) ——
  static const pergamino = Color(0xFFE6E1D8);
  static const arena = plomoClaro;
  static const beigeEnvejecido = Color(0xFF9A9288);
  static const verdeOliva = oroSuave;
  static const verdeBosque = plomoOscuro;
  static const azulLago = Color(0xFF6B6864);
  static const terracota = oro;
  static const marronCuero = plomo;
  static const marronOscuro = ink;
  static const crema = piedra;
}

/// Tipografías — minimal: logo manuscrito, títulos serif, UI limpia.
abstract final class TipografiaHaku {
  static TextStyle logo({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w600,
    Color color = PaletaRutas.piedra,
  }) {
    return GoogleFonts.caveat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle titulo({
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.w600,
    Color color = PaletaRutas.piedra,
    double? height,
    FontStyle? fontStyle,
    double? letterSpacing,
  }) {
    return GoogleFonts.crimsonPro(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle interfaz({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = PaletaRutas.piedra,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.quicksand(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

/// Snackbar consistente (carbon / oro destacado).
void mostrarSnackHaku(
  BuildContext context,
  String mensaje, {
  bool destacado = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        mensaje,
        style: TipografiaHaku.interfaz(
          color: destacado ? PaletaRutas.ink : PaletaRutas.piedra,
        ),
      ),
      backgroundColor: destacado ? PaletaRutas.oro : PaletaRutas.carbon,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
