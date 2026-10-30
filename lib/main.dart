import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'funcionalidades/carga_inicial/indice.dart';
import 'funcionalidades/inicio/indice.dart';
import 'funcionalidades/rutas/widgets/estilos_rutas.dart';
import 'nucleo/configuracion/modo_ejecucion.dart';
import 'nucleo/responsive/lienzo_haku.dart';
import 'nucleo/supabase/cliente_supabase.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(child: AplicacionHaku(prepararBackend: _prepararBackend)),
  );
}

Future<void> _prepararBackend() async {
  if (ConfigEntornoHaku.esDemo) return;

  try {
    await inicializarSupabase();
  } catch (e, st) {
    debugPrint('Supabase init: $e');
    debugPrint('$st');
    if (kDebugMode) {
      debugPrint(
        'Revisa URL / anon key en lib/nucleo/supabase/config_supabase.dart '
        'o --dart-define=SUPABASE_URL / SUPABASE_ANON_KEY',
      );
    }
    rethrow;
  }
}

class AplicacionHaku extends StatelessWidget {
  const AplicacionHaku({
    super.key,
    this.preparacion,
    this.prepararBackend,
    this.errorInicializacion,
  }) : assert(
         preparacion == null || prepararBackend == null,
         'Usa preparacion o prepararBackend, no ambos.',
       );

  final Future<void>? preparacion;
  final Future<void> Function()? prepararBackend;
  final Object? errorInicializacion;

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
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      builder: (context, contenido) {
        return EnvoltorioAppResponsiva(
          child: contenido ?? const SizedBox.shrink(),
        );
      },
      home: errorInicializacion == null
          ? PantallaCargaInicial(
              preparacion: preparacion,
              preparar: prepararBackend,
              pantallaError: const _PantallaBackendNoDisponible(),
              siguientePantalla: const PantallaInicio(),
            )
          : const _PantallaBackendNoDisponible(),
    );
  }
}

class _PantallaBackendNoDisponible extends StatelessWidget {
  const _PantallaBackendNoDisponible();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined, size: 52),
                SizedBox(height: 20),
                Text(
                  'No pudimos conectar con HAKU',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 12),
                Text(
                  'Revisa tu conexión e intenta abrir la aplicación de nuevo.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
