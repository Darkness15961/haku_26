import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/datos/rutas_datasource_local.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/pantallas/pantalla_detalle_ruta.dart';
import '../../rutas/pantallas/pantalla_rutas.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../proveedores/proveedor_almacen_feed.dart';
import '../widgets/carrusel_rutas_recomendadas.dart';
import '../widgets/carrusel_sugerencias_seguimiento.dart';
import '../widgets/publicacion_estilo_threads.dart';
import 'pantalla_busqueda_inicio.dart';
import 'pantalla_mensajes_inicio.dart';

/// Inicio = presentación del producto (descubrimientos + comunidad + posts).
class PantallaFeedInicio extends ConsumerWidget {
  const PantallaFeedInicio({super.key});

  Future<void> _abrirBusqueda(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PantallaBusquedaInicio(),
      ),
    );
  }

  Future<void> _abrirMensajes(BuildContext context, WidgetRef ref) async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PantallaMensajesInicio(),
      ),
    );
  }

  void _abrirDetalleRuta(BuildContext context, ModeloRuta ruta) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaDetalleRuta(ruta: ruta),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 110;
    final rutas = RutasDataSourceLocal.obtenerPorCategoria(
      CategoriaRuta.recomendadas,
    ).take(6).toList();
    final feed = ref.watch(almacenFeedProvider);
    final sugerencias = feed.listo
        ? feed.exploradores
        : FeedInicioDataSourceLocal.sugerencias;
    final publicaciones = feed.listo
        ? feed.publicaciones
        : FeedInicioDataSourceLocal.publicaciones;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FondoSuaveSeccion(
        child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                    child: Row(
                      children: [
                        Text(
                          'HAKU',
                          style: TipografiaHaku.titulo(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Buscar',
                          onPressed: () => _abrirBusqueda(context),
                          icon: const Icon(
                            Icons.search_rounded,
                            color: PaletaRutas.marronOscuro,
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              tooltip: 'Mensajes',
                              onPressed: () => _abrirMensajes(context, ref),
                              icon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: PaletaRutas.marronOscuro,
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 16,
                                height: 16,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: PaletaRutas.terracota,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '3',
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Column(
                      children: [
                        Text(
                          'DESCUBRIMIENTOS\nSEMANALES',
                          textAlign: TextAlign.center,
                          style: TipografiaHaku.titulo(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nuevas rutas, historias y paisajes que te esperan en Cusco.',
                          textAlign: TextAlign.center,
                          style: TipografiaHaku.interfaz(
                            fontSize: 14,
                            height: 1.4,
                            color: PaletaRutas.marronCuero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: CarruselRutasRecomendadas(
                      rutas: rutas,
                      titulo: 'Rutas destacadas',
                      onVerTodas: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PantallaRutas(),
                          ),
                        );
                      },
                      onTapRuta: (r) => _abrirDetalleRuta(context, r),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: CarruselSugerenciasSeguimiento(
                      sugerencias: sugerencias,
                      titulo: 'Exploradores destacados',
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 22, 20, 10),
                    child: _TituloConBordeInca(
                      texto: 'Publicaciones recientes',
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: i == publicaciones.length - 1 ? bottomPad : 12,
                        ),
                        child: PublicacionEstiloThreads(
                          publicacion: publicaciones[i],
                          indice: i,
                        ),
                      );
                    },
                    childCount: publicaciones.length,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _TituloConBordeInca extends StatelessWidget {
  const _TituloConBordeInca({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          texto,
          textAlign: TextAlign.center,
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ClipRect(
          child: SizedBox(
            height: 12,
            width: double.infinity,
            child: SvgPicture.asset(
              'assets/iconos/lineas_inca.svg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              colorFilter: ColorFilter.mode(
                PaletaRutas.marronCuero.withValues(alpha: 0.7),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
