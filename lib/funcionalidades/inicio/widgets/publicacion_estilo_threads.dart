import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../perfil_usuario/navegacion_perfil_ajeno.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../pantallas/pantalla_comentarios_publicacion.dart';
import '../proveedores/proveedor_almacen_feed.dart';

/// Post dark: foto grande; nombre sobre la imagen (sin avatar).
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

  void _abrirPerfil() {
    final p = widget.publicacion;
    abrirPerfilAjeno(
      context,
      ref,
      id: p.autorId.isNotEmpty ? p.autorId : p.usuario,
      nombre: p.autor,
      usuario: p.usuario,
      avatarUrl: p.avatarUrl,
    );
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
    final verificado = post.esVerificado;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImagenHaku(
                    url: imagen,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000),
                          Color(0x99000000),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: GestureDetector(
                      onTap: _abrirPerfil,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.autor,
                            style: _ui.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: PaletaRutas.piedra,
                              shadows: const [
                                Shadow(
                                  color: Color(0xCC000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          if (verificado) ...[
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: PaletaRutas.oro,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: _toggleLike,
                  icon: Icon(
                    liked ? Icons.favorite_rounded : Icons.favorite_border,
                    color: liked ? PaletaRutas.oro : PaletaRutas.piedra,
                  ),
                ),
                IconButton(
                  onPressed: _comentar,
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: PaletaRutas.piedra,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _toggleGuardar,
                  icon: Icon(
                    guardado
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: PaletaRutas.piedra,
                  ),
                ),
              ],
            ),
          ),
          if (likes > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Text(
                '$likes',
                style: _ui.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: PaletaRutas.plomoClaro,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
            child: Text(
              post.texto,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _ui.copyWith(
                fontSize: 13,
                height: 1.3,
                color: PaletaRutas.piedra.withValues(alpha: 0.9),
              ),
            ),
          ),
          if (post.musica != null && post.musica!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.music_note_rounded,
                    size: 14,
                    color: PaletaRutas.oroSuave,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      post.musica!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ui.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PaletaRutas.oroSuave,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (post.menciones.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Text(
                post.menciones.join(' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _ui.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.oro,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
