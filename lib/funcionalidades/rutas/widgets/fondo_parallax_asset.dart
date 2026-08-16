import 'package:flutter/material.dart';

/// Fondo tipo "gambar background" con parallax al hacer scroll.
class FondoParallaxAsset extends StatelessWidget {
  final String asset;
  final double scrollOffset;
  final double factorParallax;
  final BoxFit fit;
  final Alignment alignment;
  final double scale;

  const FondoParallaxAsset({
    super.key,
    required this.asset,
    required this.scrollOffset,
    this.factorParallax = 0.22,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.scale = 1.2,
  });

  @override
  Widget build(BuildContext context) {
    final dy = scrollOffset * factorParallax;
    return ClipRect(
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Transform.scale(
          scale: scale,
          alignment: alignment,
          child: Image.asset(
            asset,
            fit: fit,
            alignment: alignment,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

/// Contenedor con imagen de fondo parallax (sin velo transparente).
class TarjetaFondoParallax extends StatelessWidget {
  final String asset;
  final double scrollOffset;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double factorParallax;

  const TarjetaFondoParallax({
    super.key,
    required this.asset,
    required this.scrollOffset,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.factorParallax = 0.18,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          Positioned.fill(
            child: FondoParallaxAsset(
              asset: asset,
              scrollOffset: scrollOffset,
              factorParallax: factorParallax,
              scale: 1.28,
            ),
          ),
          Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
