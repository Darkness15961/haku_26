import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../nucleo/metricas/metricas_descubrimiento.dart';
import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/recursos/copy_haku.dart';
import '../../../nucleo/widgets/avatar_haku.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../inicio/datos/feed_inicio_datasource_local.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../inicio/proveedores/proveedor_comunidad_ui.dart';
import '../../inicio/proveedores/proveedor_navegacion_inicio.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../lugares/proveedores/proveedor_lugares.dart';
import '../../rutas/datos/rutas_datasource_local.dart';
import '../datos/catalogo_publicacion_demo.dart';
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
    this.irAComunidadAlPublicar = true,
  });

  final String? rutaId;
  final String? rutaTitulo;
  /// Si es false (p. ej. desde detalle), vuelve al contexto anterior.
  final bool irAComunidadAlPublicar;

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
  bool _opcionesAvanzadas = false;
  String? _musica;
  String? _lugarId;
  String? _rutaId;
  String? _lugarNombre;
  CategoriaLugar? _categoria;
  final List<String> _etiquetas = [];

  @override
  void initState() {
    super.initState();
    final id = widget.rutaId?.trim();
    final titulo = widget.rutaTitulo?.trim();
    if (id != null && id.isNotEmpty) {
      if (RutasDataSourceLocal.obtenerPorId(id) != null) {
        _rutaId = id;
      } else {
        _lugarId = id;
      }
    }
    if (titulo != null && titulo.isNotEmpty) {
      _lugarNombre = titulo;
      _descripcion.text = titulo;
    }
  }

  @override
  void dispose() {
    _descripcion.dispose();
    super.dispose();
  }

  void _aviso(String mensaje) {
    mostrarSnackHaku(context, mensaje);
  }

  void _abrirLugarSiFalta() {
    if (_rutaId != null && _rutaId!.isNotEmpty) return;
    if (_lugarId != null && _lugarId!.isNotEmpty) return;
    final nombre = _lugarNombre?.trim();
    if (nombre != null && nombre.isNotEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mostrarLugares();
    });
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
      _abrirLugarSiFalta();
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
      _abrirLugarSiFalta();
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
            color: PaletaRutas.carbon.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: PaletaRutas.plomo.withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: PaletaRutas.plomo,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Agregar contenido',
                style: TipografiaHaku.titulo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.piedra,
                ),
              ),
              const SizedBox(height: 14),
              _OpcionSheet(
                icono: Icons.photo_library_outlined,
                titulo: 'Foto',
                onTap: () {
                  Navigator.pop(context);
                  _elegirFoto();
                },
              ),
              const SizedBox(height: 8),
              _OpcionSheet(
                icono: Icons.videocam_outlined,
                titulo: 'Video',
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
              _rutaId = null;
              _lugarNombre = lugar.nombre;
              _categoria = lugar.categoria;
            });
            Navigator.pop(ctx);
          },
          onNuevo: (nombre) {
            setState(() {
              _lugarId = null;
              _rutaId = null;
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
            color: PaletaRutas.carbon,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
            ),
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
                  color: PaletaRutas.piedra,
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
                      selectedColor: PaletaRutas.oro.withValues(alpha: 0.22),
                      backgroundColor: PaletaRutas.carbon,
                      side: BorderSide(
                        color: _categoria == cat
                            ? PaletaRutas.oro
                            : PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
                      ),
                      labelStyle: TipografiaHaku.interfaz(
                        fontWeight: FontWeight.w700,
                        color: _categoria == cat
                            ? PaletaRutas.oro
                            : PaletaRutas.plomoClaro,
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

  void _mostrarMusica() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          decoration: BoxDecoration(
            color: PaletaRutas.carbon,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Música',
                textAlign: TextAlign.center,
                style: TipografiaHaku.titulo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.piedra,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Biblioteca demo — elige una pista para tu recuerdo',
                textAlign: TextAlign.center,
                style: TipografiaHaku.interfaz(
                  fontSize: 12,
                  color: PaletaRutas.plomoClaro,
                ),
              ),
              const SizedBox(height: 14),
              for (final pista in CatalogoPublicacionDemo.pistasMusica) ...[
                ListTile(
                  onTap: () {
                    setState(() => _musica = pista.etiqueta);
                    Navigator.pop(ctx);
                  },
                  selected: _musica == pista.etiqueta,
                  selectedTileColor: PaletaRutas.oro.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Icon(
                    Icons.music_note_rounded,
                    color: _musica == pista.etiqueta
                        ? PaletaRutas.oro
                        : PaletaRutas.plomoClaro,
                  ),
                  title: Text(
                    pista.titulo,
                    style: TipografiaHaku.interfaz(
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  subtitle: Text(
                    pista.artista,
                    style: TipografiaHaku.interfaz(
                      fontSize: 12,
                      color: PaletaRutas.plomoClaro,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (_musica != null)
                TextButton(
                  onPressed: () {
                    setState(() => _musica = null);
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    'Quitar música',
                    style: TipografiaHaku.interfaz(
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.plomoClaro,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarEtiquetas() {
    final perfiles = ref.read(almacenFeedProvider).perfiles;
    final yo = AlmacenFeedNotifier.idUsuarioLocal;
    final contactos = [
      for (final p in perfiles)
        if (p.id != yo) p,
      if (perfiles.isEmpty) ...FeedInicioDataSourceLocal.sugerencias.where((p) => p.id != yo),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _SheetEtiquetas(
          contactos: contactos,
          seleccionados: {..._etiquetas},
          onConfirmar: (seleccion) {
            setState(() => _etiquetas
              ..clear()
              ..addAll(seleccion));
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  Future<void> _publicar() async {
    var lugarId = _lugarId;
    final nombreLugar = _lugarNombre?.trim();
    final rutaId = _rutaId?.trim();
    final tieneDestino = (lugarId != null && lugarId.isNotEmpty) ||
        (rutaId != null && rutaId.isNotEmpty) ||
        (nombreLugar != null && nombreLugar.isNotEmpty);
    if (!tieneDestino) {
      _aviso('Elige dónde fue');
      return;
    }
    if ((lugarId == null || lugarId.isEmpty) &&
        nombreLugar != null &&
        nombreLugar.isNotEmpty) {
      lugarId = 'lugar_${DateTime.now().millisecondsSinceEpoch}';
      await ref.read(almacenFeedProvider.notifier).guardarLugarCreado(
            ModeloLugar(
              id: lugarId,
              nombre: nombreLugar,
              descripcion: _descripcion.text.trim().isEmpty
                  ? 'HAKU.'
                  : _descripcion.text.trim(),
              imagenUrl: _media?.path ??
                  'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
              categoria: _categoria ?? CategoriaLugar.naturaleza,
              provincia: 'Cusco',
              distrito: 'Por confirmar',
              distanciaKm: 0,
              calificacion: 5,
              nivelExploracion: NivelExploracion.nuevoEnHaku,
              descubiertoEn: DateTime.now(),
              creadoPorUsuario: true,
            ),
          );
      notificarLugaresCambiaron(ref);
      await ref
          .read(metricasDescubrimientoProvider.notifier)
          .registrarDescubrimiento(lugarId, fuente: 'publicar');
    }

    final sesion = ref.read(sesionProvider).usuario;
    final ahora = DateTime.now();
    await ref.read(almacenFeedProvider.notifier).crearPublicacion(
          PublicacionFeed(
            id: 'p_${ahora.millisecondsSinceEpoch}',
            autorId: AlmacenFeedNotifier.idUsuarioLocal,
            autor: sesion?.nombreUsuario ?? CopyHaku.nombreDefault,
            usuario: sesion != null
                ? '@${sesion.nombreUsuario.toLowerCase().replaceAll(' ', '')}'
                : '@haku',
            avatarUrl: CatalogoImagenesHaku.resolverAvatar(sesion?.avatarUrl),
            hace: 'ahora',
            texto: _descripcion.text.trim(),
            imagenUrl: _media?.path,
            likes: 0,
            comentarios: 0,
            estiloFondo: EstiloFondoPublicacion.veloNegro,
            creadoEn: ahora,
            lugarId: rutaId != null && rutaId.isNotEmpty ? null : lugarId,
            lugarNombre: nombreLugar,
            rutaId: rutaId != null && rutaId.isNotEmpty ? rutaId : null,
            categoria: _categoria?.name,
            calificacion: 5,
            musica: _musica,
            menciones: List.unmodifiable(_etiquetas),
          ),
        );

    final idMetrica = rutaId ?? lugarId ?? 'sin_lugar';
    await ref
        .read(metricasDescubrimientoProvider.notifier)
        .registrarExperiencia(idMetrica);
    bumpMetricas(ref);
    if (!mounted) return;

    final etiquetaDestino = nombreLugar ??
        (rutaId != null
            ? (RutasDataSourceLocal.obtenerPorId(rutaId)?.titulo ?? 'la ruta')
            : null);
    final mensaje = widget.irAComunidadAlPublicar
        ? (etiquetaDestino == null
            ? 'Publicado en Comunidad'
            : 'Publicado en $etiquetaDestino')
        : (etiquetaDestino == null
            ? 'Publicado — revisa Recuerdos y Experiencias'
            : 'Publicado en $etiquetaDestino');

    if (widget.irAComunidadAlPublicar) {
      ref.read(pestaniaShellInicioProvider.notifier).state = 2;
      ref.read(pestaniaComunidadProvider.notifier).state = 0;
    }

    mostrarSnackHaku(context, mensaje, destacado: true);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            PantallaPublicaciones.fondo,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => const ColoredBox(color: PaletaRutas.ink),
          ),
          ColoredBox(color: PaletaRutas.ink.withValues(alpha: 0.45)),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _EncabezadoPublicar(
                  titulo: _paso == _PasoPublicacion.elegirMedia
                      ? 'NUEVA PUBLICACIÓN'
                      : 'PUBLICAR',
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
                              icono: Icons.place_outlined,
                              titulo: 'Lugar',
                              subtitulo: _lugarNombre ?? 'Elige dónde fue',
                              onTap: _mostrarLugares,
                            ),
                            const SizedBox(height: 10),
                            _CampoDescripcion(
                              controller: _descripcion,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 18),
                            BotonPrimarioRuta(
                              texto: 'Publicar',
                              icono: Icons.send_rounded,
                              onPressed: _publicar,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => setState(
                                () => _opcionesAvanzadas = !_opcionesAvanzadas,
                              ),
                              child: Text(
                                _opcionesAvanzadas
                                    ? 'Ocultar opciones'
                                    : 'Más opciones',
                                style: TipografiaHaku.interfaz(
                                  fontWeight: FontWeight.w700,
                                  color: PaletaRutas.piedra.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                            if (_opcionesAvanzadas) ...[
                              _CardOpcion(
                                icono: Icons.music_note_rounded,
                                titulo: 'Música',
                                subtitulo: _musica ?? 'Opcional',
                                onTap: _mostrarMusica,
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
                                titulo: 'Etiquetar',
                                subtitulo: _etiquetas.isEmpty
                                    ? 'Menciona compañeros'
                                    : _etiquetas.join(', '),
                                onTap: _mostrarEtiquetas,
                              ),
                            ],
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
              color: PaletaRutas.piedra,
            ),
          ),
          Expanded(
            child: Text(
              titulo,
              textAlign: TextAlign.center,
              style: TipografiaHaku.titulo(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
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
                  color: PaletaRutas.piedra,
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
                      color: PaletaRutas.piedra.withValues(alpha: 0.28),
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
                          color: PaletaRutas.carbon.withValues(alpha: 0.62),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: PaletaRutas.carbon.withValues(alpha: 0.72),
                                border: Border.all(
                                  color: PaletaRutas.piedra.withValues(alpha: 0.9),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: PaletaRutas.piedra,
                                size: 38,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Foto o video',
                              style: TipografiaHaku.interfaz(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: PaletaRutas.piedra,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Elige foto o video',
                              textAlign: TextAlign.center,
                              style: TipografiaHaku.interfaz(
                                fontSize: 13,
                                color: PaletaRutas.piedra.withValues(alpha: 0.75),
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
            color: PaletaRutas.carbon.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PaletaRutas.piedra.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, color: PaletaRutas.piedra, size: 20),
              const SizedBox(width: 8),
              Text(
                texto,
                style: TipografiaHaku.interfaz(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.piedra,
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
      leading: Icon(icono, color: PaletaRutas.piedra),
      title: Text(
        titulo,
        style: TipografiaHaku.interfaz(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: PaletaRutas.piedra,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: PaletaRutas.piedra.withValues(alpha: 0.6),
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
                  color: PaletaRutas.carbon,
                  child: Icon(Icons.broken_image_outlined, color: PaletaRutas.plomo),
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
                      color: PaletaRutas.carbon.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: PaletaRutas.piedra.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.swap_horiz_rounded,
                          color: PaletaRutas.piedra,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Cambiar',
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
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
                  color: PaletaRutas.piedra,
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
        color: PaletaRutas.carbon,
        child: Center(
          child: CircularProgressIndicator(color: PaletaRutas.plomoClaro),
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
        color: PaletaRutas.carbon.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PaletaRutas.piedra.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: 4,
        minLines: 3,
        style: TipografiaHaku.interfaz(
          fontSize: 14,
          color: PaletaRutas.piedra,
          height: 1.35,
        ),
        cursorColor: PaletaRutas.oro,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Qué viste',
          hintStyle: TipografiaHaku.interfaz(
            fontSize: 14,
            color: PaletaRutas.piedra.withValues(alpha: 0.45),
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
            color: PaletaRutas.carbon.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PaletaRutas.piedra.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PaletaRutas.piedra.withValues(alpha: 0.12),
                ),
                child: Icon(icono, color: PaletaRutas.piedra, size: 20),
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
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: PaletaRutas.piedra.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: PaletaRutas.piedra.withValues(alpha: 0.7),
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
          color: PaletaRutas.carbon.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: PaletaRutas.piedra.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Text(
              'Lugar',
              style: TipografiaHaku.titulo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
              cursorColor: PaletaRutas.oro,
              decoration: InputDecoration(
                hintText: 'Lugar',
                hintStyle: TipografiaHaku.interfaz(
                  color: PaletaRutas.piedra.withValues(alpha: 0.45),
                ),
                prefixIcon: const Icon(Icons.search, color: PaletaRutas.plomoClaro),
                filled: true,
                fillColor: PaletaRutas.piedra.withValues(alpha: 0.08),
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
                      color: sel ? PaletaRutas.piedra : PaletaRutas.plomoClaro,
                    ),
                    title: Text(
                      l.nombre,
                      style: TipografiaHaku.interfaz(
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    subtitle: Text(
                      '${l.categoria.etiqueta} · ${l.provincia}',
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: PaletaRutas.plomoClaro,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nuevo,
              style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
              cursorColor: PaletaRutas.oro,
              decoration: InputDecoration(
                hintText: 'Nuevo lugar',
                hintStyle: TipografiaHaku.interfaz(
                  color: PaletaRutas.piedra.withValues(alpha: 0.45),
                ),
                filled: true,
                fillColor: PaletaRutas.piedra.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_rounded, color: PaletaRutas.piedra),
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

class _SheetEtiquetas extends StatefulWidget {
  const _SheetEtiquetas({
    required this.contactos,
    required this.seleccionados,
    required this.onConfirmar,
  });

  final List<SugerenciaSeguimiento> contactos;
  final Set<String> seleccionados;
  final ValueChanged<List<String>> onConfirmar;

  @override
  State<_SheetEtiquetas> createState() => _EstadoSheetEtiquetas();
}

class _EstadoSheetEtiquetas extends State<_SheetEtiquetas> {
  late Set<String> _sel;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _sel = {...widget.seleccionados};
  }

  String _mencion(SugerenciaSeguimiento p) {
    final u = p.usuario.trim();
    if (u.startsWith('@')) return u;
    return '@$u';
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = widget.contactos.where((p) {
      if (_q.isEmpty) return true;
      return p.nombre.toLowerCase().contains(_q) ||
          p.usuario.toLowerCase().contains(_q);
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
          color: PaletaRutas.carbon.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: PaletaRutas.piedra.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Text(
              'Etiquetar compañeros',
              style: TipografiaHaku.titulo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              CopyHaku.etiquetarCompanerosSub,
              style: TipografiaHaku.interfaz(
                fontSize: 12,
                color: PaletaRutas.plomoClaro,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
              cursorColor: PaletaRutas.oro,
              decoration: InputDecoration(
                hintText: 'Buscar',
                hintStyle: TipografiaHaku.interfaz(
                  color: PaletaRutas.piedra.withValues(alpha: 0.45),
                ),
                prefixIcon: const Icon(Icons.search, color: PaletaRutas.plomoClaro),
                filled: true,
                fillColor: PaletaRutas.piedra.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtrados.isEmpty
                  ? Center(
                      child: Text(
                        'Sin resultados',
                        style: TipografiaHaku.interfaz(
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtrados.length,
                      itemBuilder: (context, i) {
                        final p = filtrados[i];
                        final mencion = _mencion(p);
                        final marcado = _sel.contains(mencion);
                        return CheckboxListTile(
                          value: marcado,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _sel.add(mencion);
                              } else {
                                _sel.remove(mencion);
                              }
                            });
                          },
                          activeColor: PaletaRutas.oro,
                          checkColor: PaletaRutas.ink,
                          controlAffinity: ListTileControlAffinity.leading,
                          secondary: AvatarHaku(url: p.avatarUrl, size: 40),
                          title: Text(
                            p.nombre,
                            style: TipografiaHaku.interfaz(
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                          subtitle: Text(
                            mencion,
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: PaletaRutas.plomoClaro,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            BotonPrimarioRuta(
              texto: 'Listo',
              icono: Icons.check_rounded,
              onPressed: () => widget.onConfirmar(_sel.toList()..sort()),
            ),
          ],
        ),
      ),
    );
  }
}
