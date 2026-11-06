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

class _EstadoPantallaCargaInicial extends State<PantallaCargaInicial> {
  static const _duracionPresentacion = Duration(seconds: 5);
  Timer? _temporizadorPresentacion;
  bool _presentacionCumplida = false;
  bool _navegacionRealizada = false;
  bool _preparacionCompleta = false;
  Object? _errorPreparacion;

  @override
  void initState() {
    super.initState();
    final preparacion = widget.preparacion;
    if (preparacion != null) {
      _observarPreparacion(preparacion);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Tiempo de presentación solicitado: el backend avanza en paralelo.
      _temporizadorPresentacion = Timer(_duracionPresentacion, () {
        _presentacionCumplida = true;
        _intentarContinuar();
      });
      if (preparacion == null) _iniciarPreparacion();
    });
  }

  void _iniciarPreparacion() {
    // Future.sync captura tanto errores inmediatos como futuros fallidos.
    // Se ejecuta tras el primer frame, sin una espera artificial adicional.
    _observarPreparacion(Future<void>.sync(() => widget.preparar?.call()));
  }

  void _reintentar() {
    if (_errorPreparacion == null || widget.preparar == null) return;
    setState(() => _errorPreparacion = null);
    _iniciarPreparacion();
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
        !_presentacionCumplida ||
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
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _temporizadorPresentacion?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorPreparacion != null) {
      return widget.pantallaError ??
          Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 52),
                      const SizedBox(height: 20),
                      const Text(
                        'No pudimos iniciar HAKU',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Comprueba tu conexión y vuelve a intentarlo.',
                        textAlign: TextAlign.center,
                      ),
                      if (widget.preparar != null) ...[
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _reintentar,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
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
                      retraso: Duration.zero,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 28,
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
          ],
        ),
      ),
    );
  }
}
