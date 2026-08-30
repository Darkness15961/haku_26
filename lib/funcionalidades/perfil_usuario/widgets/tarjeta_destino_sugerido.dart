import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';

/// Card “Proximo destino sugerido” (guia Mi Viaje).
class TarjetaDestinoSugerido extends StatelessWidget {
  final String titulo;
  final double rating;
  final int resenas;
  final String imagenUrl;
  final VoidCallback? onTap;
  final int indice;

  const TarjetaDestinoSugerido({
    super.key,
    required this.titulo,
    required this.rating,
    required this.resenas,
    required this.imagenUrl,
    this.onTap,
    this.indice = 0,
  });

  static final _sombra = [
    Shadow(
      color: PaletaRutas.ink.withValues(alpha: 0.75),
      blurRadius: 5,
      offset: const Offset(0, 1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
                  color: PaletaRutas.ink.withValues(alpha: 0.52),
                ),
              ),
              Ink(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: PaletaRutas.plomo.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.8),
                        child: CachedNetworkImage(
                          imageUrl: imagenUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ColoredBox(
                            color: PaletaRutas.arena,
                            child: SizedBox(width: 72, height: 72),
                          ),
                          errorWidget: (_, __, ___) => const ColoredBox(
                            color: PaletaRutas.arena,
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: Icon(
                                Icons.landscape,
                                color: PaletaRutas.plomo,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaHaku.titulo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.piedra,
                            ).copyWith(shadows: _sombra),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '★ ${rating.toStringAsFixed(1)} ($resenas)',
                            style: TipografiaHaku.interfaz(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: PaletaRutas.oroSuave,
                            ).copyWith(shadows: _sombra),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: PaletaRutas.oro.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: PaletaRutas.oro.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: PaletaRutas.oro,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
