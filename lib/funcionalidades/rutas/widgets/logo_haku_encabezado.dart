import 'package:flutter/material.dart';

/// Logo Haku para encabezados (Inicio, Rutas, etc.).
class LogoHakuEncabezado extends StatelessWidget {
  static const asset = 'public/image/logo_haku_encabezado.jpeg';

  final double height;

  const LogoHakuEncabezado({
    super.key,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Text(
        'HAKU',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
