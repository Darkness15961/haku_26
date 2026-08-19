import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../proveedores/proveedor_almacen_feed.dart';

/// Hoja de comentarios persistidos en la BD local.
class PantallaComentariosPublicacion extends ConsumerStatefulWidget {
  final PublicacionFeed publicacion;

  const PantallaComentariosPublicacion({
    super.key,
    required this.publicacion,
  });

  @override
  ConsumerState<PantallaComentariosPublicacion> createState() =>
      _EstadoPantallaComentariosPublicacion();
}

class _EstadoPantallaComentariosPublicacion
    extends ConsumerState<PantallaComentariosPublicacion> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    _ctrl.clear();
    await ref.read(almacenFeedProvider.notifier).agregarComentario(
          publicacionId: widget.publicacion.id,
          texto: t,
        );
  }

  String _nombreDe(String autorId, EstadoAlmacenFeed feed) {
    if (autorId == AlmacenFeedNotifier.idUsuarioLocal) {
      final yo = feed.perfilPorId(autorId);
      return yo?.nombre ?? 'Yo';
    }
    return feed.perfilPorId(autorId)?.nombre ?? autorId;
  }

  String _hace(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(almacenFeedProvider);
    final comentarios = feed.comentarios
        .where((c) => c.publicacionId == widget.publicacion.id)
        .toList()
      ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
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
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
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
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    itemCount: comentarios.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final c = comentarios[i];
                      final autor = _nombreDe(c.autorId, feed);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: PaletaRutas.crema,
                            child: Text(
                              autor.isNotEmpty ? autor[0] : '?',
                              style: TipografiaHaku.interfaz(
                                fontWeight: FontWeight.w700,
                                color: PaletaRutas.marronOscuro,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '$autor  ',
                                        style: TipografiaHaku.interfaz(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      TextSpan(
                                        text: c.texto,
                                        style: TipografiaHaku.interfaz(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _hace(c.creadoEn),
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 11,
                                    color: PaletaRutas.marronCuero,
                                  ),
                                ),
                              ],
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _enviar(),
                            decoration: InputDecoration(
                              hintText: 'Comentario',
                              hintStyle: TipografiaHaku.interfaz(
                                color: PaletaRutas.marronCuero,
                              ),
                              filled: true,
                              fillColor: PaletaRutas.crema,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _enviar,
                          style: IconButton.styleFrom(
                            backgroundColor: PaletaRutas.marronOscuro,
                          ),
                          icon: const Icon(Icons.send_rounded, size: 20),
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

Future<void> abrirComentariosPublicacion(
  BuildContext context,
  PublicacionFeed publicacion,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PantallaComentariosPublicacion(publicacion: publicacion),
  );
}
