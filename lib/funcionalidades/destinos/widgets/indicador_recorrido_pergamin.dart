import 'package:flutter/material.dart';

import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';

/// Indicador de recorrido: imagen de fondo + velos negros (sin blanco).
class IndicadorRecorridoPergamino extends StatelessWidget {
  final int actual;
  final int total;

  const IndicadorRecorridoPergamino({
    super.key,
    required this.actual,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            const Positioned.fill(
              child: Image(
                image: AssetImage(FondosDetalleHaku.fondoA),
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.68),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.route_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$actual',
                    style: TipografiaHaku.titulo(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '/ $total',
                    style: TipografiaHaku.interfaz(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...List.generate(total, (i) {
                    final activo = i < actual;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      width: 4,
                      height: activo ? 10 : 4,
                      decoration: BoxDecoration(
                        color: activo
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
