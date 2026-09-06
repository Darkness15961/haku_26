import 'package:flutter/material.dart';

import '../../../nucleo/responsive/espacio_haku.dart';
import '../../../nucleo/widgets/badge_contador.dart';
import '../../rutas/widgets/estilos_rutas.dart';

/// Ítem de la barra inferior.
class ItemBarraNavegacion {
  final IconData iconoNormal;
  final IconData iconoActivo;
  final String etiqueta;
  final bool esCentral;

  const ItemBarraNavegacion({
    required this.iconoNormal,
    required this.iconoActivo,
    required this.etiqueta,
    this.esCentral = false,
  });
}

/// Barra flat dark (estilo discovery) — acento oro en activo / +.
class BarraNavegacionCurva extends StatelessWidget {
  final int indiceActual;
  final List<ItemBarraNavegacion> items;
  final ValueChanged<int> onCambiar;
  /// Misma longitud que [items]: badge numérico en ese ítem (0 = oculto).
  final List<int> contadorPorIndice;
  /// Landscape / altura corta: menos padding y sin etiquetas.
  final bool compacta;

  const BarraNavegacionCurva({
    super.key,
    required this.indiceActual,
    required this.items,
    required this.onCambiar,
    this.contadorPorIndice = const [],
    this.compacta = false,
  });

  int _contador(int index) =>
      index < contadorPorIndice.length ? contadorPorIndice[index] : 0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final escala = EspacioHaku.escala(context);
    final altoBarra = compacta
        ? 48.0
        : (EspacioHaku.esTablet(context) ? 66.0 : 58.0);
    final tamFab = (compacta ? 38.0 : 44.0) * escala.clamp(1.0, 1.12);
    final tamIcono = EspacioHaku.sp(context, compacta ? 20 : 22);
    final tamEtiqueta = EspacioHaku.sp(context, 10);
    final mostrarEtiquetas = !compacta;

    return ColoredBox(
      color: PaletaRutas.ink,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 0.6,
            color: PaletaRutas.plomoOscuro.withValues(alpha: 0.55),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: bottomInset,
              top: compacta ? 2 : 6,
            ),
            child: SizedBox(
              height: altoBarra,
              child: Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final esActivo = indiceActual == index;
                  final contador = _contador(index);

                  if (item.esCentral) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onCambiar(index),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: tamFab,
                              height: tamFab,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: PaletaRutas.oro,
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                color: PaletaRutas.ink,
                                size: (compacta ? 24 : 28) *
                                    escala.clamp(1.0, 1.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final color =
                      esActivo ? PaletaRutas.piedra : PaletaRutas.plomo;
                  final icono = BadgeContadorOverlay(
                    cantidad: contador,
                    compacto: true,
                    child: Icon(
                      esActivo ? item.iconoActivo : item.iconoNormal,
                      color: color,
                      size: tamIcono,
                    ),
                  );

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onCambiar(index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          icono,
                          if (mostrarEtiquetas) ...[
                            const SizedBox(height: 3),
                            Text(
                              item.etiqueta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TipografiaHaku.interfaz(
                                fontSize: tamEtiqueta,
                                fontWeight: esActivo
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ],
                          if (esActivo)
                            Container(
                              margin: EdgeInsets.only(top: mostrarEtiquetas ? 3 : 4),
                              width: 12,
                              height: 2,
                              color: PaletaRutas.oro,
                            )
                          else if (mostrarEtiquetas)
                            const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
