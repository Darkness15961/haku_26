import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import 'metricas_comunidad.dart';

/// Fila de estrellas + exploradores + fotos (detalle lugar / ruta).
class FilaMetricasComunidad extends StatelessWidget {
  const FilaMetricasComunidad({
    super.key,
    required this.metricas,
    required this.calificacionCatalogo,
    this.resenasCatalogo = 0,
    this.alineacion = MainAxisAlignment.start,
    this.usarSpacer = true,
    this.estrellaSize = 20,
    this.notaSize = 16,
    this.mostrarLeyendaComunidad = true,
  });

  final MetricasExperienciaComunidad metricas;
  final double calificacionCatalogo;
  final int resenasCatalogo;
  final MainAxisAlignment alineacion;
  final bool usarSpacer;
  final double estrellaSize;
  final double notaSize;
  final bool mostrarLeyendaComunidad;

  CrossAxisAlignment get _ejeColumna {
    switch (alineacion) {
      case MainAxisAlignment.center:
        return CrossAxisAlignment.center;
      case MainAxisAlignment.end:
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.start;
    }
  }

  @override
  Widget build(BuildContext context) {
    final calificacion = metricas.calificacionMostrar(calificacionCatalogo);
    final resenas = metricas.resenasMostrar(resenasCatalogo);
    final fotos = metricas.etiquetaFotos;
    final exploradores = metricas.etiquetaExploradores;
    final leyenda = mostrarLeyendaComunidad &&
        metricas.calificacionPromedio != null &&
        calificacion > 0;

    if (calificacion <= 0 && fotos.isEmpty && exploradores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: _ejeColumna,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: alineacion,
          mainAxisSize: MainAxisSize.max,
          children: [
            if (calificacion > 0) ...[
              Icon(Icons.star_rounded, size: estrellaSize, color: PaletaRutas.oro),
              const SizedBox(width: 4),
              Text(
                calificacion.toStringAsFixed(1),
                style: TipografiaHaku.interfaz(
                  fontSize: notaSize,
                  fontWeight: FontWeight.w800,
                  color: PaletaRutas.piedra,
                ),
              ),
              if (resenas > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '($resenas)',
                  style: TipografiaHaku.interfaz(
                    fontSize: notaSize - 4,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
              ],
            ],
            if (exploradores.isNotEmpty) ...[
              if (calificacion > 0) const SizedBox(width: 14),
              Icon(
                Icons.people_outline,
                size: estrellaSize - 2,
                color: PaletaRutas.plomoClaro,
              ),
              const SizedBox(width: 4),
              Text(
                exploradores,
                style: TipografiaHaku.interfaz(
                  fontSize: notaSize - 3,
                  fontWeight: FontWeight.w600,
                  color: PaletaRutas.plomoClaro,
                ),
              ),
            ],
            if (fotos.isNotEmpty) ...[
              if (usarSpacer)
                const Spacer()
              else if (calificacion > 0 || exploradores.isNotEmpty)
                const SizedBox(width: 10),
              if (!usarSpacer) ...[
                Icon(
                  Icons.photo_library_outlined,
                  size: estrellaSize - 6,
                  color: PaletaRutas.oroSuave,
                ),
                const SizedBox(width: 3),
              ],
              Text(
                fotos,
                style: TipografiaHaku.interfaz(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.oroSuave,
                ),
              ),
            ],
          ],
        ),
        if (leyenda) ...[
          const SizedBox(height: 4),
          Text(
            '★ de la comunidad',
            style: TipografiaHaku.interfaz(
              fontSize: notaSize - 5,
              fontWeight: FontWeight.w600,
              color: PaletaRutas.plomo,
            ),
          ),
        ],
      ],
    );
  }
}
