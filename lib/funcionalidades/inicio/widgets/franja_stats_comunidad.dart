import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';

/// Franja de métricas vivas de la comunidad HAKU.
class FranjaStatsComunidad extends StatelessWidget {
  const FranjaStatsComunidad({
    super.key,
    required this.aportes,
    required this.hilos,
    required this.huecos,
    required this.exploradores,
  });

  final int aportes;
  final int hilos;
  final int huecos;
  final int exploradores;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              PaletaRutas.crema,
              PaletaRutas.pergamino.withValues(alpha: 0.95),
            ],
          ),
          border: Border.all(
            color: PaletaRutas.terracota.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: PaletaRutas.marronOscuro.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Row(
                children: [
                  _Stat(
                    valor: '$aportes',
                    etiqueta: 'Aportes',
                    icono: Icons.photo_camera_outlined,
                  ),
                  _divisor(),
                  _Stat(
                    valor: '$hilos',
                    etiqueta: 'Hilos',
                    icono: Icons.auto_stories_outlined,
                  ),
                  _divisor(),
                  _Stat(
                    valor: '$huecos',
                    etiqueta: 'Huecos',
                    icono: Icons.explore_outlined,
                    acento: PaletaRutas.terracota,
                  ),
                  _divisor(),
                  _Stat(
                    valor: '$exploradores',
                    etiqueta: 'Gente',
                    icono: Icons.groups_outlined,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: LineaEncabezadoInca(altura: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divisor() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: PaletaRutas.marronCuero.withValues(alpha: 0.2),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.valor,
    required this.etiqueta,
    required this.icono,
    this.acento,
  });

  final String valor;
  final String etiqueta;
  final IconData icono;
  final Color? acento;

  @override
  Widget build(BuildContext context) {
    final color = acento ?? PaletaRutas.marronOscuro;
    return Expanded(
      child: Column(
        children: [
          Icon(icono, size: 16, color: color.withValues(alpha: 0.75)),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TipografiaHaku.titulo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            etiqueta,
            style: TipografiaHaku.interfaz(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: PaletaRutas.marronCuero,
            ),
          ),
        ],
      ),
    );
  }
}
