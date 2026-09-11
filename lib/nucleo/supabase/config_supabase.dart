/// Credenciales del API Supabase (self-host).
///
/// Preferible en runtime:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
///
/// Si no hay dart-define, se usan los fallback de abajo.
/// No subas la `service_role` key. La anon/publishable key es la del cliente.
class ConfigSupabase {
  ConfigSupabase._();

  /// ID numérico solo como pista de UX si el catálogo ya estaba sembrado a mano.
  /// La app prefiere `codigo_iso = PE`; no dependas de que el id sea siempre 1.
  static const nacionalidadIdDefault = 1;

  static const _urlDev = String.fromEnvironment(
    'SUPABASE_URL_DEV',
    defaultValue: '',
  );
  static const _anonKeyDev = String.fromEnvironment(
    'SUPABASE_ANON_KEY_DEV',
    defaultValue: '',
  );

  static String get url {
    const fromDefine = String.fromEnvironment('SUPABASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    if (_urlDev.isNotEmpty) return _urlDev;
    return _urlFallback;
  }

  static String get anonKey {
    const fromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    if (_anonKeyDev.isNotEmpty) return _anonKeyDev;
    return _anonKeyFallback;
  }

  static const _urlFallback = 'https://supabase.haku.best';

  static const _anonKeyFallback =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhha3UiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTc4MzU1MTM0MiwiZXhwIjo0MTAyNDQ0ODAwfQ.vADeXIoed1f_EmbUeh8PO8whhz7jtxI3hsHbXth0TU8';

  static void asegurarConfigurado() {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Supabase no configurado. Define SUPABASE_URL y SUPABASE_ANON_KEY '
        '(dart-define) o rellena _urlFallback / _anonKeyFallback en '
        'config_supabase.dart.',
      );
    }
  }
}
