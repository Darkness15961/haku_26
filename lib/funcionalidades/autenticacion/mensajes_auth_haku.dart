import 'package:supabase_flutter/supabase_flutter.dart';

/// Mensajes de Auth amigables.
/// Regla de oro: 1 correo = 1 usuario (varias identidades: correo y/o Google).
abstract final class MensajesAuthHaku {
  MensajesAuthHaku._();

  static const correoYaRegistrado =
      'Este correo ya está registrado. Si creaste tu cuenta con Google, '
      'inicia sesión con Google. Si quieres usar contraseña, ve a '
      '«¿Olvidaste tu contraseña?» desde Iniciar sesión.';

  static const loginClaveIncorrecta =
      'Correo o contraseña incorrectos. Si te registraste con Google, '
      'usa «Continuar con Google». Si quieres una contraseña, usa '
      '«¿Olvidaste tu contraseña?»';

  static const nickEnUso = 'Ese nickname ya está en uso. Prueba otro.';

  static const claveSesionExpirada =
      'Tu sesión expiró. Vuelve a iniciar sesión.';

  static const claveFalloGenerico =
      'No se pudo actualizar la contraseña. Intenta de nuevo.';

  /// Traduce [AuthException] a copy de usuario.
  static String desdeAuthException(
    AuthException e, {
    required AuthContexto ctx,
  }) {
    final raw = '${e.message} ${e.statusCode ?? ''} ${e.code ?? ""}'
        .toLowerCase();

    if (_esCorreoYaRegistrado(raw)) {
      return correoYaRegistrado;
    }
    if (ctx == AuthContexto.login && _esCredencialesInvalidas(raw)) {
      return loginClaveIncorrecta;
    }
    if (_esNickDuplicado(raw)) {
      return nickEnUso;
    }
    if (ctx == AuthContexto.clave) {
      if (raw.contains('session') ||
          raw.contains('jwt') ||
          raw.contains('expired') ||
          raw.contains('not authenticated')) {
        return claveSesionExpirada;
      }
      if (_esCredencialesInvalidas(raw)) {
        return 'La contraseña actual no es correcta.';
      }
      final m = e.message.trim();
      if (m.isNotEmpty && m.length < 120 && !m.contains('Exception')) {
        // Solo mensajes cortos ya amigables (p. ej. los que lanzamos nosotros).
        if (!raw.contains('postgres') && !raw.contains('gotrue')) {
          return m;
        }
      }
      return claveFalloGenerico;
    }

    final m = e.message.trim();
    if (m.isNotEmpty && m.length < 160 && !m.contains('Exception')) {
      return m;
    }
    return ctx == AuthContexto.registro
        ? 'No se pudo crear la cuenta. Intenta de nuevo.'
        : 'No se pudo iniciar sesión. Revisa conexión y datos.';
  }

  static bool esCorreoYaRegistrado(AuthException e) {
    final raw = '${e.message} ${e.statusCode ?? ''} ${e.code ?? ""}'
        .toLowerCase();
    return _esCorreoYaRegistrado(raw);
  }

  static bool _esCorreoYaRegistrado(String raw) {
    return raw.contains('already registered') ||
        raw.contains('already been registered') ||
        raw.contains('user already exists') ||
        raw.contains('email_exists') ||
        raw.contains('user_already_exists') ||
        (raw.contains('already') && raw.contains('email'));
  }

  static bool _esCredencialesInvalidas(String raw) {
    return raw.contains('invalid login') ||
        raw.contains('invalid_credentials') ||
        raw.contains('invalid email or password');
  }

  static bool _esNickDuplicado(String raw) {
    return raw.contains('nombre_nick') ||
        (raw.contains('duplicate') && raw.contains('nick'));
  }
}

enum AuthContexto { login, registro, clave }
