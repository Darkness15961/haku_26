import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/demo/senales_atencion.dart';
import '../../../nucleo/widgets/badge_contador.dart';
import '../../../nucleo/widgets/avatar_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../inicio/datos/feed_inicio_datasource_local.dart';
import '../../inicio/datos/mensajes_datasource_local.dart';
import '../../inicio/pantallas/pantalla_chat_directo.dart';
import '../../inicio/pantallas/pantalla_crear_grupo_comunidad.dart';
import '../../inicio/pantallas/pantalla_detalle_grupo.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../inicio/proveedores/proveedor_comunidad_ui.dart';
import '../../inicio/widgets/card_invitacion_grupo.dart';
import '../../inicio/widgets/publicacion_estilo_threads.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/salidas_datasource_local.dart';
import '../pantallas/pantalla_crear_salida.dart';
import '../pantallas/pantalla_detalle_comunidad.dart';
import '../widgets/chip_categoria_comunidad.dart';
import '../widgets/tarjeta_salida_comunidad.dart';

/// Comunidad unificada: Posts · Salidas · Comunidades · Mensajes.
class PantallaComunidad extends ConsumerStatefulWidget {
  const PantallaComunidad({super.key, this.mostrarAtras = false});

  final bool mostrarAtras;

  @override
  ConsumerState<PantallaComunidad> createState() => _EstadoPantallaComunidad();
}

class _EstadoPantallaComunidad extends ConsumerState<PantallaComunidad> {
  static const _tabs = ['Para ti', 'Salidas', 'Comunidades', 'Mensajes'];

  Future<void> _abrirCrearSalida() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PantallaCrearSalida(),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _abrirCrearComunidad() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => const PantallaCrearComunidad(),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _abrirCrearGrupo() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PantallaCrearGrupo()),
    );
    if (done == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(pestaniaComunidadProvider, (_, __) {
      if (mounted) setState(() {});
    });

    final pestania = ref.watch(pestaniaComunidadProvider);
    final bottom = MediaQuery.paddingOf(context).bottom +
        (widget.mostrarAtras ? 24 : 88);
    final store = ref.watch(almacenFeedProvider);
    final publicaciones = store.listo
        ? store.publicaciones
        : FeedInicioDataSourceLocal.publicaciones;
    final posts = publicaciones.where((p) => !p.esInvitacionSalida).toList();
    final invitacionesPorSalida = {
      for (final p in publicaciones.where((p) => p.esInvitacionSalida))
        if (p.salidaId != null && p.salidaId!.isNotEmpty) p.salidaId!: p,
    };
    final salidas = [
      ...SalidasDataSourceLocal.instancia.todas(),
    ]..sort((a, b) => a.fecha.compareTo(b.fecha));
    final comunidades = store.comunidades;
    final chats = [
      for (final c in MensajesDataSourceLocal.chats)
        _conUltimoChat(c, store),
    ];
    final gruposRuta = MensajeriaEstado.instancia.grupos;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    if (widget.mostrarAtras)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: PaletaRutas.piedra,
                        ),
                      )
                    else
                      const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Comunidad',
                        textAlign: TextAlign.center,
                        style: TipografiaHaku.titulo(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pestania == 1)
                          IconButton(
                            tooltip: 'Crear salida',
                            onPressed: _abrirCrearSalida,
                            icon: const Icon(
                              Icons.add_rounded,
                              color: PaletaRutas.oro,
                            ),
                          )
                        else if (pestania == 2)
                          IconButton(
                            tooltip: 'Crear comunidad',
                            onPressed: _abrirCrearComunidad,
                            icon: const Icon(
                              Icons.add_rounded,
                              color: PaletaRutas.oro,
                            ),
                          ),
                        IconButton(
                          tooltip: 'Notificaciones',
                          onPressed: () {
                            final ir = SenalesAtencion.mensajesSinLeer() > 0
                                ? 3
                                : SenalesAtencion.salidasAbiertas() > 0
                                    ? 1
                                    : 0;
                            ref
                                .read(pestaniaComunidadProvider.notifier)
                                .state = ir;
                          },
                          icon: BadgeContadorOverlay(
                            cantidad:
                                SenalesAtencion.totalPendientesComunidad(),
                            compacto: true,
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      _TabComunidad(
                        label: _tabs[i],
                        selected: pestania == i,
                        contador: switch (i) {
                          1 => SenalesAtencion.salidasAbiertas(),
                          3 => SenalesAtencion.mensajesSinLeer(),
                          _ => 0,
                        },
                        onTap: () => ref
                            .read(pestaniaComunidadProvider.notifier)
                            .state = i,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            if (pestania == 0) ..._sliverPosts(posts, bottom),
            if (pestania == 1)
              ..._sliverSalidas(salidas, invitacionesPorSalida, bottom),
            if (pestania == 2) ..._sliverGrupos(comunidades, store, bottom),
            if (pestania == 3)
              ..._sliverMensajes(chats, gruposRuta, bottom),
          ],
        ),
      ),
    );
  }

  List<Widget> _sliverPosts(List<PublicacionFeed> posts, double bottom) {
    if (posts.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 48, 24, bottom),
            child: Text(
              'Todavía no hay publicaciones',
              textAlign: TextAlign.center,
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            ),
          ),
        ),
      ];
    }
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final esUltima = i == posts.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: esUltima ? bottom : 18),
              child: PublicacionEstiloThreads(
                publicacion: posts[i],
                indice: i,
              ),
            );
          },
          childCount: posts.length,
        ),
      ),
    ];
  }

  List<Widget> _sliverSalidas(
    List<ModeloSalida> salidas,
    Map<String, PublicacionFeed> invitaciones,
    double bottom,
  ) {
    if (salidas.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 32, 24, bottom),
            child: Column(
              children: [
                Text(
                  'Aún no hay salidas',
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _abrirCrearSalida,
                  style: FilledButton.styleFrom(
                    backgroundColor: PaletaRutas.oro,
                    foregroundColor: PaletaRutas.ink,
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'Crear salida',
                    style: TipografiaHaku.interfaz(
                      fontWeight: FontWeight.w800,
                      color: PaletaRutas.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final s = salidas[i];
            final inv = invitaciones[s.id];
            final esUltima = i == salidas.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: esUltima ? bottom : 14),
              child: inv != null
                  ? CardInvitacionGrupo(publicacion: inv)
                  : TarjetaSalidaComunidad(salida: s, indice: i),
            );
          },
          childCount: salidas.length,
        ),
      ),
    ];
  }

  List<Widget> _sliverGrupos(
    List<ComunidadHaku> comunidades,
    EstadoAlmacenFeed store,
    double bottom,
  ) {
    if (comunidades.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 32, 24, bottom),
            child: Column(
              children: [
                Text(
                  'Únete o crea una comunidad temática',
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _abrirCrearComunidad,
                  style: FilledButton.styleFrom(
                    backgroundColor: PaletaRutas.oro,
                    foregroundColor: PaletaRutas.ink,
                  ),
                  icon: const Icon(Icons.diversity_3_outlined),
                  label: Text(
                    'Crear comunidad',
                    style: TipografiaHaku.interfaz(
                      fontWeight: FontWeight.w800,
                      color: PaletaRutas.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
        sliver: SliverList.separated(
          itemCount: comunidades.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final c = comunidades[i];
            final unida = store.comunidadIds.contains(c.id);
            return _TarjetaGrupoComunidad(
              comunidad: c,
              unida: unida,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PantallaDetalleComunidad(comunidadId: c.id),
                  ),
                );
              },
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _sliverMensajes(
    List<ChatConversacion> chats,
    List<GrupoRuta> gruposRuta,
    double bottom,
  ) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: OutlinedButton.icon(
            onPressed: _abrirCrearGrupo,
            style: OutlinedButton.styleFrom(
              foregroundColor: PaletaRutas.piedra,
              side: BorderSide(
                color: PaletaRutas.plomo.withValues(alpha: 0.65),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.group_add_outlined, size: 18),
            label: Text(
              'Nuevo equipo de ruta',
              style: TipografiaHaku.interfaz(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      if (chats.isEmpty && gruposRuta.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, bottom),
            child: Text(
              'Sin conversaciones aún',
              textAlign: TextAlign.center,
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            ),
          ),
        )
      else
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (gruposRuta.isNotEmpty) ...[
                Text(
                  'Equipos de ruta',
                  style: TipografiaHaku.titulo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < gruposRuta.length; i++) ...[
                  _TarjetaChatGrupoRuta(
                    grupo: gruposRuta[i],
                    onTap: () async {
                      await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) =>
                              PantallaDetalleGrupo(grupo: gruposRuta[i]),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                  if (i < gruposRuta.length - 1) const SizedBox(height: 10),
                ],
                const SizedBox(height: 18),
              ],
              Text(
                'Chats',
                style: TipografiaHaku.titulo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.plomoClaro,
                ),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < chats.length; i++) ...[
                _TarjetaChatDirecto(chat: chats[i]),
                if (i < chats.length - 1) const SizedBox(height: 10),
              ],
            ]),
          ),
        ),
    ];
  }

  ChatConversacion _conUltimoChat(
    ChatConversacion c,
    EstadoAlmacenFeed store,
  ) {
    final conv = store.mensajesDirectos
        .where((m) => m.conversacionId == c.id)
        .toList()
      ..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
    if (conv.isEmpty) return c;
    final last = conv.last;
    final mio = last.autorId == AlmacenFeedNotifier.idUsuarioLocal;
    return c.copyWith(
      ultimoMensaje: last.texto,
      hace: _hace(last.creadoEn),
      noLeidos: mio ? 0 : c.noLeidos,
    );
  }

  static String _hace(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _TabComunidad extends StatelessWidget {
  const _TabComunidad({
    required this.label,
    required this.selected,
    required this.onTap,
    this.contador = 0,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int contador;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? PaletaRutas.oro.withValues(alpha: 0.18) : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? PaletaRutas.oro
                : PaletaRutas.plomo.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TipografiaHaku.interfaz(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? PaletaRutas.oro : PaletaRutas.plomoClaro,
              ),
            ),
            if (contador > 0 && !selected) ...[
              const SizedBox(width: 6),
              BadgeContador(cantidad: contador, compacto: true),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaGrupoComunidad extends StatelessWidget {
  const _TarjetaGrupoComunidad({
    required this.comunidad,
    required this.unida,
    required this.onTap,
  });

  final ComunidadHaku comunidad;
  final bool unida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PaletaRutas.carbon,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: ImagenHaku(url: comunidad.imagenUrl, fit: BoxFit.cover),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            comunidad.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaHaku.titulo(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                        ),
                        if (unida)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: PaletaRutas.oro,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Unida',
                              style: TipografiaHaku.interfaz(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: PaletaRutas.ink,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${comunidad.miembros} miembros',
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: PaletaRutas.oro,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (comunidad.categorias.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ChipCategoriaComunidad(
                        categoria: comunidad.categorias.first,
                        sobreOscuro: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaChatDirecto extends StatelessWidget {
  const _TarjetaChatDirecto({required this.chat});

  final ChatConversacion chat;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PaletaRutas.carbon,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PantallaChatDirecto(
                persona: SugerenciaSeguimiento(
                  id: chat.id,
                  nombre: chat.nombre,
                  usuario: chat.usuario,
                  avatarUrl: chat.avatarUrl,
                  bioCorta: '',
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AvatarHaku(url: chat.avatarUrl, size: 48),
                  if (chat.noLeidos > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: BadgeContador(
                        cantidad: chat.noLeidos,
                        compacto: true,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.nombre,
                      style: TipografiaHaku.interfaz(
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    Text(
                      chat.ultimoMensaje,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: PaletaRutas.plomoClaro,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                chat.hace,
                style: TipografiaHaku.interfaz(
                  fontSize: 11,
                  color: PaletaRutas.plomo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaChatGrupoRuta extends StatelessWidget {
  const _TarjetaChatGrupoRuta({
    required this.grupo,
    required this.onTap,
  });

  final GrupoRuta grupo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PaletaRutas.carbon,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PaletaRutas.ink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hiking, color: PaletaRutas.oro),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grupo.nombre,
                      style: TipografiaHaku.interfaz(
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    Text(
                      grupo.rutaTitulo,
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: PaletaRutas.plomoClaro,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
