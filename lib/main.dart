import 'package:flutter/material.dart';

import 'funcionalidades/carga_inicial/indice.dart';
import 'funcionalidades/inicio/indice.dart';

void main() {
  runApp(const AplicacionHaku());
}

class AplicacionHaku extends StatelessWidget {
  const AplicacionHaku({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HAKU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F5D42)),
        scaffoldBackgroundColor: Colors.transparent,
        useMaterial3: true,
      ),
      builder: (context, contenido) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('public/image/fondoHaku.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: contenido ?? const SizedBox.shrink(),
        );
      },
      home: const PantallaCargaInicial(siguientePantalla: PantallaInicio()),
    );
  }
}
