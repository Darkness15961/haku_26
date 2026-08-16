import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../perfil_usuario/navegacion_perfil_ajeno.dart';
import '../datos/feed_inicio_datasource_local.dart';

/// Publicación vertical al estilo Threads (avatar + texto + acciones).
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
  late bool _liked;
  late int _likes;
  bool _guardado = false;

  @override
  void initState() {
    super.initState();
    _liked = false;
    _likes = widget.publicacion.likes;
  }

  Future<void> _toggleLike() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  Future<void> _toggleGuardar() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    setState(() => _guardado = !_guardado);
  }

  Future<void> _comentar() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Comentarios próximamente'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withValues(alpha: 0.9),
      ),
    );
  }

  Color get _textoPrincipal {
    switch (widget.publicacion.estiloFondo) {
      case EstiloFondoPublicacion.veloNegro:
      case EstiloFondoPublicacion.veloNegroSuave:
        return Colors.white;
      case EstiloFondoPublicacion.veloBlanco:
      case EstiloFondoPublicacion.sinVelo:
        return PaletaRutas.marronOscuro;
    }
  }

  Color get _textoSecundario => _textoPrincipal.withValues(alpha: 0.62);

  @override
  Widget build(BuildContext context) {
    final p = widget.publicacion;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        image: DecorationImage(
          image: AssetImage(FondosDetalleHaku.porIndice(widget.indice)),
          fit: BoxFit.cover,
          opacity: p.estiloFondo == EstiloFondoPublicacion.sinVelo ? 0.28 : 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(child: _velo(p.estiloFondo)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => abrirPerfilAjeno(
                      context,
                      id: p.usuario,
                      nombre: p.autor,
                      usuario: p.usuario,
                      avatarUrl: p.avatarUrl,
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: p.avatarUrl,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const ColoredBox(
                          color: Color(0xFFCCCCCC),
                          child: SizedBox(width: 42, height: 42),
                        ),
                        errorWidget: (_, __, ___) => const ColoredBox(
                          color: Color(0xFFBBBBBB),
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: Icon(
                              Icons.person,
                              size: 22,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => abrirPerfilAjeno(
                            context,
                            id: p.usuario,
                            nombre: p.autor,
                            usuario: p.usuario,
                            avatarUrl: p.avatarUrl,
                          ),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.autor,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _textoPrincipal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                p.usuario,
                                style: TipografiaHaku.interfaz(
                                  fontSize: 12,
                                  color: _textoSecundario,
                                ),
                              ),
                              Text(
                                ' · ${p.hace}',
                                style: TipografiaHaku.interfaz(
                                  fontSize: 12,
                                  color: _textoSecundario,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.texto,
                          style: TipografiaHaku.interfaz(
                            fontSize: 14,
                            height: 1.4,
                            color: _textoPrincipal,
                          ),
                        ),
                        if (p.imagenUrl != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AspectRatio(
                              aspectRatio: 16 / 10,
                              child: CachedNetworkImage(
                                imageUrl: p.imagenUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => ColoredBox(
                                  color: Colors.black.withValues(alpha: 0.08),
                                ),
                                errorWidget: (_, __, ___) => ColoredBox(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: _textoSecundario,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _Accion(
                              icono: _liked
                                  ? Icons.explore_rounded
                                  : Icons.explore_outlined,
                              etiqueta: '$_likes',
                              color: _liked
                                  ? PaletaRutas.verdeOliva
                                  : _textoSecundario,
                              onTap: _toggleLike,
                            ),
                            const SizedBox(width: 18),
                            _Accion(
                              icono: Icons.chat_bubble_outline_rounded,
                              etiqueta: '${p.comentarios}',
                              color: _textoSecundario,
                              onTap: _comentar,
                            ),
                            const SizedBox(width: 18),
                            _Accion(
                              icono: _guardado
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              etiqueta: '',
                              color: _guardado
                                  ? PaletaRutas.verdeOliva
                                  : _textoSecundario,
                              onTap: _toggleGuardar,
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {},
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              icon: Icon(
                                Icons.ios_share_rounded,
                                size: 18,
                                color: _textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _velo(EstiloFondoPublicacion estilo) {
    switch (estilo) {
      case EstiloFondoPublicacion.veloNegro:
        return ColoredBox(color: Colors.black.withValues(alpha: 0.72));
      case EstiloFondoPublicacion.veloNegroSuave:
        return ColoredBox(color: Colors.black.withValues(alpha: 0.52));
      case EstiloFondoPublicacion.veloBlanco:
        return ColoredBox(color: Colors.white.withValues(alpha: 0.78));
      case EstiloFondoPublicacion.sinVelo:
        return ColoredBox(color: Colors.white.withValues(alpha: 0.35));
    }
  }
}

class _Accion extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final Color color;
  final VoidCallback onTap;

  const _Accion({
    required this.icono,
    required this.etiqueta,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 20, color: color),
            if (etiqueta.isNotEmpty) ...[
              const SizedBox(width: 5),
              Text(
                etiqueta,
                style: TipografiaHaku.interfaz(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
