import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';

enum _PasoPublicacion { elegirMedia, editar }

/// Flujo: 1) subir foto/video → 2) preview + descripcion / musica / etc.
class PantallaPublicaciones extends StatefulWidget {
  const PantallaPublicaciones({super.key});

  static const fondo = 'public/image/fondo_publicaciones.jpg';

  @override
  State<PantallaPublicaciones> createState() => _EstadoPantallaPublicaciones();
}

class _EstadoPantallaPublicaciones extends State<PantallaPublicaciones> {
  final _picker = ImagePicker();
  final _descripcion = TextEditingController();

  _PasoPublicacion _paso = _PasoPublicacion.elegirMedia;
  XFile? _media;
  bool _esVideo = false;
  bool _editandoDescripcion = false;
  String? _musica;
  String? _ubicacion;
  final List<String> _etiquetas = [];

  @override
  void dispose() {
    _descripcion.dispose();
    super.dispose();
  }

  void _aviso(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: TipografiaHaku.interfaz(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _elegirFoto() async {
    try {
      final archivo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (archivo == null || !mounted) return;
      setState(() {
        _media = archivo;
        _esVideo = false;
        _paso = _PasoPublicacion.editar;
      });
    } catch (_) {
      _aviso('No se pudo abrir la galeria de fotos');
    }
  }

  Future<void> _elegirVideo() async {
    try {
      final archivo = await _picker.pickVideo(source: ImageSource.gallery);
      if (archivo == null || !mounted) return;
      setState(() {
        _media = archivo;
        _esVideo = true;
        _paso = _PasoPublicacion.editar;
      });
    } catch (_) {
      _aviso('No se pudo abrir la galeria de videos');
    }
  }

  void _mostrarSelectorMedia() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Agregar media',
                style: TipografiaHaku.titulo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              _OpcionSheet(
                icono: Icons.photo_library_outlined,
                titulo: 'Subir foto',
                onTap: () {
                  Navigator.pop(context);
                  _elegirFoto();
                },
              ),
              const SizedBox(height: 8),
              _OpcionSheet(
                icono: Icons.videocam_outlined,
                titulo: 'Subir video',
                onTap: () {
                  Navigator.pop(context);
                  _elegirVideo();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _atras() {
    if (_paso == _PasoPublicacion.editar) {
      setState(() {
        _paso = _PasoPublicacion.elegirMedia;
        _media = null;
        _esVideo = false;
      });
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            PantallaPublicaciones.fondo,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _EncabezadoPublicar(
                  titulo: _paso == _PasoPublicacion.elegirMedia
                      ? 'NUEVA PUBLICACION'
                      : 'EDITAR PUBLICACION',
                  onAtras: _atras,
                  onListo: _paso == _PasoPublicacion.editar
                      ? () => _aviso('Publicacion lista para enviar')
                      : null,
                ),
                Expanded(
                  child: _paso == _PasoPublicacion.elegirMedia
                      ? _PasoElegirMedia(
                          onAgregar: _mostrarSelectorMedia,
                          onFoto: _elegirFoto,
                          onVideo: _elegirVideo,
                        )
                      : ListView(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottom),
                          children: [
                            _PreviewMedia(
                              archivo: _media!,
                              esVideo: _esVideo,
                              onCambiar: _mostrarSelectorMedia,
                            ),
                            const SizedBox(height: 14),
                            _CardOpcion(
                              icono: Icons.notes_rounded,
                              titulo: 'Descripcion',
                              subtitulo: _descripcion.text.trim().isEmpty
                                  ? 'Cuenta tu aventura...'
                                  : _descripcion.text.trim(),
                              onTap: () => setState(
                                () => _editandoDescripcion =
                                    !_editandoDescripcion,
                              ),
                            ),
                            if (_editandoDescripcion) ...[
                              const SizedBox(height: 8),
                              _CampoDescripcion(
                                controller: _descripcion,
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                            const SizedBox(height: 10),
                            _CardOpcion(
                              icono: Icons.music_note_rounded,
                              titulo: 'Agregar musica',
                              subtitulo: _musica ?? 'Elige un sonido',
                              onTap: () {
                                setState(
                                  () => _musica = 'Sonido de los Andes',
                                );
                                _aviso('Musica: conectar biblioteca despues');
                              },
                            ),
                            const SizedBox(height: 10),
                            _CardOpcion(
                              icono: Icons.place_outlined,
                              titulo: 'Agregar ubicacion',
                              subtitulo:
                                  _ubicacion ?? 'Donde estas explorando',
                              onTap: () {
                                setState(() => _ubicacion = 'Cusco, Peru');
                                _aviso('Ubicacion: conectar mapa despues');
                              },
                            ),
                            const SizedBox(height: 10),
                            _CardOpcion(
                              icono: Icons.person_add_alt_1_rounded,
                              titulo: 'Etiquetar personas',
                              subtitulo: _etiquetas.isEmpty
                                  ? 'Menciona companeros de viaje'
                                  : _etiquetas.join(', '),
                              onTap: () {
                                setState(() {
                                  if (!_etiquetas.contains('@explorador')) {
                                    _etiquetas.add('@explorador');
                                  }
                                });
                                _aviso(
                                  'Etiquetas: conectar contactos despues',
                                );
                              },
                            ),
                            const SizedBox(height: 22),
                            BotonPrimarioRuta(
                              texto: 'Publicar',
                              icono: Icons.send_rounded,
                              onPressed: () =>
                                  _aviso('Publicacion lista para enviar'),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EncabezadoPublicar extends StatelessWidget {
  final String titulo;
  final VoidCallback onAtras;
  final VoidCallback? onListo;

  const _EncabezadoPublicar({
    required this.titulo,
    required this.onAtras,
    this.onListo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onAtras,
            icon: Icon(
              onListo == null ? Icons.close_rounded : Icons.arrow_back_rounded,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              titulo,
              textAlign: TextAlign.center,
              style: TipografiaHaku.titulo(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ).copyWith(letterSpacing: 0.6),
            ),
          ),
          if (onListo != null)
            TextButton(
              onPressed: onListo,
              child: Text(
                'Listo',
                style: TipografiaHaku.interfaz(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Paso 1: solo elegir foto o video.
class _PasoElegirMedia extends StatelessWidget {
  final VoidCallback onAgregar;
  final VoidCallback onFoto;
  final VoidCallback onVideo;

  const _PasoElegirMedia({
    required this.onAgregar,
    required this.onFoto,
    required this.onVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAgregar,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                      width: 1.2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          FondosDetalleHaku.fondoA,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const ColoredBox(color: Color(0xFF1A1A1A)),
                        ),
                        ColoredBox(
                          color: Colors.black.withValues(alpha: 0.62),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.72),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Subir foto o video',
                              style: TipografiaHaku.interfaz(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Primero elige tu media,\nluego agrega detalles',
                              textAlign: TextAlign.center,
                              style: TipografiaHaku.interfaz(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.75),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BotonMediaRapido(
                  icono: Icons.photo_outlined,
                  texto: 'Foto',
                  onTap: onFoto,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BotonMediaRapido(
                  icono: Icons.videocam_outlined,
                  texto: 'Video',
                  onTap: onVideo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BotonMediaRapido extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  const _BotonMediaRapido({
    required this.icono,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                texto,
                style: TipografiaHaku.interfaz(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcionSheet extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final VoidCallback onTap;

  const _OpcionSheet({
    required this.icono,
    required this.titulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icono, color: Colors.white),
      title: Text(
        titulo,
        style: TipografiaHaku.interfaz(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.white.withValues(alpha: 0.6),
      ),
    );
  }
}

/// Paso 2: preview del media elegido.
class _PreviewMedia extends StatelessWidget {
  final XFile archivo;
  final bool esVideo;
  final VoidCallback onCambiar;

  const _PreviewMedia({
    required this.archivo,
    required this.esVideo,
    required this.onCambiar,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (esVideo)
              _PreviewVideo(ruta: archivo.path)
            else
              Image.file(
                File(archivo.path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFF1A1A1A),
                  child: Icon(Icons.broken_image_outlined, color: Colors.white54),
                ),
              ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCambiar,
                  borderRadius: BorderRadius.circular(20),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.swap_horiz_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Cambiar',
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (esVideo)
              const Positioned(
                left: 10,
                top: 10,
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewVideo extends StatefulWidget {
  final String ruta;

  const _PreviewVideo({required this.ruta});

  @override
  State<_PreviewVideo> createState() => _EstadoPreviewVideo();
}

class _EstadoPreviewVideo extends State<_PreviewVideo> {
  late final VideoPlayerController _ctrl;
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.file(File(widget.ruta))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _listo = true);
        _ctrl
          ..setLooping(true)
          ..setVolume(0)
          ..play();
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_listo) {
      return const ColoredBox(
        color: Color(0xFF1A1A1A),
        child: Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: _ctrl.value.size.width,
        height: _ctrl.value.size.height,
        child: VideoPlayer(_ctrl),
      ),
    );
  }
}

class _CampoDescripcion extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _CampoDescripcion({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: 4,
        minLines: 3,
        style: TipografiaHaku.interfaz(
          fontSize: 14,
          color: Colors.white,
          height: 1.35,
        ),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Que descubriste hoy?',
          hintStyle: TipografiaHaku.interfaz(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _CardOpcion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _CardOpcion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                child: Icon(icono, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TipografiaHaku.interfaz(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
