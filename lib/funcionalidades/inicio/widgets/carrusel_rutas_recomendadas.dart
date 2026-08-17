import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';

/// Carrusel horizontal de rutas destacadas (fotos grandes).
class CarruselRutasRecomendadas extends StatelessWidget {
  final List<ModeloRuta> rutas;
  final ValueChanged<ModeloRuta>? onTapRuta;
  final VoidCallback? onVerTodas;
  final String titulo;

  const CarruselRutasRecomendadas({
    super.key,
    required this.rutas,
    this.onTapRuta,
    this.onVerTodas,
    this.titulo = 'Rutas recomendadas',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.titulo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.marronOscuro,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SvgPicture.asset(
                    'assets/iconos/montania.svg',
                    width: 18,
                    height: 18,
                  ),
                ),
                if (onVerTodas != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onVerTodas,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Ver todas >',
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.marronCuero,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: rutas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final ruta = rutas[index];
              return _TarjetaRutaCarrusel(
                ruta: ruta,
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
  final VoidCallback? onTap;

  const _TarjetaRutaCarrusel({
    required this.ruta,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 176,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
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
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x22000000),
                        Color(0x00000000),
                        Color(0xCC000000),
                      ],
                      stops: [0, 0.4, 1],
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
                            color: PaletaRutas.marronOscuro.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            ruta.dificultadTexto.toUpperCase(),
                            style: TipografiaHaku.interfaz(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.4,
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
                        '${ruta.dias} días · ${ruta.distancia}',
                        style: TipografiaHaku.interfaz(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      if (ruta.etiquetas.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: ruta.etiquetas.take(2).map((e) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                e,
                                style: TipografiaHaku.interfaz(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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
