import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:latlong2/latlong.dart';

import '../../../nucleo/mapas/estilos_mapa_haku.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelos/modelo_lugar.dart';

/// Mapa Explora: contorno Cusco, GPS del turista, radio 50 km y pines.
class MapaExploraLugares extends StatefulWidget {
  const MapaExploraLugares({
    super.key,
    required this.lugares,
    this.ubicacionUsuario,
    this.mostrarRadioCerca = false,
    this.radioCercaM = 50000,
    this.contornoCusco = const [],
    this.centroInicial,
    this.zoomInicial = 9.2,
    this.estiloMapa = EstilosMapaHaku.openFreeMapLiberty,
    this.preparandoRadar = false,
    required this.onLugarSeleccionado,
  });

  final List<ModeloLugar> lugares;
  final ValueChanged<ModeloLugar?> onLugarSeleccionado;
  final LatLng? ubicacionUsuario;
  final bool mostrarRadioCerca;
  final double radioCercaM;
  final List<LatLng> contornoCusco;
  final LatLng? centroInicial;
  final double zoomInicial;
  final String estiloMapa;
  final bool preparandoRadar;

  static const centroCusco = LatLng(-13.5167, -71.9788);

  @override
  State<MapaExploraLugares> createState() => MapaExploraLugaresState();
}

class MapaExploraLugaresState extends State<MapaExploraLugares>
    with SingleTickerProviderStateMixin {
  ml.MapLibreMapController? _controller;
  bool _mapaListo = false;
  String? _firmaVista;
  final Set<String> _fotosInyectadas = {};
  AnimationController? _animController;
  Animation<double>? _radioAnimacion;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animController!.addListener(() {
      if (_controller != null &&
          widget.mostrarRadioCerca &&
          widget.ubicacionUsuario != null) {
        _actualizarCirculoGeoJson(_controller!);
      }
    });
  }

  @override
  void dispose() {
    _animController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void zoomIn() {
    if (_controller == null) return;
    _controller!.animateCamera(ml.CameraUpdate.zoomIn());
  }

  void zoomOut() {
    if (_controller == null) return;
    _controller!.animateCamera(ml.CameraUpdate.zoomOut());
  }

  void recentrarEnUsuario() {
    if (_controller == null || widget.ubicacionUsuario == null) return;
    _moverSeguro(widget.ubicacionUsuario!, 15.0);
  }

  @override
  void didUpdateWidget(MapaExploraLugares oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_controller == null || !_mapaListo) return;

    if (widget.estiloMapa != oldWidget.estiloMapa) {
      return;
    }

    if (widget.mostrarRadioCerca != oldWidget.mostrarRadioCerca ||
        widget.radioCercaM != oldWidget.radioCercaM ||
        widget.preparandoRadar != oldWidget.preparandoRadar) {
      if (widget.mostrarRadioCerca) {
        _radioAnimacion = Tween<double>(begin: 0.0, end: widget.radioCercaM)
            .animate(
              CurvedAnimation(
                parent: _animController!,
                curve: Curves.easeOutCirc,
              ),
            );
        _animController!.forward(from: 0.0);
      }
      _moverSeguro(_centroVista(), _zoomVista());
    }

    if (widget.ubicacionUsuario != oldWidget.ubicacionUsuario ||
        widget.mostrarRadioCerca != oldWidget.mostrarRadioCerca ||
        widget.preparandoRadar != oldWidget.preparandoRadar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _controller == null) return;
        _actualizarGeometria(_controller!);
      });
    }

    if (widget.lugares != oldWidget.lugares) {
      _actualizarCapaLugares(_controller!);
    }
  }

  Future<void> _actualizarCapaLugares(
    ml.MapLibreMapController controller,
  ) async {
    await controller.setGeoJsonSource(
      "fuente_lugares",
      _crearLugaresGeoJson(widget.lugares),
    );

    bool hayNuevos = false;
    for (final l in widget.lugares) {
      if (l.imagenUrl.isNotEmpty &&
          !_fotosInyectadas.contains('foto_lugar_${l.id}')) {
        final hueco =
            l.nivelExploracion == NivelExploracion.pocoExplorado ||
            l.nivelExploracion == NivelExploracion.nuevoEnHaku;
        final bytes = await _crearPinConFoto(l.imagenUrl, hueco);
        if (bytes != null) {
          final nombreInyectado = 'foto_lugar_${l.id}';
          await controller.addImage(nombreInyectado, bytes);
          _fotosInyectadas.add(nombreInyectado);
          hayNuevos = true;
        }
      }
    }

    if (hayNuevos) {
      await controller.setGeoJsonSource(
        "fuente_lugares",
        _crearLugaresGeoJson(widget.lugares),
      );
    }
  }

  String _firmaActual() {
    final u = widget.ubicacionUsuario;
    final uid = u == null ? '-' : '${u.latitude},${u.longitude}';
    final ids = widget.lugares.map((l) => l.id).join(',');
    return '$uid|${widget.mostrarRadioCerca}|${widget.radioCercaM}|$ids|${widget.preparandoRadar}';
  }

  LatLng _centroVista() {
    if ((widget.mostrarRadioCerca || widget.preparandoRadar) &&
        widget.ubicacionUsuario != null) {
      return widget.ubicacionUsuario!;
    }
    if (widget.ubicacionUsuario != null && widget.lugares.isEmpty) {
      return widget.ubicacionUsuario!;
    }
    if (widget.lugares.isEmpty) {
      return widget.centroInicial ??
          widget.ubicacionUsuario ??
          MapaExploraLugares.centroCusco;
    }
    final lat =
        widget.lugares.map((l) => l.latitud).reduce((a, b) => a + b) /
        widget.lugares.length;
    final lng =
        widget.lugares.map((l) => l.longitud).reduce((a, b) => a + b) /
        widget.lugares.length;
    return LatLng(lat, lng);
  }

  double _zoomVista() {
    if (widget.preparandoRadar && widget.ubicacionUsuario != null) {
      return 8.8; // Zoom panorámico radar 50km
    }
    if (widget.mostrarRadioCerca && widget.ubicacionUsuario != null) {
      if (widget.radioCercaM <= 30000) return 9.2;
      if (widget.radioCercaM <= 40000) return 9.0;
      return 8.8; // Panorámico
    }
    if (widget.lugares.length <= 1) return 11;
    if (widget.lugares.length <= 5) return 10;
    return widget.zoomInicial;
  }

  void _moverSeguro(LatLng centro, double zoom) {
    if (!_mapaListo || _controller == null) return;
    try {
      _controller!.animateCamera(
        ml.CameraUpdate.newCameraPosition(
          ml.CameraPosition(
            target: ml.LatLng(centro.latitude, centro.longitude),
            zoom: zoom,
          ),
        ),
      );
    } catch (_) {
      // Controlador no listo.
    }
  }

  void _actualizarCirculoGeoJson(ml.MapLibreMapController controller) {
    final usuario = widget.ubicacionUsuario;
    if (usuario == null) return;
    final r = _radioAnimacion?.value ?? widget.radioCercaM;
    controller.setGeoJsonSource(
      "fuente_radio",
      _crearCirculoGeoJson(usuario, r),
    );
  }

  Map<String, dynamic> _crearPoligonoGeoJson(List<LatLng> puntos) {
    // GeoJSON exige que el polígono esté cerrado (primer y último punto iguales)
    final coordList = puntos.map((p) => [p.longitude, p.latitude]).toList();
    if (coordList.isNotEmpty &&
        (coordList.first[0] != coordList.last[0] ||
            coordList.first[1] != coordList.last[1])) {
      coordList.add(coordList.first);
    }
    return {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "Polygon",
            "coordinates": [coordList],
          },
        },
      ],
    };
  }

  Map<String, dynamic> _crearCirculoGeoJson(LatLng centro, double radioMetros) {
    const int puntos = 64;
    const double radioTierra = 6378137.0;
    final double lat = centro.latitude * math.pi / 180.0;
    final double lng = centro.longitude * math.pi / 180.0;
    final double d = radioMetros / radioTierra;

    List<List<double>> coordenadas = [];
    for (int i = 0; i <= puntos; i++) {
      final double brng = math.pi * 2 * i / puntos;
      final double latRad = math.asin(
        math.sin(lat) * math.cos(d) +
            math.cos(lat) * math.sin(d) * math.cos(brng),
      );
      final double lngRad =
          lng +
          math.atan2(
            math.sin(brng) * math.sin(d) * math.cos(lat),
            math.cos(d) - math.sin(lat) * math.sin(latRad),
          );
      coordenadas.add([lngRad * 180.0 / math.pi, latRad * 180.0 / math.pi]);
    }

    return {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "Polygon",
            "coordinates": [coordenadas],
          },
        },
      ],
    };
  }

  Future<void> _actualizarGeometria(ml.MapLibreMapController controller) async {
    if (widget.contornoCusco.length >= 3) {
      await controller.setGeoJsonSource(
        "fuente_cusco",
        _crearPoligonoGeoJson(widget.contornoCusco),
      );
    }

    final usuario = widget.ubicacionUsuario;
    if (widget.mostrarRadioCerca && usuario != null) {
      final r = _radioAnimacion?.value ?? widget.radioCercaM;
      await controller.setGeoJsonSource(
        "fuente_radio",
        _crearCirculoGeoJson(usuario, r),
      );
    } else {
      await controller.setGeoJsonSource("fuente_radio", {
        "type": "FeatureCollection",
        "features": [],
      });
    }

    // Actualizar marcadores si cambia la lista
    await controller.setGeoJsonSource(
      "fuente_lugares",
      _crearLugaresGeoJson(widget.lugares),
    );

    // Actualizar marcador de usuario
    if (usuario != null) {
      await controller.setGeoJsonSource("fuente_usuario", {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": [usuario.longitude, usuario.latitude],
            },
          },
        ],
      });
    } else {
      await controller.setGeoJsonSource("fuente_usuario", {
        "type": "FeatureCollection",
        "features": [],
      });
    }
  }

  Future<void> _cargarCapasGeometria(
    ml.MapLibreMapController controller,
  ) async {
    final oro = PaletaRutas.oro;
    // MapLibre usa colores en formato Hex: #RRGGBB
    final colorOroHex = '#${oro.toARGB32().toRadixString(16).substring(2, 8)}';

    // 1. Polígono Cusco
    // Solo agregamos las fuentes y capas vacías o iniciales una vez.
    await controller.addGeoJsonSource(
      "fuente_cusco",
      widget.contornoCusco.length >= 3
          ? _crearPoligonoGeoJson(widget.contornoCusco)
          : {"type": "FeatureCollection", "features": []},
    );
    await controller.addFillLayer(
      "fuente_cusco",
      "capa_relleno_cusco",
      ml.FillLayerProperties(fillColor: colorOroHex, fillOpacity: 0.06),
    );
    await controller.addLineLayer(
      "fuente_cusco",
      "capa_borde_cusco",
      ml.LineLayerProperties(
        lineColor: colorOroHex,
        lineOpacity: 0.85,
        lineWidth: 2.4,
      ),
    );

    // 2. Círculo Usuario
    final usuario = widget.ubicacionUsuario;
    await controller.addGeoJsonSource(
      "fuente_radio",
      (widget.mostrarRadioCerca && usuario != null)
          ? _crearCirculoGeoJson(usuario, widget.radioCercaM)
          : {"type": "FeatureCollection", "features": []},
    );
    await controller.addFillLayer(
      "fuente_radio",
      "capa_relleno_radio",
      ml.FillLayerProperties(fillColor: colorOroHex, fillOpacity: 0.10),
    );
    await controller.addLineLayer(
      "fuente_radio",
      "capa_borde_radio",
      ml.LineLayerProperties(
        lineColor: colorOroHex,
        lineOpacity: 0.55,
        lineWidth: 1.6,
      ),
    );
  }

  Future<Uint8List> _crearIconoMemoria(IconData iconData, Color color) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 56.0, // Tamaño en píxeles del PNG generado
        fontFamily: iconData.fontFamily,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(0.0, 0.0));

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(56, 56);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<ui.Image> _cargarUiImage(String url) async {
    final Completer<ui.Image> completer = Completer();
    final ImageStream stream = NetworkImage(
      url,
    ).resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!completer.isCompleted) completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (dynamic error, StackTrace? stackTrace) {
        if (!completer.isCompleted) completer.completeError(error);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  Future<Uint8List?> _crearPinConFoto(String url, bool hueco) async {
    try {
      final imagen = await _cargarUiImage(url);
      final size = 120.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final colorBorde = hueco ? PaletaRutas.oro : PaletaRutas.piedra;

      final shadowPaint = Paint()
        ..color = PaletaRutas.ink.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(
        Offset(size / 2, size / 2 + 6),
        size / 2 - 12,
        shadowPaint,
      );

      final paintBase = Paint()..color = colorBorde;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 6, paintBase);

      final radioImg = size / 2 - 14;
      final path = ui.Path()
        ..addOval(
          Rect.fromCircle(center: Offset(size / 2, size / 2), radius: radioImg),
        );
      canvas.clipPath(path);

      final src = Rect.fromLTWH(
        0,
        0,
        imagen.width.toDouble(),
        imagen.height.toDouble(),
      );
      final dst = Rect.fromCircle(
        center: Offset(size / 2, size / 2),
        radius: radioImg,
      );
      canvas.drawImageRect(imagen, src, dst, Paint());

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> _crearLugaresGeoJson(List<ModeloLugar> lugares) {
    return {
      "type": "FeatureCollection",
      "features": lugares.map((l) {
        final hueco =
            l.nivelExploracion == NivelExploracion.pocoExplorado ||
            l.nivelExploracion == NivelExploracion.nuevoEnHaku;
        return {
          "type": "Feature",
          "id": l.id,
          "properties": {
            "id": l.id.toString(),
            "icono": _fotosInyectadas.contains("foto_lugar_${l.id}")
                ? "foto_lugar_${l.id}"
                : (hueco ? "pin_oro" : "pin_plomo"),
            "nombre": l.nombre,
          },
          "geometry": {
            "type": "Point",
            "coordinates": [l.longitud, l.latitud],
          },
        };
      }).toList(),
    };
  }

  Future<void> _cargarMarcadoresClustering(
    ml.MapLibreMapController controller,
  ) async {
    // 1. Generar iconos y registrarlos en la tarjeta gráfica (Memoria)
    final oroBytes = await _crearIconoMemoria(
      Icons.location_on,
      PaletaRutas.oro,
    );
    final plomoBytes = await _crearIconoMemoria(
      Icons.location_on,
      PaletaRutas.plomoOscuro,
    );

    await controller.addImage("pin_oro", oroBytes);
    await controller.addImage("pin_plomo", plomoBytes);

    for (final l in widget.lugares) {
      if (l.imagenUrl.isNotEmpty) {
        final hueco =
            l.nivelExploracion == NivelExploracion.pocoExplorado ||
            l.nivelExploracion == NivelExploracion.nuevoEnHaku;
        final bytes = await _crearPinConFoto(l.imagenUrl, hueco);
        if (bytes != null) {
          final nombreInyectado = 'foto_lugar_${l.id}';
          await controller.addImage(nombreInyectado, bytes);
          _fotosInyectadas.add(nombreInyectado);
        }
      }
    }

    // 2. Fuente de datos con Clustering Activado
    await controller.addSource(
      "fuente_lugares",
      ml.GeojsonSourceProperties(
        data: _crearLugaresGeoJson(widget.lugares),
        cluster: true,
        clusterMaxZoom: 14,
        clusterRadius: 50,
      ),
    );

    // 3. Capa: Círculos de los clústeres
    final colorOroHex =
        '#${PaletaRutas.oro.toARGB32().toRadixString(16).substring(2, 8)}';
    await controller.addCircleLayer(
      "fuente_lugares",
      "capa_clusters",
      ml.CircleLayerProperties(
        circleColor: colorOroHex,
        circleRadius: [
          'step',
          ['get', 'point_count'],
          20,
          10,
          25,
          50,
          30,
        ],
        circleOpacity: 0.85,
        circleStrokeWidth: 2,
        circleStrokeColor: '#ffffff',
      ),
      filter: ['has', 'point_count'], // Solo aplica a grupos
    );

    // 4. Capa: Números dentro de los clústeres
    await controller.addSymbolLayer(
      "fuente_lugares",
      "capa_clusters_conteo",
      ml.SymbolLayerProperties(
        textField: '{point_count_abbreviated}',
        textSize: 14,
        textColor: '#ffffff',
        textIgnorePlacement: true,
      ),
      filter: ['has', 'point_count'],
    );

    // 5. Capa: Pines individuales (no agrupados)
    await controller.addSymbolLayer(
      "fuente_lugares",
      "capa_pines_individuales",
      ml.SymbolLayerProperties(
        iconImage: '{icono}', // Lee de las properties
        iconSize: [
          'interpolate',
          ['linear'],
          ['zoom'],
          8,
          0.5,
          15,
          0.75,
        ],
        iconAllowOverlap: true,
        iconAnchor: 'center',
      ),
      filter: [
        '!',
        ['has', 'point_count'],
      ],
    );
  }

  Future<Uint8List> _crearMarcadorUsuarioMemoria() async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final paintFondo = Paint()..color = PaletaRutas.oro.withValues(alpha: 0.22);
    canvas.drawCircle(const Offset(22, 22), 22, paintFondo);

    final shadowPaint = Paint()
      ..color = PaletaRutas.ink.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(const Offset(22, 24), 14, shadowPaint);

    final paintCentro = Paint()..color = PaletaRutas.oro;
    canvas.drawCircle(const Offset(22, 22), 14, paintCentro);

    final paintBorde = Paint()
      ..color = PaletaRutas.piedra
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(const Offset(22, 22), 14, paintBorde);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const iconData = Icons.navigation_rounded;
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 16.0,
        fontFamily: iconData.fontFamily,
        color: PaletaRutas.ink,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(14, 14));

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(44, 44);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _cargarCapasInteractivas(
    ml.MapLibreMapController controller,
  ) async {
    // Capa de Usuario
    final userBytes = await _crearMarcadorUsuarioMemoria();
    await controller.addImage("img_usuario", userBytes);

    final usuario = widget.ubicacionUsuario;
    await controller.addSource(
      "fuente_usuario",
      ml.GeojsonSourceProperties(
        data: (usuario != null)
            ? {
                "type": "FeatureCollection",
                "features": [
                  {
                    "type": "Feature",
                    "geometry": {
                      "type": "Point",
                      "coordinates": [usuario.longitude, usuario.latitude],
                    },
                  },
                ],
              }
            : {"type": "FeatureCollection", "features": []},
      ),
    );
    await controller.addSymbolLayer(
      "fuente_usuario",
      "capa_usuario",
      ml.SymbolLayerProperties(
        iconImage: "img_usuario",
        iconSize: 1.0,
        iconAllowOverlap: true,
        symbolSortKey: 10, // Asegura que el usuario se dibuje encima de otros
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final centro = _centroVista();

    return Stack(
      children: [
        ml.MapLibreMap(
          styleString: widget.estiloMapa,
          initialCameraPosition: ml.CameraPosition(
            target: ml.LatLng(centro.latitude, centro.longitude),
            zoom: _zoomVista(),
          ),
          minMaxZoomPreference: const ml.MinMaxZoomPreference(6.5, 17.0),
          onMapCreated: (controller) async {
            _controller = controller;
            _mapaListo = true;
            _firmaVista ??= _firmaActual();

            // FASE 3: Geometría
            await _cargarCapasGeometria(controller);

            // FASE 4: Marcadores Clustering
            await _cargarMarcadoresClustering(controller);

            // FASE 5: Capas interactivas
            await _cargarCapasInteractivas(controller);
          },
          onStyleLoadedCallback: () async {
            // Cuando se cambia entre Liberty y Positron, MapLibre limpia todas las capas personalizadas.
            // Es vital recargarlas aquí para evitar que el mapa quede vacío.
            if (_controller != null && _mapaListo) {
              await _cargarCapasGeometria(_controller!);
              await _cargarMarcadoresClustering(_controller!);
              await _cargarCapasInteractivas(_controller!);
              await _actualizarGeometria(_controller!);
            }
          },
          onMapClick: (point, latLng) async {
            // Se delegó toda la lógica al Listener (Escudo Táctil Transparente) superior
            // para evitar los bugs nativos de consumo de eventos táctiles.
          },
        ),

        // 2. Escudo Táctil Transparente (Detector Inteligente con Tolerancia a Dedos)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (e) async {
              if (_controller == null) return;

              // Convertimos píxeles a lat/lng usando el motor de MapLibre
              final point = math.Point<num>(
                e.localPosition.dx,
                e.localPosition.dy,
              );
              LatLng latLng;
              try {
                final pos = await _controller!.toLatLng(point);
                latLng = LatLng(pos.latitude, pos.longitude);
              } catch (_) {
                return;
              }

              // 1. Detectar si el usuario tocó un Cluster nativo primero
              final rectCluster = Rect.fromCenter(
                center: e.localPosition,
                width: 70.0,
                height: 70.0,
              );

              try {
                final clusterFeatures = await _controller!
                    .queryRenderedFeaturesInRect(rectCluster, [
                      "capa_clusters",
                    ], null);

                if (clusterFeatures.isNotEmpty) {
                  HapticFeedback.selectionClick();
                  final currentZoom = _controller!.cameraPosition?.zoom ?? 10;
                  _moverSeguro(
                    LatLng(latLng.latitude, latLng.longitude),
                    currentZoom + 2.0,
                  );
                  return; // Fin del hilo. Tocó un clúster.
                }
              } catch (_) {
                // Ignoramos fallos nativos al leer el clúster.
              }

              // 2. Matemática Pura para los lugares
              final tapPoint = LatLng(latLng.latitude, latLng.longitude);
              final distanciaMath = const Distance();
              final currentZoom = _controller!.cameraPosition?.zoom ?? 10.0;

              // Fórmula Web Mercator (metros por píxel en este zoom/latitud)
              final metrosPorPixel =
                  156543.03392 *
                  math.cos(latLng.latitude * math.pi / 180.0) /
                  math.pow(2, currentZoom);

              // Radio imán ampliado: 60 píxeles de tolerancia (120px de diámetro, enorme)
              final radioToleranciaMetros = 60.0 * metrosPorPixel;

              double menorDistancia = double.infinity;
              ModeloLugar? lugarMasCercano;

              for (final lugar in widget.lugares) {
                final d = distanciaMath.distance(
                  tapPoint,
                  LatLng(lugar.latitud, lugar.longitud),
                );
                if (d < menorDistancia) {
                  menorDistancia = d;
                  lugarMasCercano = lugar;
                }
              }

              // 3. Evaluar resultado matemático
              if (lugarMasCercano != null &&
                  menorDistancia <= radioToleranciaMetros) {
                HapticFeedback.selectionClick();
                widget.onLugarSeleccionado(lugarMasCercano);
                _moverSeguro(
                  LatLng(lugarMasCercano.latitud, lugarMasCercano.longitud),
                  _controller!.cameraPosition?.zoom ?? 14.5,
                );
              } else {
                widget.onLugarSeleccionado(null); // Tocó fondo vacío
              }
            },
          ),
        ),

        // FASE 5: Aquí colocaremos el Overlay (cajita) del pin seleccionado en el futuro.
      ],
    );
  }
}
