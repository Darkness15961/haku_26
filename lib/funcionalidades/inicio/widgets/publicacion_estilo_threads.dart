import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final imagen = post.imagenUrl ??
        'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=900&q=80';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: p.avatarUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
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
              aspectRatio: 4 / 5,
              child: _ImagenPublicacion(url: imagen),
            ),
            if ((post.lugarNombre ?? '').isNotEmpty ||
                (post.categoria ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  [
                    if ((post.lugarNombre ?? '').isNotEmpty) post.lugarNombre,
                    if ((post.categoria ?? '').isNotEmpty)
                      _etiquetaCategoria(post.categoria!),
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
            if (p.comentarios > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: GestureDetector(
                  onTap: _comentar,
                  child: Text(
                    'Ver los ${p.comentarios} comentarios',
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
    final local = !url.startsWith('http');
    if (local) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: Color(0xFFD4C8B8),
          child: Icon(Icons.image_not_supported_outlined),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, __) => const ColoredBox(color: Color(0xFFE8E0D4)),
      errorWidget: (_, __, ___) => const ColoredBox(
        color: Color(0xFFD4C8B8),
        child: Icon(Icons.image_not_supported_outlined),
      ),
    );
  }
}
