import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../../funcionalidades/rutas/widgets/estilos_rutas.dart';
import 'estilos_mapa_haku.dart';

class MapaMarcadorHaku extends StatefulWidget {
  const MapaMarcadorHaku({
    super.key,
    required this.punto,
    this.zoom = 15,
    this.minZoom = 5,
    this.maxZoom = 18,
    this.color = PaletaRutas.oro,
    this.overlay,
  });

  final LatLng punto;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final Color color;
  final Widget? overlay;

  @override
  State<MapaMarcadorHaku> createState() => _MapaMarcadorHakuState();
}

class _MapaMarcadorHakuState extends State<MapaMarcadorHaku> {
  ml.MapLibreMapController? _controller;
  bool _mapaListo = false;

  @override
  void didUpdateWidget(covariant MapaMarcadorHaku oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.punto != widget.punto) {
      _actualizarPunto();
      _moverAPunto();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _moverAPunto() async {
    if (!_mapaListo || _controller == null) return;
    await _controller!.animateCamera(
      ml.CameraUpdate.newCameraPosition(
        ml.CameraPosition(target: _aMl(widget.punto), zoom: widget.zoom),
      ),
    );
  }

  Future<void> _cargarPunto() async {
    if (!_mapaListo || _controller == null) return;
    final controller = _controller!;
    try {
      await controller.setGeoJsonSource('haku_punto', _puntoGeoJson());
      return;
    } catch (_) {
      // La fuente todavia no existe o el estilo fue recargado.
    }

    await controller.addGeoJsonSource('haku_punto', _puntoGeoJson());
    await controller.addCircleLayer(
      'haku_punto',
      'haku_punto_halo',
      ml.CircleLayerProperties(
        circleColor: _hex(widget.color),
        circleOpacity: 0.22,
        circleRadius: 20,
      ),
    );
    await controller.addCircleLayer(
      'haku_punto',
      'haku_punto_centro',
      ml.CircleLayerProperties(
        circleColor: _hex(widget.color),
        circleStrokeColor: _hex(PaletaRutas.ink),
        circleStrokeWidth: 2,
        circleRadius: 8,
      ),
    );
  }

  Future<void> _actualizarPunto() async {
    if (!_mapaListo || _controller == null) return;
    await _controller!.setGeoJsonSource('haku_punto', _puntoGeoJson());
  }

  Map<String, dynamic> _puntoGeoJson() {
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [widget.punto.longitude, widget.punto.latitude],
          },
          'properties': {},
        },
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ml.MapLibreMap(
          styleString: EstilosMapaHaku.openFreeMapLiberty,
          initialCameraPosition: ml.CameraPosition(
            target: _aMl(widget.punto),
            zoom: widget.zoom,
          ),
          minMaxZoomPreference: ml.MinMaxZoomPreference(
            widget.minZoom,
            widget.maxZoom,
          ),
          rotateGesturesEnabled: false,
          attributionButtonPosition: ml.AttributionButtonPosition.bottomLeft,
          onMapCreated: (controller) {
            _controller = controller;
            _mapaListo = true;
          },
          onStyleLoadedCallback: _cargarPunto,
        ),
        const Positioned(left: 8, bottom: 8, child: _AtribucionMapa()),
        if (widget.overlay != null) widget.overlay!,
      ],
    );
  }
}

class _AtribucionMapa extends StatelessWidget {
  const _AtribucionMapa();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${EstilosMapaHaku.atribucionOpenStreetMap} · '
        '${EstilosMapaHaku.atribucionOpenFreeMap}',
        style: TipografiaHaku.interfaz(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: PaletaRutas.plomoClaro,
        ),
      ),
    );
  }
}

ml.LatLng _aMl(LatLng punto) => ml.LatLng(punto.latitude, punto.longitude);

String _hex(Color color) {
  return '#${color.toARGB32().toRadixString(16).substring(2, 8)}';
}
