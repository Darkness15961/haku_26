/// Credenciales del API Supabase (self-host).
///
/// Preferible en runtime:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
///
/// Si no hay dart-define, se usan los fallback de abajo.
/// No subas la `service_role` key. La anon/publishable key es la del cliente.
class ConfigSupabase {
  ConfigSupabase._();

  /// Redirect deep link Android (recuperar clave / flujos web).
  /// Debe coincidir con ADDITIONAL_REDIRECT_URLS del Auth en el VPS
  /// y con el intent-filter de AndroidManifest (`hakuapp` / `login-callback`).
  static const oauthRedirectUri = 'hakuapp://login-callback';

  /// Client ID tipo **Web** de Google Cloud (el mismo que usa Auth en el VPS:
  /// `GOTRUE_EXTERNAL_GOOGLE_CLIENT_ID`). Obligatorio para Google nativo
  /// (`serverClientId` → idToken). No es el Client ID de Android.
  ///
  /// `flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com`
  /// o rellena [_googleWebClientIdFallback].
  static String get googleWebClientId {
    const fromDefine = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    if (fromDefine.isNotEmpty) return fromDefine;
    return _googleWebClientIdFallback;
  }

  /// Client ID iOS (opcional hasta que toquemos iOS).
  static String get googleIosClientId {
    const fromDefine = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
    if (fromDefine.isNotEmpty) return fromDefine;
    return _googleIosClientIdFallback;
  }

  /// Pista de UX si el catálogo ya tenía ids fijos; la app prefiere `codigo_iso = PE`.
  static const nacionalidadIdDefault = 1;

  /// Client ID público del proveedor Google configurado en Auth del VPS.
  static const _googleWebClientIdFallback =
      '30837355283-jvlh7jvjjtcg3f69ibnbgd3icpq3vur9.apps.googleusercontent.com';

  static const _googleIosClientIdFallback = '';

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
