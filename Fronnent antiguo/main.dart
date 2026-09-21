import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'funcionalidades/carga_inicial/indice.dart';
import 'funcionalidades/inicio/indice.dart';
import 'funcionalidades/rutas/widgets/estilos_rutas.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AplicacionHaku()));
}

class AplicacionHaku extends StatelessWidget {
  const AplicacionHaku({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HAKU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: PaletaRutas.oro,
          secondary: PaletaRutas.oroSuave,
          surface: PaletaRutas.carbon,
          onPrimary: PaletaRutas.ink,
          onSurface: PaletaRutas.piedra,
        ),
        scaffoldBackgroundColor: PaletaRutas.ink,
        useMaterial3: true,
        iconTheme: const IconThemeData(color: PaletaRutas.piedra),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: PaletaRutas.oro,
          foregroundColor: PaletaRutas.ink,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: PaletaRutas.carbon,
          contentTextStyle: TextStyle(color: PaletaRutas.piedra),
        ),
      ),
      builder: (context, contenido) {
        return ColoredBox(
          color: PaletaRutas.ink,
          child: contenido ?? const SizedBox.shrink(),
        );
      },
      home: const PantallaCargaInicial(siguientePantalla: PantallaInicio()),
    );
  }
}
