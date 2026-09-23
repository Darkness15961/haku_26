import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../nucleo/mapas/mapa_marcador_haku.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/contenido_chat_especial.dart';

/// Preview liviano de ubicación (sin mapa en el ListView — evita jank).
/// Tap → diálogo con mapa OSM.
class BurbujaUbicacionChat extends StatelessWidget {
  const BurbujaUbicacionChat({
    super.key,
    required this.ubicacion,
    this.sobreOscuro = true,
  });

  final ContenidoUbicacionChat ubicacion;
  final bool sobreOscuro;

  Future<void> _abrirMapa(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final punto = LatLng(ubicacion.lat, ubicacion.lng);
        return AlertDialog(
          backgroundColor: PaletaRutas.carbon,
          title: Text(
            ubicacion.label,
            style: TipografiaHaku.titulo(
              fontSize: 16,
              color: PaletaRutas.piedra,
            ),
          ),
          content: SizedBox(
            width: 320,
            height: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MapaMarcadorHaku(
                punto: punto,
                zoom: 15,
                color: const Color(0xFFE53935),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cerrar',
                style: TipografiaHaku.interfaz(color: PaletaRutas.oro),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fg = sobreOscuro ? PaletaRutas.piedra : PaletaRutas.ink;
    final muted = sobreOscuro ? PaletaRutas.plomoClaro : PaletaRutas.plomo;

    return InkWell(
      onTap: () => _abrirMapa(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: PaletaRutas.ink.withValues(alpha: sobreOscuro ? 0.35 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: PaletaRutas.plomoOscuro.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: PaletaRutas.oro, size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ubicacion.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TipografiaHaku.interfaz(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  Text(
                    'Tocá para ver el mapa',
                    style: TipografiaHaku.interfaz(fontSize: 10, color: muted),
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
