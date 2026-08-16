import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelos/destino_destacado.dart';
import 'indicador_tendencia.dart';

/// Panel de ranking de destinos estilizado como Nichos de Piedra Inca.
class RankingDestinos extends StatelessWidget {
  final List<DestinoDestacado> destinos;
  final String titulo;

  const RankingDestinos({
    super.key,
    required this.destinos,
    this.titulo = 'Top destinos del mes',
  });

  @override
  Widget build(BuildContext context) {
    if (destinos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF6F0E2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TipografiaHaku.interfaz(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF6F0E2),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(destinos.length, (index) {
          return _ItemRanking(
            destino: destinos[index],
            esUltimo: index == destinos.length - 1,
          );
        }),
      ],
    );
  }
}

class _ItemRanking extends StatelessWidget {
  final DestinoDestacado destino;
  final bool esUltimo;

  const _ItemRanking({
    required this.destino,
    this.esUltimo = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorBadge = switch (destino.posicion) {
      1 => const Color(0xFFF6F0E2),
      2 => const Color(0xFFD8C29A),
      3 => const Color(0xFFB45E3B),
      _ => Colors.white54,
    };

    return Container(
      margin: EdgeInsets.only(bottom: esUltimo ? 0 : 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF261D18),
            Color(0xFF16100B),
          ],
        ),
        shape: BeveledRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(4),
          ),
          side: BorderSide(
            color: const Color(0xFF2D432B).withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: ShapeDecoration(
              color: const Color(0xFF38281C),
              shape: BeveledRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                side: BorderSide(
                  color: colorBadge,
                  width: 1.2,
                ),
              ),
            ),
            child: Text(
              '#${destino.posicion}',
              style: TipografiaHaku.interfaz(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: colorBadge,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destino.nombre,
                  style: TipografiaHaku.titulo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  destino.descripcion,
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IndicadorTendencia(
            porcentaje: destino.crecimientoMensual,
            fontSize: 10,
          ),
        ],
      ),
    );
  }
}
