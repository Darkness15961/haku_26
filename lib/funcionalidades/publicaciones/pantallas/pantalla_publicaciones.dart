import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../nucleo/metricas/metricas_descubrimiento.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../inicio/datos/feed_inicio_datasource_local.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../lugares/proveedores/proveedor_lugares.dart';
import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';

enum _PasoPublicacion { elegirMedia, editar }

/// Flujo: 1) subir foto/video → 2) preview + descripcion / musica / etc.
/// Preferible vincular a un lugar (rutaId / rutaTitulo = id/nombre de lugar).
class PantallaPublicaciones extends ConsumerStatefulWidget {
  const PantallaPublicaciones({
    super.key,
    this.rutaId,
    this.rutaTitulo,
  });

  final String? rutaId;
  final String? rutaTitulo;

  static const fondo = 'public/image/fondo_publicaciones.jpg';

  @override
  ConsumerState<PantallaPublicaciones> createState() =>
      _EstadoPantallaPublicaciones();
}

class _EstadoPantallaPublicaciones
    extends ConsumerState<PantallaPublicaciones> {
  final _picker = ImagePicker();
  final _descripcion = TextEditingController();

  _PasoPublicacion _paso = _PasoPublicacion.elegirMedia;
  XFile? _media;
  bool _esVideo = false;
  bool _editandoDescripcion = false;
  String? _musica;
  String? _lugarId;
  String? _lugarNombre;
  CategoriaLugar? _categoria;
  final List<String> _etiquetas = [];

  @override
  void initState() {
    super.initState();
    final titulo = widget.rutaTitulo?.trim();
    _lugarId = widget.rutaId;
    if (titulo != null && titulo.isNotEmpty) {
      _lugarNombre = titulo;
      _descripcion.text = 'Documentando: $titulo';
    }
  }

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

  void _mostrarLugares() {
    final lugares = ref.read(lugaresListaProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _SheetLugar(
          lugares: lugares,
          seleccionadoId: _lugarId,
          onElegir: (lugar) {
            setState(() {
              _lugarId = lugar.id;
              _lugarNombre = lugar.nombre;
              _categoria = lugar.categoria;
            });
            Navigator.pop(ctx);
          },
          onNuevo: (nombre) {
            setState(() {
              _lugarId = null;
              _lugarNombre = nombre;
            });
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  void _mostrarCategorias() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Categoría',
                textAlign: TextAlign.center,
                style: TipografiaHaku.titulo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cat in CategoriaLugar.values)
                    ChoiceChip(
                      label: Text(cat.etiqueta),
                      selected: _categoria == cat,
                      onSelected: (_) {
                        setState(() => _categoria = cat);
                        Navigator.pop(ctx);
                      },
                      selectedColor: Colors.white,
                      labelStyle: TipografiaHaku.interfaz(
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.marronOscuro,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _publicar() async {
    var lugarId = _lugarId;
    final nombreLugar = _lugarNombre?.trim();
    if ((lugarId == null || lugarId.isEmpty) &&
        nombreLugar != null &&
        nombreLugar.isNotEmpty) {
      lugarId = 'lugar_${DateTime.now().millisecondsSinceEpoch}';
      ref.read(lugaresDataSourceProvider).agregar(
            ModeloLugar(
              id: lugarId,
              nombre: nombreLugar,
              descripcion: _descripcion.text.trim().isEmpty
                  ? 'Documentado en una publicación HAKU.'
                  : _descripcion.text.trim(),
              imagenUrl: _media?.path ??
                  'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
              categoria: _categoria ?? CategoriaLugar.naturaleza,
              provincia: 'Cusco',
              distrito: 'Por confirmar',
              distanciaKm: 0,
              calificacion: 5,
              exploradores: 1,
              fotos: 1,
              nivelExploracion: NivelExploracion.nuevoEnHaku,
              descubiertoEn: DateTime.now(),
              creadoPorUsuario: true,
            ),
          );
      notificarLugaresCambiaron(ref);
    }

    final sesion = ref.read(sesionProvider).usuario;
    final ahora = DateTime.now();
    await ref.read(almacenFeedProvider.notifier).crearPublicacion(
          PublicacionFeed(
            id: 'p_${ahora.millisecondsSinceEpoch}',
            autorId: AlmacenFeedNotifier.idUsuarioLocal,
            autor: sesion?.nombreUsuario ?? 'Explorador HAKU',
            usuario: sesion != null
                ? '@${sesion.nombreUsuario.toLowerCase().replaceAll(' ', '')}'
                : '@haku',
            avatarUrl:
                'https://images.unsplash.com/photo-1551632811-561732d1e306?w=200&q=80',
            hace: 'ahora',
            texto: _descripcion.text.trim(),
            imagenUrl: _media?.path,
            likes: 0,
            comentarios: 0,
            estiloFondo: EstiloFondoPublicacion.veloNegro,
            creadoEn: ahora,
            lugarId: lugarId,
            lugarNombre: nombreLugar,
            categoria: _categoria?.name,
          ),
        );

    final idMetrica = lugarId ?? 'sin_lugar';
    ref.read(metricasDescubrimientoProvider.notifier).registrarExperiencia(idMetrica);
    bumpMetricas(ref);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nombreLugar == null
              ? 'Publicación lista'
              : 'Publicado en $nombreLugar',
          style: TipografiaHaku.interfaz(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                  onListo: _paso == _PasoPublicacion.editar ? _publicar : null,
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
                              titulo: 'Lugar',
                              subtitulo: _lugarNombre ??
                                  'Elige o escribe el lugar después',
                              onTap: _mostrarLugares,
                            ),
                            const SizedBox(height: 10),
                            _CardOpcion(
                              icono: Icons.category_outlined,
                              titulo: 'Categoría',
                              subtitulo: _categoria?.etiqueta ??
                                  'Caminata, cultura, naturaleza…',
                              onTap: _mostrarCategorias,
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
                              onPressed: _publicar,
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

class _SheetLugar extends StatefulWidget {
  final List<ModeloLugar> lugares;
  final String? seleccionadoId;
  final ValueChanged<ModeloLugar> onElegir;
  final ValueChanged<String> onNuevo;

  const _SheetLugar({
    required this.lugares,
    required this.seleccionadoId,
    required this.onElegir,
    required this.onNuevo,
  });

  @override
  State<_SheetLugar> createState() => _EstadoSheetLugar();
}

class _EstadoSheetLugar extends State<_SheetLugar> {
  final _nuevo = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _nuevo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = widget.lugares.where((l) {
      if (_q.isEmpty) return true;
      return l.nombre.toLowerCase().contains(_q) ||
          l.categoria.etiqueta.toLowerCase().contains(_q);
    }).toList();
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Text(
              'Lugar',
              style: TipografiaHaku.titulo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              style: TipografiaHaku.interfaz(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Buscar un lugar existente…',
                hintStyle: TipografiaHaku.interfaz(
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filtrados.length,
                itemBuilder: (context, i) {
                  final l = filtrados[i];
                  final sel = l.id == widget.seleccionadoId;
                  return ListTile(
                    onTap: () => widget.onElegir(l),
                    selected: sel,
                    leading: Icon(
                      Icons.place_outlined,
                      color: sel ? Colors.white : Colors.white70,
                    ),
                    title: Text(
                      l.nombre,
                      style: TipografiaHaku.interfaz(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      '${l.categoria.etiqueta} · ${l.provincia}',
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nuevo,
              style: TipografiaHaku.interfaz(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'O escribe un lugar nuevo…',
                hintStyle: TipografiaHaku.interfaz(
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                  onPressed: () {
                    final n = _nuevo.text.trim();
                    if (n.isEmpty) return;
                    widget.onNuevo(n);
                  },
                ),
              ),
              onSubmitted: (v) {
                final n = v.trim();
                if (n.isEmpty) return;
                widget.onNuevo(n);
              },
            ),
          ],
        ),
      ),
    );
  }
}
