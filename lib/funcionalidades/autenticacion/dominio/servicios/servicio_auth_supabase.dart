import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../nucleo/supabase/cliente_supabase.dart';
import '../../../../nucleo/supabase/config_supabase.dart';

/// Resultado de registro / login nativo.
class ResultadoAuth {
  final User usuario;
  final Session? sesion;

  const ResultadoAuth({required this.usuario, this.sesion});

  bool get tieneSesion => sesion != null;
}

/// Auth vía SDK. Metadata de registro = columnas de `public.usuario` (vía trigger).
class ServicioAuthSupabase {
  ServicioAuthSupabase({SupabaseClient? cliente})
      : _cliente = cliente ?? clienteSupabase;

  final SupabaseClient _cliente;

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

  Future<void> cerrarSesion() async {
    await _cliente.auth.signOut();
  }

  User? get usuarioActual => _cliente.auth.currentUser;

  Session? get sesionActual => _cliente.auth.currentSession;

  static String _normalizarNick(String raw) {
    var n = raw.trim();
    if (n.startsWith('@')) n = n.substring(1);
    return n;
  }
}
