import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../inicio/widgets/publicacion_estilo_threads.dart';
import '../../rutas/datos/rutas_datasource_local.dart';
import '../../rutas/pantallas/pantalla_detalle_ruta.dart';
import '../../rutas/pantallas/pantalla_rutas.dart';
import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';

/// Guardados reales: rutas + publicaciones.
class PantallaFavoritos extends ConsumerWidget {
  const PantallaFavoritos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(almacenFeedProvider);
    final rutas = [
      for (final id in store.favoritosRutaIds)
        if (RutasDataSourceLocal.obtenerPorId(id) != null)
          RutasDataSourceLocal.obtenerPorId(id)!,
    ];
    final posts = [
      for (final p in store.publicaciones)
        if (store.guardadosIds.contains(p.id)) p,
    ];
    final bottomPad = MediaQuery.paddingOf(context).bottom + 24;
    final vacio = rutas.isEmpty && posts.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
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
                      color: PaletaRutas.marronOscuro,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Guardados',
                      style: TipografiaHaku.titulo(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
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
              child: FondoSuaveSeccion(
                child: vacio
                    ? ListView(
                        padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad),
                        children: [
                          Text(
                            'Vacío',
                            textAlign: TextAlign.center,
                            style: TipografiaHaku.titulo(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          BotonPrimarioRuta(
                            texto: 'Rutas',
                            icono: Icons.map_outlined,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const PantallaRutas(),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    : ListView(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                        children: [
                          if (rutas.isNotEmpty) ...[
                            Text(
                              'Rutas',
                              style: TipografiaHaku.titulo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
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
                            const SizedBox(height: 12),
                          ],
                          if (posts.isNotEmpty) ...[
                            Text(
                              'Publicaciones',
                              style: TipografiaHaku.titulo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _TileRuta extends StatelessWidget {
  final String titulo;
  final String imagen;
  final VoidCallback onTap;

  const _TileRuta({
    required this.titulo,
    required this.imagen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.88),
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
                child: imagen.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: imagen,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(imagen),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Color(0xFF333333)),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: TipografiaHaku.titulo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
