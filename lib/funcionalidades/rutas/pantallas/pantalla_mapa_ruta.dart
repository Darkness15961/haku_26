import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../dominio/modelos/modelo_ruta.dart';
import '../widgets/boton_primario_ruta.dart';
import '../widgets/estilos_rutas.dart';
import '../widgets/linea_encabezado_inca.dart';

/// Mapa de paradas reales. El sendero solo se dibuja cuando existe un
/// LineString validado; nunca se inventa un trazo uniendo nodos.
class PantallaMapaRuta extends StatefulWidget {
  final ModeloRuta ruta;

  const PantallaMapaRuta({super.key, required this.ruta});

  @override
  State<PantallaMapaRuta> createState() => _EstadoPantallaMapaRuta();
}

class _EstadoPantallaMapaRuta extends State<PantallaMapaRuta> {
  int _paradaSeleccionada = 0;

  ModeloRuta get ruta => widget.ruta;

  List<PuntoRuta> get _puntos => ruta.puntos;

  Future<void> _copiarCoords(PuntoRuta p) async {
    await Clipboard.setData(ClipboardData(text: '${p.lat}, ${p.lng}'));
    if (!mounted) return;
    mostrarSnackHaku(context, 'Copiado', destacado: true);
  }

  @override
  Widget build(BuildContext context) {
    final puntos = _puntos;
    final indiceSeguro = puntos.isEmpty
        ? 0
        : _paradaSeleccionada.clamp(0, puntos.length - 1);
    final sel = puntos.isEmpty ? null : puntos[indiceSeguro];
    final coordenadas = puntos.map((p) => LatLng(p.lat, p.lng)).toList();
    final trazado = ruta.trazado
        .map((coordenada) => LatLng(coordenada.lat, coordenada.lng))
        .toList();
    final puntosVista = trazado.isEmpty
        ? coordenadas
        : [...coordenadas, ...trazado];
    final hayMapa = puntos.isNotEmpty || trazado.length >= 2;
    final consejosGenerales =
        ruta.requisitos.isEmpty && ruta.advertencias.isEmpty
        ? ruta.tips
        : const <String>[];
    final bottom = MediaQuery.paddingOf(context).bottom + 20;
    final ancho = MediaQuery.sizeOf(context).width;
    final horizontal = ancho > 792 ? (ancho - 760) / 2 : 16.0;
    final proporcionMapa = ancho > 600 ? 1.6 : 1.15;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Mapa de la ruta',
                      style: TipografiaHaku.titulo(
                        fontSize: 20,
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
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  14,
                  horizontal,
                  bottom,
                ),
                children: [
                  Text(
                    ruta.titulo,
                    style: TipografiaHaku.titulo(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  if (ruta.puntoPartida.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Partida: ${ruta.puntoPartida}',
                      style: TipografiaHaku.interfaz(
                        fontSize: 13,
                        color: PaletaRutas.plomoClaro,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: proporcionMapa,
                      child: !hayMapa
                          ? ColoredBox(
                              color: PaletaRutas.carbon,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'Esta ruta aún no tiene un recorrido disponible.',
                                    textAlign: TextAlign.center,
                                    style: TipografiaHaku.interfaz(
                                      color: PaletaRutas.plomoClaro,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Stack(
                              children: [
                                FlutterMap(
                                  options: MapOptions(
                                    initialCenter: puntosVista.first,
                                    initialZoom: puntosVista.length == 1
                                        ? 14
                                        : 11,
                                    initialCameraFit: puntosVista.length > 1
                                        ? CameraFit.bounds(
                                            bounds: LatLngBounds.fromPoints(
                                              puntosVista,
                                            ),
                                            padding: const EdgeInsets.all(38),
                                          )
                                        : null,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                                      subdomains: const ['a', 'b', 'c', 'd'],
                                      userAgentPackageName: 'com.example.haku',
                                      retinaMode: RetinaMode.isHighDensity(
                                        context,
                                      ),
                                    ),
                                    if (trazado.length >= 2)
                                      PolylineLayer(
                                        polylines: [
                                          Polyline(
                                            points: trazado,
                                            color: PaletaRutas.oro,
                                            strokeWidth: 4,
                                          ),
                                        ],
                                      ),
                                    MarkerLayer(
                                      markers: [
                                        for (var i = 0; i < puntos.length; i++)
                                          Marker(
                                            point: coordenadas[i],
                                            width: 38,
                                            height: 38,
                                            child: GestureDetector(
                                              onTap: () => setState(
                                                () => _paradaSeleccionada = i,
                                              ),
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: i == indiceSeguro
                                                      ? PaletaRutas.oro
                                                      : PaletaRutas.piedra,
                                                  border: Border.all(
                                                    color: PaletaRutas.ink,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${i + 1}',
                                                    style:
                                                        TipografiaHaku.interfaz(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color:
                                                              PaletaRutas.ink,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    RichAttributionWidget(
                                      attributions: [
                                        TextSourceAttribution(
                                          'OpenStreetMap contributors',
                                        ),
                                        TextSourceAttribution('CARTO'),
                                      ],
                                    ),
                                  ],
                                ),
                                Positioned(
                                  right: 10,
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: PaletaRutas.carbon.withValues(
                                        alpha: 0.92,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      ruta.distancia.isEmpty
                                          ? (puntos.isEmpty
                                                ? 'Recorrido disponible'
                                                : '${puntos.length} puntos')
                                          : ruta.distancia,
                                      style: TipografiaHaku.interfaz(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: PaletaRutas.piedra,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (puntos.isNotEmpty) ...[
                    Text(
                      'Paradas',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < puntos.length; i++)
                      _TileParada(
                        punto: puntos[i],
                        indice: i + 1,
                        seleccionado: i == _paradaSeleccionada,
                        onTap: () => setState(() => _paradaSeleccionada = i),
                        onCopiar: () => _copiarCoords(puntos[i]),
                      ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: PaletaRutas.carbon,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: PaletaRutas.plomo.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cómo llegar',
                          style: TipografiaHaku.titulo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ruta.comoLlegar.isEmpty
                              ? (puntos.isEmpty
                                    ? 'Consulta el recorrido del mapa para orientarte.'
                                    : 'Sigue las paradas en el orden indicado.')
                              : ruta.comoLlegar,
                          style: TipografiaHaku.interfaz(
                            fontSize: 13,
                            height: 1.4,
                            color: PaletaRutas.plomoClaro,
                          ),
                        ),
                        if (ruta.transporte.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            ruta.transporte,
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.oro,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        if (sel != null)
                          Text(
                            '${sel.nombre}\n'
                            '${sel.lat.toStringAsFixed(4)}, ${sel.lng.toStringAsFixed(4)}',
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: PaletaRutas.plomo,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (ruta.requisitos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ListaIndicaciones(
                      titulo: 'Antes de ir',
                      items: ruta.requisitos,
                      icono: Icons.check_circle_outline,
                    ),
                  ],
                  if (ruta.advertencias.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ListaIndicaciones(
                      titulo: 'Ten en cuenta',
                      items: ruta.advertencias,
                      icono: Icons.warning_amber_rounded,
                    ),
                  ],
                  if (consejosGenerales.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ListaIndicaciones(
                      titulo: 'Recomendaciones',
                      items: consejosGenerales,
                      icono: Icons.lightbulb_outline_rounded,
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (sel != null)
                    BotonPrimarioRuta(
                      texto: 'Copiar ubicación',
                      icono: Icons.copy_rounded,
                      onPressed: () => _copiarCoords(sel),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaIndicaciones extends StatelessWidget {
  const _ListaIndicaciones({
    required this.titulo,
    required this.items,
    required this.icono,
  });

  final String titulo;
  final List<String> items;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TipografiaHaku.titulo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, size: 18, color: PaletaRutas.oro),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TipografiaHaku.interfaz(
                      fontSize: 13,
                      height: 1.35,
                      color: PaletaRutas.plomoClaro,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TileParada extends StatelessWidget {
  final PuntoRuta punto;
  final int indice;
  final bool seleccionado;
  final VoidCallback onTap;
  final VoidCallback onCopiar;

  const _TileParada({
    required this.punto,
    required this.indice,
    required this.seleccionado,
    required this.onTap,
    required this.onCopiar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: seleccionado
            ? PaletaRutas.carbon
            : PaletaRutas.carbon.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: seleccionado
                      ? PaletaRutas.oro.withValues(alpha: 0.22)
                      : PaletaRutas.plomo.withValues(alpha: 0.35),
                  child: Text(
                    '$indice',
                    style: TipografiaHaku.interfaz(
                      fontWeight: FontWeight.w800,
                      color: seleccionado
                          ? PaletaRutas.oro
                          : PaletaRutas.piedra,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        punto.nombre,
                        style: TipografiaHaku.interfaz(
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      Text(
                        [
                          punto.tipo,
                          if (punto.nota != null) punto.nota!,
                        ].join(' · '),
                        style: TipografiaHaku.interfaz(
                          fontSize: 11,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar ubicación',
                  onPressed: onCopiar,
                  icon: const Icon(
                    Icons.my_location_rounded,
                    color: PaletaRutas.oro,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
