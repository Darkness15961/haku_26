import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PantallaCargaInicial extends StatefulWidget {
  final Widget siguientePantalla;

  const PantallaCargaInicial({required this.siguientePantalla, super.key});

  @override
  State<PantallaCargaInicial> createState() => _EstadoPantallaCargaInicial();
}

class _EstadoPantallaCargaInicial extends State<PantallaCargaInicial> {
  static const _rutaVideo = 'assets/videos/inicio_haku.mp4';
  static const _duracionAlternativa = Duration(seconds: 2);

  VideoPlayerController? _controladorVideo;
  Timer? _temporizador;
  bool _videoDisponible = false;
  bool _navegacionRealizada = false;

  @override
  void initState() {
    super.initState();
    _prepararVideo();
  }

  Future<void> _prepararVideo() async {
    final controlador = VideoPlayerController.asset(_rutaVideo);
    _controladorVideo = controlador;

    try {
      await controlador.initialize();
      await controlador.setLooping(false);
      await controlador.setVolume(0);

      if (!mounted) return;

      setState(() => _videoDisponible = true);
      controlador.addListener(_verificarFinDelVideo);
      await controlador.play();
    } catch (_) {
      _temporizador = Timer(_duracionAlternativa, _continuar);
    }
  }

  void _verificarFinDelVideo() {
    final controlador = _controladorVideo;
    if (controlador != null &&
        controlador.value.isInitialized &&
        controlador.value.position >= controlador.value.duration) {
      _continuar();
    }
  }

  void _continuar() {
    if (!mounted || _navegacionRealizada) return;

    _navegacionRealizada = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => widget.siguientePantalla),
    );
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _controladorVideo?.removeListener(_verificarFinDelVideo);
    _controladorVideo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controlador = _controladorVideo;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F2),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_videoDisponible && controlador != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controlador.value.size.width,
                height: controlador.value.size.height,
                child: VideoPlayer(controlador),
              ),
            )
          else
            const _CargaAlternativa(),
        ],
      ),
    );
  }
}

class _CargaAlternativa extends StatelessWidget {
  const _CargaAlternativa();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'HAKU',
            style: TextStyle(
              color: Color(0xFF1F5D42),
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: 6,
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Color(0xFF1F5D42),
              strokeWidth: 2,
            ),
          ),
        ],
      ),
    );
  }
}
