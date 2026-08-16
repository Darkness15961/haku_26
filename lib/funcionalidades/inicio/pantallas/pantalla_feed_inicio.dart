import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/datos/rutas_datasource_local.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/pantallas/pantalla_detalle_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../../rutas/widgets/logo_haku_encabezado.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../widgets/carrusel_rutas_recomendadas.dart';
import '../widgets/carrusel_sugerencias_seguimiento.dart';
import '../widgets/publicacion_estilo_threads.dart';
import 'pantalla_busqueda_inicio.dart';
import 'pantalla_mensajes_inicio.dart';

/// Inicio: feed con carruseles + publicaciones estilo Threads.
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
    if (!ok) return;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PantallaMensajesInicio(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 110;
    final rutas = RutasDataSourceLocal.obtenerPorCategoria(
      CategoriaRuta.recomendadas,
    );
    final sugerencias = FeedInicioDataSourceLocal.sugerencias;
    final publicaciones = FeedInicioDataSourceLocal.publicaciones;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
              child: Column(
                children: [
                  const LogoHakuEncabezado(height: 68),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _abrirBusqueda(context),
                            borderRadius: BorderRadius.circular(14),
                            child: Ink(
                              height: 44,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.82),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  width: 1.1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    size: 22,
                                    color: PaletaRutas.marronOscuro
                                        .withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Buscar personas o lugares',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TipografiaHaku.interfaz(
                                        fontSize: 13,
                                        color: PaletaRutas.marronOscuro
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _abrirMensajes(context, ref),
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
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
            Expanded(
              child: FondoSuaveSeccion(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(0, 16, 0, bottomPad),
                  children: [
                    CarruselRutasRecomendadas(
                      rutas: rutas,
                      onTapRuta: (ruta) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PantallaDetalleRuta(ruta: ruta),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    CarruselSugerenciasSeguimiento(sugerencias: sugerencias),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Publicaciones',
                        style: TipografiaHaku.titulo(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.marronOscuro,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < publicaciones.length; i++) ...[
                      PublicacionEstiloThreads(
                        publicacion: publicaciones[i],
                        indice: i,
                      ),
                      if (i < publicaciones.length - 1)
                        const SizedBox(height: 12),
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
