import 'package:supabase_flutter/supabase_flutter.dart';

import 'config_supabase.dart';

/// `true` si [inicializarSupabase] terminó bien.
bool supabaseListo = false;
Future<void>? _inicializacion;

/// Inicialización única del cliente Supabase (credenciales en [ConfigSupabase]).
Future<void> inicializarSupabase() {
  if (supabaseListo) return Future<void>.value();
  return _inicializacion ??= _inicializar();
}

Future<void> _inicializar() async {
  // La validación es anterior a crear recursos del SDK.
  // El await permite que el futuro compartido quede asignado incluso si falla.
  await Future<void>.value();
  try {
    ConfigSupabase.asegurarConfigurado();
    await Supabase.initialize(
      url: ConfigSupabase.url,
      publishableKey: ConfigSupabase.anonKey,
    );
    supabaseListo = true;
  } catch (_) {
    // El SDK marca la instancia como inicializada antes de restaurar Auth.
    // Si esa restauración falla, hay que liberar la instancia parcial para
    // que el siguiente intento no la acepte como una inicialización completa.
    try {
      await Supabase.instance.dispose();
    } catch (_) {
      // Puede fallar antes de existir una instancia; conserva el error original.
    }
    _inicializacion = null;
    rethrow;
  }
}

SupabaseClient get clienteSupabase {
  if (!supabaseListo) {
    throw StateError(
      'Supabase no inicializado. Revisa config_supabase.dart / logs de main.',
    );
  }
  return Supabase.instance.client;
}
