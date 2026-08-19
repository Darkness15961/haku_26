/// Conexión opcional a Supabase. Vacío = solo BD local.
///
/// flutter run --dart-define=HAKU_SUPABASE_URL=https://xxxx.supabase.co --dart-define=HAKU_SUPABASE_ANON=eyJ...
class ConfiguracionHaku {
  ConfiguracionHaku._();

  static const supabaseUrl = String.fromEnvironment('HAKU_SUPABASE_URL');
  static const supabaseAnon = String.fromEnvironment('HAKU_SUPABASE_ANON');

  static bool get remotoActivo =>
      supabaseUrl.isNotEmpty && supabaseAnon.isNotEmpty;
}
