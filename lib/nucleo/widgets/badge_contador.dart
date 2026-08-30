import 'package:flutter/material.dart';

import '../../funcionalidades/rutas/widgets/estilos_rutas.dart';

/// Contador estático (estilo Facebook) — sin pulso ni luz verde.
class BadgeContador extends StatelessWidget {
  const BadgeContador({
    super.key,
    required this.cantidad,
    this.compacto = false,
  });

  final int cantidad;
  final bool compacto;

  String get _texto {
    if (cantidad <= 0) return '';
    if (cantidad > 99) return '99+';
    return '$cantidad';
  }

  @override
  Widget build(BuildContext context) {
    if (cantidad <= 0) return const SizedBox.shrink();

    final h = compacto ? 16.0 : 18.0;
    return Container(
      constraints: BoxConstraints(minWidth: h, minHeight: h),
      padding: EdgeInsets.symmetric(horizontal: compacto ? 4 : 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PaletaRutas.oro,
        borderRadius: BorderRadius.circular(h / 2),
        border: Border.all(color: PaletaRutas.ink, width: 1.2),
      ),
      child: Text(
        _texto,
        style: TipografiaHaku.interfaz(
          fontSize: compacto ? 9 : 10,
          fontWeight: FontWeight.w900,
          color: PaletaRutas.ink,
          height: 1,
        ),
      ),
    );
  }
}

/// Badge numérico sobre un icono (esquina superior derecha).
class BadgeContadorOverlay extends StatelessWidget {
  const BadgeContadorOverlay({
    super.key,
    required this.cantidad,
    required this.child,
    this.compacto = false,
  });

  final int cantidad;
  final Widget child;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    if (cantidad <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        child,
        Positioned(
          right: compacto ? -4 : -6,
          top: compacto ? -4 : -6,
          child: BadgeContador(cantidad: cantidad, compacto: compacto),
        ),
      ],
    );
  }
}
