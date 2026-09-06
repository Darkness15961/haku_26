import 'package:flutter/material.dart';

import '../../../nucleo/widgets/imagen_haku.dart';
import '../dominio/modelos/modelo_ruta.dart';
import 'decoracion_detalle_fondo.dart';
import 'estilos_rutas.dart';

/// Tarjeta de ruta para la lista (miniatura + meta + dificultad).
class TarjetaRuta extends StatelessWidget {
  final ModeloRuta ruta;
  final VoidCallback? onTap;
  final int indice;
  final bool compacta;

  const TarjetaRuta({
    super.key,
    required this.ruta,
    this.onTap,
    this.indice = 0,
    this.compacta = false,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = compacta ? 64.0 : 80.0;
    final pad = compacta ? 10.0 : 12.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    FondosDetalleHaku.porIndice(indice),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: PaletaRutas.carbon),
                  ),
                ),
                Positioned.fill(
                  child: ColoredBox(
                    color: PaletaRutas.ink.withValues(alpha: 0.82),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: PaletaRutas.plomo.withValues(alpha: 0.35),
                    ),
                  ),
                  padding: EdgeInsets.all(pad),
                  child: Row(
                    children: [
                      SizedBox(
                        width: thumb,
                        height: thumb,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: PaletaRutas.plomo.withValues(alpha: 0.45),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: ImagenHaku(
                              url: ruta.imagenUrl,
                              fit: BoxFit.cover,
                              width: thumb,
                              height: thumb,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: compacta ? 10 : 14),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ruta.titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TipografiaHaku.titulo(
                                fontSize: compacta ? 15 : 16,
                                fontWeight: FontWeight.w700,
                                color: PaletaRutas.piedra,
                              ),
                            ),
                            SizedBox(height: compacta ? 3 : 5),
                            Text(
                              [
                                if (ruta.calificacion > 0)
                                  '★ ${ruta.calificacion.toStringAsFixed(1)}',
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
                            if (!compacta) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'Dificultad',
                                    style: TipografiaHaku.interfaz(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: PaletaRutas.plomoClaro,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ...List.generate(4, (i) {
                                    final activo = i < ruta.nivelDificultad;
                                    return Container(
                                      margin: const EdgeInsets.only(right: 4),
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: activo
                                            ? PaletaRutas.oro
                                            : PaletaRutas.plomo
                                                .withValues(alpha: 0.45),
                                      ),
                                    );
                                  }),
                                  Text(
                                    ruta.dificultadTexto,
                                    style: TipografiaHaku.interfaz(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: PaletaRutas.plomoClaro,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
