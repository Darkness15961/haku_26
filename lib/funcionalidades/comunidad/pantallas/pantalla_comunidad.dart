import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inicio/datos/feed_inicio_datasource_local.dart';
import '../../inicio/pantallas/pantalla_busqueda_inicio.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../inicio/widgets/card_invitacion_grupo.dart';
import '../../inicio/widgets/publicacion_estilo_threads.dart';
import '../../rutas/widgets/estilos_rutas.dart';

/// Comunidad: estilo TikTok — Para ti | Salidas.
class PantallaComunidad extends ConsumerStatefulWidget {
  final bool mostrarAtras;

  const PantallaComunidad({super.key, this.mostrarAtras = false});

  @override
  ConsumerState<PantallaComunidad> createState() => _EstadoPantallaComunidad();
}

class _EstadoPantallaComunidad extends ConsumerState<PantallaComunidad> {
  /// 0 = Para ti (posts) · 1 = Salidas
  int _pestania = 0;

  Future<void> _abrirBusqueda() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PantallaBusquedaInicio(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom +
        (widget.mostrarAtras ? 24 : 88);
    final store = ref.watch(almacenFeedProvider);
    final publicaciones = store.listo
        ? store.publicaciones
        : FeedInicioDataSourceLocal.publicaciones;
    final invitaciones =
        publicaciones.where((p) => p.esInvitacionSalida).toList();
    final posts = publicaciones.where((p) => !p.esInvitacionSalida).toList();
    final enParaTi = _pestania == 0;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _TabTikTok(
                            label: 'Para ti',
                            selected: enParaTi,
                            onTap: () => setState(() => _pestania = 0),
                          ),
                          const SizedBox(width: 22),
                          _TabTikTok(
                            label: 'Salidas',
                            selected: !enParaTi,
                            onTap: () => setState(() => _pestania = 1),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Buscar',
                      onPressed: _abrirBusqueda,
                      icon: const Icon(
                        Icons.search_rounded,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            if (enParaTi) ...[
              if (posts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 48, 24, bottom),
                    child: Text(
                      'Todavía no hay publicaciones',
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.interfaz(
                        color: PaletaRutas.plomoClaro,
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final esUltima = i == posts.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: esUltima ? bottom : 18,
                        ),
                        child: PublicacionEstiloThreads(
                          publicacion: posts[i],
                          indice: i,
                        ),
                      );
                    },
                    childCount: posts.length,
                  ),
                ),
            ] else ...[
              if (invitaciones.isEmpty)
                ContenedorSliverVacio(
                  bottom: bottom,
                  texto: 'Aún no hay salidas grupales',
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final esUltima = i == invitaciones.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: esUltima ? bottom : 18,
                        ),
                        child: CardInvitacionGrupo(
                          publicacion: invitaciones[i],
                        ),
                      );
                    },
                    childCount: invitaciones.length,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class ContenedorSliverVacio extends StatelessWidget {
  const ContenedorSliverVacio({
    super.key,
    required this.bottom,
    required this.texto,
  });

  final double bottom;
  final String texto;

  @override
  Widget build(BuildContext context) {
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
}

/// Pestaña estilo TikTok: solo palabra + subrayado dorado.
class _TabTikTok extends StatelessWidget {
  const _TabTikTok({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TipografiaHaku.interfaz(
                fontSize: 16,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? PaletaRutas.piedra
                    : PaletaRutas.plomoClaro.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2.5,
              width: selected ? 28 : 0,
              decoration: BoxDecoration(
                color: PaletaRutas.oro,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
