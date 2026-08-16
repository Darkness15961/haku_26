import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';

/// Flash breve de brujula + huellas al cambiar de destino.
class TransicionBrujulaHuellas extends StatefulWidget {
  final bool visible;

  const TransicionBrujulaHuellas({super.key, required this.visible});

  @override
  State<TransicionBrujulaHuellas> createState() =>
      _EstadoTransicionBrujulaHuellas();
}

class _EstadoTransicionBrujulaHuellas extends State<TransicionBrujulaHuellas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.visible) _ctrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant TransicionBrujulaHuellas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && !_ctrl.isAnimating) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final opacity = (1.0 - (_ctrl.value - 0.55).clamp(0.0, 1.0) / 0.45)
              .clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity * 0.85,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: _ctrl.value * math.pi * 2,
                    child: const Icon(
                      Icons.explore_rounded,
                      size: 56,
                      color: PaletaRutas.crema,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(4, (i) {
                      final delay = i * 0.12;
                      final local =
                          ((_ctrl.value - delay) / 0.4).clamp(0.0, 1.0);
                      return Opacity(
                        opacity: local,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Transform.rotate(
                            angle: i.isEven ? -0.2 : 0.2,
                            child: Icon(
                              Icons.directions_walk_rounded,
                              size: 18,
                              color: PaletaRutas.crema.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
