import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias locales de la simulación (onboarding).
abstract final class PreferenciasDemoHaku {
  static const _onboarding = 'haku_onboarding_demo_v1';

  static Future<bool> onboardingVisto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboarding) ?? false;
  }

  static Future<void> marcarOnboardingVisto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboarding, true);
  }
}
