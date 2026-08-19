import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';

/// Intro breve al abrir Inicio: marca + brújula + CTA.
class HeroEntradaInicio extends StatefulWidget {
  final VoidCallback onComenzar;

  const HeroEntradaInicio({super.key, required this.onComenzar});

  @override
  State<HeroEntradaInicio> createState() => _EstadoHeroEntradaInicio();
}

class _EstadoHeroEntradaInicio extends State<HeroEntradaInicio>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PaletaRutas.marronOscuro.withValues(alpha: 0.88),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_ctrl.value.clamp(0.0, 1.0));
            final giro = _ctrl.value * math.pi * 1.2;
            return Opacity(
              opacity: t,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.rotate(
                        angle: giro,
                        child: Icon(
                          Icons.explore_rounded,
                          size: 72,
                          color: PaletaRutas.crema.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'HAKU',
                        style: TipografiaHaku.logo(
                          fontSize: 56,
                          color: PaletaRutas.crema,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cusco',
                        textAlign: TextAlign.center,
                        style: TipografiaHaku.interfaz(
                          fontSize: 15,
                          color: PaletaRutas.crema.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 36),
                      FilledButton(
                        onPressed: widget.onComenzar,
                        style: FilledButton.styleFrom(
                          backgroundColor: PaletaRutas.verdeBosque,
                          foregroundColor: PaletaRutas.crema,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                            side: const BorderSide(color: Color(0xFF2D432B)),
                          ),
                        ),
                        child: Text(
                          'Explorar',
                          style: TipografiaHaku.interfaz(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.crema,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
