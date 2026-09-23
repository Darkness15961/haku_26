import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../../../nucleo/mapas/estilos_mapa_haku.dart';
import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/geocodificador_lugar.dart';
import '../dominio/logica_ubicacion_lugar.dart';

/// Mapa para marcar un punto: búsqueda + tap. Confirma lat/lon.
class PantallaElegirUbicacionLugar extends StatefulWidget {
  const PantallaElegirUbicacionLugar({
    super.key,
    this.inicial,
    this.distritoNombre,
    this.provinciaNombre,
  });

  final LatLng? inicial;
  final String? distritoNombre;
  final String? provinciaNombre;

  @override
  State<PantallaElegirUbicacionLugar> createState() =>
      _EstadoPantallaElegirUbicacionLugar();
}

class _EstadoPantallaElegirUbicacionLugar
    extends State<PantallaElegirUbicacionLugar> {
  final _busqueda = TextEditingController();
  ml.MapLibreMapController? _mapController;
  bool _mapaListo = false;

  late LatLng _punto;
  var _tocoMapa = false;
  var _buscando = false;
  var _centrandoTerritorio = false;

  @override
  void initState() {
    super.initState();
    _punto =
        widget.inicial ??
        const LatLng(
          LogicaUbicacionLugar.latCusco,
          LogicaUbicacionLugar.lonCusco,
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _intentarCentrarDistrito();
    });
  }

  @override
  void dispose() {
    _busqueda.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _moverMapa(LatLng punto, double zoom) async {
    if (!_mapaListo || _mapController == null) return;
    await _mapController!.animateCamera(
      ml.CameraUpdate.newCameraPosition(
        ml.CameraPosition(target: _aMl(punto), zoom: zoom),
      ),
    );
  }

  Future<void> _cargarPuntoMapa(ml.MapLibreMapController controller) async {
    try {
      await controller.setGeoJsonSource('punto_lugar', _puntoGeoJson());
      return;
    } catch (_) {
      // La fuente todavia no existe o el estilo fue recargado.
    }

    await controller.addGeoJsonSource('punto_lugar', _puntoGeoJson());
    await controller.addCircleLayer(
      'punto_lugar',
      'punto_lugar_halo',
      ml.CircleLayerProperties(
        circleColor: _hex(PaletaRutas.oro),
        circleOpacity: 0.22,
        circleRadius: 20,
      ),
    );
    await controller.addCircleLayer(
      'punto_lugar',
      'punto_lugar_centro',
      ml.CircleLayerProperties(
        circleColor: _hex(PaletaRutas.oro),
        circleStrokeColor: _hex(PaletaRutas.ink),
        circleStrokeWidth: 2,
        circleRadius: 8,
      ),
    );
  }

  Future<void> _actualizarPuntoMapa() async {
    if (!_mapaListo || _mapController == null) return;
    await _mapController!.setGeoJsonSource('punto_lugar', _puntoGeoJson());
  }

  Map<String, dynamic> _puntoGeoJson() {
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [_punto.longitude, _punto.latitude],
          },
          'properties': {},
        },
      ],
    };
  }

  Future<void> _intentarCentrarDistrito() async {
    if (widget.inicial != null) return;
    final dist = widget.distritoNombre?.trim();
    final prov = widget.provinciaNombre?.trim();
    if (dist == null || dist.isEmpty) return;

    setState(() => _centrandoTerritorio = true);
    try {
      final punto = await GeocodificadorLugar.centrarTerritorio(
        distrito: dist,
        provincia: prov ?? 'Cusco',
      );
      if (!mounted || punto == null) return;
      setState(() {
        _punto = punto;
        _tocoMapa = false;
      });
      await _moverMapa(punto, 13);
      await _actualizarPuntoMapa();
    } catch (e) {
      debugPrint('Centrar distrito: $e');
    } finally {
      if (mounted) setState(() => _centrandoTerritorio = false);
    }
  }

  Future<void> _buscar() async {
    final q = _busqueda.text.trim();
    if (q.isEmpty) {
      mostrarSnackHaku(context, 'Escribe un nombre para buscar');
      return;
    }
    setState(() => _buscando = true);
    try {
      final punto = await GeocodificadorLugar.buscar(
        consulta: q,
        distrito: widget.distritoNombre,
        provincia: widget.provinciaNombre,
      );
      if (!mounted) return;
      if (punto == null) {
        mostrarSnackHaku(
          context,
          'No encontramos ese lugar. Prueba otro nombre.',
        );
        return;
      }
      setState(() {
        _punto = punto;
        _tocoMapa = true;
      });
      await _moverMapa(punto, 15);
      await _actualizarPuntoMapa();
    } catch (e) {
      debugPrint('Buscar mapa: $e');
      if (mounted) {
        mostrarSnackHaku(context, 'No se pudo buscar. Revisa la conexión.');
      }
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  void _confirmar() {
    final err = LogicaUbicacionLugar.mensajeErrorUbicacion(
      _punto.latitude,
      _punto.longitude,
    );
    if (err != null) {
      mostrarSnackHaku(context, err);
      return;
    }
    Navigator.of(context).pop(_punto);
  }

  @override
  Widget build(BuildContext context) {
    final territorio = [
      if (widget.distritoNombre?.trim().isNotEmpty == true)
        widget.distritoNombre!.trim(),
      if (widget.provinciaNombre?.trim().isNotEmpty == true)
        widget.provinciaNombre!.trim(),
    ].join(' · ');

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        title: Text(
          'Marcar en el mapa',
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: PaletaRutas.piedra,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (territorio.isNotEmpty)
                  Text(
                    territorio,
                    style: TipografiaHaku.interfaz(
                      fontSize: 12,
                      color: PaletaRutas.oro,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  _centrandoTerritorio
                      ? 'Acercando al distrito…'
                      : (_tocoMapa
                            ? 'Punto marcado. Puedes moverlo tocando otra vez.'
                            : 'Busca un nombre o toca el mapa para fijar el punto.'),
                  style: TipografiaHaku.interfaz(
                    fontSize: 13,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _busqueda,
                        style: TipografiaHaku.interfaz(
                          color: PaletaRutas.piedra,
                        ),
                        cursorColor: PaletaRutas.oro,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _buscar(),
                        decoration: InputDecoration(
                          hintText: 'Ej. Plaza de Armas, Sacsayhuamán…',
                          hintStyle: TipografiaHaku.interfaz(
                            color: PaletaRutas.plomo,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: PaletaRutas.carbon,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: PaletaRutas.plomoOscuro.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: PaletaRutas.plomoOscuro.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: PaletaRutas.oro,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _buscando ? null : _buscar,
                      style: IconButton.styleFrom(
                        backgroundColor: PaletaRutas.oro,
                        foregroundColor: PaletaRutas.ink,
                      ),
                      icon: _buscando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: PaletaRutas.ink,
                              ),
                            )
                          : const Icon(Icons.search),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ml.MapLibreMap(
                  styleString: EstilosMapaHaku.openFreeMapLiberty,
                  initialCameraPosition: ml.CameraPosition(
                    target: _aMl(_punto),
                    zoom: 12,
                  ),
                  minMaxZoomPreference: const ml.MinMaxZoomPreference(5, 18),
                  rotateGesturesEnabled: false,
                  attributionButtonPosition:
                      ml.AttributionButtonPosition.bottomLeft,
                  onMapCreated: (controller) async {
                    _mapController = controller;
                    _mapaListo = true;
                    await _cargarPuntoMapa(controller);
                  },
                  onStyleLoadedCallback: () async {
                    if (!_mapaListo || _mapController == null) return;
                    await _cargarPuntoMapa(_mapController!);
                  },
                  onMapClick: (_, punto) async {
                    setState(() {
                      _punto = LatLng(punto.latitude, punto.longitude);
                      _tocoMapa = true;
                    });
                    await _actualizarPuntoMapa();
                  },
                ),
                const Positioned(
                  left: 8,
                  bottom: 8,
                  child: _AtribucionMapaSeleccion(),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${_punto.latitude.toStringAsFixed(5)}, ${_punto.longitude.toStringAsFixed(5)}',
                    textAlign: TextAlign.center,
                    style: TipografiaHaku.interfaz(
                      fontSize: 12,
                      color: PaletaRutas.plomo,
                    ),
                  ),
                  const SizedBox(height: 10),
                  BotonPrimarioRuta(
                    texto: 'Usar este punto',
                    onPressed: _confirmar,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

ml.LatLng _aMl(LatLng punto) => ml.LatLng(punto.latitude, punto.longitude);

String _hex(Color color) {
  return '#${color.toARGB32().toRadixString(16).substring(2, 8)}';
}

class _AtribucionMapaSeleccion extends StatelessWidget {
  const _AtribucionMapaSeleccion();

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
