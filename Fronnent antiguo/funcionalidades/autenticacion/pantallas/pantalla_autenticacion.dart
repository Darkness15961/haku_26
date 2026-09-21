import 'package:flutter/material.dart';

import 'pantalla_iniciar_sesion.dart';

/// Punto de entrada legacy → redirige a iniciar sesión.
class PantallaAutenticacion extends StatelessWidget {
  const PantallaAutenticacion({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaIniciarSesion();
  }
}
