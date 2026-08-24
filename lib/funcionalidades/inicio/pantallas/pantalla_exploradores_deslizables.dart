import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/widgets/avatar_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/widgets/boton_fondo_textil.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../proveedores/proveedor_almacen_feed.dart';
import 'pantalla_chat_directo.dart';
import 'pantalla_clips_perfil.dart';

/// Perfil estilo TikTok: stats, seguir, mensaje, grid con vistas y favoritos.
class PantallaExploradoresDeslizables extends ConsumerStatefulWidget {
  final List<SugerenciaSeguimiento> exploradores;
  final int indiceInicial;

  const PantallaExploradoresDeslizables({
    super.key,
    required this.exploradores,
    required this.indiceInicial,
  });

  @override
  ConsumerState<PantallaExploradoresDeslizables> createState() =>
      _EstadoPantallaExploradoresDeslizables();
}

class _EstadoPantallaExploradoresDeslizables
    extends ConsumerState<PantallaExploradoresDeslizables> {
  late final int _indice;

  @override
  void initState() {
    super.initState();
    _indice = widget.indiceInicial.clamp(0, widget.exploradores.length - 1);
  }

  SugerenciaSeguimiento get _base => widget.exploradores[_indice];

  Future<void> _toggleSeguir(String id) async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await ref.read(almacenFeedProvider.notifier).toggleSeguir(id);
  }

  Future<void> _escribir(SugerenciaSeguimiento s) async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaChatDirecto(persona: s),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(almacenFeedProvider);
    final persona = feed.perfilPorId(_base.id) ?? _base;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FondoSuaveSeccion(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 2, 8, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: PaletaRutas.marronOscuro,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            persona.usuario,
                            textAlign: TextAlign.center,
                            style: TipografiaHaku.titulo(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Compartir',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Perfil'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.ios_share_rounded,
                            color: PaletaRutas.marronOscuro,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: LineaEncabezadoInca(altura: 2),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _PerfilTikTok(
                  persona: persona,
                  siguiendo: feed.siguiendoIds.contains(persona.id),
                  onSeguir: () => _toggleSeguir(persona.id),
                  onMensaje: () => _escribir(persona),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerfilTikTok extends StatefulWidget {
  final SugerenciaSeguimiento persona;
  final bool siguiendo;
  final VoidCallback onSeguir;
  final VoidCallback onMensaje;

  const _PerfilTikTok({
    required this.persona,
    required this.siguiendo,
    required this.onSeguir,
    required this.onMensaje,
  });

  @override
  State<_PerfilTikTok> createState() => _EstadoPerfilTikTok();
}

class _EstadoPerfilTikTok extends State<_PerfilTikTok> {
  int _tab = 0;

  List<ClipPerfil> get _clips {
    final p = widget.persona;
    if (_tab == 1) return p.favoritos;
    if (_tab == 2) return p.publicaciones.take(4).toList();
    return p.publicaciones;
  }

  void _abrirClip(int i) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaClipsPerfil(
          persona: widget.persona,
          clips: _clips,
          indiceInicial: i,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.persona;
    final clips = _clips;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                AvatarHaku(url: p.avatarUrl, size: 92),
                const SizedBox(height: 10),
                Text(
                  p.nombre,
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.titulo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${p.usuario} · ${p.provincia}',
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(
                    fontSize: 13,
                    color: PaletaRutas.marronCuero,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Stat(
                      valor: formatearConteo(p.siguiendo),
                      etiqueta: 'Siguiendo',
                    ),
                    _divisor(),
                    _Stat(
                      valor: formatearConteo(p.seguidores),
                      etiqueta: 'Seguidores',
                    ),
                    _divisor(),
                    _Stat(
                      valor: formatearConteo(p.meGusta),
                      etiqueta: 'Me gusta',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: BotonFondoTextil(
                        texto: widget.siguiendo ? 'Siguiendo' : 'Seguir',
                        onPressed: widget.onSeguir,
                        altura: 44,
                        radius: 10,
                        indiceFondo: 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _BotonIcono(
                      icono: Icons.chat_bubble_outline_rounded,
                      tooltip: 'Mensaje',
                      onTap: widget.onMensaje,
                    ),
                    const SizedBox(width: 8),
                    _BotonIcono(
                      icono: Icons.bookmark_border_rounded,
                      tooltip: 'Favoritos',
                      onTap: () => setState(() => _tab = 1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  p.bio.isEmpty ? p.bioCorta : p.bio,
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(
                    fontSize: 13,
                    height: 1.4,
                    color: PaletaRutas.marronOscuro,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _TabIcono(
                      icono: Icons.grid_on_rounded,
                      activo: _tab == 0,
                      onTap: () => setState(() => _tab = 0),
                    ),
                    _TabIcono(
                      icono: Icons.bookmark_rounded,
                      activo: _tab == 1,
                      onTap: () => setState(() => _tab = 1),
                    ),
                    _TabIcono(
                      icono: Icons.favorite_rounded,
                      activo: _tab == 2,
                      onTap: () => setState(() => _tab = 2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (clips.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                _tab == 1
                    ? 'Sin favoritos'
                    : 'Sin publicaciones',
                style: TipografiaHaku.interfaz(color: PaletaRutas.marronCuero),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final c = clips[i];
                  return GestureDetector(
                    onTap: () => _abrirClip(i),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: c.imagenUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const ColoredBox(color: Color(0xFFD4C8B8)),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.center,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0x99000000)],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                formatearConteo(c.vistas),
                                style: TipografiaHaku.interfaz(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: clips.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _divisor() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      color: PaletaRutas.arena,
    );
  }
}

class _Stat extends StatelessWidget {
  final String valor;
  final String etiqueta;

  const _Stat({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          etiqueta,
          style: TipografiaHaku.interfaz(
            fontSize: 12,
            color: PaletaRutas.marronCuero,
          ),
        ),
      ],
    );
  }
}

class _BotonIcono extends StatelessWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;

  const _BotonIcono({
    required this.icono,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: PaletaRutas.marronOscuro,
          side: const BorderSide(color: PaletaRutas.arena),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Icon(icono, size: 20),
      ),
    );
  }
}

class _TabIcono extends StatelessWidget {
  final IconData icono;
  final bool activo;
  final VoidCallback onTap;

  const _TabIcono({
    required this.icono,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Icon(
                icono,
                color: activo
                    ? PaletaRutas.marronOscuro
                    : PaletaRutas.marronCuero.withValues(alpha: 0.45),
              ),
            ),
            Container(
              height: 2,
              color: activo ? PaletaRutas.marronOscuro : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
