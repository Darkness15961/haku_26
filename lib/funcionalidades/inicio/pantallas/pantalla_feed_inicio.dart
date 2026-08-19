import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../lugares/datos/lugares_datasource_local.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../publicaciones/pantallas/pantalla_publicaciones.dart';
import '../../rutas/datos/rutas_datasource_local.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/pantallas/pantalla_detalle_ruta.dart';
import '../../rutas/pantallas/pantalla_rutas.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../proveedores/proveedor_almacen_feed.dart';
import '../proveedores/proveedor_navegacion_inicio.dart';
import '../widgets/banner_acciones_rapidas.dart';
import '../widgets/carrusel_rutas_recomendadas.dart';
import '../widgets/carrusel_sugerencias_seguimiento.dart';
import '../widgets/franja_stats_comunidad.dart';
import '../widgets/mosaico_hilos_cultura.dart';
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

  ModeloRuta? _rutaPorHilo(List<ModeloRuta> culturales, HiloCultura hilo) {
    for (final r in culturales) {
      if (r.hilo == hilo) return r;
    }
    return culturales.isNotEmpty ? culturales.first : null;
  }

  int _contarHuecos() {
    return LugaresDataSourceLocal.instancia.todos().where((l) {
      return l.nivelExploracion == NivelExploracion.pocoExplorado ||
          l.nivelExploracion == NivelExploracion.nuevoEnHaku;
    }).length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 110;
    final culturales = RutasDataSourceLocal.obtenerCultura();
    final destacada = culturales.isNotEmpty ? culturales.first : null;
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HAKU',
                            style: TipografiaHaku.logo(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Cultura y territorio',
                            style: TipografiaHaku.interfaz(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: PaletaRutas.marronCuero,
                            ),
                          ),
                        ],
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
                  destacada: destacada,
                  onDestacada: destacada == null
                      ? null
                      : () => _abrirDetalleRuta(context, destacada),
                  onHilo: (h) {
                    final r = _rutaPorHilo(culturales, h);
                    if (r != null) _abrirDetalleRuta(context, r);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: FranjaStatsComunidad(
                  aportes: publicaciones.length,
                  hilos: culturales.length,
                  huecos: _contarHuecos(),
                  exploradores: sugerencias.length,
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
                  onAportar: () => _publicar(context, ref),
                ),
              ),
              SliverToBoxAdapter(
                child: MosaicoHilosCultura(
                  rutas: culturales,
                  onHilo: (h) {
                    final r = _rutaPorHilo(culturales, h);
                    if (r != null) _abrirDetalleRuta(context, r);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: CarruselRutasRecomendadas(
                    rutas: culturales,
                    titulo: 'Explora cultura',
                    subtitulo: 'Hilos documentados por la comunidad',
                    iconoAsset: 'assets/iconos/ceramica.svg',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aportes',
                                  style: TipografiaHaku.titulo(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Fotos y relatos de la comunidad',
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 12,
                                    color: PaletaRutas.marronCuero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _publicar(context, ref),
                            style: FilledButton.styleFrom(
                              backgroundColor: PaletaRutas.terracota,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                            label: Text(
                              'Aportar',
                              style: TipografiaHaku.interfaz(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const LineaEncabezadoInca(altura: 2),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: PublicacionEstiloThreads(
                        publicacion: publicaciones[i],
                        indice: i,
                      ),
                    );
                  },
                  childCount: publicaciones.length,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 8, 0, bottomPad),
                  child: CarruselSugerenciasSeguimiento(
                    sugerencias: sugerencias,
                    titulo: 'Exploradores',
                    subtitulo: 'Gente que documenta Cusco contigo',
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
