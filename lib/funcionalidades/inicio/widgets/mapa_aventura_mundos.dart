import 'package:flutter/material.dart';

import '../datos/mapa_aventura_datasource_local.dart';
import 'camino_punteado_aventura.dart';
import 'nodo_destino_aventura.dart';

/// Mapa a pantalla completa: provincias repartidas en todo el lienzo.
class MapaAventuraMundos extends StatelessWidget {
  final List<NodoMapaAventura> nodos;
  final List<AristaMapaAventura> aristas;
  final String idSeleccionado;
  final ValueChanged<String> onSeleccionar;
  /// Espacio inferior reservado (joystick / barra).
  final double paddingInferior;

  const MapaAventuraMundos({
    super.key,
    required this.nodos,
    required this.aristas,
    required this.idSeleccionado,
    required this.onSeleccionar,
    this.paddingInferior = 130,
  });

  @override
  Widget build(BuildContext context) {
    final porId = {for (final n in nodos) n.id: n};

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final alto =
            (constraints.maxHeight - paddingInferior).clamp(280.0, 900.0);
        // Provincias un poco más compactas para que entren bien.
        final escalaNodo = ((ancho / 400) * (alto / 560)).clamp(0.38, 0.52);
        final mitadW = 70 * escalaNodo;
        final mitadH = 54 * escalaNodo;

        // Márgenes suficientes para que nodos+etiqueta no se corten ni
        // se acerquen al joystick; el área ya empieza bajo el encabezado.
        final margenX = mitadW * 0.7 + 6;
        final margenY = mitadH * 0.78 + 8;
        final utilAncho = (ancho - margenX * 2).clamp(1.0, ancho);
        final utilAlto = (alto - margenY * 2).clamp(1.0, alto);

        Offset puntoDe(Offset normalizado) => Offset(
              margenX + normalizado.dx * utilAncho,
              margenY + normalizado.dy * utilAlto,
            );

        return Padding(
          padding: EdgeInsets.only(bottom: paddingInferior),
          child: SizedBox(
            width: ancho,
            height: alto,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (final arista in aristas)
                  if (porId.containsKey(arista.desdeId) &&
                      porId.containsKey(arista.hastaId))
                    Positioned.fill(
                      child: CaminoPunteadoAventura(
                        desde: puntoDe(porId[arista.desdeId]!.posicion),
                        hasta: puntoDe(porId[arista.hastaId]!.posicion),
                        resaltado: arista.desdeId == idSeleccionado ||
                            arista.hastaId == idSeleccionado,
                      ),
                    ),
                for (final nodo in nodos)
                  Positioned(
                    left: puntoDe(nodo.posicion).dx - mitadW,
                    top: puntoDe(nodo.posicion).dy - mitadH,
                    width: mitadW * 2,
                    child: NodoDestinoAventura(
                      nodo: nodo,
                      seleccionado: nodo.id == idSeleccionado,
                      escala: escalaNodo,
                      onTap: () => onSeleccionar(nodo.id),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
