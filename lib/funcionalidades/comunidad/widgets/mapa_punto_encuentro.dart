import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../lugares/datos/coordenadas_lugares_cusco.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/salidas_datasource_local.dart';

/// Coordenadas del punto de encuentro de una salida.
abstract final class CoordenadasEncuentroSalida {
  static const _plazaArmas = LatLng(-13.5167, -71.9788);
  static const _cristoBlanco = LatLng(-13.5083, -71.9728);
  static const _sanFrancisco = LatLng(-13.5175, -71.9805);
  static const _oropesa = LatLng(-13.5940, -71.7630);
  static const _maras = LatLng(-13.3350, -72.1560);
  static const _qorikancha = LatLng(-13.5205, -71.9755);
  static const _cuscoCentro = LatLng(-13.5160, -71.9785);

  static LatLng deSalida(ModeloSalida s) {
    final p = s.puntoEncuentro.toLowerCase();
    if (p.contains('plaza de armas')) return _plazaArmas;
    if (p.contains('cristo blanco')) return _cristoBlanco;
    if (p.contains('san francisco')) return _sanFrancisco;
    if (p.contains('oropesa')) return _oropesa;
    if (p.contains('maras')) return _maras;
    if (p.contains('qorikancha') || p.contains('qoricancha')) {
      return _qorikancha;
    }
    if (p.contains('cusco') || p.contains('centro')) return _cuscoCentro;

    final lugar = CoordenadasLugaresCusco.porId[s.lugarId];
    if (lugar != null) return LatLng(lugar.$1, lugar.$2);
    return _plazaArmas;
  }
}

/// Mapa estilo OSM/Google con el punto de encuentro marcado.
class MapaPuntoEncuentro extends StatelessWidget {
  const MapaPuntoEncuentro({
    super.key,
    required this.salida,
    this.altura = 200,
  });

  final ModeloSalida salida;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final punto = CoordenadasEncuentroSalida.deSalida(salida);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: altura,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: punto,
                initialZoom: 15.2,
                minZoom: 12,
                maxZoom: 18,
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
                  retinaMode: RetinaMode.isHighDensity(context),
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: punto,
                      width: 48,
                      height: 48,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        size: 44,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: PaletaRutas.ink.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: PaletaRutas.oro.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.place,
                      size: 16,
                      color: Color(0xFFE53935),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Encuentro: ${salida.puntoEncuentro}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
