import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../../../nucleo/mapas/estilos_mapa_haku.dart';
import '../../lugares/dominio/servicio_ubicacion_mapa.dart';
import '../dominio/modelos/modelo_ruta.dart';
import '../widgets/boton_primario_ruta.dart';
import '../widgets/estilos_rutas.dart';
import '../widgets/linea_encabezado_inca.dart';

/// Mapa de paradas reales. Si existe un LineString validado se usa como
/// recorrido real; si no, se muestra una linea guia entre paradas.
class PantallaMapaRuta extends StatefulWidget {
  final ModeloRuta ruta;
  final bool inmersivo;

  const PantallaMapaRuta({
    super.key,
    required this.ruta,
    this.inmersivo = false,
  });

  @override
  State<PantallaMapaRuta> createState() => _EstadoPantallaMapaRuta();
}

class _EstadoPantallaMapaRuta extends State<PantallaMapaRuta> {
  int _paradaSeleccionada = 0;
  ml.MapLibreMapController? _controller;
  bool _mapaListo = false;
  bool _ubicandoUsuario = false;
  ml.LatLng? _usuarioMapa;

  ModeloRuta get ruta => widget.ruta;

  List<PuntoRuta> get _puntos => ruta.puntos;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _copiarCoords(PuntoRuta p) async {
    await Clipboard.setData(ClipboardData(text: '${p.lat}, ${p.lng}'));
    if (!mounted) return;
    mostrarSnackHaku(context, 'Copiado', destacado: true);
  }

  Future<void> _seleccionarParada(int index) async {
    setState(() => _paradaSeleccionada = index);
    final punto = _puntos[index];
    if (_controller == null || !_mapaListo) return;
    await _controller!.animateCamera(
      ml.CameraUpdate.newCameraPosition(
        ml.CameraPosition(target: ml.LatLng(punto.lat, punto.lng), zoom: 14.5),
      ),
    );
  }

  Future<void> _cargarCapasRuta(ml.MapLibreMapController controller) async {
    try {
      await controller.setGeoJsonSource('ruta_trazado', _trazadoGeoJson());
      await controller.setGeoJsonSource('ruta_paradas', _paradasGeoJson());
      await _actualizarUsuarioMapa();
      await _encuadrarRuta(controller);
      return;
    } catch (_) {
      // La fuente todavia no existe o el estilo fue recargado.
    }

    await controller.addGeoJsonSource('ruta_trazado', _trazadoGeoJson());
    await controller.addGeoJsonSource('ruta_paradas', _paradasGeoJson());

    await controller.addLineLayer(
      'ruta_trazado',
      'ruta_trazado_linea',
      ml.LineLayerProperties(
        lineColor: [
          'case',
          [
            '==',
            ['get', 'guia'],
            true,
          ],
          _hex(PaletaRutas.plomoClaro),
          _hex(PaletaRutas.oro),
        ],
        lineOpacity: [
          'case',
          [
            '==',
            ['get', 'guia'],
            true,
          ],
          0.72,
          0.92,
        ],
        lineWidth: [
          'case',
          [
            '==',
            ['get', 'guia'],
            true,
          ],
          3.0,
          4.0,
        ],
      ),
    );
    await controller.addCircleLayer(
      'ruta_paradas',
      'ruta_paradas_circulo',
      ml.CircleLayerProperties(
        circleColor: [
          'case',
          [
            '==',
            ['get', 'seleccionada'],
            true,
          ],
          _hex(PaletaRutas.oro),
          _hex(PaletaRutas.piedra),
        ],
        circleStrokeColor: _hex(PaletaRutas.ink),
        circleStrokeWidth: 2.0,
        circleRadius: [
          'case',
          [
            '==',
            ['get', 'seleccionada'],
            true,
          ],
          10.0,
          8.0,
        ],
      ),
    );
    await controller.addSymbolLayer(
      'ruta_paradas',
      'ruta_paradas_numero',
      const ml.SymbolLayerProperties(
        textField: ['get', 'orden'],
        textSize: 11.0,
        textColor: '#141210',
        textAllowOverlap: true,
        textIgnorePlacement: true,
      ),
    );
    await _actualizarUsuarioMapa();
    await _encuadrarRuta(controller);
  }

  Future<void> _actualizarParadasMapa() async {
    if (_controller == null || !_mapaListo) return;
    await _controller!.setGeoJsonSource('ruta_paradas', _paradasGeoJson());
  }

  Future<void> _actualizarUsuarioMapa() async {
    if (_controller == null || !_mapaListo) return;
    final controller = _controller!;
    try {
      await controller.setGeoJsonSource('ruta_usuario', _usuarioGeoJson());
      return;
    } catch (_) {
      // La fuente todavia no existe o el estilo fue recargado.
    }

    await controller.addGeoJsonSource('ruta_usuario', _usuarioGeoJson());
    await controller.addCircleLayer(
      'ruta_usuario',
      'ruta_usuario_halo',
      ml.CircleLayerProperties(
        circleColor: _hex(PaletaRutas.oro),
        circleOpacity: 0.22,
        circleRadius: 20,
      ),
    );
    await controller.addCircleLayer(
      'ruta_usuario',
      'ruta_usuario_centro',
      ml.CircleLayerProperties(
        circleColor: _hex(PaletaRutas.oro),
        circleStrokeColor: _hex(PaletaRutas.ink),
        circleStrokeWidth: 2.5,
        circleRadius: 8,
      ),
    );
  }

  Future<void> _usarMiUbicacion() async {
    if (_ubicandoUsuario) return;
    setState(() => _ubicandoUsuario = true);
    final resultado = await ServicioUbicacionMapa.obtenerActual(
      timeLimit: const Duration(seconds: 12),
    );
    if (!mounted) return;
    setState(() => _ubicandoUsuario = false);

    if (!resultado.tienePunto) {
      mostrarSnackHaku(context, _mensajeGps(resultado.estado), destacado: true);
      if (resultado.estado == EstadoUbicacionMapa.gpsApagado ||
          resultado.estado == EstadoUbicacionMapa.permisoPermanente) {
        await _ofrecerAjustesGps(resultado.estado);
      }
      return;
    }

    final usuario = ml.LatLng(resultado.latitud!, resultado.longitud!);
    setState(() => _usuarioMapa = usuario);
    await _actualizarUsuarioMapa();
    if (_controller == null || !_mapaListo) return;
    await _controller!.animateCamera(
      ml.CameraUpdate.newCameraPosition(
        ml.CameraPosition(target: usuario, zoom: 15.5),
      ),
    );
  }

  Future<void> _ofrecerAjustesGps(EstadoUbicacionMapa estado) async {
    if (!mounted) return;
    final abrir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PaletaRutas.carbon,
        title: Text(
          estado == EstadoUbicacionMapa.gpsApagado
              ? 'GPS apagado'
              : 'Permiso de ubicacion',
          style: TipografiaHaku.titulo(color: PaletaRutas.piedra),
        ),
        content: Text(
          estado == EstadoUbicacionMapa.gpsApagado
              ? 'Activa la ubicacion del telefono para centrarte en el mapa.'
              : 'Habilita el permiso de ubicacion para mostrar tu posicion.',
          style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ahora no'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );
    if (abrir != true) return;
    if (estado == EstadoUbicacionMapa.gpsApagado) {
      await ServicioUbicacionMapa.abrirAjustesUbicacion();
    } else {
      await ServicioUbicacionMapa.abrirAjustesApp();
    }
  }

  String _mensajeGps(EstadoUbicacionMapa estado) {
    return switch (estado) {
      EstadoUbicacionMapa.gpsApagado => 'Activa el GPS para ver tu ubicacion.',
      EstadoUbicacionMapa.permisoDenegado =>
        'Permiso de ubicacion denegado.',
      EstadoUbicacionMapa.permisoPermanente =>
        'Habilita el permiso de ubicacion en ajustes.',
      EstadoUbicacionMapa.timeout =>
        'No pudimos obtener tu ubicacion a tiempo.',
      EstadoUbicacionMapa.error => 'No pudimos obtener tu ubicacion.',
      EstadoUbicacionMapa.ok => 'Ubicacion lista.',
    };
  }

  Future<void> _centrarRecorrido() async {
    if (_controller == null || !_mapaListo) return;
    await _encuadrarRuta(_controller!);
  }

  void _abrirMapaCompleto() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PantallaMapaRuta(ruta: ruta, inmersivo: true),
      ),
    );
  }

  int? _indiceParadaCercana(ml.LatLng latLng) {
    if (_puntos.isEmpty) return null;
    var mejorIndice = 0;
    var mejorDistancia = double.infinity;
    for (var i = 0; i < _puntos.length; i++) {
      final p = _puntos[i];
      final d = _distanciaM(latLng.latitude, latLng.longitude, p.lat, p.lng);
      if (d < mejorDistancia) {
        mejorDistancia = d;
        mejorIndice = i;
      }
    }
    return mejorDistancia <= _radioToqueMapa(latLng) ? mejorIndice : null;
  }

  double _radioToqueMapa(ml.LatLng latLng) {
    final zoom = _controller?.cameraPosition?.zoom ?? 12.0;
    final metrosPorPixel =
        (156543.03392 *
                math.cos(latLng.latitude * math.pi / 180.0) /
                math.pow(2, zoom))
            .toDouble();
    return math.max(80.0, 46.0 * metrosPorPixel);
  }

  double _distanciaM(double latA, double lngA, double latB, double lngB) {
    const radioTierra = 6371000.0;
    final dLat = _rad(latB - latA);
    final dLng = _rad(lngB - lngA);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(latA)) *
            math.cos(_rad(latB)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return radioTierra * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _rad(double grados) => grados * math.pi / 180;

  Future<void> _encuadrarRuta(ml.MapLibreMapController controller) async {
    final puntosVista = _puntosVista;
    if (puntosVista.isEmpty) return;
    if (puntosVista.length == 1) {
      await controller.animateCamera(
        ml.CameraUpdate.newCameraPosition(
          ml.CameraPosition(target: puntosVista.first, zoom: 14),
        ),
      );
      return;
    }

    var west = puntosVista.first.longitude;
    var east = puntosVista.first.longitude;
    var south = puntosVista.first.latitude;
    var north = puntosVista.first.latitude;
    for (final punto in puntosVista.skip(1)) {
      west = west < punto.longitude ? west : punto.longitude;
      east = east > punto.longitude ? east : punto.longitude;
      south = south < punto.latitude ? south : punto.latitude;
      north = north > punto.latitude ? north : punto.latitude;
    }
    await controller.setCameraBounds(
      west: west,
      north: north,
      south: south,
      east: east,
      padding: 54,
    );
  }

  List<ml.LatLng> get _puntosMapa =>
      _puntos.map((p) => ml.LatLng(p.lat, p.lng)).toList(growable: false);

  List<ml.LatLng> get _trazadoMapa => ruta.trazado
      .map((coordenada) => ml.LatLng(coordenada.lat, coordenada.lng))
      .toList(growable: false);

  bool get _usaLineaGuia => _trazadoMapa.length < 2 && _puntosMapa.length >= 2;

  List<ml.LatLng> get _lineaMapa {
    final trazado = _trazadoMapa;
    if (trazado.length >= 2) return trazado;
    final puntos = _puntosMapa;
    return puntos.length >= 2 ? puntos : const <ml.LatLng>[];
  }

  List<ml.LatLng> get _puntosVista {
    final trazado = _lineaMapa;
    final puntos = _puntosMapa;
    return trazado.isEmpty ? puntos : [...puntos, ...trazado];
  }

  Map<String, dynamic> _vacioGeoJson() {
    return {'type': 'FeatureCollection', 'features': []};
  }

  Map<String, dynamic> _trazadoGeoJson() {
    final linea = _lineaMapa;
    if (linea.length < 2) return _vacioGeoJson();
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'LineString',
            'coordinates': [
              for (final p in linea) [p.longitude, p.latitude],
            ],
          },
          'properties': {'guia': _usaLineaGuia},
        },
      ],
    };
  }

  Map<String, dynamic> _paradasGeoJson() {
    return {
      'type': 'FeatureCollection',
      'features': [
        for (var i = 0; i < _puntos.length; i++)
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [_puntos[i].lng, _puntos[i].lat],
            },
            'properties': {
              'id': _puntos[i].id,
              'orden': '${i + 1}',
              'nombre': _puntos[i].nombre,
              'seleccionada': i == _paradaSeleccionada,
            },
          },
      ],
    };
  }

  Map<String, dynamic> _usuarioGeoJson() {
    final usuario = _usuarioMapa;
    return {
      'type': 'FeatureCollection',
      'features': [
        if (usuario != null)
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [usuario.longitude, usuario.latitude],
            },
            'properties': {},
          },
      ],
    };
  }

  Widget _construirMapa({
    required bool hayMapa,
    required List<ml.LatLng> puntosVista,
    required bool mostrarExpandir,
  }) {
    if (!hayMapa) {
      return ColoredBox(
        color: PaletaRutas.carbon,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Esta ruta aun no tiene un recorrido disponible.',
              textAlign: TextAlign.center,
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        ml.MapLibreMap(
          styleString: EstilosMapaHaku.openFreeMapLiberty,
          initialCameraPosition: ml.CameraPosition(
            target: puntosVista.first,
            zoom: puntosVista.length == 1 ? 14 : 11,
          ),
          minMaxZoomPreference: const ml.MinMaxZoomPreference(6.5, 17.0),
          attributionButtonPosition: ml.AttributionButtonPosition.bottomLeft,
          onMapCreated: (controller) async {
            _controller = controller;
            _mapaListo = true;
            await _cargarCapasRuta(controller);
          },
          onStyleLoadedCallback: () async {
            if (_controller == null || !_mapaListo) return;
            await _cargarCapasRuta(_controller!);
          },
          onMapClick: (_, latLng) async {
            final cercano = _indiceParadaCercana(latLng);
            if (cercano == null) return;
            await _seleccionarParada(cercano);
            await _actualizarParadasMapa();
          },
        ),
        const Positioned(left: 8, bottom: 8, child: _AtribucionMapa()),
        Positioned(
          right: 10,
          top: 10,
          child: _ControlesMapaRuta(
            ubicando: _ubicandoUsuario,
            mostrarExpandir: mostrarExpandir,
            onCentrar: _centrarRecorrido,
            onUbicacion: _usarMiUbicacion,
            onExpandir: _abrirMapaCompleto,
          ),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: PaletaRutas.carbon.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _etiquetaMapa(),
              style: TipografiaHaku.interfaz(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _etiquetaMapa() {
    if (ruta.distancia.isNotEmpty) return ruta.distancia;
    if (_usaLineaGuia) return 'Linea guia';
    if (_puntos.isEmpty) return 'Recorrido disponible';
    return '${_puntos.length} puntos';
  }

  Widget _construirInmersivo({
    required bool hayMapa,
    required List<ml.LatLng> puntosVista,
    required PuntoRuta? seleccionada,
  }) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _construirMapa(
                hayMapa: hayMapa,
                puntosVista: puntosVista,
                mostrarExpandir: false,
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 76,
              child: Row(
                children: [
                  _BotonControlMapa(
                    tooltip: 'Volver',
                    icono: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: PaletaRutas.carbon.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ruta.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.interfaz(
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (seleccionada != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12 + bottom,
                child: _ResumenParadaMapa(
                  punto: seleccionada,
                  onCopiar: () => _copiarCoords(seleccionada),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puntos = _puntos;
    final indiceSeguro = puntos.isEmpty
        ? 0
        : _paradaSeleccionada.clamp(0, puntos.length - 1);
    final sel = puntos.isEmpty ? null : puntos[indiceSeguro];
    final puntosVista = _puntosVista;
    final hayMapa = puntos.isNotEmpty || _lineaMapa.length >= 2;
    final consejosGenerales =
        ruta.requisitos.isEmpty && ruta.advertencias.isEmpty
        ? ruta.tips
        : const <String>[];
    final bottom = MediaQuery.paddingOf(context).bottom + 20;
    final ancho = MediaQuery.sizeOf(context).width;
    final horizontal = ancho > 792 ? (ancho - 760) / 2 : 16.0;
    final proporcionMapa = ancho > 600 ? 1.6 : 1.15;

    if (widget.inmersivo) {
      return _construirInmersivo(
        hayMapa: hayMapa,
        puntosVista: puntosVista,
        seleccionada: sel,
      );
    }

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
                      child: _construirMapa(
                        hayMapa: hayMapa,
                        puntosVista: puntosVista,
                        mostrarExpandir: true,
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
                        onTap: () async {
                          await _seleccionarParada(i);
                          await _actualizarParadasMapa();
                        },
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

class _ControlesMapaRuta extends StatelessWidget {
  const _ControlesMapaRuta({
    required this.ubicando,
    required this.mostrarExpandir,
    required this.onCentrar,
    required this.onUbicacion,
    required this.onExpandir,
  });

  final bool ubicando;
  final bool mostrarExpandir;
  final VoidCallback onCentrar;
  final VoidCallback onUbicacion;
  final VoidCallback onExpandir;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BotonControlMapa(
          tooltip: 'Ver toda la ruta',
          icono: Icons.center_focus_strong_rounded,
          onTap: onCentrar,
        ),
        const SizedBox(height: 8),
        _BotonControlMapa(
          tooltip: 'Mi ubicacion',
          icono: Icons.my_location_rounded,
          cargando: ubicando,
          onTap: ubicando ? null : onUbicacion,
        ),
        if (mostrarExpandir) ...[
          const SizedBox(height: 8),
          _BotonControlMapa(
            tooltip: 'Pantalla completa',
            icono: Icons.fullscreen_rounded,
            onTap: onExpandir,
          ),
        ],
      ],
    );
  }
}

class _BotonControlMapa extends StatelessWidget {
  const _BotonControlMapa({
    required this.tooltip,
    required this.icono,
    required this.onTap,
    this.cargando = false,
  });

  final String tooltip;
  final IconData icono;
  final VoidCallback? onTap;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: PaletaRutas.carbon.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Center(
              child: cargando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PaletaRutas.oro,
                      ),
                    )
                  : Icon(icono, size: 21, color: PaletaRutas.piedra),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumenParadaMapa extends StatelessWidget {
  const _ResumenParadaMapa({required this.punto, required this.onCopiar});

  final PuntoRuta punto;
  final VoidCallback onCopiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PaletaRutas.plomo.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, color: PaletaRutas.oro, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  punto.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TipografiaHaku.interfaz(
                    fontWeight: FontWeight.w800,
                    color: PaletaRutas.piedra,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${punto.lat.toStringAsFixed(4)}, ${punto.lng.toStringAsFixed(4)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar ubicacion',
            onPressed: onCopiar,
            icon: const Icon(Icons.copy_rounded, color: PaletaRutas.oro),
          ),
        ],
      ),
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

String _hex(Color color) {
  return '#${color.toARGB32().toRadixString(16).substring(2, 8)}';
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
