import 'package:flutter/material.dart';

import 'espacio_haku.dart';

/// Centra y limita el ancho solo en tablets reales.
/// En teléfono (incluso landscape) ocupa todo el ancho disponible.
class LienzoHaku extends StatelessWidget {
  const LienzoHaku({
    super.key,
    required this.child,
    this.fondo = const Color(0xFF141210),
  });

  final Widget child;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    if (!EspacioHaku.esTablet(context)) return child;

    final maxAncho = EspacioHaku.maxAnchoContenido(context);
    final w = MediaQuery.sizeOf(context).width;
    if (w <= maxAncho + 8) return child;

    return ColoredBox(
      color: fondo,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxAncho),
          child: child,
        ),
      ),
    );
  }
}

/// Aplica textScaler acotado + [LienzoHaku] al árbol de rutas.
class EnvoltorioAppResponsiva extends StatelessWidget {
  const EnvoltorioAppResponsiva({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(textScaler: EspacioHaku.textScalerAcotado(context)),
      child: LienzoHaku(child: child),
    );
  }
}
