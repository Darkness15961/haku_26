import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pantallas/pantalla_iniciar_sesion.dart';
import 'proveedores/proveedor_sesion.dart';

/// Si no hay sesión, abre iniciar sesión. Devuelve true si ya puede continuar.
Future<bool> asegurarSesion(BuildContext context, WidgetRef ref) async {
  if (ref.read(sesionProvider).autenticado) return true;

  final resultado = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const PantallaIniciarSesion(),
    ),
  );

  return resultado == true && ref.read(sesionProvider).autenticado;
}
