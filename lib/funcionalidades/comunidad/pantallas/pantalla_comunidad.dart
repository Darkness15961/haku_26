import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/responsive/espacio_haku.dart';
import '../../../nucleo/responsive/rejilla_lego_haku.dart';
import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../../nucleo/widgets/badge_contador.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../inicio/proveedores/proveedor_comunidad_ui.dart';
import '../../publicaciones/pantallas/pantalla_publicaciones.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../dominio/modelo_comunidad.dart';
import '../dominio/modelo_publicacion.dart';
import '../dominio/modelo_salida.dart';
import '../pantallas/pantalla_crear_comunidad_remota.dart';
import '../pantallas/pantalla_crear_salida_remota.dart';
import '../pantallas/pantalla_detalle_comunidad.dart';
import '../proveedores/proveedor_comunidad.dart';
import '../proveedores/proveedor_publicaciones.dart';
import '../proveedores/proveedor_salidas.dart';
import '../widgets/chip_categoria_comunidad.dart';
import '../widgets/tarjeta_publicacion_remota.dart';
import '../widgets/tarjeta_salida_remota.dart';
import '../../chat/indice.dart';

/// Comunidad unificada: Posts · Salidas · Comunidades · Mensajes.
class PantallaComunidad extends ConsumerStatefulWidget {
  const PantallaComunidad({super.key, this.mostrarAtras = false});

  final bool mostrarAtras;

  @override
  ConsumerState<PantallaComunidad> createState() => _EstadoPantallaComunidad();
}

class _EstadoPantallaComunidad extends ConsumerState<PantallaComunidad> {
  static const _tabs = ['Para ti', 'Salidas', 'Comunidades', 'Mensajes'];

  /// Filtro bandeja: 0 todos · 1 comunidades · 2 salidas · 3 privados.
  int _filtroMensajes = 0;
  final _buscaMensajes = TextEditingController();
  String _queryMensajes = '';

  @override
  void dispose() {
    _buscaMensajes.dispose();
    super.dispose();
  }

  Future<void> _abrirCrearPublicacion() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const PantallaPublicaciones()),
    );
  }

  Future<void> _abrirCrearSalida() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const PantallaCrearSalidaRemota(),
      ),
    );
  }

  Future<void> _abrirCrearComunidad() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const PantallaCrearComunidadRemota(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pestania = ref.watch(pestaniaComunidadProvider);
    final mensajesNoLeidos = ref.watch(totalNoLeidosChatProvider);
    final bottom = widget.mostrarAtras
        ? MediaQuery.paddingOf(context).bottom + 24
        : EspacioHaku.bottomNavClearance(context);
    final postsAsync = pestania == 0
        ? ref.watch(publicacionesRemotasProvider)
        : const AsyncValue<List<ModeloPublicacionRemota>>.data([]);
    final salidasAsync = pestania == 1
        ? ref.watch(salidasRemotasProvider)
        : const AsyncValue<List<ModeloSalidaRemota>>.data([]);
    final comunidadesAsync = pestania == 2
        ? ref.watch(comunidadesRemotasProvider)
        : const AsyncValue<List<ComunidadHaku>>.data([]);
    // Mantener actualizado el badge aunque el usuario aún no abra Mensajes.
    ref.watch(chatBandejaRealtimeProvider);
    final chatsAsync = pestania == 3
        ? ref.watch(previewsChatBandejaProvider)
        : const AsyncValue<List<PreviewChatSala>>.data([]);
    final uidSesion = ref.watch(
      sesionProvider.select((s) => s.usuario?.id ?? ''),
    );

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
                          fontSize: EspacioHaku.sp(context, 18),
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pestania == 0)
                          IconButton(
                            tooltip: 'Crear publicación',
                            onPressed: _abrirCrearPublicacion,
                            icon: const Icon(
                              Icons.add_rounded,
                              color: PaletaRutas.oro,
                            ),
                          )
                        else if (pestania == 1)
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
                            final ir = mensajesNoLeidos > 0 ? 3 : 0;
                            ref.read(pestaniaComunidadProvider.notifier).state =
                                ir;
                          },
                          icon: BadgeContadorOverlay(
                            cantidad: mensajesNoLeidos,
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
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: LineaEncabezadoInca(altura: 3),
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
                          3 => mensajesNoLeidos,
                          _ => 0,
                        },
                        onTap: () =>
                            ref.read(pestaniaComunidadProvider.notifier).state =
                                i,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            if (pestania == 0) ..._sliverPostsRemotos(postsAsync, bottom),
            if (pestania == 1) ..._sliverSalidasRemotas(salidasAsync, bottom),
            if (pestania == 2)
              ..._sliverGruposRemotos(comunidadesAsync, uidSesion, bottom),
            if (pestania == 3) ...[
              SliverToBoxAdapter(child: _barraBandejaMensajes()),
              ..._sliverMensajesRemotos(chatsAsync, uidSesion, bottom),
            ],
          ],
        ),
      ),
    );
  }

  Widget _barraBandejaMensajes() {
    Widget chip(String label, int value) {
      final sel = _filtroMensajes == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: sel,
          onSelected: (_) => setState(() => _filtroMensajes = value),
          selectedColor: PaletaRutas.oro.withValues(alpha: 0.25),
          checkmarkColor: PaletaRutas.oro,
          labelStyle: TipografiaHaku.interfaz(
            fontSize: 12,
            fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
            color: sel ? PaletaRutas.oro : PaletaRutas.piedra,
          ),
          backgroundColor: PaletaRutas.carbon,
          side: BorderSide(
            color: sel
                ? PaletaRutas.oro
                : PaletaRutas.plomoOscuro.withValues(alpha: 0.5),
          ),
          showCheckmark: false,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _buscaMensajes,
            onChanged: (v) => setState(() => _queryMensajes = v.trim()),
            style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
            cursorColor: PaletaRutas.oro,
            decoration: InputDecoration(
              hintText: 'Buscar chat…',
              hintStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomo),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: PaletaRutas.plomoClaro,
              ),
              filled: true,
              fillColor: PaletaRutas.carbon,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip('Todos', 0),
                chip('Comunidades', 1),
                chip('Salidas', 2),
                chip('Privados', 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PreviewChatSala> _filtrarBandeja(List<PreviewChatSala> all) {
    Iterable<PreviewChatSala> list = all;
    switch (_filtroMensajes) {
      case 1:
        list = list.where((p) => p.esComunidad);
      case 2:
        list = list.where((p) => p.esSalida);
      case 3:
        list = list.where((p) => p.esPrivado);
      default:
        break;
    }
    final q = _queryMensajes.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) => p.titulo.toLowerCase().contains(q));
    }
    return list.toList();
  }

  List<Widget> _sliverPostsRemotos(
    AsyncValue<List<ModeloPublicacionRemota>> async,
    double bottom,
  ) {
    if (!supabaseListo) {
      return [
        _sliverMsgCentro(
          'Las publicaciones no están disponibles en este momento.',
          bottom,
        ),
      ];
    }
    if (async.isLoading && !async.hasValue) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(
              child: CircularProgressIndicator(color: PaletaRutas.oro),
            ),
          ),
        ),
      ];
    }
    if (async.hasError && !async.hasValue) {
      return [
        _sliverError(
          'No pudimos cargar las publicaciones.',
          bottom,
          () => ref.invalidate(publicacionesRemotasProvider),
        ),
      ];
    }
    final posts = async.valueOrNull ?? const <ModeloPublicacionRemota>[];
    if (posts.isEmpty) {
      return [
        _sliverMsgCentro(
          'Todavía no hay publicaciones públicas.\n'
          'Toca + para compartir la primera experiencia.',
          bottom,
        ),
      ];
    }

    final cols = EspacioHaku.columnasPublicaciones(context);
    if (cols <= 1) {
      return [
        SliverPadding(
          padding: EdgeInsets.only(bottom: bottom),
          sliver: SliverList.builder(
            itemCount: posts.length,
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(bottom: i == posts.length - 1 ? 0 : 18),
              child: TarjetaPublicacionRemota(publicacion: posts[i]),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          EspacioHaku.horizontal(context),
          0,
          EspacioHaku.horizontal(context),
          bottom,
        ),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 14,
            crossAxisSpacing: 12,
            childAspectRatio: EspacioHaku.esHorizontal(context) ? 0.78 : 0.72,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) =>
                TarjetaPublicacionRemota(publicacion: posts[i], compacta: true),
            childCount: posts.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _sliverSalidasRemotas(
    AsyncValue<List<ModeloSalidaRemota>> async,
    double bottom,
  ) {
    if (async.isLoading && !async.hasValue) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 48, 24, bottom),
            child: const Center(
              child: CircularProgressIndicator(color: PaletaRutas.oro),
            ),
          ),
        ),
      ];
    }
    if (async.hasError && !async.hasValue) {
      return [
        _sliverError(
          'No pudimos cargar las salidas.',
          bottom,
          () => ref.invalidate(salidasRemotasProvider),
        ),
      ];
    }

    final salidas = async.value ?? const <ModeloSalidaRemota>[];
    if (salidas.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 32, 24, bottom),
            child: Column(
              children: [
                Text(
                  !supabaseListo
                      ? 'Contenido temporalmente no disponible.'
                      : 'Aún no hay salidas.',
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
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
      ...RejillaLegoHaku.slivers(
        context: context,
        itemCount: salidas.length,
        bottom: bottom,
        // Landscape: más “tarjeta”; portrait usa lista fila (enRejilla false).
        childAspectRatio: 0.92,
        itemBuilder: (context, i) {
          return TarjetaSalidaRemota(
            salida: salidas[i],
            enRejilla: RejillaLegoHaku.columnas(context) > 1,
            omitirPadding: true,
          );
        },
      ),
    ];
  }

  List<Widget> _sliverGruposRemotos(
    AsyncValue<List<ComunidadHaku>> async,
    String uidSesion,
    double bottom,
  ) {
    if (async.isLoading && !async.hasValue) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 48, 24, bottom),
            child: const Center(
              child: CircularProgressIndicator(color: PaletaRutas.oro),
            ),
          ),
        ),
      ];
    }
    if (async.hasError && !async.hasValue) {
      return [
        _sliverError(
          'No pudimos cargar las comunidades.',
          bottom,
          () => ref.invalidate(comunidadesRemotasProvider),
        ),
      ];
    }

    final comunidades = async.value ?? const <ComunidadHaku>[];
    if (comunidades.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 32, 24, bottom),
            child: Column(
              children: [
                Text(
                  !supabaseListo
                      ? 'Contenido temporalmente no disponible.'
                      : 'Aún no hay comunidades visibles.',
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
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
    final enRejilla = RejillaLegoHaku.columnas(context) > 1;
    return [
      ...RejillaLegoHaku.slivers(
        context: context,
        itemCount: comunidades.length,
        bottom: bottom,
        childAspectRatio: enRejilla ? 0.92 : 2.8,
        itemBuilder: (context, i) {
          final c = comunidades[i];
          final unida =
              uidSesion.isNotEmpty &&
              (c.esMiembro(uidSesion) || c.creadorId == uidSesion);
          return _TarjetaGrupoComunidad(
            comunidad: c,
            unida: unida,
            enRejilla: enRejilla,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PantallaDetalleComunidad(comunidadId: c.id),
                ),
              );
            },
          );
        },
      ),
    ];
  }

  List<Widget> _sliverMensajesRemotos(
    AsyncValue<List<PreviewChatSala>> async,
    String uidSesion,
    double bottom,
  ) {
    if (!supabaseListo) {
      return [
        _sliverMsgCentro(
          'Los mensajes no están disponibles en este momento.',
          bottom,
        ),
      ];
    }
    if (uidSesion.isEmpty) {
      return [_sliverMsgCentro('Inicia sesión para ver tus mensajes.', bottom)];
    }
    if (async.isLoading && !async.hasValue) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(
              child: CircularProgressIndicator(color: PaletaRutas.oro),
            ),
          ),
        ),
      ];
    }
    if (async.hasError && !async.hasValue) {
      return [
        _sliverError(
          'No pudimos cargar los mensajes.',
          bottom,
          () => ref.invalidate(previewsChatBandejaProvider),
        ),
      ];
    }
    final previews = _filtrarBandeja(async.valueOrNull ?? const []);
    if (previews.isEmpty) {
      final vacio = _queryMensajes.isNotEmpty
          ? 'No hay chats con ese nombre.'
          : (_filtroMensajes == 3
                ? 'Todavía no tienes chats privados.\nToca el nombre de alguien dentro de un chat grupal.'
                : (_filtroMensajes == 2
                      ? 'Todavía no tienes chats de salidas.\nEntra a una salida y abre el chat.'
                      : (_filtroMensajes == 1
                            ? 'Todavía no tienes chats de comunidades.\nUn administrador debe abrir el chat por primera vez.'
                            : 'Aquí verás todos tus chats.')));
      return [_sliverMsgCentro(vacio, bottom)];
    }

    return [
      ...RejillaLegoHaku.slivers(
        context: context,
        itemCount: previews.length,
        bottom: bottom,
        childAspectRatio: 3.1,
        itemBuilder: (context, i) {
          final p = previews[i];
          return _TarjetaChatComunidadRemota(
            preview: p,
            onTap: () {
              if (!p.puedeAbrir) {
                mostrarSnackHaku(
                  context,
                  p.esSalida
                      ? 'Cuando el organizador abra el chat, aparece acá.'
                      : 'Cuando el admin active el chat, aparece acá.',
                );
                return;
              }
              if (p.esSalida) {
                final sid = p.salidaId;
                if (sid == null || sid.isEmpty) return;
                abrirChatSalida(context, ref, salidaId: sid, titulo: p.titulo);
                return;
              }
              if (p.esPrivado) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PantallaChatSala(salaId: p.salaId, titulo: p.titulo),
                  ),
                );
                return;
              }
              final cid = p.comunidadId;
              if (cid == null || cid.isEmpty) return;
              abrirChatComunidad(
                context,
                ref,
                comunidadId: cid,
                titulo: p.titulo,
              );
            },
          );
        },
      ),
    ];
  }

  SliverToBoxAdapter _sliverMsgCentro(String texto, double bottom) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 48, 24, bottom),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
        ),
      ),
    );
  }

  SliverToBoxAdapter _sliverError(
    String texto,
    double bottom,
    VoidCallback onReintentar,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 40, 24, bottom),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 36,
              color: PaletaRutas.plomo,
            ),
            const SizedBox(height: 10),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  static String _hace(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'ahora';
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
    this.enRejilla = false,
  });

  final ComunidadHaku comunidad;
  final bool unida;
  final VoidCallback onTap;
  final bool enRejilla;

  @override
  Widget build(BuildContext context) {
    final texto = Padding(
      padding: EdgeInsets.all(enRejilla ? 10 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comunidad.nombre,
                  maxLines: enRejilla ? 2 : 1,
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
            '${comunidad.miembros} miembros'
            '${comunidad.esPrivada ? ' · privada' : ''}',
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              color: PaletaRutas.oro,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!comunidad.remoto && comunidad.categorias.isNotEmpty) ...[
            const SizedBox(height: 6),
            ChipCategoriaComunidad(
              categoria: comunidad.categorias.first,
              sobreOscuro: true,
            ),
          ],
        ],
      ),
    );

    Widget portada() {
      if (comunidad.imagenUrl.trim().isEmpty) {
        return const _PortadaComunidadVacia();
      }
      return ImagenHaku(url: comunidad.imagenUrl, fit: BoxFit.cover);
    }

    return Material(
      color: PaletaRutas.carbon,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: enRejilla
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: portada()),
                  const LineaEncabezadoInca(altura: 2.5),
                  texto,
                ],
              )
            : SizedBox(
                height: 88,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _FranjaPolleraVertical(),
                    SizedBox(width: 88, child: portada()),
                    Expanded(child: texto),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Sin `foto_portada` en BD: placeholder neutro (no inventa foto de lugar).
class _PortadaComunidadVacia extends StatelessWidget {
  const _PortadaComunidadVacia();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PaletaRutas.carbon,
      child: Center(
        child: Icon(
          Icons.diversity_3_outlined,
          color: PaletaRutas.plomo.withValues(alpha: 0.85),
          size: 28,
        ),
      ),
    );
  }
}

/// Contraste tipo pollera al costado (vertical).
/// Gradient fijo: sin Column/Expanded/LayoutBuilder (evita layout roto en IntrinsicHeight).
class _FranjaPolleraVertical extends StatelessWidget {
  const _FranjaPolleraVertical();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PaletaRutas.oro,
              Color(0xFFD4C4A8), // piedra aprox
              PaletaRutas.oroOscuro,
              Color(0xFFB8B0A4), // plomoClaro aprox
              PaletaRutas.oro,
            ],
            stops: [0.0, 0.31, 0.50, 0.69, 1.0],
          ),
        ),
      ),
    );
  }
}

class _TarjetaChatComunidadRemota extends StatelessWidget {
  const _TarjetaChatComunidadRemota({
    required this.preview,
    required this.onTap,
  });

  final PreviewChatSala preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ultimo = preview.ultimo;
    final previewTxt = ultimo == null
        ? preview.previewVacioEtiqueta
        : ultimo.contenidoVisible;

    final hace = ultimo == null
        ? ''
        : _EstadoPantallaComunidad._hace(ultimo.fechaEnvio);
    final foto = preview.fotoPortada?.trim() ?? '';
    final badge = preview.noLeidos;

    return Material(
      color: PaletaRutas.carbon,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _FranjaPolleraVertical(),
              if (foto.isEmpty)
                Container(
                  width: 56,
                  color: PaletaRutas.ink,
                  alignment: Alignment.center,
                  child: Icon(
                    preview.esSalida ? Icons.hiking : Icons.forum_outlined,
                    color: PaletaRutas.oro,
                  ),
                )
              else
                SizedBox(
                  width: 56,
                  child: ImagenHaku(url: foto, fit: BoxFit.cover),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    preview.titulo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TipografiaHaku.interfaz(
                                      fontWeight: FontWeight.w700,
                                      color: PaletaRutas.piedra,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: PaletaRutas.ink,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    preview.etiquetaTipo,
                                    style: TipografiaHaku.interfaz(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: PaletaRutas.oro,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              previewTxt,
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
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (hace.isNotEmpty)
                            Text(
                              hace,
                              style: TipografiaHaku.interfaz(
                                fontSize: 11,
                                color: PaletaRutas.plomo,
                              ),
                            ),
                          if (badge > 0) ...[
                            const SizedBox(height: 4),
                            BadgeContador(cantidad: badge, compacto: true),
                          ],
                        ],
                      ),
                    ],
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
