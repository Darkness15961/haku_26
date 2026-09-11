import 'package:supabase_flutter/supabase_flutter.dart';

import 'config_supabase.dart';

/// `true` si [inicializarSupabase] terminó bien.
bool supabaseListo = false;

/// Inicialización única del cliente Supabase (credenciales en [ConfigSupabase]).
Future<void> inicializarSupabase() async {
  ConfigSupabase.asegurarConfigurado();
  await Supabase.initialize(
    url: ConfigSupabase.url,
    publishableKey: ConfigSupabase.anonKey,
  );
  supabaseListo = true;
}

SupabaseClient get clienteSupabase {
  if (!supabaseListo) {
    throw StateError(
      'Supabase no inicializado. Revisa config_supabase.dart / logs de main.',
    );
  }
  return Supabase.instance.client;
}
