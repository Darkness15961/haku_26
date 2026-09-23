import 'package:flutter/material.dart';

import '../../../nucleo/widgets/imagen_haku.dart';
import '../dominio/modelos/modelo_ruta.dart';
import 'estilos_rutas.dart';
import 'linea_encabezado_inca.dart';

/// Celda Lego de ruta: foto que llena su zona + meta compacta (sin campo negro).
class TarjetaRutaLego extends StatelessWidget {
  const TarjetaRutaLego({
    super.key,
    required this.ruta,
    required this.indice,
    this.onTap,
  });

  final ModeloRuta ruta;
  final int indice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PaletaRutas.carbon,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 11,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: ImagenHaku(url: ruta.imagenUrl, fit: BoxFit.cover),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [Color(0xA8141210), Color(0x00000000)],
                      ),
                    ),
                  ),
                  if (ruta.calificacion > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: PaletaRutas.ink.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: PaletaRutas.oro,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              ruta.cantidadResenas > 0
                                  ? '${ruta.calificacion.toStringAsFixed(1)} (${ruta.cantidadResenas})'
                                  : ruta.calificacion.toStringAsFixed(1),
                              style: TipografiaHaku.interfaz(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: PaletaRutas.piedra,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const LineaEncabezadoInca(altura: 2.5),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ruta.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TipografiaHaku.titulo(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: PaletaRutas.piedra,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      ruta.hilo == HiloCultura.camino
                          ? '${ruta.cantidadLugares} lugares'
                          : ruta.hilo.etiqueta,
                      ruta.dias == 1 ? '1 día' : '${ruta.dias} días',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TipografiaHaku.interfaz(
                      fontSize: 11,
                      color: PaletaRutas.plomoClaro,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(4, (i) {
                        final activo = i < ruta.nivelDificultad;
                        return Container(
                          margin: const EdgeInsets.only(right: 3),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: activo
                                ? PaletaRutas.oro
                                : PaletaRutas.plomo.withValues(alpha: 0.4),
                          ),
                        );
                      }),
                      Expanded(
                        child: Text(
                          ruta.dificultadTexto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TipografiaHaku.interfaz(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: PaletaRutas.plomoClaro,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
