import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelos/modelo_lugar.dart';

/// Mapa interactivo con marcadores de lugares.
class MapaExploraLugares extends StatefulWidget {
  const MapaExploraLugares({
    super.key,
    required this.lugares,
    required this.onTap,
  });

  final List<ModeloLugar> lugares;
  final ValueChanged<String> onTap;

  static const _centroCusco = LatLng(-13.52, -71.97);

  @override
  State<MapaExploraLugares> createState() => _EstadoMapaExploraLugares();
}

class _EstadoMapaExploraLugares extends State<MapaExploraLugares> {
  final _controller = MapController();
  String? _seleccionadoId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LatLng _centroLista() {
    if (widget.lugares.isEmpty) return MapaExploraLugares._centroCusco;
    final lat =
        widget.lugares.map((l) => l.latitud).reduce((a, b) => a + b) /
            widget.lugares.length;
    final lng =
        widget.lugares.map((l) => l.longitud).reduce((a, b) => a + b) /
            widget.lugares.length;
    return LatLng(lat, lng);
  }

  String _nombreCorto(String nombre) {
    if (nombre.length <= 22) return nombre;
    return '${nombre.substring(0, 20)}…';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lugares.isEmpty) {
      return ColoredBox(
        color: PaletaRutas.carbon,
        child: Center(
          child: Text(
            'Sin lugares en el mapa',
            style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: _centroLista(),
        initialZoom: 8.6,
        minZoom: 7,
        maxZoom: 16,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
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
        MarkerLayer(
          markers: [
            for (final l in widget.lugares)
              Marker(
                point: LatLng(l.latitud, l.longitud),
                width: _seleccionadoId == l.id ? 148 : 40,
                height: _seleccionadoId == l.id ? 70 : 40,
                alignment: Alignment.topCenter,
                child: _PinLugar(
                  lugar: l,
                  seleccionado: _seleccionadoId == l.id,
                  nombreCorto: _nombreCorto(l.nombre),
                  onTap: () {
                    setState(() => _seleccionadoId = l.id);
                    widget.onTap(l.id);
                  },
                  onSeleccionar: () {
                    setState(() => _seleccionadoId = l.id);
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PinLugar extends StatelessWidget {
  const _PinLugar({
    required this.lugar,
    required this.seleccionado,
    required this.nombreCorto,
    required this.onTap,
    required this.onSeleccionar,
  });

  final ModeloLugar lugar;
  final bool seleccionado;
  final String nombreCorto;
  final VoidCallback onTap;
  final VoidCallback onSeleccionar;

  @override
  Widget build(BuildContext context) {
    final hueco =
        lugar.nivelExploracion == NivelExploracion.pocoExplorado ||
            lugar.nivelExploracion == NivelExploracion.nuevoEnHaku;
    final colorPin = hueco ? PaletaRutas.oro : PaletaRutas.plomoOscuro;

    return GestureDetector(
      onTap: () {
        onSeleccionar();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (seleccionado)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: PaletaRutas.ink,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PaletaRutas.oro),
              ),
              child: Text(
                nombreCorto,
                maxLines: 1,
                softWrap: false,
                style: TipografiaHaku.interfaz(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.piedra,
                ),
              ),
            ),
          Icon(
            Icons.location_on,
            size: seleccionado ? 36 : 32,
            color: colorPin,
          ),
        ],
      ),
    );
  }
}
