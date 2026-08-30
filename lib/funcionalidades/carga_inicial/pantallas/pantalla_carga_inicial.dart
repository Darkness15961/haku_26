import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../nucleo/demo/preferencias_demo_haku.dart';
import '../../../nucleo/recursos/copy_haku.dart';
import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import 'pantalla_onboarding_demo.dart';

/// Splash — montaña andina + marca HAKU.
class PantallaCargaInicial extends StatefulWidget {
  final Widget siguientePantalla;

  const PantallaCargaInicial({required this.siguientePantalla, super.key});

  @override
  State<PantallaCargaInicial> createState() => _EstadoPantallaCargaInicial();
}

class _EstadoPantallaCargaInicial extends State<PantallaCargaInicial>
    with SingleTickerProviderStateMixin {
  static const _duracion = Duration(milliseconds: 2200);

  Timer? _temporizador;
  bool _navegacionRealizada = false;
  late final AnimationController _entrada;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _entrada, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrada, curve: Curves.easeOutCubic));
    _entrada.forward();
    _temporizador = Timer(_duracion, _continuar);
  }

  Future<void> _continuar() async {
    if (!mounted || _navegacionRealizada) return;
    _navegacionRealizada = true;

    final onboardingVisto = await PreferenciasDemoHaku.onboardingVisto();
    if (!mounted) return;

    final destino = onboardingVisto
        ? widget.siguientePantalla
        : PantallaOnboardingDemo(siguiente: widget.siguientePantalla);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => destino,
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 550),
      ),
    );
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _entrada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: PaletaRutas.ink,
        body: Stack(
          fit: StackFit.expand,
          children: [
            ImagenHaku(
              url: CatalogoImagenesHaku.splashFondo,
              fit: BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PaletaRutas.ink.withValues(alpha: 0.55),
                    PaletaRutas.ink.withValues(alpha: 0.2),
                    PaletaRutas.ink.withValues(alpha: 0.88),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'HAKU',
                          textAlign: TextAlign.center,
                          style: TipografiaHaku.titulo(
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
                            letterSpacing: 10,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: 48,
                          height: 2,
                          decoration: BoxDecoration(
                            color: PaletaRutas.oro.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 28,
              child: FadeTransition(
                opacity: _fade,
                child: Text(
                  CopyHaku.splashPie,
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: PaletaRutas.plomo,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _continuar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
