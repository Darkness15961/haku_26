import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_map/flutter_map.dart'; // Eliminado
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:latlong2/latlong.dart';

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
    this.estiloMapa = 'https://tiles.openfreemap.org/styles/liberty',
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

class MapaExploraLugaresState extends State<MapaExploraLugares> with SingleTickerProviderStateMixin {
  ml.MapLibreMapController? _controller;
  String? _firmaVista;
  var _mapaListo = false;
  AnimationController? _animController;
  Animation<double>? _radioAnimacion;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController!.addListener(() {
      if (_controller != null && widget.mostrarRadioCerca && widget.ubicacionUsuario != null) {
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

    final empezoMostrarRadio = widget.mostrarRadioCerca && !oldWidget.mostrarRadioCerca;
    final cambioRadio = widget.mostrarRadioCerca && oldWidget.mostrarRadioCerca && widget.radioCercaM != oldWidget.radioCercaM;
    
    if (empezoMostrarRadio) {
      _radioAnimacion = Tween<double>(begin: 0.0, end: widget.radioCercaM)
          .animate(CurvedAnimation(parent: _animController!, curve: Curves.easeOutCirc));
      _animController!.forward(from: 0.0);
    } else if (cambioRadio) {
      final radioActual = _radioAnimacion?.value ?? oldWidget.radioCercaM;
      _radioAnimacion = Tween<double>(begin: radioActual, end: widget.radioCercaM)
          .animate(CurvedAnimation(parent: _animController!, curve: Curves.easeOutCirc));
      _animController!.forward(from: 0.0);
    }

    final firma = _firmaActual();
    if (firma != _firmaVista) {
      _firmaVista = firma;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _moverSeguro(_centroVista(), _zoomVista());
        if (_controller != null) {
          _actualizarGeometria(_controller!);
        }
      });
    }
  }

  String _firmaActual() {
    final u = widget.ubicacionUsuario;
    final uid = u == null ? '-' : '${u.latitude},${u.longitude}';
    final ids = widget.lugares.map((l) => l.id).join(',');
    return '$uid|${widget.mostrarRadioCerca}|${widget.radioCercaM}|$ids|${widget.preparandoRadar}';
  }

  LatLng _centroVista() {
    if ((widget.mostrarRadioCerca || widget.preparandoRadar) && widget.ubicacionUsuario != null) {
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
      return 9.6; // Zoom óptimo para ver el radar de 50km entero al nacer
    }
    if (widget.mostrarRadioCerca && widget.ubicacionUsuario != null) {
      if (widget.radioCercaM <= 30000) return 10.6;
      if (widget.radioCercaM <= 40000) return 10.4;
      return 10.1;
    }
    if (widget.lugares.length <= 1) return 11;
    if (widget.lugares.length <= 5) return 10;
    return widget.zoomInicial;
  }

  void _moverSeguro(LatLng centro, double zoom) {
    if (!_mapaListo || _controller == null) return;
    try {
      _controller!.animateCamera(ml.CameraUpdate.newCameraPosition(
        ml.CameraPosition(
          target: ml.LatLng(centro.latitude, centro.longitude),
          zoom: zoom,
        ),
      ));
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
       (coordList.first[0] != coordList.last[0] || coordList.first[1] != coordList.last[1])) {
      coordList.add(coordList.first);
    }
    return {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "Polygon",
            "coordinates": [coordList]
          }
        }
      ]
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
      final double latRad = math.asin(math.sin(lat) * math.cos(d) +
          math.cos(lat) * math.sin(d) * math.cos(brng));
      final double lngRad = lng +
          math.atan2(math.sin(brng) * math.sin(d) * math.cos(lat),
              math.cos(d) - math.sin(lat) * math.sin(latRad));
      coordenadas.add([lngRad * 180.0 / math.pi, latRad * 180.0 / math.pi]);
    }

    return {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "Polygon",
            "coordinates": [coordenadas]
          }
        }
      ]
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
      await controller.setGeoJsonSource(
        "fuente_radio",
        {"type": "FeatureCollection", "features": []},
      );
    }

    // Actualizar marcadores si cambia la lista
    await controller.setGeoJsonSource(
      "fuente_lugares",
      _crearLugaresGeoJson(widget.lugares),
    );

    // Actualizar marcador de usuario
    if (usuario != null) {
      await controller.setGeoJsonSource(
        "fuente_usuario",
        {
          "type": "FeatureCollection",
          "features": [{
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": [usuario.longitude, usuario.latitude]
            }
          }]
        }
      );
    } else {
      await controller.setGeoJsonSource("fuente_usuario", {"type": "FeatureCollection", "features": []});
    }
  }

  Future<void> _cargarCapasGeometria(ml.MapLibreMapController controller) async {
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
      ml.LineLayerProperties(lineColor: colorOroHex, lineOpacity: 0.85, lineWidth: 2.4),
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
      ml.LineLayerProperties(lineColor: colorOroHex, lineOpacity: 0.55, lineWidth: 1.6),
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

  Map<String, dynamic> _crearLugaresGeoJson(List<ModeloLugar> lugares) {
    return {
      "type": "FeatureCollection",
      "features": lugares.map((l) {
        final hueco = l.nivelExploracion == NivelExploracion.pocoExplorado ||
            l.nivelExploracion == NivelExploracion.nuevoEnHaku;
        return {
          "type": "Feature",
          "id": l.id,
          "properties": {
            "id": l.id,
            "icono": hueco ? "pin_oro" : "pin_plomo",
            "nombre": l.nombre
          },
          "geometry": {
            "type": "Point",
            "coordinates": [l.longitud, l.latitud]
          }
        };
      }).toList()
    };
  }

  Future<void> _cargarMarcadoresClustering(ml.MapLibreMapController controller) async {
    // 1. Generar iconos y registrarlos en la tarjeta gráfica (Memoria)
    final oroBytes = await _crearIconoMemoria(Icons.location_on, PaletaRutas.oro);
    final plomoBytes = await _crearIconoMemoria(Icons.location_on, PaletaRutas.plomoOscuro);
    
    await controller.addImage("pin_oro", oroBytes);
    await controller.addImage("pin_plomo", plomoBytes);

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
    final colorOroHex = '#${PaletaRutas.oro.toARGB32().toRadixString(16).substring(2, 8)}';
    await controller.addCircleLayer(
      "fuente_lugares",
      "capa_clusters",
      ml.CircleLayerProperties(
        circleColor: colorOroHex,
        circleRadius: [
          'step', ['get', 'point_count'],
          20, 10, 
          25, 50, 
          30
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
        iconImage: '{icono}', // Lee de las properties (pin_oro o pin_plomo)
        iconSize: 0.8,
        iconAllowOverlap: true,
        iconAnchor: 'bottom', // Para que la punta del pin apunte a la coordenada
      ),
      filter: ['!', ['has', 'point_count']],
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


  Future<void> _cargarCapasInteractivas(ml.MapLibreMapController controller) async {
    // Capa de Usuario
    final userBytes = await _crearMarcadorUsuarioMemoria();
    await controller.addImage("img_usuario", userBytes);
    
    final usuario = widget.ubicacionUsuario;
    await controller.addSource("fuente_usuario", ml.GeojsonSourceProperties(
      data: (usuario != null) ? {
        "type": "FeatureCollection",
        "features": [{
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [usuario.longitude, usuario.latitude]
          }
        }]
      } : {"type": "FeatureCollection", "features": []}
    ));
    await controller.addSymbolLayer("fuente_usuario", "capa_usuario", ml.SymbolLayerProperties(
      iconImage: "img_usuario",
      iconSize: 1.0,
      iconAllowOverlap: true,
      symbolSortKey: 10, // Asegura que el usuario se dibuje encima de otros
    ));
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
            if (_controller == null) return;
            // Consultar si tocamos un pin interactivo
            final features = await _controller!.queryRenderedFeatures(
              point,
              ["capa_pines_individuales"],
              null,
            );

            if (features.isNotEmpty) {
              final capaTocada = features.first['layer']['id'];
              final props = features.first['properties'];

              if (capaTocada == "capa_pines_individuales") {
                // Tocó un pin -> Seleccionar y mostrar modal Flutter
                HapticFeedback.selectionClick();
                final id = props['id'];
                ModeloLugar? lugar;
                try {
                  lugar = widget.lugares.firstWhere((l) => l.id == id);
                } catch (_) {}

                if (lugar != null) {
                  widget.onLugarSeleccionado(lugar);
                  // Opcional: Centrar cámara
                  _moverSeguro(LatLng(lugar.latitud, lugar.longitud), 14.5);
                }
              }
            } else {
              // Tocó fondo vacío -> Limpiar selección modal
              widget.onLugarSeleccionado(null);
            }
          },
        ),
        
        // FASE 5: Aquí colocaremos el Overlay (cajita) del pin seleccionado en el futuro.
      ],
    );
  }
}
