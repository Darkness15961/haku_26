import 'package:flutter/material.dart';

import 'estilos_rutas.dart';

/// Franja tipo pollera bajo encabezados / cards (contraste oro–piedra).
class LineaEncabezadoInca extends StatelessWidget {
  final double altura;
  final Color color;

  const LineaEncabezadoInca({
    super.key,
    this.altura = 3,
    this.color = PaletaRutas.oro,
  });

  @override
  Widget build(BuildContext context) {
    final h = altura.clamp(2.0, 6.0);
    return SizedBox(
      width: double.infinity,
      height: h,
      child: Row(
        children: [
          Expanded(flex: 5, child: ColoredBox(color: color)),
          Expanded(
            flex: 2,
            child: ColoredBox(color: PaletaRutas.piedra.withValues(alpha: 0.85)),
          ),
          Expanded(flex: 3, child: ColoredBox(color: PaletaRutas.oroOscuro)),
          Expanded(
            flex: 2,
            child: ColoredBox(color: PaletaRutas.plomoClaro.withValues(alpha: 0.7)),
          ),
          Expanded(flex: 4, child: ColoredBox(color: color)),
        ],
      ),
    );
  }
}
