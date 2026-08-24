import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelos/modelo_lugar.dart';

/// Mapa interactivo estilo Google Maps con marcadores de lugares.
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
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.haku.app',
        ),
        MarkerLayer(
          markers: [
            for (final l in widget.lugares)
              Marker(
                point: LatLng(l.latitud, l.longitud),
                width: 120,
                height: 72,
                alignment: Alignment.topCenter,
                child: _PinLugar(
                  lugar: l,
                  onTap: () => widget.onTap(l.id),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PinLugar extends StatelessWidget {
  const _PinLugar({required this.lugar, required this.onTap});

  final ModeloLugar lugar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hueco =
        lugar.nivelExploracion == NivelExploracion.pocoExplorado ||
            lugar.nivelExploracion == NivelExploracion.nuevoEnHaku;
    final colorPin = hueco ? PaletaRutas.oro : PaletaRutas.plomoOscuro;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: PaletaRutas.ink.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: PaletaRutas.oro.withValues(alpha: 0.4)),
            ),
            child: Text(
              lugar.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TipografiaHaku.interfaz(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Icon(Icons.location_on, size: 34, color: colorPin),
        ],
      ),
    );
  }
}
