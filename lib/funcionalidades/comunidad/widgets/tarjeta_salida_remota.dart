import 'package:flutter/material.dart';

import '../../../nucleo/responsive/espacio_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../dominio/modelo_salida.dart';
import '../pantallas/pantalla_detalle_salida_remota.dart';

/// Tarjeta de salida remota — mismo lenguaje visual que el listado original.
class TarjetaSalidaRemota extends StatelessWidget {
  const TarjetaSalidaRemota({
    super.key,
    required this.salida,
    this.enRejilla = false,
    this.omitirPadding = false,
  });

  final ModeloSalidaRemota salida;
  final bool enRejilla;
  final bool omitirPadding;

  @override
  Widget build(BuildContext context) {
    final lleno = salida.llena;
    final colorCupos = lleno ? PaletaRutas.plomoOscuro : PaletaRutas.oro;
    final colorTextoCupos = lleno ? PaletaRutas.plomoClaro : PaletaRutas.ink;
    final foto = salida.lugarFotoPortada?.trim() ?? '';

    Widget portada() {
      if (foto.isEmpty) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                PaletaRutas.carbon,
                PaletaRutas.ink,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.directions_walk_rounded,
              color: PaletaRutas.plomoOscuro.withValues(alpha: 0.6),
              size: 36,
            ),
          ),
        );
      }
      return ImagenHaku(url: foto, fit: BoxFit.cover);
    }

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
                  salida.etiquetaPrincipal,
                  maxLines: enRejilla ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TipografiaHaku.titulo(
                    fontSize: enRejilla ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    color: PaletaRutas.piedra,
                    height: 1.1,
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
                  lleno
                      ? 'Lleno'
                      : '${salida.inscritos}/${salida.cuposTotales}',
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
            '${salida.fechaHoraEtiqueta} · ${salida.puntoEncuentroEtiqueta}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TipografiaHaku.interfaz(
              fontSize: 11,
              color: PaletaRutas.plomoClaro,
            ),
          ),
          if (salida.comunidadNombre != null &&
              salida.comunidadNombre!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.groups_outlined, size: 14, color: PaletaRutas.oro),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    salida.comunidadNombre!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TipografiaHaku.interfaz(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.oro,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
              builder: (_) => PantallaDetalleSalidaRemota(salidaId: salida.id),
            ),
          );
        },
        // Portrait: fila ordenada (como comunidades). Landscape grid: foto arriba.
        child: enRejilla
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: portada()),
                  const LineaEncabezadoInca(altura: 2.5),
                  meta,
                ],
              )
              : SizedBox(
                  height: 116,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _FranjaSalida(),
                      SizedBox(width: 104, child: portada()),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: meta,
                        ),
                      ),
                    ],
                  ),
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

class _FranjaSalida extends StatelessWidget {
  const _FranjaSalida();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PaletaRutas.oro,
              Color(0x55D4C4A8),
              PaletaRutas.plomoOscuro,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
