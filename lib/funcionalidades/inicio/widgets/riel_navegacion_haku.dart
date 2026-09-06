import 'package:flutter/material.dart';

import '../../../nucleo/responsive/espacio_haku.dart';
import '../../../nucleo/widgets/badge_contador.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import 'barra_navegacion_curva.dart';

/// Navegación lateral para landscape: libera altura vertical.
class RielNavegacionHaku extends StatelessWidget {
  const RielNavegacionHaku({
    super.key,
    required this.indiceActual,
    required this.items,
    required this.onCambiar,
    this.contadorPorIndice = const [],
  });

  final int indiceActual;
  final List<ItemBarraNavegacion> items;
  final ValueChanged<int> onCambiar;
  final List<int> contadorPorIndice;

  int _contador(int index) =>
      index < contadorPorIndice.length ? contadorPorIndice[index] : 0;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    final compacto = EspacioHaku.esTelefono(context);
    final ancho = compacto ? 72.0 : 88.0;

    return ColoredBox(
      color: PaletaRutas.ink,
      child: SizedBox(
        width: ancho + safe.left,
        child: Padding(
          padding: EdgeInsets.only(left: safe.left),
          child: Column(
            children: [
              SizedBox(height: safe.top + 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _ItemRiel(
                        item: items[i],
                        activo: indiceActual == i,
                        contador: _contador(i),
                        compacto: compacto,
                        onTap: () => onCambiar(i),
                      ),
                  ],
                ),
              ),
              SizedBox(height: safe.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRiel extends StatelessWidget {
  const _ItemRiel({
    required this.item,
    required this.activo,
    required this.contador,
    required this.compacto,
    required this.onTap,
  });

  final ItemBarraNavegacion item;
  final bool activo;
  final int contador;
  final bool compacto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (item.esCentral) {
      return Tooltip(
        message: 'Publicar',
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: compacto ? 40 : 46,
            height: compacto ? 40 : 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: PaletaRutas.oro,
            ),
            child: Icon(
              Icons.add_rounded,
              color: PaletaRutas.ink,
              size: compacto ? 24 : 28,
            ),
          ),
        ),
      );
    }

    final color = activo ? PaletaRutas.piedra : PaletaRutas.plomo;
    return Tooltip(
      message: item.etiqueta,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BadgeContadorOverlay(
                cantidad: contador,
                compacto: true,
                child: Icon(
                  activo ? item.iconoActivo : item.iconoNormal,
                  color: color,
                  size: compacto ? 22 : 24,
                ),
              ),
              if (!compacto) ...[
                const SizedBox(height: 4),
                Text(
                  item.etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TipografiaHaku.interfaz(
                    fontSize: 10,
                    fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
              if (activo)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 14,
                  height: 2,
                  color: PaletaRutas.oro,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
