import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/widgets/avatar_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/publicacion_datasource_supabase.dart';
import '../dominio/modelo_publicacion.dart';
import '../proveedores/proveedor_publicaciones.dart';

/// Hoja de comentarios remotos (un nivel) sobre una publicación.
class PantallaComentariosPublicacionRemota extends ConsumerStatefulWidget {
  const PantallaComentariosPublicacionRemota({
    super.key,
    required this.publicacion,
    this.onContadorCambiado,
  });

  final ModeloPublicacionRemota publicacion;
  final ValueChanged<int>? onContadorCambiado;

  @override
  ConsumerState<PantallaComentariosPublicacionRemota> createState() =>
      _EstadoComentariosPublicacionRemota();
}

class _EstadoComentariosPublicacionRemota
    extends ConsumerState<PantallaComentariosPublicacionRemota> {
  final _ctrl = TextEditingController();
  final _ds = PublicacionDataSourceSupabase();
  List<ModeloComentarioPublicacion> _comentarios = const [];
  bool _cargando = true;
  bool _enviando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _ds.listarComentarios(widget.publicacion.id);
      if (!mounted) return;
      setState(() {
        _comentarios = lista;
        _cargando = false;
      });
      widget.onContadorCambiado?.call(lista.length);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar los comentarios.';
      });
    }
  }

  Future<void> _enviar() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    final t = _ctrl.text.trim();
    if (t.isEmpty || _enviando) return;

    setState(() => _enviando = true);
    try {
      final creado = await _ds.crearComentario(
        publicacionId: widget.publicacion.id,
        texto: t,
      );
      if (!mounted) return;
      _ctrl.clear();
      setState(() {
        _comentarios = [creado, ..._comentarios];
        _enviando = false;
      });
      widget.onContadorCambiado?.call(_comentarios.length);
      notificarPublicacionesCambiaron(ref);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo publicar el comentario')),
      );
    }
  }

  Future<void> _borrar(ModeloComentarioPublicacion c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PaletaRutas.carbon,
        title: Text(
          'Borrar comentario',
          style: TipografiaHaku.titulo(
            fontSize: 18,
            color: PaletaRutas.piedra,
          ),
        ),
        content: Text(
          '¿Lo quitas de esta publicación?',
          style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomo),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Borrar',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: PaletaRutas.oro,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await _ds.eliminarComentario(c.id);
      if (!mounted) return;
      setState(() {
        _comentarios = _comentarios.where((x) => x.id != c.id).toList();
      });
      widget.onContadorCambiado?.call(_comentarios.length);
      notificarPublicacionesCambiaron(ref);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo borrar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(sesionProvider.select((s) => s.usuario?.id));
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scroll) {
          return Material(
            color: PaletaRutas.carbon,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PaletaRutas.plomoOscuro,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Comentarios',
                          style: TipografiaHaku.titulo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _cargando
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: PaletaRutas.oro,
                            strokeWidth: 2,
                          ),
                        )
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: TipografiaHaku.interfaz(
                                        color: PaletaRutas.plomoClaro,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: _cargar,
                                      child: Text(
                                        'Reintentar',
                                        style: TipografiaHaku.interfaz(
                                          fontWeight: FontWeight.w700,
                                          color: PaletaRutas.oro,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _comentarios.isEmpty
                              ? Center(
                                  child: Text(
                                    'Sé el primero en comentar.',
                                    style: TipografiaHaku.interfaz(
                                      color: PaletaRutas.plomoClaro,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  controller: scroll,
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 12),
                                  itemCount: _comentarios.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, i) {
                                    final c = _comentarios[i];
                                    final esMio = uid != null &&
                                        uid == c.usuarioId;
                                    final foto =
                                        c.autorFotoPerfil?.trim() ?? '';
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (foto.isEmpty)
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: PaletaRutas.ink,
                                            child: Text(
                                              c.etiquetaAutor.isNotEmpty
                                                  ? c.etiquetaAutor
                                                      .replaceAll('@', '')
                                                      .substring(0, 1)
                                                      .toUpperCase()
                                                  : '?',
                                              style: TipografiaHaku.interfaz(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: PaletaRutas.oro,
                                              ),
                                            ),
                                          )
                                        else
                                          AvatarHaku(url: foto, size: 32),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: c.etiquetaAutor,
                                                      style: TipografiaHaku
                                                          .interfaz(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            PaletaRutas.piedra,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: '  ${c.hace}',
                                                      style: TipografiaHaku
                                                          .interfaz(
                                                        fontSize: 11,
                                                        color:
                                                            PaletaRutas.plomo,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                c.texto,
                                                style: TipografiaHaku.interfaz(
                                                  height: 1.35,
                                                  color: PaletaRutas.piedra,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (esMio)
                                          IconButton(
                                            tooltip: 'Borrar',
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: () => _borrar(c),
                                            icon: Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: PaletaRutas.plomo
                                                  .withValues(alpha: 0.9),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _enviar(),
                            style: TipografiaHaku.interfaz(
                              color: PaletaRutas.piedra,
                            ),
                            cursorColor: PaletaRutas.oro,
                            decoration: InputDecoration(
                              hintText: 'Escribe un comentario…',
                              hintStyle: TipografiaHaku.interfaz(
                                color: PaletaRutas.plomo,
                              ),
                              filled: true,
                              fillColor: PaletaRutas.ink,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Enviar',
                          onPressed: _enviando ? null : _enviar,
                          style: IconButton.styleFrom(
                            backgroundColor: PaletaRutas.oro,
                            foregroundColor: PaletaRutas.ink,
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<void> abrirComentariosPublicacionRemota(
  BuildContext context, {
  required ModeloPublicacionRemota publicacion,
  ValueChanged<int>? onContadorCambiado,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PantallaComentariosPublicacionRemota(
      publicacion: publicacion,
      onContadorCambiado: onContadorCambiado,
    ),
  );
}
