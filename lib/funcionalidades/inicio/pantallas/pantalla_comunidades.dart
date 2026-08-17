import 'package:flutter/material.dart';

import '../../comunidad/pantallas/pantalla_comunidad.dart';

/// Acceso a comunidades desde Mensajes (misma lista de la BD local).
class PantallaComunidades extends StatelessWidget {
  const PantallaComunidades({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaComunidad(mostrarAtras: true);
  }
}
