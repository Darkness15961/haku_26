import 'package:flutter/material.dart';

import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/responsive/espacio_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/salidas_datasource_local.dart';
import '../pantallas/pantalla_salidas.dart';

/// Tarjeta de salida (con foto del lugar; sin invitación de feed).
class TarjetaSalidaComunidad extends StatelessWidget {
  const TarjetaSalidaComunidad({
    super.key,
    required this.salida,
    required this.indice,
    this.enRejilla = false,
    this.omitirPadding = false,
  });

  final ModeloSalida salida;
  final int indice;
  final bool enRejilla;
  final bool omitirPadding;

  @override
  Widget build(BuildContext context) {
    final fecha = '${salida.fecha.day}/${salida.fecha.month} · ${salida.hora}';
    final cuposMax = salida.cuposTotales;
    final lleno = salida.inscritos >= cuposMax;
    final colorCupos = lleno ? PaletaRutas.plomoOscuro : PaletaRutas.oro;
    final colorTextoCupos = lleno ? PaletaRutas.plomoClaro : PaletaRutas.ink;
    final imagen = CatalogoImagenesHaku.imagenDescubiertoComunidad(
      lugarId: salida.lugarId,
      provincia: '',
    );

    final meta = Padding(
      padding: EdgeInsets.all(enRejilla ? 10 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  salida.lugarNombre,
                  maxLines: enRejilla ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TipografiaHaku.titulo(
                    fontSize: enRejilla ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    color: PaletaRutas.piedra,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorCupos,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  lleno ? 'Lleno' : '${salida.inscritos}/$cuposMax',
                  style: TipografiaHaku.interfaz(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: colorTextoCupos,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$fecha · ${salida.puntoEncuentro}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TipografiaHaku.interfaz(
              fontSize: 11,
              color: PaletaRutas.plomoClaro,
            ),
          ),
        ],
      ),
    );

    final card = Material(
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
        child: enRejilla
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ImagenHaku(url: imagen, fit: BoxFit.cover),
                  ),
                  const LineaEncabezadoInca(altura: 2.5),
                  meta,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 2.2,
                    child: ImagenHaku(url: imagen, fit: BoxFit.cover),
                  ),
                  const LineaEncabezadoInca(altura: 2.5),
                  meta,
                ],
              ),
      ),
    );

    if (enRejilla || omitirPadding) return card;

    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: EspacioHaku.horizontal(context)),
      child: card,
    );
  }
}
