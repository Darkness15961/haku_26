import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';

/// Carrusel horizontal de rutas destacadas (fotos grandes).
class CarruselRutasRecomendadas extends StatelessWidget {
  final List<ModeloRuta> rutas;
  final ValueChanged<ModeloRuta>? onTapRuta;
  final VoidCallback? onVerTodas;
  final String titulo;
  final String? iconoAsset;
  final double? altura;
  final double? anchoTarjeta;
  final String? subtitulo;

  const CarruselRutasRecomendadas({
    super.key,
    required this.rutas,
    this.onTapRuta,
    this.onVerTodas,
    this.titulo = 'Rutas recomendadas',
    this.iconoAsset,
    this.altura,
    this.anchoTarjeta,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
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
                        iconoAsset ?? 'assets/iconos/montania.svg',
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
                            'Ver todas',
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
              if (subtitulo != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitulo!,
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    color: PaletaRutas.marronCuero,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: LineaEncabezadoInca(altura: 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: altura ?? 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: rutas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final ruta = rutas[index];
              return _TarjetaRutaCarrusel(
                ruta: ruta,
                ancho: anchoTarjeta ?? 210,
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
  final double ancho;

  const _TarjetaRutaCarrusel({
    required this.ruta,
    this.onTap,
    this.ancho = 176,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: ancho,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImagenHaku(
                  url: ruta.imagenUrl,
                  fit: BoxFit.cover,
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
                            color: ruta.hilo == HiloCultura.camino
                                ? PaletaRutas.marronOscuro.withValues(alpha: 0.72)
                                : PaletaRutas.terracota.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            ruta.hilo == HiloCultura.camino
                                ? ruta.dificultadTexto.toUpperCase()
                                : ruta.hilo.etiqueta.toUpperCase(),
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
                        ruta.hilo == HiloCultura.camino
                            ? '${ruta.dias} días · ${ruta.distancia}'
                            : ruta.subtitulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
