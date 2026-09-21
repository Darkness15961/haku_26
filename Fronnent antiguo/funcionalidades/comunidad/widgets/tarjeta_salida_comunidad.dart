import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/salidas_datasource_local.dart';
import '../pantallas/pantalla_salidas.dart';

/// Tarjeta compacta de salida (cuando no hay invitación en el feed).
class TarjetaSalidaComunidad extends StatelessWidget {
  const TarjetaSalidaComunidad({
    super.key,
    required this.salida,
    required this.indice,
  });

  final ModeloSalida salida;
  final int indice;

  @override
  Widget build(BuildContext context) {
    final fecha = '${salida.fecha.day}/${salida.fecha.month} · ${salida.hora}';
    final cuposMax = salida.cuposTotales;
    final lleno = salida.inscritos >= cuposMax;
    final colorCupos = lleno ? PaletaRutas.plomoOscuro : PaletaRutas.oro;
    final colorTextoCupos = lleno ? PaletaRutas.plomoClaro : PaletaRutas.ink;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PantallaDetalleSalida(salidaId: salida.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: PaletaRutas.ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.hiking_rounded,
                    color: PaletaRutas.oro,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salida.lugarNombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.titulo(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$fecha · ${salida.puntoEncuentro}',
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorCupos,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    lleno ? 'Lleno' : '${salida.inscritos}/$cuposMax',
                    style: TipografiaHaku.interfaz(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorTextoCupos,
                    ),
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
