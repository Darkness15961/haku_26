import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';

/// Carrusel horizontal de rutas recomendadas con foto.
class CarruselRutasRecomendadas extends StatelessWidget {
  final List<ModeloRuta> rutas;
  final ValueChanged<ModeloRuta>? onTapRuta;

  const CarruselRutasRecomendadas({
    super.key,
    required this.rutas,
    this.onTapRuta,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Rutas recomendadas',
            style: TipografiaHaku.titulo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: PaletaRutas.marronOscuro,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: rutas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final ruta = rutas[index];
              final veloNegro = index.isEven;
              return _TarjetaRutaCarrusel(
                ruta: ruta,
                veloNegro: veloNegro,
                onTap: () => onTapRuta?.call(ruta),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TarjetaRutaCarrusel extends StatelessWidget {
  final ModeloRuta ruta;
  final bool veloNegro;
  final VoidCallback? onTap;

  const _TarjetaRutaCarrusel({
    required this.ruta,
    required this.veloNegro,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 168,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black,
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: ruta.imagenUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const ColoredBox(color: Color(0xFFE8E0D4)),
                  errorWidget: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFFD4C8B8)),
                ),
                // Delineado fino interno para realzar la foto.
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.8),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.85),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: veloNegro
                          ? [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.72),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.55),
                            ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: veloNegro
                                ? Colors.black.withValues(alpha: 0.45)
                                : Colors.white.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            ruta.dificultadTexto,
                            style: TipografiaHaku.interfaz(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        ruta.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.titulo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ruta.dias} d · ${ruta.distancia}',
                        style: TipografiaHaku.interfaz(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.88),
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
