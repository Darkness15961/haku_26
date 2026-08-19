import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/widgets/avatar_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../proveedores/proveedor_almacen_feed.dart';
import 'pantalla_chat_directo.dart';

/// Visor vertical de clips de un perfil (estilo TikTok).
class PantallaClipsPerfil extends ConsumerStatefulWidget {
  final SugerenciaSeguimiento persona;
  final List<ClipPerfil> clips;
  final int indiceInicial;

  const PantallaClipsPerfil({
    super.key,
    required this.persona,
    required this.clips,
    required this.indiceInicial,
  });

  @override
  ConsumerState<PantallaClipsPerfil> createState() => _EstadoPantallaClipsPerfil();
}

class _EstadoPantallaClipsPerfil extends ConsumerState<PantallaClipsPerfil> {
  late final PageController _page;
  late int _indice;

  @override
  void initState() {
    super.initState();
    _indice = widget.indiceInicial.clamp(0, widget.clips.length - 1);
    _page = PageController(initialPage: _indice);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.clips.isEmpty) return;
      ref
          .read(almacenFeedProvider.notifier)
          .registrarVistaClip(widget.clips[_indice].id);
    });
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _like(ClipPerfil c) async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await ref.read(almacenFeedProvider.notifier).toggleLikeClip(c.id);
  }

  Future<void> _mensaje() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaChatDirecto(persona: widget.persona),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _page,
            scrollDirection: Axis.vertical,
            itemCount: widget.clips.length,
            onPageChanged: (i) {
              setState(() => _indice = i);
              ref
                  .read(almacenFeedProvider.notifier)
                  .registrarVistaClip(widget.clips[i].id);
            },
            itemBuilder: (context, i) {
              final feed = ref.watch(almacenFeedProvider);
              final base = widget.clips[i];
              ClipPerfil c = base;
              for (final p in feed.perfiles) {
                for (final clip in p.publicaciones) {
                  if (clip.id == base.id) c = clip;
                }
              }
              final liked = feed.likesClipIds.contains(c.id);
              return Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: c.imagenUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const ColoredBox(color: Colors.black),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x66000000),
                          Color(0x00000000),
                          Color(0xCC000000),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 88,
                    child: Column(
                      children: [
                        AvatarHaku(url: widget.persona.avatarUrl, size: 48),
                        const SizedBox(height: 18),
                        _AccionClip(
                          icono: liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          etiqueta: formatearConteo(
                            c.likes + (liked ? 1 : 0),
                          ),
                          color: liked ? PaletaRutas.terracota : Colors.white,
                          onTap: () => _like(c),
                        ),
                        const SizedBox(height: 16),
                        _AccionClip(
                          icono: Icons.chat_bubble_outline_rounded,
                          etiqueta: formatearConteo(c.comentarios),
                          onTap: _mensaje,
                        ),
                        const SizedBox(height: 16),
                        _AccionClip(
                          icono: Icons.visibility_outlined,
                          etiqueta: formatearConteo(c.vistas),
                          onTap: () {},
                        ),
                        const SizedBox(height: 16),
                        _AccionClip(
                          icono: Icons.share_rounded,
                          etiqueta: 'Enviar',
                          onTap: _mensaje,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 88,
                    bottom: 36,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.persona.usuario,
                          style: TipografiaHaku.titulo(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.texto,
                          style: TipografiaHaku.interfaz(
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 4,
            left: 4,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccionClip extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
  final Color color;

  const _AccionClip({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icono, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            etiqueta,
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
