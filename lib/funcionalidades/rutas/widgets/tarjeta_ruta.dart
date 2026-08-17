import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../dominio/modelos/modelo_ruta.dart';
import 'decoracion_detalle_fondo.dart';
import 'estilos_rutas.dart';

/// Tarjeta de ruta para la lista (miniatura + meta + dificultad).
class TarjetaRuta extends StatelessWidget {
  final ModeloRuta ruta;
  final VoidCallback? onTap;
  final int indice;

  const TarjetaRuta({
    super.key,
    required this.ruta,
    this.onTap,
    this.indice = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    FondosDetalleHaku.porIndice(indice),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Colors.black87),
                  ),
                ),
                // Velo un poco más oscuro para mejor contraste de texto.
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.82),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.8),
                          child: CachedNetworkImage(
                            imageUrl: ruta.imagenUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: PaletaRutas.arena,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: PaletaRutas.arena,
                              child: const Icon(
                                Icons.terrain_rounded,
                                color: PaletaRutas.marronCuero,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ruta.titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TipografiaHaku.titulo(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (ruta.calificacion > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 15,
                                    color: PaletaRutas.terracota,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    ruta.calificacion.toStringAsFixed(1),
                                    style: TipografiaHaku.interfaz(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (ruta.tipoSitio != null) ...[
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        ruta.tipoSitio!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TipografiaHaku.interfaz(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white
                                              .withValues(alpha: 0.88),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${ruta.cantidadLugares} lugares',
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.schedule_outlined,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ruta.dias == 1
                                      ? '1 día'
                                      : '${ruta.dias} días',
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Dificultad',
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ...List.generate(4, (i) {
                                  final activo = i < ruta.nivelDificultad;
                                  return Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: activo
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.28),
                                    ),
                                  );
                                }),
                                const SizedBox(width: 6),
                                Text(
                                  ruta.dificultadTexto,
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.85),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
