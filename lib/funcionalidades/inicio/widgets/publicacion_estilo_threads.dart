import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../nucleo/widgets/avatar_haku.dart';
import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../perfil_usuario/navegacion_perfil_ajeno.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../pantallas/pantalla_comentarios_publicacion.dart';
import '../proveedores/proveedor_almacen_feed.dart';

/// Post estilo Instagram: foto grande, poco texto, acciones claras.
class PublicacionEstiloThreads extends ConsumerStatefulWidget {
  final PublicacionFeed publicacion;
  final int indice;

  const PublicacionEstiloThreads({
    super.key,
    required this.publicacion,
    required this.indice,
  });

  @override
  ConsumerState<PublicacionEstiloThreads> createState() =>
      _EstadoPublicacionEstiloThreads();
}

class _EstadoPublicacionEstiloThreads
    extends ConsumerState<PublicacionEstiloThreads> {
  static TextStyle get _ui => TipografiaHaku.interfaz();

  Future<void> _toggleLike() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await ref
        .read(almacenFeedProvider.notifier)
        .toggleLikePublicacion(widget.publicacion.id);
  }

  Future<void> _toggleGuardar() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await ref
        .read(almacenFeedProvider.notifier)
        .toggleGuardarPublicacion(widget.publicacion.id);
  }

  Future<void> _comentar() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await abrirComentariosPublicacion(context, widget.publicacion);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.publicacion;
    final feed = ref.watch(almacenFeedProvider);
    final live = feed.publicaciones.where((x) => x.id == p.id);
    final post = live.isNotEmpty ? live.first : p;
    final liked = feed.likesPublicacionIds.contains(p.id);
    final likes = post.likes;
    final guardado = feed.guardadosIds.contains(p.id);
    final imagen = post.imagenUrl ?? CatalogoImagenesHaku.respaldo;
    final esCultural = (post.categoria ?? '').isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: PaletaRutas.marronOscuro.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (esCultural)
                Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        PaletaRutas.terracota,
                        PaletaRutas.marronCuero,
                        PaletaRutas.terracota,
                      ],
                    ),
                  ),
                ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => abrirPerfilAjeno(
                      context,
                      ref,
                      id: p.autorId.isNotEmpty ? p.autorId : p.usuario,
                      nombre: p.autor,
                      usuario: p.usuario,
                      avatarUrl: p.avatarUrl,
                    ),
                    child: AvatarHaku(url: p.avatarUrl, size: 36),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => abrirPerfilAjeno(
                        context,
                        ref,
                        id: p.autorId.isNotEmpty ? p.autorId : p.usuario,
                        nombre: p.autor,
                        usuario: p.usuario,
                        avatarUrl: p.avatarUrl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.autor,
                            style: _ui.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${p.usuario} · ${p.hace}',
                            style: _ui.copyWith(
                              fontSize: 12,
                              color: PaletaRutas.marronCuero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.more_horiz,
                      color: PaletaRutas.marronOscuro,
                    ),
                  ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: widget.indice.isEven ? 4 / 5 : 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ImagenPublicacion(url: imagen),
                  if ((post.categoria ?? '').isNotEmpty)
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: PaletaRutas.terracota.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _etiquetaCategoria(post.categoria!),
                          style: _ui.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if ((post.lugarNombre ?? '').isNotEmpty ||
                (post.categoria ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  [
                    if ((post.categoria ?? '').isNotEmpty)
                      _etiquetaCategoria(post.categoria!),
                    if ((post.lugarNombre ?? '').isNotEmpty) post.lugarNombre,
                  ].join(' · '),
                  style: _ui.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.marronCuero,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _toggleLike,
                    icon: Icon(
                      liked ? Icons.favorite_rounded : Icons.favorite_border,
                      color: liked
                          ? PaletaRutas.terracota
                          : PaletaRutas.marronOscuro,
                    ),
                  ),
                  IconButton(
                    onPressed: _comentar,
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: PaletaRutas.marronOscuro,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.send_outlined,
                      color: PaletaRutas.marronOscuro,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _toggleGuardar,
                    icon: Icon(
                      guardado
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: PaletaRutas.marronOscuro,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                '$likes me gusta',
                style: _ui.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            if ((post.lugarNombre ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text(
                  post.lugarNombre!,
                  style: _ui.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.terracota,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: RichText(
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: _ui.copyWith(fontSize: 13, height: 1.35),
                  children: [
                    TextSpan(
                      text: '${p.autor} ',
                      style: _ui.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(text: p.texto),
                  ],
                ),
              ),
            ),
            if (post.comentarios > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: GestureDetector(
                  onTap: _comentar,
                  child: Text(
                    '${post.comentarios} comentarios',
                    style: _ui.copyWith(
                      fontSize: 13,
                      color: PaletaRutas.marronCuero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _etiquetaCategoria(String id) {
  for (final c in CategoriaLugar.values) {
    if (c.name == id) return c.etiqueta;
  }
  return id;
}

class _ImagenPublicacion extends StatelessWidget {
  final String url;

  const _ImagenPublicacion({required this.url});

  @override
  Widget build(BuildContext context) {
    return ImagenHaku(
      url: url,
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }
}
