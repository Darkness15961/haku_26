import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';

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
        ? const Color(0xFF6E8B4A)
        : const Color(0xFFB45E3B);

    final colorTexto = esPositivo
        ? const Color(0xFF6E8B4A)
        : const Color(0xFFB45E3B);

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
            style: TipografiaHaku.interfaz(
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
