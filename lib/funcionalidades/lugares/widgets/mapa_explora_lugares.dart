import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelos/modelo_lugar.dart';

/// Mapa Explora: contorno Cusco, GPS del turista, radio 50 km y pines.
class MapaExploraLugares extends StatefulWidget {
  const MapaExploraLugares({
    super.key,
    required this.lugares,
    required this.onAbrirLugar,
    this.ubicacionUsuario,
    this.mostrarRadioCerca = false,
    this.radioCercaM = 50000,
    this.contornoCusco = const [],
    this.centroInicial,
    this.zoomInicial = 9.2,
  });

  final List<ModeloLugar> lugares;
  final ValueChanged<String> onAbrirLugar;
  final LatLng? ubicacionUsuario;
  final bool mostrarRadioCerca;
  final double radioCercaM;
  final List<LatLng> contornoCusco;
  final LatLng? centroInicial;
  final double zoomInicial;

  static const centroCusco = LatLng(-13.5167, -71.9788);

  @override
  State<MapaExploraLugares> createState() => MapaExploraLugaresState();
}

class MapaExploraLugaresState extends State<MapaExploraLugares> {
  final _controller = MapController();
  String? _seleccionadoId;
  String? _firmaVista;
  var _mapaListo = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MapaExploraLugares oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si el pin seleccionado ya no está en la lista (cambio de filtro), limpiar.
    if (_seleccionadoId != null &&
        !widget.lugares.any((l) => l.id == _seleccionadoId)) {
      _seleccionadoId = null;
    }

    final firma = _firmaActual();
    if (firma != _firmaVista) {
      _firmaVista = firma;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _moverSeguro(_centroVista(), _zoomVista());
      });
    }
  }

  String _firmaActual() {
    final u = widget.ubicacionUsuario;
    final uid = u == null ? '-' : '${u.latitude},${u.longitude}';
    final ids = widget.lugares.map((l) => l.id).join(',');
    return '$uid|${widget.mostrarRadioCerca}|$ids';
  }

  LatLng _centroVista() {
    if (widget.mostrarRadioCerca && widget.ubicacionUsuario != null) {
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
    if (widget.mostrarRadioCerca && widget.ubicacionUsuario != null) {
      return 10.2;
    }
    if (widget.lugares.length <= 1) return 11;
    if (widget.lugares.length <= 5) return 10;
    return widget.zoomInicial;
  }

  String _nombreCorto(String nombre) {
    if (nombre.length <= 22) return nombre;
    return '${nombre.substring(0, 20)}…';
  }

  void _moverSeguro(LatLng centro, double zoom) {
    if (!_mapaListo) return;
    try {
      _controller.move(centro, zoom);
    } catch (_) {
      // MapController aún no listo o ya disposed.
    }
  }

  void recentrarEnUsuario() {
    final u = widget.ubicacionUsuario;
    if (u == null) return;
    _moverSeguro(u, widget.mostrarRadioCerca ? 10.2 : 12);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.ubicacionUsuario;
    final oro = PaletaRutas.oro;

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: _centroVista(),
        initialZoom: _zoomVista(),
        minZoom: 6.5,
        maxZoom: 17,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onMapReady: () {
          _mapaListo = true;
          _firmaVista ??= _firmaActual();
        },
        onTap: (_, __) => setState(() => _seleccionadoId = null),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.haku.app',
          retinaMode: RetinaMode.isHighDensity(context),
        ),
        if (widget.contornoCusco.length >= 3)
          PolygonLayer(
            polygons: [
              Polygon(
                points: widget.contornoCusco,
                color: oro.withValues(alpha: 0.06),
                borderColor: oro.withValues(alpha: 0.85),
                borderStrokeWidth: 2.4,
              ),
            ],
          ),
        if (widget.mostrarRadioCerca && usuario != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: usuario,
                radius: widget.radioCercaM,
                useRadiusInMeter: true,
                color: oro.withValues(alpha: 0.10),
                borderColor: oro.withValues(alpha: 0.55),
                borderStrokeWidth: 1.6,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (usuario != null)
              Marker(
                point: usuario,
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: const _MarcadorUsuario(),
              ),
            for (final l in widget.lugares)
              Marker(
                point: LatLng(l.latitud, l.longitud),
                width: _seleccionadoId == l.id ? 168 : 40,
                height: _seleccionadoId == l.id ? 92 : 40,
                alignment: Alignment.topCenter,
                child: _PinLugar(
                  lugar: l,
                  seleccionado: _seleccionadoId == l.id,
                  nombreCorto: _nombreCorto(l.nombre),
                  onSeleccionar: () {
                    HapticFeedback.selectionClick();
                    setState(() => _seleccionadoId = l.id);
                  },
                  onAbrir: () {
                    HapticFeedback.lightImpact();
                    widget.onAbrirLugar(l.id);
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MarcadorUsuario extends StatelessWidget {
  const _MarcadorUsuario();

  @override
  Widget build(BuildContext context) {
    // Punto “estoy aquí”: anillo + núcleo oro bien visibles sobre el mapa.
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PaletaRutas.oro.withValues(alpha: 0.22),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PaletaRutas.oro,
              border: Border.all(color: PaletaRutas.piedra, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: PaletaRutas.ink.withValues(alpha: 0.45),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: PaletaRutas.ink,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinLugar extends StatelessWidget {
  const _PinLugar({
    required this.lugar,
    required this.seleccionado,
    required this.nombreCorto,
    required this.onSeleccionar,
    required this.onAbrir,
  });

  final ModeloLugar lugar;
  final bool seleccionado;
  final String nombreCorto;
  final VoidCallback onSeleccionar;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final hueco =
        lugar.nivelExploracion == NivelExploracion.pocoExplorado ||
            lugar.nivelExploracion == NivelExploracion.nuevoEnHaku;
    final colorPin = hueco ? PaletaRutas.oro : PaletaRutas.plomoOscuro;

    // Bubbles e icono separados: evita double-tap / Flexible en Row min.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (seleccionado)
          Material(
            color: PaletaRutas.ink,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onAbrir,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 156),
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PaletaRutas.oro),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        nombreCorto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.interfaz(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: PaletaRutas.oro,
                    ),
                  ],
                ),
              ),
            ),
          ),
        GestureDetector(
          onTap: seleccionado ? onAbrir : onSeleccionar,
          child: Icon(
            Icons.location_on,
            size: seleccionado ? 36 : 32,
            color: colorPin,
          ),
        ),
      ],
    );
  }
}
