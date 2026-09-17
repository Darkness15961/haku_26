import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/widgets/imagen_haku.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../inicio/widgets/publicacion_estilo_threads.dart';
import '../../lugares/datos/lugares_datasource_local.dart';
import '../../lugares/pantallas/pantalla_detalle_lugar.dart';
import '../../lugares/proveedores/proveedor_explora_ui.dart';
import '../../rutas/pantallas/pantalla_detalle_ruta.dart';
import '../../rutas/proveedores/proveedor_rutas.dart';
import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';

/// Guardados reales: rutas + publicaciones.
class PantallaFavoritos extends ConsumerWidget {
  const PantallaFavoritos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(almacenFeedProvider);
    final idsRutas = store.favoritosRutaIds
        .where((id) => !id.startsWith('lugar_'))
        .toSet();
    final idsRutasOrdenados = idsRutas.toList()..sort();
    final rutasAsync = ref.watch(
      rutasGuardadasProvider(idsRutasOrdenados.join(',')),
    );
    final catalogoRutas = rutasAsync.valueOrNull ?? const [];
    final rutasPorId = {for (final ruta in catalogoRutas) ruta.id: ruta};
    final rutas = [
      for (final id in idsRutas)
        if (rutasPorId[id] != null) rutasPorId[id]!,
    ];
    final rutasNoDisponibles = rutasAsync.hasValue
        ? idsRutas.where((id) => !rutasPorId.containsKey(id)).toList()
        : const <String>[];
    final lugares = [
      for (final id in store.favoritosRutaIds)
        if (id.startsWith('lugar_'))
          LugaresDataSourceLocal.instancia.porId(id.substring('lugar_'.length)),
    ].whereType();
    final posts = [
      for (final p in store.publicaciones)
        if (store.guardadosIds.contains(p.id)) p,
    ];
    final bottomPad = MediaQuery.paddingOf(context).bottom + 24;
    final vacio = idsRutas.isEmpty && lugares.isEmpty && posts.isEmpty;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Guardados',
                      style: TipografiaHaku.titulo(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LineaEncabezadoInca(altura: 2),
            ),
            Expanded(
              child: vacio
                  ? ListView(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad),
                      children: [
                        Text(
                          'Todavía no hay nada',
                          textAlign: TextAlign.center,
                          style: TipografiaHaku.titulo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                        const SizedBox(height: 16),
                        BotonPrimarioRuta(
                          texto: 'Rutas',
                          icono: Icons.map_outlined,
                          onPressed: () {
                            irAExplora(ref, modo: ModoExplora.rutas);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    )
                  : ListView(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                      children: [
                        if (lugares.isNotEmpty) ...[
                          Text(
                            'Lugares',
                            style: TipografiaHaku.titulo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final l in lugares) ...[
                            _TileRuta(
                              titulo: l.nombre,
                              imagen: l.imagenUrl,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        PantallaDetalleLugar(lugarId: l.id),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 12),
                        ],
                        if (idsRutas.isNotEmpty) ...[
                          Text(
                            'Rutas',
                            style: TipografiaHaku.titulo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (rutasAsync.isLoading && !rutasAsync.hasValue)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: PaletaRutas.oro,
                                ),
                              ),
                            )
                          else if (rutasAsync.hasError && !rutasAsync.hasValue)
                            _ErrorRutasGuardadas(
                              onReintentar: () => ref.invalidate(
                                rutasGuardadasProvider(
                                  idsRutasOrdenados.join(','),
                                ),
                              ),
                            ),
                          for (final r in rutas) ...[
                            _TileRuta(
                              titulo: r.titulo,
                              imagen: r.imagenUrl,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        PantallaDetalleRuta(ruta: r),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                          for (final id in rutasNoDisponibles) ...[
                            _TileRuta(
                              titulo: 'Ruta ya no disponible',
                              subtitulo: 'Guardado · $id',
                              onQuitar: () => ref
                                  .read(almacenFeedProvider.notifier)
                                  .toggleFavoritoRuta(id),
                            ),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 12),
                        ],
                        if (posts.isNotEmpty) ...[
                          Text(
                            'Publicaciones',
                            style: TipografiaHaku.titulo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (var i = 0; i < posts.length; i++) ...[
                            PublicacionEstiloThreads(
                              publicacion: posts[i],
                              indice: i,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileRuta extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final String? imagen;
  final VoidCallback? onTap;
  final VoidCallback? onQuitar;

  const _TileRuta({
    required this.titulo,
    this.subtitulo,
    this.imagen,
    this.onTap,
    this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PaletaRutas.carbon,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imagen == null
                    ? Container(
                        width: 64,
                        height: 64,
                        color: PaletaRutas.plomoOscuro,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.route_outlined,
                          color: PaletaRutas.plomoClaro,
                        ),
                      )
                    : ImagenHaku(
                        url: imagen!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TipografiaHaku.titulo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    if (subtitulo != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitulo!,
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onQuitar != null)
                IconButton(
                  tooltip: 'Quitar de guardados',
                  onPressed: onQuitar,
                  icon: const Icon(
                    Icons.bookmark_remove_outlined,
                    color: PaletaRutas.oro,
                  ),
                )
              else
                Icon(
                  onTap == null
                      ? Icons.info_outline_rounded
                      : Icons.chevron_right,
                  color: PaletaRutas.plomo,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorRutasGuardadas extends StatelessWidget {
  const _ErrorRutasGuardadas({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            'No pudimos actualizar tus rutas guardadas.',
            textAlign: TextAlign.center,
            style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
          ),
          TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
