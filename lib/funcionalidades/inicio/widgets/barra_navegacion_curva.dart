import 'package:flutter/material.dart';

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

  const BarraNavegacionCurva({
    super.key,
    required this.indiceActual,
    required this.items,
    required this.onCambiar,
    this.contadorPorIndice = const [],
  });

  int _contador(int index) =>
      index < contadorPorIndice.length ? contadorPorIndice[index] : 0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
            padding: EdgeInsets.only(bottom: bottomInset, top: 6),
            child: SizedBox(
              height: 58,
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
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: PaletaRutas.oro,
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: PaletaRutas.ink,
                                size: 28,
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
                      size: 22,
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
                          const SizedBox(height: 3),
                          Text(
                            item.etiqueta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaHaku.interfaz(
                              fontSize: 10,
                              fontWeight:
                                  esActivo ? FontWeight.w700 : FontWeight.w500,
                              color: color,
                            ),
                          ),
                          if (esActivo)
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              width: 12,
                              height: 2,
                              color: PaletaRutas.oro,
                            )
                          else
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
