import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../nucleo/recursos/copy_haku.dart';
import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/widgets/cargador_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/widgets/estilos_rutas.dart';

/// Splash corto — entra directo al shell (sin onboarding).
class PantallaCargaInicial extends StatefulWidget {
  final Widget siguientePantalla;
  final Future<void>? preparacion;
  final Future<void> Function()? preparar;
  final Widget? pantallaError;

  const PantallaCargaInicial({
    required this.siguientePantalla,
    this.preparacion,
    this.preparar,
    this.pantallaError,
    super.key,
  }) : assert(
         preparacion == null || preparar == null,
         'Usa preparacion o preparar, no ambos.',
       );

  @override
  State<PantallaCargaInicial> createState() => _EstadoPantallaCargaInicial();
}

class _EstadoPantallaCargaInicial extends State<PantallaCargaInicial>
    with SingleTickerProviderStateMixin {
  static const _duracion = Duration(milliseconds: 8800);
  static const _margenPrimerFrame = Duration(milliseconds: 200);

  Timer? _temporizador;
  Timer? _temporizadorPreparacion;
  bool _navegacionRealizada = false;
  bool _esperaMinimaCumplida = false;
  bool _preparacionCompleta = false;
  Object? _errorPreparacion;
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
    _preparacionCompleta =
        widget.preparacion == null && widget.preparar == null;
    final preparacion = widget.preparacion;
    if (preparacion != null) {
      _observarPreparacion(preparacion);
    } else if (widget.preparar != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _temporizadorPreparacion = Timer(_margenPrimerFrame, () {
          if (!mounted) return;
          _observarPreparacion(widget.preparar!());
        });
      });
    }
    _temporizador = Timer(_duracion, () {
      _esperaMinimaCumplida = true;
      _intentarContinuar();
    });
  }

  void _observarPreparacion(Future<void> preparacion) {
    preparacion.then<void>(
      (_) {
        if (!mounted) return;
        _preparacionCompleta = true;
        _intentarContinuar();
      },
      onError: (Object error, StackTrace _) {
        if (!mounted) return;
        setState(() => _errorPreparacion = error);
      },
    );
  }

  void _intentarContinuar() {
    if (!mounted ||
        _navegacionRealizada ||
        !_esperaMinimaCumplida ||
        !_preparacionCompleta ||
        _errorPreparacion != null) {
      return;
    }
    _navegacionRealizada = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => widget.siguientePantalla,
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _temporizadorPreparacion?.cancel();
    _entrada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorPreparacion != null && widget.pantallaError != null) {
      return widget.pantallaError!;
    }

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
                        const SizedBox(height: 22),
                        const CargadorHaku(
                          mensaje: null,
                          tamano: 112,
                          centrado: false,
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
                onTap: _intentarContinuar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
