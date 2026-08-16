import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta vintage de la sección Rutas.
abstract final class PaletaRutas {
  static const pergamino = Color(0xFFEADCC2);
  static const arena = Color(0xFFD8C29A);
  static const beigeEnvejecido = Color(0xFFC8B18A);
  static const verdeOliva = Color(0xFF6E8B4A);
  static const verdeBosque = Color(0xFF3F5E3B);
  static const azulLago = Color(0xFF3D7184);
  static const terracota = Color(0xFFB45E3B);
  static const marronCuero = Color(0xFF8A5A3C);
  static const marronOscuro = Color(0xFF3B2E22);
  static const crema = Color(0xFFF6F0E2);
}

/// Tipografías del producto Haku (familias disponibles en google_fonts).
abstract final class TipografiaHaku {
  /// Logo / marca — Caveat (manuscrita; alternativa a Edu VIC WA NT Hand).
  static TextStyle logo({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w600,
    Color color = PaletaRutas.marronOscuro,
  }) {
    return GoogleFonts.caveat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Títulos — Crimson Pro.
  static TextStyle titulo({
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.w600,
    Color color = PaletaRutas.marronOscuro,
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

  /// Interfaz y cuerpo — Quicksand.
  static TextStyle interfaz({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = PaletaRutas.marronOscuro,
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
