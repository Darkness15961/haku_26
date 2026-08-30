import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'estilos_rutas.dart';

/// Imagen hero: se mueve con el scroll y base circular (arco inferior).
class ImagenParallaxRuta extends StatelessWidget {
  final String imagenUrl;
  final double altura;
  final double scrollOffset;
  /// 1.0 = la imagen se mueve al mismo ritmo que el scroll.
  final double factorParallax;

  const ImagenParallaxRuta({
    super.key,
    required this.imagenUrl,
    this.altura = 300,
    this.scrollOffset = 0,
    this.factorParallax = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final desplazamiento = scrollOffset * factorParallax;

    return ClipPath(
      clipper: const _ClipBaseCircularInferior(),
      child: SizedBox(
        height: altura,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(0, desplazamiento),
              child: Transform.scale(
                scale: 1.2,
                alignment: Alignment.topCenter,
                child: CachedNetworkImage(
                  imageUrl: imagenUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  placeholder: (_, __) => Container(color: PaletaRutas.arena),
                  errorWidget: (_, __, ___) => Container(
                    color: PaletaRutas.arena,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.landscape_rounded,
                      size: 48,
                      color: PaletaRutas.plomo,
                    ),
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33000000),
                    Color(0x00000000),
                    Color(0x22000000),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recorte inferior en arco (base circular), no borde de hoja rota.
class _ClipBaseCircularInferior extends CustomClipper<Path> {
  const _ClipBaseCircularInferior();

  @override
  Path getClip(Size size) {
    final arco = size.height * 0.12;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - arco)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + arco * 0.35,
        0,
        size.height - arco,
      )
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
