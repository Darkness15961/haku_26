import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../rutas/widgets/estilos_rutas.dart';

/// Splash tipo Netflix: video a pantalla completa + marca HAKU encima.
class PantallaCargaInicial extends StatefulWidget {
  final Widget siguientePantalla;

  const PantallaCargaInicial({required this.siguientePantalla, super.key});

  @override
  State<PantallaCargaInicial> createState() => _EstadoPantallaCargaInicial();
}

class _EstadoPantallaCargaInicial extends State<PantallaCargaInicial>
    with SingleTickerProviderStateMixin {
  static const _rutaVideo = 'assets/videos/inicio_haku.mp4';
  static const _duracionAlternativa = Duration(seconds: 3);

  VideoPlayerController? _controladorVideo;
  Timer? _temporizador;
  bool _videoDisponible = false;
  bool _navegacionRealizada = false;
  late final AnimationController _fadeLogo;

  @override
  void initState() {
    super.initState();
    _fadeLogo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _prepararVideo();
  }

  Future<void> _prepararVideo() async {
    final controlador = VideoPlayerController.asset(_rutaVideo);
    _controladorVideo = controlador;

    try {
      await controlador.initialize();
      await controlador.setLooping(false);
      await controlador.setVolume(0.85);

      if (!mounted) return;

      setState(() => _videoDisponible = true);
      controlador.addListener(_verificarFinDelVideo);
      await controlador.play();

      // Tope máximo por si el video es muy largo (estilo intro corta).
      _temporizador = Timer(const Duration(seconds: 12), _continuar);
    } catch (_) {
      _temporizador = Timer(_duracionAlternativa, _continuar);
    }
  }

  void _verificarFinDelVideo() {
    final controlador = _controladorVideo;
    if (controlador != null &&
        controlador.value.isInitialized &&
        controlador.value.duration > Duration.zero &&
        controlador.value.position >=
            controlador.value.duration - const Duration(milliseconds: 200)) {
      _continuar();
    }
  }

  void _continuar() {
    if (!mounted || _navegacionRealizada) return;

    _navegacionRealizada = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => widget.siguientePantalla,
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _fadeLogo.dispose();
    _controladorVideo?.removeListener(_verificarFinDelVideo);
    _controladorVideo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controlador = _controladorVideo;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_videoDisponible &&
                controlador != null &&
                controlador.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controlador.value.size.width,
                  height: controlador.value.size.height,
                  child: VideoPlayer(controlador),
                ),
              )
            else
              const ColoredBox(color: Colors.black),
            // Velo suave para legibilidad del logo.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fadeLogo,
                child: Text(
                  'HAKU',
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.logo(
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ).copyWith(
                    letterSpacing: 10,
                    shadows: const [
                      Shadow(
                        color: Color(0xCC000000),
                        blurRadius: 18,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Tap para saltar intro.
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
