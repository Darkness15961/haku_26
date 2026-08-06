import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'funcionalidades/carga_inicial/indice.dart';
import 'funcionalidades/inicio/indice.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5E3C)),
        scaffoldBackgroundColor: Colors.transparent,
        useMaterial3: true,
      ),
      builder: (context, contenido) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('public/image/fondoHaku.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Color(0x30C9A84C),
                BlendMode.srcOver,
              ),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  const Color(0xFFEAD8B1).withValues(alpha: 0.25),
                  const Color(0xFF2D1810).withValues(alpha: 0.15),
                ],
              ),
            ),
            child: contenido ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const PantallaCargaInicial(siguientePantalla: PantallaInicio()),
    );
  }
}
