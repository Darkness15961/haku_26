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
        colorScheme: ColorScheme.fromSeed(
          seedColor: PaletaRutas.verdeBosque,
          primary: PaletaRutas.verdeBosque,
          secondary: PaletaRutas.verdeOliva,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        useMaterial3: true,
        iconTheme: const IconThemeData(color: PaletaRutas.verdeBosque),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.black,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      builder: (context, contenido) {
        return ColoredBox(
          color: Colors.white,
          child: contenido ?? const SizedBox.shrink(),
        );
      },
      home: const PantallaCargaInicial(siguientePantalla: PantallaInicio()),
    );
  }
}
