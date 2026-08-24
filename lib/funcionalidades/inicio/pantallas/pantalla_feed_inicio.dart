import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../publicaciones/pantallas/pantalla_publicaciones.dart';
import '../../rutas/datos/rutas_datasource_local.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/pantallas/pantalla_detalle_ruta.dart';
import '../../rutas/pantallas/pantalla_rutas.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../proveedores/proveedor_almacen_feed.dart';
import '../proveedores/proveedor_navegacion_inicio.dart';
import '../widgets/banner_acciones_rapidas.dart';
import '../widgets/carrusel_rutas_recomendadas.dart';
import '../widgets/portada_inicio_cultura.dart';
import '../widgets/publicacion_estilo_threads.dart';
import 'pantalla_busqueda_inicio.dart';
import 'pantalla_mensajes_inicio.dart';

/// Inicio Fase 1 = cultura viva + aportes comunitarios.
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

  Future<void> _publicar(BuildContext context, WidgetRef ref) async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PantallaPublicaciones(),
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
    final culturales = RutasDataSourceLocal.obtenerCultura();
    final feed = ref.watch(almacenFeedProvider);
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
                  padding: const EdgeInsets.fromLTRB(12, 6, 4, 0),
                  child: Row(
                    children: [
                      Image.asset(
                        'public/image/logo_haku_encabezado.jpeg',
                        height: 36,
                        width: 36,
                        errorBuilder: (_, __, ___) => Text(
                          'HAKU',
                          style: TipografiaHaku.logo(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'HAKU',
                        style: TipografiaHaku.logo(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
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
                child: PortadaInicioCultura(
                  rutas: culturales,
                ),
              ),
              SliverToBoxAdapter(
                child: BannerAccionesRapidas(
                  onExplorar: () =>
                      ref.read(pestaniaShellInicioProvider.notifier).state = 1,
                  onCultura: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PantallaRutas(),
                      ),
                    );
                  },
                  onCompartir: () => _publicar(context, ref),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: CarruselRutasRecomendadas(
                    rutas: culturales,
                    titulo: 'Descubrimientos semanales',
                    iconoAsset: 'assets/iconos/montania.svg',
                    altura: 300,
                    anchoTarjeta: 220,
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
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'Publicaciones',
                    style: TipografiaHaku.titulo(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final esUltima = i == publicaciones.length - 1;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: esUltima ? bottomPad : 14,
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
