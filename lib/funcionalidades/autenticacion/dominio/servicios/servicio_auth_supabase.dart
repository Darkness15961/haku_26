import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../nucleo/supabase/cliente_supabase.dart';
import '../../../../nucleo/supabase/config_supabase.dart';

/// Resultado de registro / login nativo u OAuth.
class ResultadoAuth {
  final User usuario;
  final Session? sesion;

  const ResultadoAuth({required this.usuario, this.sesion});

  bool get tieneSesion => sesion != null;
}

/// Auth vía SDK oficial (`supabase_flutter`).
///
/// Reglas de oro (Bloque B Etapa 4) — ver `docs/fase-autenticacion.md`:
/// - Solo métodos del SDK (signUp / signInWithPassword / signInWithIdToken / signOut).
/// - No HTTP manual a `/auth/v1`.
/// - Perfil editable en `public.usuario` vía [ServicioPerfilSupabase], no aquí.
class ServicioAuthSupabase {
  ServicioAuthSupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? clienteSupabase;

  final SupabaseClient _cliente;

  static bool _googleInicializado = false;

  static Map<String, dynamic> metadataRegistro({
    required String nombres,
    required String apellidos,
    required String nombreNick,
    required int nacionalidadId,
  }) {
    return {
      'nombres': nombres,
      'apellidos': apellidos,
      'nombre_nick': nombreNick,
      // String: el trigger lee con ->> (texto).
      'nacionalidad_id': '$nacionalidadId',
    };
  }

  Future<ResultadoAuth> registrarConCorreo({
    required String correo,
    required String clave,
    required String nombreNick,
    required String nombres,
    required String apellidos,
    int? nacionalidadId,
  }) async {
    final nick = _normalizarNick(nombreNick);
    final response = await _cliente.auth.signUp(
      email: correo.trim(),
      password: clave,
      data: metadataRegistro(
        nombres: nombres.trim(),
        apellidos: apellidos.trim(),
        nombreNick: nick,
        nacionalidadId: nacionalidadId ?? ConfigSupabase.nacionalidadIdDefault,
      ),
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException(
        'No se pudo crear la cuenta. Intenta de nuevo.',
      );
    }

    return ResultadoAuth(usuario: user, sesion: response.session);
  }

  Future<ResultadoAuth> iniciarSesionConCorreo({
    required String correo,
    required String clave,
  }) async {
    final response = await _cliente.auth.signInWithPassword(
      email: correo.trim(),
      password: clave,
    );

    final user = response.user;
    final session = response.session;
    if (user == null || session == null) {
      throw const AuthException('No se pudo iniciar sesión.');
    }

    return ResultadoAuth(usuario: user, sesion: session);
  }

  /// Usuario cerró el selector de Google (no es error de producto).
  static const mensajeGoogleCancelado = '__haku_google_cancelado__';

  /// Google nativo (ventana de cuentas / Play Services) → `signInWithIdToken`.
  /// Requiere SHA-1 + package en Google Cloud (Android) y Web Client ID en la app.
  Future<ResultadoAuth> iniciarConGoogle() async {
    await _asegurarGoogleNativo();

    try {
      final googleAccount = await GoogleSignIn.instance.authenticate();
      final idToken = googleAccount.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        debugPrint(
          'Google idToken null: falta o mal GOOGLE_WEB_CLIENT_ID '
          '(debe ser el Client ID tipo Web del Auth).',
        );
        throw const AuthException(
          'No se pudo completar el acceso con Google. Intenta de nuevo.',
        );
      }

      final response = await _cliente.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final user = response.user;
      final session = response.session;
      if (user == null || session == null) {
        throw const AuthException('No se pudo iniciar sesión con Google.');
      }

      return ResultadoAuth(usuario: user, sesion: session);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException(mensajeGoogleCancelado);
      }
      debugPrint('GoogleSignInException: ${e.code} ${e.description}');
      throw const AuthException(
        'No se pudo entrar con Google. Intenta de nuevo.',
      );
    }
  }

  /// Envía correo de recuperación (habilita clave también si la cuenta nace en Google).
  Future<void> enviarRecuperacionContrasena(String correo) async {
    await _cliente.auth.resetPasswordForEmail(
      correo.trim(),
      redirectTo: ConfigSupabase.oauthRedirectUri,
    );
  }

  Future<void> cerrarSesion() async {
    // Siempre intentar limpiar Google (si no, al reabrir puede reusar la cuenta
    // sin volver a mostrar el selector).
    try {
      if (ConfigSupabase.googleWebClientId.isNotEmpty) {
        await _asegurarGoogleNativo();
        await GoogleSignIn.instance.signOut();
      }
    } catch (e) {
      debugPrint('Google signOut: $e');
    }
    await _cliente.auth.signOut();
  }

  User? get usuarioActual => _cliente.auth.currentUser;

  Session? get sesionActual => _cliente.auth.currentSession;

  static Future<void> _asegurarGoogleNativo() async {
    if (_googleInicializado) return;

    try {
      final web = ConfigSupabase.googleWebClientId;
      if (web.isEmpty) {
        debugPrint(
          'GOOGLE_WEB_CLIENT_ID vacío: mismo Client ID Web que '
          'GOTRUE_EXTERNAL_GOOGLE_CLIENT_ID en el VPS.',
        );
        throw const AuthException(
          'El acceso con Google aún no está listo. Intenta más tarde.',
        );
      }

      final ios = ConfigSupabase.googleIosClientId;
      await GoogleSignIn.instance.initialize(
        serverClientId: web,
        clientId: ios.isEmpty ? null : ios,
      );
      _googleInicializado = true;
    } catch (e) {
      _googleInicializado = false;
      rethrow;
    }
  }

  static String _normalizarNick(String raw) {
    var n = raw.trim();
    if (n.startsWith('@')) n = n.substring(1);
    return n;
  }
}
