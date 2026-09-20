import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../comunidad/dominio/modelo_publicacion.dart';
import '../../comunidad/datos/servicio_video_publicacion.dart';
import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/widgets/avatar_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../comunidad/datos/publicacion_datasource_supabase.dart';
import '../../comunidad/dominio/modelo_comunidad.dart';
import '../../comunidad/dominio/modelo_salida.dart';
import '../../comunidad/proveedores/proveedor_comunidad.dart';
import '../../comunidad/proveedores/proveedor_publicaciones.dart';
import '../../comunidad/proveedores/proveedor_salidas.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../lugares/proveedores/proveedor_lugares.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/proveedores/proveedor_rutas.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';

// ─────────────────────────────────────────────────────────────────────────────
// A.4 — Bottom sheet: Elegir Lugar
// ─────────────────────────────────────────────────────────────────────────────

Future<ModeloLugar?> mostrarSelectorLugar(
  BuildContext context,
  WidgetRef ref,
) async {
  final lugares = ref.read(lugaresListaProvider);
  return showModalBottomSheet<ModeloLugar>(
    context: context,
    backgroundColor: PaletaRutas.carbon,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (_) => _SelectorLugarSheet(lugares: lugares),
  );
}

class _SelectorLugarSheet extends StatefulWidget {
  const _SelectorLugarSheet({required this.lugares});
  final List<ModeloLugar> lugares;

  @override
  State<_SelectorLugarSheet> createState() => _SelectorLugarSheetState();
}

class _SelectorLugarSheetState extends State<_SelectorLugarSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtrados = widget.lugares
        .where((l) => l.nombre.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, sc) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: PaletaRutas.plomo,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.place_outlined, color: PaletaRutas.oro, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Etiquetar lugar',
                  style: TipografiaHaku.titulo(fontSize: 17, color: PaletaRutas.piedra),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
              cursorColor: PaletaRutas.oro,
              decoration: InputDecoration(
                hintText: 'Buscar lugar\u2026',
                hintStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomo),
                prefixIcon: const Icon(Icons.search, color: PaletaRutas.plomo, size: 20),
                filled: true,
                fillColor: PaletaRutas.ink,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtrados.isEmpty
                ? Center(
                    child: Text(
                      widget.lugares.isEmpty ? 'Sin lugares disponibles' : 'Sin resultados',
                      style: TipografiaHaku.interfaz(color: PaletaRutas.plomo),
                    ),
                  )
                : ListView.builder(
                    controller: sc,
                    itemCount: filtrados.length,
                    itemBuilder: (_, i) {
                      final l = filtrados[i];
                      return ListTile(
                        leading: const Icon(
                          Icons.landscape_outlined,
                          color: PaletaRutas.oro,
                          size: 22,
                        ),
                        title: Text(
                          l.nombre,
                          style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                        ),
                        subtitle: l.distrito.isNotEmpty
                            ? Text(
                                l.distrito,
                                style: TipografiaHaku.interfaz(
                                  fontSize: 12,
                                  color: PaletaRutas.plomo,
                                ),
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(l),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A.5 — Bottom sheet: Elegir Comunidad
// ─────────────────────────────────────────────────────────────────────────────

Future<ComunidadHaku?> mostrarSelectorComunidad(
  BuildContext context,
  WidgetRef ref,
) async {
  final uid = ref.read(sesionProvider).usuario?.id ?? '';
  final comunidades = ref
      .read(comunidadesListaProvider)
      .where((c) => uid.isNotEmpty && (c.esMiembro(uid) || c.creadorId == uid))
      .toList();

  return showModalBottomSheet<ComunidadHaku>(
    context: context,
    backgroundColor: PaletaRutas.carbon,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (_) => _SelectorComunidadSheet(comunidades: comunidades),
  );
}

class _SelectorComunidadSheet extends StatefulWidget {
  const _SelectorComunidadSheet({required this.comunidades});
  final List<ComunidadHaku> comunidades;

  @override
  State<_SelectorComunidadSheet> createState() =>
      _SelectorComunidadSheetState();
}

class _SelectorComunidadSheetState extends State<_SelectorComunidadSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtradas = widget.comunidades
        .where((c) => c.nombre.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      expand: false,
      builder: (_, sc) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: PaletaRutas.plomo,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.groups_outlined, color: PaletaRutas.oro, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Etiquetar comunidad',
                  style: TipografiaHaku.titulo(fontSize: 17, color: PaletaRutas.piedra),
                ),
              ],
            ),
          ),
          if (widget.comunidades.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                cursorColor: PaletaRutas.oro,
                decoration: InputDecoration(
                  hintText: 'Buscar comunidad\u2026',
                  hintStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomo),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: PaletaRutas.plomo,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: PaletaRutas.ink,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.comunidades.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Únete a una comunidad para poder etiquetarla',
                        textAlign: TextAlign.center,
                        style: TipografiaHaku.interfaz(color: PaletaRutas.plomo),
                      ),
                    ),
                  )
                : filtradas.isEmpty
                    ? Center(
                        child: Text(
                          'Sin resultados',
                          style: TipografiaHaku.interfaz(color: PaletaRutas.plomo),
                        ),
                      )
                    : ListView.builder(
                        controller: sc,
                        itemCount: filtradas.length,
                        itemBuilder: (_, i) {
                          final c = filtradas[i];
                          return ListTile(
                            leading: const Icon(
                              Icons.people_outline,
                              color: PaletaRutas.oro,
                              size: 22,
                            ),
                            title: Text(
                              c.nombre,
                              style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                            ),
                            trailing: c.esPrivada
                                ? const Icon(
                                    Icons.lock_outline,
                                    color: PaletaRutas.plomoClaro,
                                    size: 16,
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(c),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A.6 — Bottom sheet: Elegir Salida
// ─────────────────────────────────────────────────────────────────────────────

Future<ModeloSalidaRemota?> mostrarSelectorSalida(
  BuildContext context,
  WidgetRef ref,
) async {
  final salidas = ref.read(salidasRemotasProvider).valueOrNull ?? const [];
  final activas = salidas.where((s) => s.estado != 'cancelada').toList();

  return showModalBottomSheet<ModeloSalidaRemota>(
    context: context,
    backgroundColor: PaletaRutas.carbon,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (_) => _SelectorSalidaSheet(salidas: activas),
  );
}

class _SelectorSalidaSheet extends StatelessWidget {
  const _SelectorSalidaSheet({required this.salidas});
  final List<ModeloSalidaRemota> salidas;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      expand: false,
      builder: (_, sc) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: PaletaRutas.plomo,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.hiking, color: PaletaRutas.oro, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Etiquetar salida',
                  style: TipografiaHaku.titulo(fontSize: 17, color: PaletaRutas.piedra),
                ),
              ],
            ),
          ),
          Expanded(
            child: salidas.isEmpty
                ? Center(
                    child: Text(
                      'No hay salidas disponibles',
                      style: TipografiaHaku.interfaz(color: PaletaRutas.plomo),
                    ),
                  )
                : ListView.builder(
                    controller: sc,
                    itemCount: salidas.length,
                    itemBuilder: (_, i) {
                      final s = salidas[i];
                      return ListTile(
                        leading: const Icon(
                          Icons.directions_walk_outlined,
                          color: PaletaRutas.oro,
                          size: 22,
                        ),
                        title: Text(
                          s.etiquetaPrincipal,
                          style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                        ),
                        subtitle: Text(
                          s.fechaHoraEtiqueta,
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            color: PaletaRutas.plomo,
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop(s),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A.7 — Bottom sheet: Elegir Ruta
// ─────────────────────────────────────────────────────────────────────────────

Future<ModeloRuta?> mostrarSelectorRuta(
  BuildContext context,
  WidgetRef ref,
) async {
  final rutas = ref.read(rutasPublicadasProvider).valueOrNull ?? const [];

  return showModalBottomSheet<ModeloRuta>(
    context: context,
    backgroundColor: PaletaRutas.carbon,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (_) => _SelectorRutaSheet(rutas: rutas),
  );
}

class _SelectorRutaSheet extends StatelessWidget {
  const _SelectorRutaSheet({required this.rutas});
  final List<ModeloRuta> rutas;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      expand: false,
      builder: (_, sc) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: PaletaRutas.plomo,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: PaletaRutas.oro, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Etiquetar ruta',
                  style: TipografiaHaku.titulo(fontSize: 17, color: PaletaRutas.piedra),
                ),
              ],
            ),
          ),
          Expanded(
            child: rutas.isEmpty
                ? Center(
                    child: Text(
                      'No hay rutas publicadas',
                      style: TipografiaHaku.interfaz(color: PaletaRutas.plomo),
                    ),
                  )
                : ListView.builder(
                    controller: sc,
                    itemCount: rutas.length,
                    itemBuilder: (_, i) {
                      final r = rutas[i];
                      return ListTile(
                        leading: const Icon(
                          Icons.route_outlined,
                          color: PaletaRutas.oro,
                          size: 22,
                        ),
                        title: Text(
                          r.titulo,
                          style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                        ),
                        subtitle: r.distancia.isNotEmpty
                            ? Text(
                                '${r.dificultadTexto} \u00b7 ${r.distancia}',
                                style: TipografiaHaku.interfaz(
                                  fontSize: 12,
                                  color: PaletaRutas.plomo,
                                ),
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(r),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A.8 — Chip de contexto reutilizable (lugar / comunidad / salida / ruta)
// ─────────────────────────────────────────────────────────────────────────────

class _ChipContexto extends StatelessWidget {
  const _ChipContexto({
    required this.icono,
    required this.etiqueta,
    required this.onQuitar,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PaletaRutas.oro.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: PaletaRutas.oro),
          const SizedBox(width: 6),
          Text(
            etiqueta,
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: PaletaRutas.piedra,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onQuitar,
            child: const Icon(Icons.close, size: 14, color: PaletaRutas.plomoClaro),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla principal unificada (A.1 — A.8)
// ─────────────────────────────────────────────────────────────────────────────

/// Pantalla unificada para editar publicaciones.
class PantallaEditarPublicacion extends ConsumerStatefulWidget {
  const PantallaEditarPublicacion({
    super.key,
    required this.publicacion,
  });

  final ModeloPublicacionRemota publicacion;

  @override
  ConsumerState<PantallaEditarPublicacion> createState() =>
      _EstadoPantallaEditarPublicacion();
}

class _EstadoPantallaEditarPublicacion
    extends ConsumerState<PantallaEditarPublicacion> {
  final _texto = TextEditingController();
  final _picker = ImagePicker();

  // Media (A.3)
  XFile? _foto;
  Uint8List? _fotoBytes;
  XFile? _video;
  int? _videoTamano;
  
  String? _fotoUrlActual;
  bool _fotoEliminada = false;

  String? _videoUrlActual;
  String? _videoMiniaturaActual;
  bool _videoEliminada = false;

  // Privacidad (A.2)
  bool _esPrivado = false;

  // Etiquetas (A.4 — A.7)
  ModeloLugar? _lugar;
  ComunidadHaku? _comunidad;
  ModeloSalidaRemota? _salida;
  ModeloRuta? _ruta;

  bool _guardando = false;
  double? _progresoVideo; // null = sin video; 0.0..1.0 = progreso TUS

  @override
  void initState() {
    super.initState();
    _texto.text = widget.publicacion.contenido;
    _esPrivado = widget.publicacion.estado == 'privado';
    _fotoUrlActual = widget.publicacion.imagenUrl;
    _videoUrlActual = widget.publicacion.videoUrl;
    _videoMiniaturaActual = widget.publicacion.videoMiniaturaUrl;
    
    Future.microtask(() {
      final lugares = ref.read(lugaresListaProvider);
      final comunidades = ref.read(comunidadesListaProvider);
      final salidas = ref.read(salidasRemotasProvider).valueOrNull ?? const [];
      final rutas = ref.read(rutasPublicadasProvider).valueOrNull ?? const [];
      
      setState(() {
        if (widget.publicacion.lugarId != null) {
          _lugar = lugares.cast<ModeloLugar?>().firstWhere((l) => l?.id == widget.publicacion.lugarId, orElse: () => null);
        }
        if (widget.publicacion.comunidades.isNotEmpty) {
          final cId = widget.publicacion.comunidades.first.comunidadId.toString();
          _comunidad = comunidades.cast<ComunidadHaku?>().firstWhere((c) => c?.id == cId, orElse: () => null);
        }
        if (widget.publicacion.salidaId != null) {
          _salida = salidas.cast<ModeloSalidaRemota?>().firstWhere((s) => s?.id == widget.publicacion.salidaId, orElse: () => null);
        }
        if (widget.publicacion.rutaId != null) {
          _ruta = rutas.cast<ModeloRuta?>().firstWhere((r) => r?.id == widget.publicacion.rutaId, orElse: () => null);
        }
      });
    });
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  // ── A.9: Lógica de publicación completa ────────────────────────────────────
  //
  // Casos:
  //   1. Solo texto (o texto + lugar/comunidad/salida/ruta) → RPC directo.
  //   2. Foto → subirImagen → RPC con p_imagen_url.
  //   3. Video → RPC (crea publicación), preparar ticket Bunny, subir TUS.
  //      Si Bunny falla → soft-delete de la publicación crea (compensación).
  Future<void> _guardarEdicion() async {
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

    final estado = _esPrivado ? 'privado' : 'publico';
    final comunidadId = _comunidad?.id;
    final lugarId = _lugar?.id;
    final rutaId = _ruta?.id;
    final salidaId = _salida?.id;

    setState(() {
      _guardando = true;
      _progresoVideo = _video == null ? null : 0;
    });

    try {
      final ds = ref.read(publicacionRemotoDataSourceProvider);

      if (_video != null) {
        // ── Caso video nuevo ─────────────────────────────────────────────
        // 1. Borramos cualquier media existente en la BD primero (esto dispara el trigger)
        await ds.editar(
          publicacionId: widget.publicacion.id,
          contenido: contenido,
          estado: estado,
          comunidadId: comunidadId,
          lugarId: lugarId,
          rutaId: rutaId,
          salidaId: salidaId,
          eliminarImagenActual: true,
        );

        // 2. Preparamos ticket Bunny (ya no hay media que bloquee)
        final publicacionIdNum = int.tryParse(widget.publicacion.id);
        if (publicacionIdNum == null) {
          throw const ErrorVideoPublicacion('ID de publicación inválido.');
        }

        final servicio = ServicioVideoPublicacion();
        try {
          final ticket = await servicio.preparar(publicacionIdNum);
          await servicio.subir(
            archivo: _video!,
            ticket: ticket,
            alProgresar: (progreso) {
              if (mounted) setState(() => _progresoVideo = progreso);
            },
          );
        } catch (_) {
          // Si falla Bunny, no hacemos soft-delete de la publicación entera
          // porque es una edición. El usuario solo perdió el intento de video.
          rethrow;
        }
        // Estado Bunny puede tardar
        try { await servicio.consultarEstado(publicacionIdNum); } catch (_) {}

      } else if (_foto != null && _fotoBytes != null) {
        // ── Caso foto nueva ──────────────────────────────────────────────
        final nombre = _foto!.name.toLowerCase();
        final ext = nombre.endsWith('.png')
            ? 'png'
            : (nombre.endsWith('.webp') ? 'webp' : 'jpg');
        final contentType = ext == 'png'
            ? 'image/png'
            : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
            
        await ds.editarConImagen(
          publicacionId: widget.publicacion.id,
          userId: uid,
          bytes: _fotoBytes!,
          contentType: contentType,
          extension: ext,
          contenido: contenido,
          estado: estado,
          comunidadId: comunidadId,
          lugarId: lugarId,
          rutaId: rutaId,
          salidaId: salidaId,
          eliminarImagenActual: true,
          imagenUrlActual: widget.publicacion.imagenUrl,
        );

      } else {
        // ── Caso solo texto (o mantiene media actual, o eliminó media) ────
        // Si _fotoEliminada o _videoEliminada son verdaderos, entonces el usuario presionó la 'X'.
        final seEliminoMedia = _fotoEliminada || _videoEliminada;
        
        await ds.editar(
          publicacionId: widget.publicacion.id,
          contenido: contenido,
          estado: estado,
          comunidadId: comunidadId,
          lugarId: lugarId,
          rutaId: rutaId,
          salidaId: salidaId,
          nuevaImagenUrl: null, // NUNCA pasar URL aquí. Si se mantiene, no se toca. Si se elimina, se elimina.
          eliminarImagenActual: seEliminoMedia,
        );
      }

      notificarPublicacionesCambiaron(ref);
      if (!mounted) return;
      mostrarSnackHaku(
        context,
        _video == null 
          ? 'Publicación actualizada' 
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
          'No se pudo actualizar. Revisa tu conexión.',
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
        _fotoEliminada = true; 
        _videoEliminada = true; // El video nuevo reemplaza al anterior
      });
    } on ErrorVideoPublicacion catch (error) {
      if (mounted) mostrarSnackHaku(context, error.mensaje);
    }
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
      _fotoEliminada = false;
      _video = null;
      _videoTamano = null;
      _videoEliminada = true; // La foto nueva reemplaza al video anterior
    });
  }

  String _mostrarTamano(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = ref.watch(sesionProvider).usuario?.avatarUrl;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── FONDO ANDINO ───────────────────────────────────────────────
          Image.asset(
            CatalogoImagenesHaku.fondoPublicaciones,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: PaletaRutas.ink),
          ),
          // Overlay degradado de arriba (transparente) a abajo (casi opaco)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.25, 0.55, 1.0],
                colors: [
                  Color(0x88000000),
                  Color(0xBB0A0A0F),
                  Color(0xE50A0A0F),
                  Color(0xFF0A0A0F),
                ],
              ),
            ),
          ),

          // ── CONTENIDO ──────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── HEADER PREMIUM ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
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
                          'Editar publicación',
                          textAlign: TextAlign.center,
                          style: TipografiaHaku.titulo(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                      ),
                      // Botón publicar tipo pill dorado
                      GestureDetector(
                        onTap: _guardando ? null : _guardarEdicion,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: _guardando
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFD4A843),
                                      Color(0xFFB8860B),
                                    ],
                                  ),
                            color: _guardando
                                ? PaletaRutas.plomo.withValues(alpha: 0.3)
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _guardando
                                ? null
                                : [
                                    BoxShadow(
                                      color: PaletaRutas.oro
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                          ),
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
                                  'Guardar',
                                  style: TipografiaHaku.interfaz(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: PaletaRutas.ink,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: LineaEncabezadoInca(altura: 2),
                ),

                // ── ÁREA DE CONTENIDO (GLASSMORPHISM CARD) ─────────────
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(12, 16, 12, bottom + 16),
                    children: [
                      // Card principal translúcida
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: PaletaRutas.carbon.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: PaletaRutas.plomo.withValues(alpha: 0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar
                                AvatarHaku(url: avatarUrl, size: 44),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // A.2: Toggle público / privado
                                      GestureDetector(
                                        onTap: () => setState(
                                            () => _esPrivado = !_esPrivado),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _esPrivado
                                                ? PaletaRutas.oro
                                                    .withValues(alpha: 0.12)
                                                : PaletaRutas.ink
                                                    .withValues(alpha: 0.5),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _esPrivado
                                                  ? PaletaRutas.oro
                                                      .withValues(alpha: 0.5)
                                                  : PaletaRutas.plomo
                                                      .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _esPrivado
                                                    ? Icons.lock_outline
                                                    : Icons.public,
                                                size: 14,
                                                color: _esPrivado
                                                    ? PaletaRutas.oro
                                                    : PaletaRutas.plomoClaro,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _esPrivado
                                                    ? 'Solo comunidad'
                                                    : 'Público',
                                                style:
                                                    TipografiaHaku.interfaz(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: _esPrivado
                                                      ? PaletaRutas.oro
                                                      : PaletaRutas
                                                          .plomoClaro,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      // Textarea
                                      TextField(
                                        controller: _texto,
                                        minLines: 3,
                                        maxLines: null,
                                        enabled: !_guardando,
                                        style: TipografiaHaku.interfaz(
                                          color: PaletaRutas.piedra,
                                          fontSize: 16,
                                        ),
                                        cursorColor: PaletaRutas.oro,
                                        decoration: InputDecoration(
                                          hintText:
                                              '\u00bfQué estás explorando?',
                                          hintStyle: TipografiaHaku.interfaz(
                                            color: PaletaRutas.plomo,
                                            fontSize: 16,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // A.8: Etiquetas interactivas (seleccionadas y por seleccionar)
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // LUGAR
                                if (_lugar != null)
                                  _ChipContexto(
                                    icono: Icons.place_outlined,
                                    etiqueta: _lugar!.nombre,
                                    onQuitar: () => setState(() => _lugar = null),
                                  )
                                else
                                  _BotonAccionEtiqueta(
                                    icono: Icons.place_outlined,
                                    etiqueta: 'Lugar',
                                    onTap: _guardando ? null : () async {
                                      final r = await mostrarSelectorLugar(context, ref);
                                      if (r != null) setState(() => _lugar = r);
                                    },
                                  ),
                                  
                                // COMUNIDAD
                                if (_comunidad != null)
                                  _ChipContexto(
                                    icono: Icons.groups_outlined,
                                    etiqueta: _comunidad!.nombre,
                                    onQuitar: () => setState(() => _comunidad = null),
                                  )
                                else
                                  _BotonAccionEtiqueta(
                                    icono: Icons.groups_outlined,
                                    etiqueta: 'Comunidad',
                                    onTap: _guardando ? null : () async {
                                      final r = await mostrarSelectorComunidad(context, ref);
                                      if (r != null) setState(() => _comunidad = r);
                                    },
                                  ),
                                  
                                // SALIDA
                                if (_salida != null)
                                  _ChipContexto(
                                    icono: Icons.hiking,
                                    etiqueta: _salida!.etiquetaPrincipal,
                                    onQuitar: () => setState(() => _salida = null),
                                  )
                                else
                                  _BotonAccionEtiqueta(
                                    icono: Icons.hiking,
                                    etiqueta: 'Salida',
                                    onTap: _guardando ? null : () async {
                                      final r = await mostrarSelectorSalida(context, ref);
                                      if (r != null) setState(() => _salida = r);
                                    },
                                  ),
                                  
                                // RUTA
                                if (_ruta != null)
                                  _ChipContexto(
                                    icono: Icons.route_outlined,
                                    etiqueta: _ruta!.titulo,
                                    onQuitar: () => setState(() => _ruta = null),
                                  )
                                else
                                  _BotonAccionEtiqueta(
                                    icono: Icons.route_outlined,
                                    etiqueta: 'Ruta',
                                    onTap: _guardando ? null : () async {
                                      final r = await mostrarSelectorRuta(context, ref);
                                      if (r != null) setState(() => _ruta = r);
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // A.3: Preview foto (nueva o actual)
                      if ((_fotoBytes != null || (_fotoUrlActual != null && !_fotoEliminada)) && _video == null && (_videoUrlActual == null || _videoEliminada)) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              if (_fotoBytes != null)
                                Image.memory(
                                  _fotoBytes!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              else
                                CachedNetworkImage(
                                  imageUrl: _fotoUrlActual!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  onPressed: _guardando
                                      ? null
                                      : () => setState(() {
                                          _foto = null;
                                          _fotoBytes = null;
                                          _fotoEliminada = true;
                                        }),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                  ),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // A.3: Preview video (nuevo)
                      if (_video != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: PaletaRutas.carbon.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: PaletaRutas.oro.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.movie_outlined,
                                color: PaletaRutas.oro,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
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
                                        '${_mostrarTamano(_videoTamano!)} \u00b7 máximo 10 min',
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
                        if (_guardando && _progresoVideo != null) ...[
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: _progresoVideo,
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(8),
                            color: PaletaRutas.oro,
                            backgroundColor: PaletaRutas.carbon,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Subiendo video ${((_progresoVideo ?? 0) * 100).round()}%',
                            textAlign: TextAlign.center,
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: PaletaRutas.plomoClaro,
                            ),
                          ),
                        ],
                      ],

                      // A.3: Preview video (actual)
                      if (_videoUrlActual != null && !_videoEliminada && _video == null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CachedNetworkImage(
                                imageUrl: _videoMiniaturaActual ?? CatalogoImagenesHaku.respaldo,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                              // Capa oscura para que resalte el ícono de play
                              Container(
                                width: double.infinity,
                                height: 200,
                                color: Colors.black.withValues(alpha: 0.3),
                              ),
                              const Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: 56,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  onPressed: _guardando
                                      ? null
                                      : () => setState(() {
                                          _videoEliminada = true;
                                        }),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                  ),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ],
                    ),
                ),

                // ── BARRA INFERIOR PREMIUM ─────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: PaletaRutas.carbon.withValues(alpha: 0.85),
                    border: Border(
                      top: BorderSide(
                        color: PaletaRutas.oro.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Añadir multimedia',
                        style: TipografiaHaku.interfaz(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                      const Spacer(),
                      _BotonAdjuntoMini(
                        icono: Icons.image_outlined,
                        activo: (_foto != null || (_fotoUrlActual != null && !_fotoEliminada)) && _video == null && (_videoUrlActual == null || _videoEliminada),
                        onTap: _guardando ? null : _elegirFoto,
                      ),
                      const SizedBox(width: 16),
                      _BotonAdjuntoMini(
                        icono: Icons.video_library_outlined,
                        activo: _video != null || (_videoUrlActual != null && !_videoEliminada),
                        onTap: _guardando ? null : _elegirVideo,
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

/// Botón redondeado de acción para añadir etiquetas.
class _BotonAccionEtiqueta extends StatelessWidget {
  const _BotonAccionEtiqueta({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: PaletaRutas.ink.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PaletaRutas.plomo.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: PaletaRutas.plomoClaro),
            const SizedBox(width: 4),
            Icon(icono, size: 14, color: PaletaRutas.plomoClaro),
            const SizedBox(width: 6),
            Text(
              etiqueta,
              style: TipografiaHaku.interfaz(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: PaletaRutas.plomoClaro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón pequeño para adjuntar multimedia (barra inferior).
class _BotonAdjuntoMini extends StatelessWidget {
  const _BotonAdjuntoMini({
    required this.icono,
    required this.activo,
    required this.onTap,
  });

  final IconData icono;
  final bool activo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: activo
              ? PaletaRutas.oro.withValues(alpha: 0.15)
              : PaletaRutas.ink.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(
            color: activo
                ? PaletaRutas.oro.withValues(alpha: 0.5)
                : PaletaRutas.plomo.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          icono,
          size: 22,
          color: activo ? PaletaRutas.oro : PaletaRutas.plomoClaro,
        ),
      ),
    );
  }
}
