import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../lugares/proveedores/proveedor_lugares.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/publicacion_datasource_supabase.dart';
import '../datos/servicio_video_publicacion.dart';
import '../proveedores/proveedor_comunidad.dart';
import '../proveedores/proveedor_publicaciones.dart';

/// Alta remota: `publicacion` + opcionales etiqueta comunidad / lugar / foto.
/// Sin likes, música, menciones inventadas.
class PantallaCrearPublicacionRemota extends ConsumerStatefulWidget {
  const PantallaCrearPublicacionRemota({
    super.key,
    this.comunidadIdInicial,
    this.lugarIdInicial,
    this.lugarNombreInicial,
  });

  final String? comunidadIdInicial;
  final String? lugarIdInicial;
  final String? lugarNombreInicial;

  @override
  ConsumerState<PantallaCrearPublicacionRemota> createState() =>
      _EstadoPantallaCrearPublicacionRemota();
}

class _EstadoPantallaCrearPublicacionRemota
    extends ConsumerState<PantallaCrearPublicacionRemota> {
  final _texto = TextEditingController();
  final _picker = ImagePicker();
  XFile? _foto;
  Uint8List? _fotoBytes;
  XFile? _video;
  int? _videoTamano;
  String? _comunidadId;
  String? _lugarId;
  bool _guardando = false;
  double? _progresoVideo;

  @override
  void initState() {
    super.initState();
    _comunidadId = widget.comunidadIdInicial;
    _lugarId = widget.lugarIdInicial;
    final nombre = widget.lugarNombreInicial?.trim();
    if (nombre != null && nombre.isNotEmpty) {
      _texto.text = nombre;
    }
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _foto = file;
      _fotoBytes = bytes;
      _video = null;
      _videoTamano = null;
    });
  }

  Future<void> _elegirVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 10),
    );
    if (file == null) return;
    try {
      final tamano = await ServicioVideoPublicacion().validarArchivo(file);
      if (!mounted) return;
      setState(() {
        _video = file;
        _videoTamano = tamano;
        _foto = null;
        _fotoBytes = null;
      });
    } on ErrorVideoPublicacion catch (error) {
      if (mounted) mostrarSnackHaku(context, error.mensaje);
    }
  }

  Future<void> _publicar() async {
    final contenido = _texto.text.trim();
    if (contenido.isEmpty) {
      mostrarSnackHaku(context, 'Escribe algo para publicar');
      return;
    }
    if (contenido.length > PublicacionDataSourceSupabase.maxLenContenido) {
      mostrarSnackHaku(
        context,
        'Máximo ${PublicacionDataSourceSupabase.maxLenContenido} caracteres',
      );
      return;
    }

    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    if (!supabaseListo) {
      mostrarSnackHaku(context, 'La publicación no está disponible ahora');
      return;
    }
    final uid = clienteSupabase.auth.currentUser?.id;
    if (uid == null) {
      mostrarSnackHaku(context, 'Inicia sesión');
      return;
    }

    setState(() {
      _guardando = true;
      _progresoVideo = _video == null ? null : 0;
    });
    try {
      final ds = ref.read(publicacionRemotoDataSourceProvider);
      if (_video != null) {
        final creada = await ds.crear(
          contenido: contenido,
          comunidadId: _comunidadId,
          lugarId: _lugarId,
        );
        final publicacionId = int.tryParse(creada.id);
        if (publicacionId == null) {
          throw const ErrorVideoPublicacion(
            'No se pudo identificar la publicación creada.',
          );
        }

        final servicio = ServicioVideoPublicacion();
        try {
          final ticket = await servicio.preparar(publicacionId);
          await servicio.subir(
            archivo: _video!,
            ticket: ticket,
            alProgresar: (progreso) {
              if (mounted) setState(() => _progresoVideo = progreso);
            },
          );
        } catch (_) {
          try {
            await servicio.cancelar(publicacionId);
          } catch (_) {}
          try {
            await ds.eliminarLogica(creada.id);
          } catch (_) {}
          rethrow;
        }
        // La subida ya fue confirmada. Una caída temporal al consultar el
        // procesamiento no debe borrar un video cargado correctamente.
        try {
          await servicio.consultarEstado(publicacionId);
        } catch (_) {}
      } else if (_foto != null && _fotoBytes != null) {
        final name = _foto!.name.toLowerCase();
        final ext = name.endsWith('.png')
            ? 'png'
            : (name.endsWith('.webp') ? 'webp' : 'jpg');
        final contentType = ext == 'png'
            ? 'image/png'
            : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
        await ds.crearConImagen(
          userId: uid,
          bytes: _fotoBytes!,
          contentType: contentType,
          extension: ext,
          contenido: contenido,
          comunidadId: _comunidadId,
          lugarId: _lugarId,
        );
      } else {
        await ds.crear(
          contenido: contenido,
          comunidadId: _comunidadId,
          lugarId: _lugarId,
        );
      }

      notificarPublicacionesCambiaron(ref);
      if (!mounted) return;
      mostrarSnackHaku(
        context,
        _video == null
            ? 'Publicado'
            : 'Video subido. Bunny Stream lo está procesando.',
        destacado: true,
      );
      Navigator.of(context).pop(true);
    } on ErrorVideoPublicacion catch (e) {
      if (mounted) mostrarSnackHaku(context, e.mensaje);
    } on AuthException catch (e) {
      if (mounted) mostrarSnackHaku(context, e.message);
    } catch (_) {
      if (mounted) {
        mostrarSnackHaku(
          context,
          'No se pudo publicar. Revisa membresía / lugar.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
          _progresoVideo = null;
        });
      }
    }
  }

  String _mostrarTamano(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(sesionProvider).usuario?.id ?? '';
    final comunidadesAsync = ref.watch(comunidadesRemotasProvider);
    final lugaresAsync = ref.watch(lugaresRemotosProvider);
    final mias = (comunidadesAsync.valueOrNull ?? const [])
        .where(
          (c) => uid.isNotEmpty && (c.esMiembro(uid) || c.creadorId == uid),
        )
        .toList();
    final lugares = lugaresAsync.valueOrNull ?? const [];
    final bottom = MediaQuery.paddingOf(context).bottom + 16;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _guardando
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Nueva publicación',
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.titulo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _guardando ? null : _publicar,
                    child: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: PaletaRutas.oro,
                            ),
                          )
                        : Text(
                            'Publicar',
                            style: TipografiaHaku.interfaz(
                              fontWeight: FontWeight.w800,
                              color: PaletaRutas.oro,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: LineaEncabezadoInca(altura: 2),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
                children: [
                  TextField(
                    controller: _texto,
                    maxLines: 6,
                    maxLength: PublicacionDataSourceSupabase.maxLenContenido,
                    enabled: !_guardando,
                    style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                    cursorColor: PaletaRutas.oro,
                    decoration: InputDecoration(
                      hintText: '¿Qué estás explorando?',
                      hintStyle: TipografiaHaku.interfaz(
                        color: PaletaRutas.plomo,
                      ),
                      filled: true,
                      fillColor: PaletaRutas.carbon,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _guardando ? null : _elegirFoto,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PaletaRutas.piedra,
                            side: BorderSide(
                              color: PaletaRutas.plomo.withValues(alpha: 0.6),
                            ),
                          ),
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: Text(
                            _foto == null ? 'Foto' : 'Cambiar foto',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaHaku.interfaz(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _guardando ? null : _elegirVideo,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PaletaRutas.piedra,
                            side: BorderSide(
                              color: PaletaRutas.oro.withValues(alpha: 0.65),
                            ),
                          ),
                          icon: const Icon(
                            Icons.video_library_outlined,
                            size: 18,
                          ),
                          label: Text(
                            _video == null ? 'Video' : 'Cambiar video',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaHaku.interfaz(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_fotoBytes != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.memory(_fotoBytes!, fit: BoxFit.cover),
                      ),
                    ),
                    TextButton(
                      onPressed: _guardando
                          ? null
                          : () => setState(() {
                              _foto = null;
                              _fotoBytes = null;
                            }),
                      child: Text(
                        'Quitar foto',
                        style: TipografiaHaku.interfaz(
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                    ),
                  ],
                  if (_video != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PaletaRutas.carbon,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: PaletaRutas.oro.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.movie_outlined,
                            color: PaletaRutas.oro,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _video!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TipografiaHaku.interfaz(
                                    fontWeight: FontWeight.w700,
                                    color: PaletaRutas.piedra,
                                  ),
                                ),
                                if (_videoTamano != null)
                                  Text(
                                    '${_mostrarTamano(_videoTamano!)} · máximo 10 min',
                                    style: TipografiaHaku.interfaz(
                                      fontSize: 11,
                                      color: PaletaRutas.plomoClaro,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Quitar video',
                            onPressed: _guardando
                                ? null
                                : () => setState(() {
                                    _video = null;
                                    _videoTamano = null;
                                  }),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: PaletaRutas.plomoClaro,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_guardando && _progresoVideo != null) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _progresoVideo,
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(8),
                      color: PaletaRutas.oro,
                      backgroundColor: PaletaRutas.carbon,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Subiendo video ${((_progresoVideo ?? 0) * 100).round()}%',
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: PaletaRutas.plomoClaro,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Comunidad (opcional)',
                    style: TipografiaHaku.interfaz(
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.plomoClaro,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    // ignore: deprecated_member_use
                    value: _comunidadId,
                    dropdownColor: PaletaRutas.carbon,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: PaletaRutas.carbon,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    hint: Text(
                      mias.isEmpty
                          ? 'Únete a una comunidad para etiquetar'
                          : 'Sin etiqueta',
                      style: TipografiaHaku.interfaz(color: PaletaRutas.plomo),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'Sin etiqueta',
                          style: TipografiaHaku.interfaz(
                            color: PaletaRutas.piedra,
                          ),
                        ),
                      ),
                      for (final c in mias)
                        DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(
                            c.nombre,
                            style: TipografiaHaku.interfaz(
                              color: PaletaRutas.piedra,
                            ),
                          ),
                        ),
                    ],
                    onChanged: _guardando || mias.isEmpty
                        ? null
                        : (v) => setState(() => _comunidadId = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lugar Explora (opcional)',
                    style: TipografiaHaku.interfaz(
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.plomoClaro,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (lugaresAsync.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: PaletaRutas.oro,
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<String?>(
                      // ignore: deprecated_member_use
                      value: _lugarId,
                      dropdownColor: PaletaRutas.carbon,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: PaletaRutas.carbon,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      hint: Text(
                        lugares.isEmpty ? 'Sin lugares activos' : 'Sin lugar',
                        style: TipografiaHaku.interfaz(
                          color: PaletaRutas.plomo,
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Sin lugar',
                            style: TipografiaHaku.interfaz(
                              color: PaletaRutas.piedra,
                            ),
                          ),
                        ),
                        for (final l in lugares)
                          DropdownMenuItem<String?>(
                            value: l.id,
                            child: Text(
                              l.nombre,
                              style: TipografiaHaku.interfaz(
                                color: PaletaRutas.piedra,
                              ),
                            ),
                          ),
                      ],
                      onChanged: _guardando || lugares.isEmpty
                          ? null
                          : (v) => setState(() => _lugarId = v),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Puedes adjuntar una foto o un video de hasta 10 minutos y 500 MB.',
                    style: TipografiaHaku.interfaz(
                      fontSize: 11,
                      color: PaletaRutas.plomo,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
