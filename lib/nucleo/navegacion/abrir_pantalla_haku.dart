import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Navegación con pila: cada pantalla se apila y el atrás del sistema
/// vuelve a la anterior (no cierra la app).
Future<T?> abrirPantallaHaku<T>(BuildContext context, Widget pantalla) {
  return Navigator.of(context).push<T>(
    CupertinoPageRoute<T>(
      builder: (_) => pantalla,
    ),
  );
}

Future<T?> abrirPantallaModalHaku<T>(BuildContext context, Widget pantalla) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute<T>(
      fullscreenDialog: true,
      builder: (_) => pantalla,
    ),
  );
}
