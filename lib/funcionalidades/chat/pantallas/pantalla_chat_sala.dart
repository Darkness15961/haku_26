import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../comunidad/dominio/modelo_comunidad.dart';
import '../../comunidad/proveedores/proveedor_comunidad.dart';
import '../../comunidad/proveedores/proveedor_salidas.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/chat_datasource_supabase.dart';
import '../dominio/contenido_chat_especial.dart';
import '../dominio/modelo_mensaje_chat.dart';
import '../proveedores/proveedor_chat.dart';
import '../widgets/burbuja_mensaje_chat.dart';
import '../widgets/sheet_crear_chat_grupal.dart';
import 'pantalla_gestion_participantes_chat.dart';
import 'pantalla_perfil_participante_chat.dart';

/// Chat genérico por `sala_id` (comunidad o salida).
class PantallaChatSala extends ConsumerStatefulWidget {
  const PantallaChatSala({
    super.key,
    required this.salaId,
    required this.titulo,
    this.comunidadId,
    this.salidaId,
  });

  final String salaId;
  final String titulo;
  final String? comunidadId;
  final String? salidaId;

  @override
  ConsumerState<PantallaChatSala> createState() => _EstadoPantallaChatSala();
}

class _EstadoPantallaChatSala extends ConsumerState<PantallaChatSala>
    with WidgetsBindingObserver {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();

  bool _enviando = false;
  bool _cargandoMas = false;
  bool _hayMas = true;
  List<ModeloMensajeChat> _extraAntiguos = const [];

  /// Mensajes enviados locales hasta que Realtime / seed los confirme.
  List<ModeloMensajeChat> _enviadosLocal = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.removeListener(_onScroll);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(chatDataSourceProvider).marcarLeido(widget.salaId);
      ref.invalidate(mensajesSalaProvider(widget.salaId));
      notificarChatCambio(ref);
    }
  }

  List<ModeloMensajeChat> _fusionar(List<ModeloMensajeChat> live) {
    final ids = <String>{};
    final out = <ModeloMensajeChat>[];
    for (final m in [..._extraAntiguos, ...live]) {
      if (m.id.isEmpty || !ids.add(m.id)) continue;
      out.add(m);
    }
    // Parches locales (envio/edit/delete): el cuerpo puede ir delante del stream.
    // Las reacciones siempre vienen del live (Realtime); el overlay no las pisa.
    for (final m in _enviadosLocal) {
      if (m.id.isEmpty) continue;
      final i = out.indexWhere((x) => x.id == m.id);
      if (i >= 0) {
        out[i] = m.copyWith(reacciones: out[i].reacciones);
      } else {
        out.add(m);
      }
    }
    out.sort((a, b) {
      final c = a.fechaEnvio.compareTo(b.fechaEnvio);
      if (c != 0) return c;
      final ai = int.tryParse(a.id);
      final bi = int.tryParse(b.id);
      if (ai != null && bi != null) return ai.compareTo(bi);
      return a.id.compareTo(b.id);
    });
    return out;
  }

  void _onScroll() {
    if (!_scroll.hasClients || _cargandoMas || !_hayMas) return;
    if (_scroll.position.pixels <= 80) {
      _cargarMas();
    }
  }

  Future<void> _cargarMas() async {
    if (_cargandoMas || !_hayMas) return;
    final live =
        ref.read(mensajesSalaProvider(widget.salaId)).valueOrNull ??
        const <ModeloMensajeChat>[];
    final todos = _fusionar(live);
    if (todos.isEmpty) return;

    final primero = todos.first;
    setState(() => _cargandoMas = true);
    if (!_scroll.hasClients) {
      setState(() => _cargandoMas = false);
      return;
    }
    final before = _scroll.position.pixels;
    final maxBefore = _scroll.position.maxScrollExtent;

    try {
      final page = await ref
          .read(chatDataSourceProvider)
          .listarMensajes(
            widget.salaId,
            limite: ChatDataSourceSupabase.pageSizeDefault,
            antesDe: CursorMensajeChat(
              fechaEnvio: primero.fechaEnvio,
              id: primero.id,
            ),
            comunidadId: widget.comunidadId,
            salidaId: widget.salidaId,
          );
      if (!mounted) return;
      if (page.isEmpty) {
        setState(() {
          _hayMas = false;
          _cargandoMas = false;
        });
        return;
      }
      final ids = {...todos.map((e) => e.id)};
      final nuevos = page.where((m) => ids.add(m.id)).toList();
      setState(() {
        _extraAntiguos = [...nuevos, ..._extraAntiguos];
        _cargandoMas = false;
        if (nuevos.length < ChatDataSourceSupabase.pageSizeDefault) {
          _hayMas = false;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        final maxAfter = _scroll.position.maxScrollExtent;
        _scroll.jumpTo(before + (maxAfter - maxBefore));
      });
    } catch (_) {
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  Future<void> _enviarTexto() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty || _enviando) return;
    if (texto.length > ChatDataSourceSupabase.maxLenMensaje) {
      mostrarSnackHaku(
        context,
        'Máximo ${ChatDataSourceSupabase.maxLenMensaje} caracteres',
      );
      return;
    }

    setState(() => _enviando = true);
    _ctrl.clear();
    try {
      final ok = await asegurarSesion(context, ref);
      if (!ok || !mounted) {
        _ctrl.text = texto;
        return;
      }
      final enviado = await ref
          .read(chatDataSourceProvider)
          .enviarTexto(
            salaId: widget.salaId,
            texto: texto,
            comunidadId: widget.comunidadId,
            salidaId: widget.salidaId,
          );
      if (!mounted) return;
      setState(() {
        if (_enviadosLocal.every((m) => m.id != enviado.id)) {
          _enviadosLocal = [..._enviadosLocal, enviado];
        }
      });
      notificarChatCambio(ref);
      _scrollAlFinal();
    } on AuthException catch (e) {
      if (mounted) {
        _ctrl.text = texto;
        mostrarSnackHaku(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        _ctrl.text = texto;
        mostrarSnackHaku(context, 'No se pudo enviar el mensaje');
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _enviarImagen(ImageSource source) async {
    if (_enviando) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;

    final file = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (file == null || !mounted) return;

    setState(() => _enviando = true);
    try {
      final bytes = await file.readAsBytes();
      final enviado = await ref
          .read(chatDataSourceProvider)
          .enviarImagen(
            salaId: widget.salaId,
            bytes: bytes,
            comunidadId: widget.comunidadId,
            salidaId: widget.salidaId,
          );
      if (!mounted) return;
      setState(() {
        if (_enviadosLocal.every((m) => m.id != enviado.id)) {
          _enviadosLocal = [..._enviadosLocal, enviado];
        }
      });
      notificarChatCambio(ref);
      _scrollAlFinal();
    } on AuthException catch (e) {
      if (mounted) mostrarSnackHaku(context, e.message);
    } catch (_) {
      if (mounted) {
        mostrarSnackHaku(context, 'No se pudo enviar la imagen');
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _enviarUbicacion() async {
    if (_enviando) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;

    setState(() => _enviando = true);
    try {
      final enviado = await ref
          .read(chatDataSourceProvider)
          .enviarUbicacionActual(
            salaId: widget.salaId,
            comunidadId: widget.comunidadId,
            salidaId: widget.salidaId,
          );
      if (!mounted) return;
      setState(() {
        if (_enviadosLocal.every((m) => m.id != enviado.id)) {
          _enviadosLocal = [..._enviadosLocal, enviado];
        }
      });
      notificarChatCambio(ref);
      _scrollAlFinal();
    } on AuthException catch (e) {
      if (mounted) mostrarSnackHaku(context, e.message);
    } catch (_) {
      if (mounted) {
        mostrarSnackHaku(context, 'No se pudo compartir la ubicación');
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _abrirStickers() async {
    if (_enviando) return;
    final id = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: PaletaRutas.carbon,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Elegí un sticker',
                  style: TipografiaHaku.interfaz(
                    fontWeight: FontWeight.w800,
                    color: PaletaRutas.piedra,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (final sid in PackStickersChat.ids)
                      InkWell(
                        onTap: () => Navigator.pop(ctx, sid),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: PaletaRutas.ink,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            PackStickersChat.glyph(sid) ?? '?',
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (id == null || !mounted) return;
    await _enviarSticker(id);
  }

  Future<void> _enviarSticker(String stickerId) async {
    if (_enviando) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;

    setState(() => _enviando = true);
    try {
      final enviado = await ref
          .read(chatDataSourceProvider)
          .enviarSticker(
            salaId: widget.salaId,
            stickerId: stickerId,
            comunidadId: widget.comunidadId,
            salidaId: widget.salidaId,
          );
      if (!mounted) return;
      setState(() {
        if (_enviadosLocal.every((m) => m.id != enviado.id)) {
          _enviadosLocal = [..._enviadosLocal, enviado];
        }
      });
      notificarChatCambio(ref);
      _scrollAlFinal();
    } on AuthException catch (e) {
      if (mounted) mostrarSnackHaku(context, e.message);
    } catch (_) {
      if (mounted) mostrarSnackHaku(context, 'No se pudo enviar el sticker');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _abrirAutor(ModeloMensajeChat mensaje) async {
    final uid = ref.read(sesionProvider).usuario?.id ?? '';
    if (mensaje.usuarioId.isEmpty || mensaje.usuarioId == uid) return;
    final contexto = (widget.comunidadId?.trim().isNotEmpty ?? false)
        ? 'esta comunidad'
        : 'esta salida';
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaPerfilParticipanteChat(
          usuarioId: mensaje.usuarioId,
          salaOrigenId: widget.salaId,
          contextoCompartido: contexto,
        ),
      ),
    );
  }

  Future<void> _abrirGestionParticipantes({required bool puedeEditar}) async {
    final cid = widget.comunidadId?.trim() ?? '';
    final sid = widget.salidaId?.trim() ?? '';
    if (cid.isEmpty && sid.isEmpty) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PantallaGestionParticipantesChat(
          salaId: widget.salaId,
          comunidadId: cid.isEmpty ? null : cid,
          salidaId: sid.isEmpty ? null : sid,
          titulo: puedeEditar ? 'Miembros del chat' : 'Quién está en el chat',
          puedeEditar: puedeEditar,
        ),
      ),
    );
  }

  void _aplicarLocal(ModeloMensajeChat m) {
    setState(() {
      final i = _enviadosLocal.indexWhere((x) => x.id == m.id);
      if (i >= 0) {
        _enviadosLocal = [..._enviadosLocal]..[i] = m;
      } else {
        _enviadosLocal = [..._enviadosLocal, m];
      }
      final j = _extraAntiguos.indexWhere((x) => x.id == m.id);
      if (j >= 0) {
        _extraAntiguos = [..._extraAntiguos]..[j] = m;
      }
    });
  }

  Future<void> _menuMensaje(ModeloMensajeChat m, bool mio) async {
    if (m.eliminado) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: PaletaRutas.carbon,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: PaletaRutas.plomoOscuro,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Reaccionar',
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final e in EmojisReaccionChat.pack)
                      InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _toggleReaccion(m, e);
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (mio) ...[
                  const SizedBox(height: 8),
                  Divider(
                    color: PaletaRutas.plomoOscuro.withValues(alpha: 0.5),
                  ),
                  if (m.esTextoEditable)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.edit_outlined,
                        color: PaletaRutas.oro,
                      ),
                      title: Text(
                        'Editar mensaje',
                        style: TipografiaHaku.interfaz(
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _editarMensaje(m);
                      },
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    title: Text(
                      'Eliminar para todos',
                      style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _eliminarMensaje(m);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _menuAdjuntar() async {
    if (_enviando) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: PaletaRutas.carbon,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        Widget tile({
          required IconData icon,
          required String title,
          required String subtitle,
          required VoidCallback onTap,
        }) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: PaletaRutas.ink,
              child: Icon(icon, color: PaletaRutas.oro, size: 22),
            ),
            title: Text(
              title,
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TipografiaHaku.interfaz(
                fontSize: 12,
                color: PaletaRutas.plomoClaro,
              ),
            ),
            onTap: () {
              Navigator.pop(ctx);
              onTap();
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: PaletaRutas.plomoOscuro,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                tile(
                  icon: Icons.photo_library_outlined,
                  title: 'Galería',
                  subtitle: 'Elegí una imagen de tu galería',
                  onTap: () => _enviarImagen(ImageSource.gallery),
                ),
                tile(
                  icon: Icons.photo_camera_outlined,
                  title: 'Cámara',
                  subtitle: 'Tomá una foto ahora',
                  onTap: () => _enviarImagen(ImageSource.camera),
                ),
                tile(
                  icon: Icons.location_on_outlined,
                  title: 'Ubicación',
                  subtitle: 'Compartir dónde estás',
                  onTap: _enviarUbicacion,
                ),
                tile(
                  icon: Icons.emoji_emotions_outlined,
                  title: 'Sticker',
                  subtitle: 'Pack de Haku',
                  onTap: _abrirStickers,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleReaccion(ModeloMensajeChat m, String emoji) async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    try {
      await ref
          .read(chatDataSourceProvider)
          .toggleReaccion(mensajeId: m.id, emoji: emoji);
      // Fuente de verdad = buffer del stream (Realtime + reload forzado).
      // No usar overlay de cuerpo: pisaría reacciones ajenas.
      forzarRecargaMensajeChat(ref, widget.salaId, m.id);
    } on AuthException catch (e) {
      if (mounted) mostrarSnackHaku(context, e.message);
    } catch (_) {
      if (mounted) mostrarSnackHaku(context, 'No se pudo reaccionar');
    }
  }

  Future<void> _editarMensaje(ModeloMensajeChat m) async {
    final ctrl = TextEditingController(text: m.contenido);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: PaletaRutas.carbon,
          title: Text(
            'Editar mensaje',
            style: TipografiaHaku.titulo(
              color: PaletaRutas.piedra,
              fontSize: 18,
            ),
          ),
          content: TextField(
            controller: ctrl,
            maxLength: ChatDataSourceSupabase.maxLenMensaje,
            maxLines: 4,
            autofocus: true,
            style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
            decoration: InputDecoration(
              filled: true,
              fillColor: PaletaRutas.ink,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(
                'Guardar',
                style: TipografiaHaku.interfaz(
                  color: PaletaRutas.oro,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    if (nuevo == null || !mounted) return;
    if (nuevo.isEmpty || nuevo == m.contenido) return;
    try {
      final editado = await ref
          .read(chatDataSourceProvider)
          .editarTexto(
            mensajeId: m.id,
            nuevoTexto: nuevo,
            comunidadId: widget.comunidadId,
            salidaId: widget.salidaId,
          );
      if (mounted) _aplicarLocal(editado);
      notificarChatCambio(ref);
    } on AuthException catch (e) {
      if (mounted) mostrarSnackHaku(context, e.message);
    } catch (_) {
      if (mounted) mostrarSnackHaku(context, 'No se pudo editar');
    }
  }

  Future<void> _eliminarMensaje(ModeloMensajeChat m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PaletaRutas.carbon,
        title: Text(
          'Eliminar mensaje',
          style: TipografiaHaku.titulo(color: PaletaRutas.piedra, fontSize: 18),
        ),
        content: Text(
          'Se ocultará para todos. No se borra de la base (soft delete).',
          style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Eliminar',
              style: TipografiaHaku.interfaz(
                color: Colors.redAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final borrado = await ref
          .read(chatDataSourceProvider)
          .softDeleteMensaje(
            mensajeId: m.id,
            comunidadId: widget.comunidadId,
            salidaId: widget.salidaId,
          );
      if (mounted) _aplicarLocal(borrado);
      notificarChatCambio(ref);
    } on AuthException catch (e) {
      if (mounted) mostrarSnackHaku(context, e.message);
    } catch (_) {
      if (mounted) mostrarSnackHaku(context, 'No se pudo eliminar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(sesionProvider.select((s) => s.usuario?.id ?? ''));
    final async = ref.watch(mensajesSalaProvider(widget.salaId));
    final cid = widget.comunidadId?.trim() ?? '';
    final sid = widget.salidaId?.trim() ?? '';
    final comunidadAsync = cid.isEmpty
        ? const AsyncValue<ComunidadHaku?>.data(null)
        : ref.watch(comunidadDetalleProvider(cid));
    final salidaAsync = sid.isEmpty
        ? null
        : ref.watch(salidaDetalleProvider(sid));

    final soyAdminComunidad = comunidadAsync.maybeWhen(
      data: (c) => c != null && uid.isNotEmpty && c.esAdminDe(uid),
      orElse: () => false,
    );
    final soyOrgSalida =
        salidaAsync?.maybeWhen(
          data: (s) => s != null && uid.isNotEmpty && s.organizadorId == uid,
          orElse: () => false,
        ) ??
        false;
    final puedeEditarRoster = soyAdminComunidad || soyOrgSalida;
    final mostrarMiembros = cid.isNotEmpty || sid.isNotEmpty;

    ref.listen(mensajesSalaProvider(widget.salaId), (prev, next) {
      final before = prev?.valueOrNull?.length ?? 0;
      final after = next.valueOrNull?.length ?? 0;
      if (after <= before) return;
      final cercaDelFinal =
          !_scroll.hasClients ||
          _scroll.position.maxScrollExtent - _scroll.position.pixels <= 160;
      if (cercaDelFinal) _scrollAlFinal();
    });

    final contexto = cid.isNotEmpty
        ? 'Comunidad'
        : (sid.isNotEmpty ? 'Salida' : 'Chat');

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 8, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TipografiaHaku.titulo(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                        Text(
                          contexto,
                          style: TipografiaHaku.interfaz(
                            fontSize: 11,
                            color: PaletaRutas.plomoClaro,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (mostrarMiembros)
                    IconButton(
                      tooltip: puedeEditarRoster
                          ? 'Gestionar miembros'
                          : 'Ver miembros',
                      onPressed: () => _abrirGestionParticipantes(
                        puedeEditar: puedeEditarRoster,
                      ),
                      icon: Icon(
                        puedeEditarRoster
                            ? Icons.group_add_outlined
                            : Icons.people_outline_rounded,
                        color: PaletaRutas.oro,
                      ),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LineaEncabezadoInca(altura: 2),
            ),
            if (async.hasError && async.hasValue)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                color: Colors.orange.withValues(alpha: 0.14),
                child: Text(
                  'Conexión inestable. Al volver a la app se reconectará.',
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(
                    fontSize: 11,
                    color: PaletaRutas.oro,
                  ),
                ),
              ),
            Expanded(child: _cuerpo(uid, async)),
            Container(
              padding: EdgeInsets.fromLTRB(
                8,
                8,
                8,
                8 + MediaQuery.paddingOf(context).bottom.clamp(0, 8),
              ),
              decoration: BoxDecoration(
                color: PaletaRutas.ink,
                border: Border(
                  top: BorderSide(
                    color: PaletaRutas.plomoOscuro.withValues(alpha: 0.45),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Adjuntar',
                    onPressed: _enviando ? null : _menuAdjuntar,
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: PaletaRutas.oro,
                      size: 28,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      enabled: !_enviando,
                      maxLength: ChatDataSourceSupabase.maxLenMensaje,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviarTexto(),
                      style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                      cursorColor: PaletaRutas.oro,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Escribí un mensaje…',
                        hintStyle: TipografiaHaku.interfaz(
                          color: PaletaRutas.plomo,
                        ),
                        filled: true,
                        fillColor: PaletaRutas.carbon,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: _enviando ? null : _enviarTexto,
                    style: IconButton.styleFrom(
                      backgroundColor: PaletaRutas.oro,
                      foregroundColor: PaletaRutas.ink,
                      disabledBackgroundColor: PaletaRutas.oro.withValues(
                        alpha: 0.35,
                      ),
                    ),
                    icon: _enviando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: PaletaRutas.ink,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cuerpo(String uid, AsyncValue<List<ModeloMensajeChat>> async) {
    if (async.isLoading && !async.hasValue) {
      return const Center(
        child: CircularProgressIndicator(color: PaletaRutas.oro),
      );
    }
    if (async.hasError && !async.hasValue) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No se pudieron cargar los mensajes.',
            textAlign: TextAlign.center,
            style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
          ),
        ),
      );
    }

    final live = async.valueOrNull ?? const <ModeloMensajeChat>[];
    // Solo limpia parches locales cuando el stream ya los cubre (no por id solo).
    if (_enviadosLocal.isNotEmpty) {
      final byId = {for (final m in live) m.id: m};
      final quedan = <ModeloMensajeChat>[];
      for (final local in _enviadosLocal) {
        final liveMsg = byId[local.id];
        if (liveMsg == null || !local.cubiertoPor(liveMsg)) {
          quedan.add(local);
        }
      }
      if (quedan.length != _enviadosLocal.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _enviadosLocal = quedan);
        });
      }
    }
    final mensajes = _fusionar(live);

    // Siempre ListView + controller (evita crash al pasar vacío ↔ lista).
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      itemCount: mensajes.isEmpty
          ? 1
          : mensajes.length + (_cargandoMas ? 1 : 0),
      itemBuilder: (context, i) {
        if (mensajes.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(32, 64, 32, 24),
            child: Column(
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 40,
                  color: PaletaRutas.plomo.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 12),
                Text(
                  'Todavía no hay mensajes',
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.piedra,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Escribí algo o adjuntá una imagen, ubicación o sticker.',
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(
                    fontSize: 13,
                    color: PaletaRutas.plomoClaro,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          );
        }
        if (_cargandoMas && i == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PaletaRutas.oro,
                ),
              ),
            ),
          );
        }
        final idx = _cargandoMas ? i - 1 : i;
        final m = mensajes[idx];
        final mio = uid.isNotEmpty && m.usuarioId == uid;
        return BurbujaMensajeChat(
          mensaje: m,
          mio: mio,
          onLongPress: m.eliminado ? null : () => _menuMensaje(m, mio),
          onToggleReaccion: (emoji) => _toggleReaccion(m, emoji),
          onTapAutor:
              !mio &&
                  !m.eliminado &&
                  (widget.comunidadId != null || widget.salidaId != null)
              ? () => _abrirAutor(m)
              : null,
        );
      },
    );
  }
}

/// Abre un DM ya establecido desde perfiles generales.
///
/// No crea relaciones arbitrarias: sin [salaOrigenId], el RPC solo devuelve
/// una conversación que ya existe. Los DMs nuevos nacen desde un chat grupal.
Future<void> abrirChatPrivadoExistente(
  BuildContext context,
  WidgetRef ref, {
  required String usuarioId,
  required String titulo,
}) async {
  final ok = await asegurarSesion(context, ref);
  if (!ok || !context.mounted) return;
  try {
    final salaId = await ref
        .read(chatDataSourceProvider)
        .asegurarSalaPrivada(otroUsuarioId: usuarioId);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaChatSala(
          salaId: salaId,
          titulo: titulo.trim().isEmpty ? 'Chat privado' : titulo.trim(),
        ),
      ),
    );
  } on AuthException catch (e) {
    if (!context.mounted) return;
    final sinRelacion = e.message.contains('Solo puedes iniciar');
    mostrarSnackHaku(
      context,
      sinRelacion
          ? 'Para iniciar este chat, primero coincidan en una comunidad o salida.'
          : e.message,
    );
  } catch (_) {
    if (context.mounted) {
      mostrarSnackHaku(context, 'No se pudo abrir el chat privado');
    }
  }
}

/// Abre chat de comunidad: si no existe, el admin elige crear (todos / elegir).
Future<void> abrirChatComunidad(
  BuildContext context,
  WidgetRef ref, {
  required String comunidadId,
  String? titulo,
}) async {
  final ok = await asegurarSesion(context, ref);
  if (!ok || !context.mounted) return;

  final uid = ref.read(sesionProvider).usuario?.id ?? '';
  final ds = ref.read(chatDataSourceProvider);
  final tituloChat = (titulo?.trim().isNotEmpty ?? false)
      ? titulo!.trim()
      : 'Chat';

  try {
    // DEFINER: distingue "no hay sala" vs "hay sala pero no estoy en roster".
    final existente = await ds.idSalaComunidadSiExiste(comunidadId);
    late final String salaId;

    if (existente != null && existente.isNotEmpty) {
      final enRoster = await ds.soyParticipanteSala(existente);
      if (!enRoster) {
        final comunidad = await ref.read(
          comunidadDetalleProvider(comunidadId).future,
        );
        final esAdmin =
            comunidad != null && uid.isNotEmpty && comunidad.esAdminDe(uid);
        if (!esAdmin) {
          if (context.mounted) {
            mostrarSnackHaku(
              context,
              'No estás en el chat grupal. Pedile al admin que te agregue.',
            );
          }
          return;
        }
      }
      // Admin fuera del roster: asegurar lo reincorpora. Miembro en roster: entra.
      salaId = await ds.asegurarSalaComunidad(comunidadId);
    } else {
      final comunidad = await ref.read(
        comunidadDetalleProvider(comunidadId).future,
      );
      final esAdmin =
          comunidad != null && uid.isNotEmpty && comunidad.esAdminDe(uid);
      if (!esAdmin) {
        if (context.mounted) {
          mostrarSnackHaku(
            context,
            'El admin todavía no habilitó el chat grupal.',
          );
        }
        return;
      }
      if (!context.mounted) return;
      final opcion = await mostrarSheetCrearChatGrupal(
        context,
        tituloContexto: 'esta comunidad',
      );
      if (opcion == null || !context.mounted) return;

      if (opcion == OpcionCrearChatGrupal.todos) {
        final okCrear = await confirmarCrearChatConTodos(
          context,
          tituloContexto: 'esta comunidad',
        );
        if (!okCrear || !context.mounted) return;
        salaId = await ds.asegurarSalaComunidad(
          comunidadId,
          seedAprobados: true,
        );
        notificarChatCambio(ref);
      } else {
        // Elegir: picker primero; crear solo al pulsar «Crear chat».
        final creada = await Navigator.of(context).push<String>(
          MaterialPageRoute<String>(
            builder: (_) => PantallaGestionParticipantesChat(
              comunidadId: comunidadId,
              titulo: 'Elegí quién entra al chat',
              puedeEditar: true,
              modoCreacion: true,
            ),
          ),
        );
        if (creada == null || creada.isEmpty || !context.mounted) return;
        salaId = creada;
      }
    }

    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaChatSala(
          salaId: salaId,
          titulo: tituloChat,
          comunidadId: comunidadId,
        ),
      ),
    );
  } on AuthException catch (e) {
    if (context.mounted) mostrarSnackHaku(context, e.message);
  } catch (_) {
    if (context.mounted) {
      mostrarSnackHaku(
        context,
        'No se pudo abrir el chat. Si sos miembro, pedile al admin que lo active.',
      );
    }
  }
}

/// Abre chat de salida: si no existe, el organizador elige crear.
Future<void> abrirChatSalida(
  BuildContext context,
  WidgetRef ref, {
  required String salidaId,
  String? titulo,
}) async {
  final ok = await asegurarSesion(context, ref);
  if (!ok || !context.mounted) return;

  final uid = ref.read(sesionProvider).usuario?.id ?? '';
  final ds = ref.read(chatDataSourceProvider);
  final tituloChat = (titulo?.trim().isNotEmpty ?? false)
      ? titulo!.trim()
      : 'Chat de la salida';

  try {
    final existente = await ds.idSalaSalidaSiExiste(salidaId);
    late final String salaId;

    if (existente != null && existente.isNotEmpty) {
      final enRoster = await ds.soyParticipanteSala(existente);
      if (!enRoster) {
        final salida = await ref.read(salidaDetalleProvider(salidaId).future);
        final esOrg =
            salida != null && uid.isNotEmpty && salida.organizadorId == uid;
        if (!esOrg) {
          if (context.mounted) {
            mostrarSnackHaku(
              context,
              'No estás en el chat de la salida. Pedile al organizador que te agregue.',
            );
          }
          return;
        }
      }
      salaId = await ds.asegurarSalaSalida(salidaId);
    } else {
      final salida = await ref.read(salidaDetalleProvider(salidaId).future);
      final esOrg =
          salida != null && uid.isNotEmpty && salida.organizadorId == uid;
      if (!esOrg) {
        if (context.mounted) {
          mostrarSnackHaku(
            context,
            'El organizador todavía no habilitó el chat de la salida.',
          );
        }
        return;
      }
      if (!context.mounted) return;
      final opcion = await mostrarSheetCrearChatGrupal(
        context,
        tituloContexto: 'esta salida',
      );
      if (opcion == null || !context.mounted) return;

      if (opcion == OpcionCrearChatGrupal.todos) {
        final okCrear = await confirmarCrearChatConTodos(
          context,
          tituloContexto: 'esta salida',
        );
        if (!okCrear || !context.mounted) return;
        salaId = await ds.asegurarSalaSalida(salidaId, seedConfirmados: true);
        notificarChatCambio(ref);
      } else {
        final creada = await Navigator.of(context).push<String>(
          MaterialPageRoute<String>(
            builder: (_) => PantallaGestionParticipantesChat(
              salidaId: salidaId,
              titulo: 'Elegí quién entra al chat',
              puedeEditar: true,
              modoCreacion: true,
            ),
          ),
        );
        if (creada == null || creada.isEmpty || !context.mounted) return;
        salaId = creada;
      }
    }

    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaChatSala(
          salaId: salaId,
          titulo: tituloChat,
          salidaId: salidaId,
        ),
      ),
    );
  } on AuthException catch (e) {
    if (context.mounted) mostrarSnackHaku(context, e.message);
  } catch (_) {
    if (context.mounted) {
      mostrarSnackHaku(
        context,
        'No se pudo abrir el chat de la salida. '
        'Si no sos el organizador, pedile que lo abra una vez.',
      );
    }
  }
}
