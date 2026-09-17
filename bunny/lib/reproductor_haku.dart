import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Fase 8: Componente Reproductor HLS
/// Recibe el GUID de la base de datos y arma la URL dinámica hacia Bunny CDN.
class ReproductorHaku extends StatefulWidget {
  final String proveedorVideoId;

  const ReproductorHaku({super.key, required this.proveedorVideoId});

  @override
  State<ReproductorHaku> createState() => _ReproductorHakuState();
}

class _ReproductorHakuState extends State<ReproductorHaku> {
  late VideoPlayerController _controller;
  bool _inicializado = false;
  bool _error = false;

  // 1. Enrutamiento Dinámico (Construcción de la URL de Bunny Stream)
  final String _cdnDomain = 'https://vz-4481808a-a3e.b-cdn.net';

  @override
  void initState() {
    super.initState();
    _inicializarReproductor();
  }

  Future<void> _inicializarReproductor() async {
    try {
      // Ensamblaje exacto hacia el manifiesto HLS
      final urlHls = '$_cdnDomain/${widget.proveedorVideoId}/playlist.m3u8';
      print('🎬 Inicializando reproductor HLS: $urlHls');

      _controller = VideoPlayerController.networkUrl(Uri.parse(urlHls));

      // Inicializa la conexión y descarga los metadatos y el primer fragmento de video
      await _controller.initialize();
      
      // (Opcional) Reproducción automática silenciosa para el Feed
      await _controller.setVolume(0.0); // Muteado por defecto para UX del Feed
      await _controller.setLooping(true);
      await _controller.play();

      if (mounted) {
        setState(() {
          _inicializado = true;
        });
      }
    } catch (e) {
      print('❌ Error inicializando el reproductor HLS: $e');
      if (mounted) {
        setState(() {
          _error = true;
        });
      }
    }
  }

  @override
  void dispose() {
    // ⚠️ CRÍTICO: Prevención de Memory Leaks. 
    // Destruye el motor del reproductor cuando el Widget sale de la pantalla.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
    }

    if (!_inicializado) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blue), // Indicador de carga
      );
    }

    // Renderizado del reproductor conservando el Aspect Ratio original del video
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_controller),
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true, // Permite al turista adelantar/retroceder el video
            colors: const VideoProgressColors(
              playedColor: Colors.blue,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pantalla de prueba aislada para ver el reproductor en acción
class PantallaPruebaHls extends StatelessWidget {
  final String videoGuid;

  const PantallaPruebaHls({super.key, required this.videoGuid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎬 HLS (Fase 8)'),
        backgroundColor: Colors.deepPurple,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: ReproductorHaku(proveedorVideoId: videoGuid),
      ),
    );
  }
}
