import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/navegacion/abrir_pantalla_haku.dart';
import 'pantallas/pantalla_iniciar_sesion.dart';
import 'proveedores/proveedor_sesion.dart';

/// Si no hay sesión, abre iniciar sesión. Devuelve true si ya puede continuar.
Future<bool> asegurarSesion(BuildContext context, WidgetRef ref) async {
  // Evita carrera: splash → Inicio → tocar acción antes de hidratar JWT.
  await ref.read(sesionProvider.notifier).esperarListo();
  if (!context.mounted) return false;
  if (ref.read(sesionProvider).autenticado) return true;

  final resultado = await abrirPantallaModalHaku<bool>(
    context,
    const PantallaIniciarSesion(),
  );

  if (!context.mounted) return false;
  return resultado == true && ref.read(sesionProvider).autenticado;
}
