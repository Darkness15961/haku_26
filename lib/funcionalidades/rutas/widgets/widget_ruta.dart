import 'package:flutter/material.dart';

import '../dominio/modelos/modelo_ruta.dart';
import 'tarjeta_ruta.dart';

/// Punto de extensión histórico del feature; delega a [TarjetaRuta].
class WidgetRuta extends StatelessWidget {
  final ModeloRuta? ruta;
  final VoidCallback? onTap;

  const WidgetRuta({super.key, this.ruta, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (ruta == null) return const SizedBox.shrink();
    return TarjetaRuta(ruta: ruta!, onTap: onTap);
  }
}
