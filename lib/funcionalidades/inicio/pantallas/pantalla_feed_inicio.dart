import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../lugares/datos/lugares_datasource_local.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../lugares/pantallas/pantalla_detalle_lugar.dart';
import '../../rutas/datos/rutas_datasource_local.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/pantallas/pantalla_detalle_ruta.dart';
import '../../rutas/pantallas/pantalla_rutas.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../proveedores/proveedor_navegacion_inicio.dart';
import '../widgets/card_escapada_comunidad.dart';
import '../widgets/carrusel_rutas_recomendadas.dart';
import '../widgets/portada_inicio_cultura.dart';
import 'pantalla_busqueda_inicio.dart';
import 'pantalla_mensajes_inicio.dart';

/// Descubre: categorías agrupadas + descubiertos por la comunidad.
class PantallaFeedInicio extends ConsumerStatefulWidget {
  const PantallaFeedInicio({super.key});

  @override
  ConsumerState<PantallaFeedInicio> createState() => _EstadoPantallaFeedInicio();
}

class _EstadoPantallaFeedInicio extends ConsumerState<PantallaFeedInicio> {
  final _scroll = ScrollController();
  final _keys = <String, GlobalKey>{
    'aventura': GlobalKey(),
    'comida': GlobalKey(),
    'ceramica': GlobalKey(),
    'mistico': GlobalKey(),
    'naturaleza': GlobalKey(),
    'foto': GlobalKey(),
    'refugios': GlobalKey(),
    'descubiertos': GlobalKey(),
  };

  Future<void> _abrirBusqueda() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PantallaBusquedaInicio(),
      ),
    );
  }

  Future<void> _abrirMensajes() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PantallaMensajesInicio(),
      ),
    );
  }

  void _abrirDetalle(ModeloRuta ruta) {
    if (ruta.id.startsWith('lugar_')) {
      final lugarId = ruta.id.substring('lugar_'.length);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PantallaDetalleLugar(lugarId: lugarId),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaDetalleRuta(ruta: ruta),
      ),
    );
  }

  void _abrirRutas() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PantallaRutas()),
    );
  }

  ModeloRuta _desdeLugar(ModeloLugar l) {
    return ModeloRuta(
      id: 'lugar_${l.id}',
      titulo: l.nombre,
      subtitulo: l.descripcion,
      descripcion: l.descripcion,
      imagenUrl: l.imagenUrl,
      categoria: CategoriaRuta.recomendadas,
      provincia: l.provincia,
      calificacion: l.calificacion,
      cantidadResenas: l.exploradores,
      etiquetas: [l.categoria.etiqueta],
      tipoSitio: _tipoLugar(l.categoria),
    );
  }

  String _tipoLugar(CategoriaLugar c) {
    switch (c) {
      case CategoriaLugar.gastronomia:
        return 'Restaurante';
      case CategoriaLugar.cultura:
        return 'Cultura';
      case CategoriaLugar.naturaleza:
        return 'Naturaleza';
      case CategoriaLugar.aventura:
        return 'Aventura';
      case CategoriaLugar.caminata:
        return 'Caminata';
      case CategoriaLugar.fotografia:
        return 'Fotografía';
      case CategoriaLugar.misterioso:
        return 'Místico';
      case CategoriaLugar.magico:
        return 'Ritual';
    }
  }

  /// Lugares recién descubiertos / poco explorados — elegidos por la comunidad.
  List<ModeloRuta> _descubiertosPorComunidad(List<ModeloLugar> lugares) {
    final recientes = lugares
        .where(
          (l) =>
              l.nivelExploracion == NivelExploracion.nuevoEnHaku ||
              l.nivelExploracion == NivelExploracion.pocoExplorado,
        )
        .map(_desdeLugar)
        .map((r) {
          final lugarId = r.id.startsWith('lugar_')
              ? r.id.substring('lugar_'.length)
              : r.id;
          return r.copyWith(
            imagenUrl: CatalogoImagenesHaku.imagenDescubiertoComunidad(
              lugarId: lugarId,
              provincia: r.provincia,
            ),
          );
        })
        .toList()
      ..sort((a, b) {
        final sa = a.cantidadResenas * a.calificacion;
        final sb = b.cantidadResenas * b.calificacion;
        final c = sb.compareTo(sa);
        if (c != 0) return c;
        return b.calificacion.compareTo(a.calificacion);
      });
    return recientes;
  }

  Widget _seccion({
    required String keyId,
    required List<ModeloRuta> rutas,
    required String titulo,
    required String subtitulo,
    required EstiloPieCarrusel estilo,
    VoidCallback? onVerTodas,
    double altura = 300,
  }) {
    if (rutas.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: _keys[keyId],
      padding: const EdgeInsets.only(top: 28),
      child: CarruselRutasRecomendadas(
        rutas: rutas,
        titulo: titulo,
        subtitulo: subtitulo,
        estiloPie: estilo,
        altura: altura,
        anchoTarjeta: 168,
        onVerTodas: onVerTodas ?? _abrirRutas,
        onTapRuta: _abrirDetalle,
      ),
    );
  }

  /// Evita la misma tarjeta o la misma imagen en Descubre.
  List<ModeloRuta> _sinDuplicados(
    List<ModeloRuta> lista,
    Set<String> idsUsados,
    Set<String> imagenesUsadas,
  ) {
    final out = <ModeloRuta>[];
    for (final r in lista) {
      final img = r.imagenUrl.trim();
      if (idsUsados.contains(r.id)) continue;
      if (img.isNotEmpty && imagenesUsadas.contains(img)) continue;
      idsUsados.add(r.id);
      if (img.isNotEmpty) imagenesUsadas.add(img);
      out.add(r);
    }
    return out;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 88;
    final todasRutas = RutasDataSourceLocal.obtenerTodas();
    final culturales = RutasDataSourceLocal.obtenerCultura();
    final caminos = todasRutas
        .where((r) => r.hilo == HiloCultura.camino)
        .toList();
    final lugares = LugaresDataSourceLocal.instancia.todos();

    // Carrusel hero: solo lo mágico / misterioso / místico
    final cuscoMagico = lugares
        .where(
          (l) =>
              l.categoria == CategoriaLugar.misterioso ||
              l.categoria == CategoriaLugar.magico,
        )
        .map((l) {
          final r = _desdeLugar(l);
          return r.copyWith(
            imagenUrl: CatalogoImagenesHaku.imagenCuscoMagico(lugarId: l.id),
          );
        })
        .toList()
      ..sort((a, b) => b.calificacion.compareTo(a.calificacion));
    // Prioriza tours curiosos (Almudena, noche, wak’as…) al frente
    cuscoMagico.sort((a, b) {
      int peso(ModeloRuta r) {
        final t = r.titulo.toLowerCase();
        if (t.contains('almudena')) return 0;
        if (t.contains('noche') || t.contains('luna')) return 1;
        if (t.contains('wak') || t.contains('qorikancha')) return 2;
        return 3;
      }

      final c = peso(a).compareTo(peso(b));
      if (c != 0) return c;
      return b.calificacion.compareTo(a.calificacion);
    });
    final heroMagico = cuscoMagico.take(7).toList();

    var descubiertos = _descubiertosPorComunidad(lugares)
        .where((r) => !heroMagico.any((h) => h.id == r.id))
        .toList();
    var aventura = <ModeloRuta>[
      ...caminos,
      ...lugares
          .where(
            (l) =>
                l.categoria == CategoriaLugar.aventura ||
                l.categoria == CategoriaLugar.caminata,
          )
          .map(_desdeLugar),
    ];

    var comida = <ModeloRuta>[
      ...todasRutas.where((r) => r.hilo == HiloCultura.comida).map((r) {
        return r.copyWith(
          imagenUrl: CatalogoImagenesHaku.imagenRutaComida(r.id),
        );
      }),
      ...lugares
          .where((l) => l.categoria == CategoriaLugar.gastronomia)
          .map((l) {
            final r = _desdeLugar(l);
            return r.copyWith(
              imagenUrl: CatalogoImagenesHaku.imagenFogones(lugarId: l.id),
            );
          }),
    ];

    // Cerámica / talleres / tejido / arte (no monumentos genéricos)
    var ceramicaYTalleres = <ModeloRuta>[
      ...todasRutas.where(
        (r) =>
            r.hilo == HiloCultura.ceramica ||
            r.hilo == HiloCultura.tejido ||
            r.hilo == HiloCultura.pintura ||
            r.hilo == HiloCultura.teatro,
      ),
      ...lugares
          .where(
            (l) =>
                l.categoria == CategoriaLugar.cultura &&
                (l.nombre.toLowerCase().contains('taller') ||
                    l.nombre.toLowerCase().contains('cerám') ||
                    l.nombre.toLowerCase().contains('museo') ||
                    l.nombre.toLowerCase().contains('tejido') ||
                    l.nombre.toLowerCase().contains('fiesta')),
          )
          .map(_desdeLugar),
    ];

    var misticos = <ModeloRuta>[];

    var naturaleza = <ModeloRuta>[
      ...lugares
          .where((l) => l.categoria == CategoriaLugar.naturaleza)
          .map(_desdeLugar),
    ];
    if (naturaleza.isEmpty) {
      naturaleza.addAll(
        caminos.where((r) => r.categoria == CategoriaRuta.naturaleza),
      );
    }

    var foto = lugares
        .where((l) => l.categoria == CategoriaLugar.fotografia)
        .map(_desdeLugar)
        .toList();

    var refugios = <ModeloRuta>[
      ...lugares
          .where(
            (l) =>
                l.nombre.toLowerCase().contains('casa') ||
                l.tiempoEstimado.toLowerCase().contains('noche'),
          )
          .map(_desdeLugar),
    ];

    // —— Agrupación estricta por categoría ——
    final idsUsados = <String>{};
    final imgsUsadas = <String>{};
    // Portada mística reserva sus fotos primero
    for (final r in heroMagico) {
      if (r.imagenUrl.isNotEmpty) imgsUsadas.add(r.imagenUrl);
      idsUsados.add(r.id);
    }
    // Card descubiertos — reserva ids para no repetir abajo
    for (final r in descubiertos.take(5)) {
      idsUsados.add(r.id);
      if (r.imagenUrl.isNotEmpty) imgsUsadas.add(r.imagenUrl);
    }
    aventura = _sinDuplicados(aventura, idsUsados, imgsUsadas);
    comida = _sinDuplicados(comida, idsUsados, imgsUsadas);
    ceramicaYTalleres =
        _sinDuplicados(ceramicaYTalleres, idsUsados, imgsUsadas);
    // Sección místicos: el resto que no salió en el hero
    misticos = _sinDuplicados(
      cuscoMagico.where((r) => !idsUsados.contains(r.id)).toList(),
      idsUsados,
      imgsUsadas,
    );
    naturaleza = _sinDuplicados(naturaleza, idsUsados, imgsUsadas);
    foto = _sinDuplicados(foto, idsUsados, imgsUsadas);
    refugios = _sinDuplicados(refugios, idsUsados, imgsUsadas);

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '¿Qué descubres hoy?',
                        style: TipografiaHaku.titulo(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                          height: 1.05,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Mensajes',
                      onPressed: _abrirMensajes,
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Material(
                  color: PaletaRutas.carbon,
                  borderRadius: BorderRadius.circular(28),
                  child: InkWell(
                    onTap: _abrirBusqueda,
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: PaletaRutas.plomoClaro,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Buscar descubrimientos en Cusco…',
                              style: TipografiaHaku.interfaz(
                                fontSize: 14,
                                color: PaletaRutas.plomo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        ref.read(pestaniaShellInicioProvider.notifier).state = 1,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: ColoredBox(
                                color: PaletaRutas.carbon,
                                child: Icon(
                                  Icons.near_me_rounded,
                                  color: PaletaRutas.oro,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cerca para descubrir',
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: PaletaRutas.piedra,
                                  ),
                                ),
                                Text(
                                  'Cusco, Perú',
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 12,
                                    color: PaletaRutas.plomoClaro,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: PaletaRutas.plomo,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: PortadaInicioCultura(
                rutas: heroMagico.isNotEmpty
                    ? heroMagico
                    : (culturales.isNotEmpty ? culturales : caminos),
                onExplorar: () {
                  final ctx = _keys['mistico']?.currentContext;
                  if (ctx != null) {
                    Scrollable.ensureVisible(
                      ctx,
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      alignment: 0.08,
                    );
                  }
                },
                onTapRuta: _abrirDetalle,
              ),
            ),

            // Aventura agrupada
            SliverToBoxAdapter(
              child: _seccion(
                keyId: 'aventura',
                rutas: aventura,
                titulo: 'Senderos por descubrir',
                subtitulo: 'Rafting, ferrata, trekking y caminatas',
                estilo: EstiloPieCarrusel.tipoYProvincia,
                altura: 310,
              ),
            ),
            // Comida / restaurantes
            SliverToBoxAdapter(
              child: _seccion(
                keyId: 'comida',
                rutas: comida,
                titulo: 'Fogones por descubrir',
                subtitulo: 'Restaurantes, picanterías y mercados',
                estilo: EstiloPieCarrusel.tipoYProvincia,
              ),
            ),
            // Descubiertos por la comunidad — card grande
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: _keys['descubiertos'],
                child: CardEscapadaComunidad(
                  lugares: descubiertos,
                  onConocerMas: _abrirDetalle,
                ),
              ),
            ),
            // Cerámica / talleres
            SliverToBoxAdapter(
              child: _seccion(
                keyId: 'ceramica',
                rutas: ceramicaYTalleres,
                titulo: 'Talleres y oficios vivos',
                subtitulo: 'Cerámica, tejido, pintura y teatro',
                estilo: EstiloPieCarrusel.tipoYProvincia,
              ),
            ),
            // Místicos
            SliverToBoxAdapter(
              child: _seccion(
                keyId: 'mistico',
                rutas: misticos,
                titulo: 'Experiencias místicas',
                subtitulo: 'Noche, leyendas y ese silencio que solo Cusco tiene',
                estilo: EstiloPieCarrusel.tipoYProvincia,
              ),
            ),
            // Naturaleza
            SliverToBoxAdapter(
              child: _seccion(
                keyId: 'naturaleza',
                rutas: naturaleza,
                titulo: 'Cumbres y lagunas',
                subtitulo: 'Naturaleza para descubrir con calma',
                estilo: EstiloPieCarrusel.tipoYProvincia,
              ),
            ),
            // Foto
            SliverToBoxAdapter(
              child: _seccion(
                keyId: 'foto',
                rutas: foto,
                titulo: 'Miradas que inspiran',
                subtitulo: 'Sesiones y ángulos por descubrir',
                estilo: EstiloPieCarrusel.tipoYProvincia,
              ),
            ),
            // Refugios
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPad),
                child: _seccion(
                  keyId: 'refugios',
                  rutas: refugios,
                  titulo: 'Refugios del camino',
                  subtitulo: 'Dónde quedarte mientras descubres',
                  estilo: EstiloPieCarrusel.tipoYProvincia,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
