import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/servicio_video_publicacion.dart';

class VideoPublicacionHaku extends StatefulWidget {
  const VideoPublicacionHaku({
    super.key,
    required this.publicacionId,
    required this.url,
    required this.estadoInicial,
    this.miniaturaUrl,
  });

  final String publicacionId;
  final String url;
  final String estadoInicial;
  final String? miniaturaUrl;

  @override
  State<VideoPublicacionHaku> createState() => _EstadoVideoPublicacionHaku();
}

class _EstadoVideoPublicacionHaku extends State<VideoPublicacionHaku> {
  final _servicio = ServicioVideoPublicacion();
  VideoPlayerController? _controller;
  late String _estado;
  bool _ocupado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _estado = widget.estadoInicial.trim().isEmpty
        ? 'processing'
        : widget.estadoInicial.trim();
    if (_estado != 'ready' && _estado != 'error') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sincronizarInicial();
      });
    }
  }

  @override
  void didUpdateWidget(covariant VideoPublicacionHaku oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.publicacionId == widget.publicacionId &&
        oldWidget.url == widget.url) {
      return;
    }
    _controller?.dispose();
    _controller = null;
    _error = null;
    _estado = widget.estadoInicial.trim().isEmpty
        ? 'processing'
        : widget.estadoInicial.trim();
    if (_estado != 'ready' && _estado != 'error') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sincronizarInicial();
      });
    }
  }

  Future<void> _sincronizarInicial() async {
    final id = int.tryParse(widget.publicacionId);
    if (!mounted || id == null) return;
    try {
      final remoto = await _servicio.consultarEstado(id);
      if (!mounted || widget.publicacionId != '$id') return;
      setState(() {
        _estado = remoto.estado;
        if (remoto.estado == 'error') {
          _error = 'El video no pudo procesarse.';
        }
      });
    } catch (_) {
      // La miniatura y el reintento manual siguen disponibles sin conexión.
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _activar() async {
    if (_ocupado) return;
    final existente = _controller;
    if (existente != null && existente.value.isInitialized) {
      if (existente.value.isPlaying) {
        await existente.pause();
      } else {
        await existente.play();
      }
      if (mounted) setState(() {});
      return;
    }

    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      if (_estado != 'ready') {
        final id = int.tryParse(widget.publicacionId);
        if (id == null) {
          throw const ErrorVideoPublicacion('Publicación inválida.');
        }
        final remoto = await _servicio.consultarEstado(id);
        _estado = remoto.estado;
        if (!remoto.listo) {
          if (!mounted) return;
          setState(() {
            _error = remoto.estado == 'error'
                ? 'El video no pudo procesarse.'
                : 'El video todavía se está procesando.';
          });
          return;
        }
      }

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );
      await controller.initialize();
      await controller.setLooping(false);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;
    } catch (error) {
      _error = error is ErrorVideoPublicacion
          ? error.mensaje
          : 'No se pudo reproducir el video.';
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final reproduciendo =
        controller != null &&
        controller.value.isInitialized &&
        controller.value.isPlaying;
    final miniatura = widget.miniaturaUrl?.trim() ?? '';

    return Material(
      color: PaletaRutas.carbon,
      child: InkWell(
        onTap: _activar,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (controller != null && controller.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            else if (miniatura.isNotEmpty)
              ImagenHaku(url: miniatura, fit: BoxFit.cover)
            else
              const ColoredBox(color: PaletaRutas.carbon),
            if (!reproduciendo)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                ),
              ),
            if (_ocupado)
              const Center(
                child: CircularProgressIndicator(color: PaletaRutas.oro),
              )
            else if (!reproduciendo)
              Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: PaletaRutas.ink.withValues(alpha: 0.88),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: PaletaRutas.oro.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Icon(
                    _estado == 'ready'
                        ? Icons.play_arrow_rounded
                        : Icons.sync_rounded,
                    size: 32,
                    color: PaletaRutas.oro,
                  ),
                ),
              ),
            if (_error != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: PaletaRutas.ink.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TipografiaHaku.interfaz(
                      fontSize: 11,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
