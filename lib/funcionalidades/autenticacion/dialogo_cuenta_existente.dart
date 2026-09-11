import 'package:flutter/material.dart';

import '../rutas/widgets/estilos_rutas.dart';
import 'mensajes_auth_haku.dart';
import 'pantallas/pantalla_recuperar_contrasena.dart';

/// Diálogo cuando intentan registrarse con un correo que ya existe (p. ej. Google).
Future<void> mostrarDialogoCorreoYaRegistrado(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: PaletaRutas.carbon,
        title: Text(
          'Cuenta ya existente',
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
        content: Text(
          MensajesAuthHaku.correoYaRegistrado,
          style: TipografiaHaku.interfaz(
            fontSize: 14,
            height: 1.4,
            color: PaletaRutas.plomoClaro,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Entendido',
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PantallaRecuperarContrasena(),
                ),
              );
            },
            child: Text(
              'Olvidé mi contraseña',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: PaletaRutas.oro,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Vuelve a login si estamos en registro (pop registro → login).
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(false);
              }
            },
            child: Text(
              'Ir a iniciar sesión',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: PaletaRutas.oro,
              ),
            ),
          ),
        ],
      );
    },
  );
}
