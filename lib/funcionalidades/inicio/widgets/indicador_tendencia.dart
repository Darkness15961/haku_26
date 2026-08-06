import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Indicador de tendencia en bloque de piedra pulida inca.
class IndicadorTendencia extends StatelessWidget {
  final double porcentaje;
  final double fontSize;

  const IndicadorTendencia({
    super.key,
    required this.porcentaje,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final esPositivo = porcentaje > 0;
    final color = esPositivo
        ? const Color(0xFF2D6A4F)
        : const Color(0xFFA63A3A);

    final colorTexto = esPositivo
        ? const Color(0xFF40916C)
        : const Color(0xFFE55B5B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: ShapeDecoration(
        color: const Color(0xFF1E1612),
        shape: BeveledRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          side: BorderSide(
            color: color.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorTexto,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '${esPositivo ? '+' : ''}${porcentaje.toStringAsFixed(1)}%',
            style: GoogleFonts.cinzel(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: colorTexto,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
