import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Retroceso tipo “pila de ventanas”:
/// 1) Si hay rutas encima del shell → el Navigator las hace pop (no intervenimos).
/// 2) En el shell, si no estás en Inicio → vuelve a Inicio.
/// 3) En Inicio raíz → doble atrás para salir (no expulsar al primer toque).
class ControlRetrocesoShell {
  ControlRetrocesoShell._();

  static DateTime? _ultimoIntentoSalir;

  /// Devuelve `true` si el evento quedó consumido (no salir de la app).
  static bool alIntentarSalirDelShell({
    required BuildContext context,
    required int indiceTab,
    required void Function(int tab) irATab,
  }) {
    if (indiceTab != 0) {
      irATab(0);
      return true;
    }

    final ahora = DateTime.now();
    final previo = _ultimoIntentoSalir;
    _ultimoIntentoSalir = ahora;

    if (previo != null &&
        ahora.difference(previo) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return true;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF1F1C18),
        content: Text(
          'Pulsa otra vez para salir',
          style: TextStyle(color: Color(0xFFF0EDE8)),
        ),
      ),
    );
    return true;
  }
}

/// Envuelve una pantalla empujada para que el botón/sistema atrás haga [pop]
/// de forma explícita (útil con predictive back en Android 14+).
class PantallaConPila extends StatelessWidget {
  const PantallaConPila({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: child,
    );
  }
}

/// [Navigator.pop] seguro: solo si hay algo que cerrar.
void retrocederOIgnorar(BuildContext context) {
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.pop();
  }
}
