import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../nucleo/supabase/cliente_supabase.dart';
import '../modelos/modelo_nacionalidad.dart';
import '../../datos/nacionalidad_datasource.dart';

/// Perfil completo leído de `public.usuario` (+ nacionalidad).
class PerfilUsuarioDb {
  const PerfilUsuarioDb({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.nombreNick,
    required this.correo,
    required this.nacionalidadId,
    this.fotoPerfil,
    this.nacionalidad,
  });

  final String id;
  final String nombres;
  final String apellidos;
  final String nombreNick;
  final String correo;
  final int nacionalidadId;
  final String? fotoPerfil;
  final ModeloNacionalidad? nacionalidad;
}

/// Actualización de perfil: `public.usuario` + Auth cuando aplica.
///
/// Reglas: updates de ficha con RLS (`auth.uid() = id`). Correo/clave vía SDK Auth.
/// Foto: Storage (o S3 después) → solo URL en `foto_perfil`.
/// Ver `docs/fase-autenticacion.md` (Bloque B Etapa 4).
class ServicioPerfilSupabase {
  ServicioPerfilSupabase({SupabaseClient? cliente})
      : _cliente = cliente ?? clienteSupabase;

  final SupabaseClient _cliente;

  /// Bucket actual (self-host). Sustituible por S3 sin tocar la columna BD.
  static const bucketMedia = 'haku-storage-produccion-2026';

  Future<PerfilUsuarioDb?> cargarPerfil(String userId) async {
    final row = await _cliente
        .from('usuario')
        .select(
          'id, nombres, apellidos, nombre_nick, correo, foto_perfil, nacionalidad_id',
        )
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;

    final nacRaw = row['nacionalidad_id'];
    final nacId = nacRaw is int ? nacRaw : int.parse('$nacRaw');
    ModeloNacionalidad? nac;
    try {
      final lista = await NacionalidadDataSource().listar();
      for (final n in lista) {
        if (n.id == nacId) {
          nac = n;
          break;
        }
      }
    } catch (_) {}

    return PerfilUsuarioDb(
      id: row['id'] as String,
      nombres: (row['nombres'] as String?)?.trim() ?? '',
      apellidos: (row['apellidos'] as String?)?.trim() ?? '',
      nombreNick: (row['nombre_nick'] as String?)?.trim() ?? '',
      correo: (row['correo'] as String?)?.trim() ?? '',
      nacionalidadId: nacId,
      fotoPerfil: row['foto_perfil'] as String?,
      nacionalidad: nac,
    );
  }

  Future<void> actualizarDatosPerfil({
    required String userId,
    required String nombres,
    required String apellidos,
    required String nombreNick,
    required int nacionalidadId,
  }) async {
    final nick = _normalizarNick(nombreNick);
    final row = await _cliente
        .from('usuario')
        .update({
          'nombres': nombres.trim(),
          'apellidos': apellidos.trim(),
          'nombre_nick': nick,
          'nacionalidad_id': nacionalidadId,
        })
        .eq('id', userId)
        .select('id')
        .maybeSingle();
    if (row == null) {
      throw const AuthException(
        'No se pudo guardar el perfil. ¿Existe tu ficha en el servidor?',
      );
    }

    // Mantener metadata Auth alineada (útil para OAuth / claims).
    await _cliente.auth.updateUser(
      UserAttributes(
        data: {
          'nombres': nombres.trim(),
          'apellidos': apellidos.trim(),
          'nombre_nick': nick,
          'nacionalidad_id': '$nacionalidadId',
        },
      ),
    );
  }

  /// Cambia correo en Auth y sincroniza `public.usuario.correo`.
  /// Sin SMTP: puede aplicar directo (autoconfirm). Con SMTP: GoTrue pedirá confirmar.
  Future<void> actualizarCorreo({
    required String userId,
    required String correoNuevo,
  }) async {
    final correo = correoNuevo.trim();
    await _cliente.auth.updateUser(UserAttributes(email: correo));
    final row = await _cliente
        .from('usuario')
        .update({'correo': correo})
        .eq('id', userId)
        .select('id')
        .maybeSingle();
    if (row == null) {
      throw const AuthException('No se pudo sincronizar el correo en el perfil.');
    }
  }

  Future<void> actualizarContrasena({
    required String correo,
    required String claveActual,
    required String claveNueva,
  }) async {
    // Reautenticar: evita cambio de clave sin probar la actual.
    await _cliente.auth.signInWithPassword(
      email: correo.trim(),
      password: claveActual,
    );
    await _cliente.auth.updateUser(UserAttributes(password: claveNueva));
  }

  /// Google-only (sesión JWT activa): añade clave sin pedir la actual ni SMTP.
  /// Luego puede entrar con Google o con correo + esta clave.
  Future<void> crearContrasena(String claveNueva) async {
    final session = _cliente.auth.currentSession;
    if (session == null) {
      throw const AuthException('Tu sesión expiró. Vuelve a iniciar sesión.');
    }
    await _cliente.auth.updateUser(
      UserAttributes(password: claveNueva),
    );
    // Refresca identidades locales (puede aparecer `email` tras set password).
    try {
      await _cliente.auth.getUser();
    } catch (_) {}
  }

  /// Sube bytes y devuelve URL pública para guardar en `foto_perfil`.
  Future<String> subirFotoPerfil({
    required String userId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String extension = 'jpg',
  }) async {
    final path =
        '$userId/perfil/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _cliente.storage.from(bucketMedia).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );
    final url = _cliente.storage.from(bucketMedia).getPublicUrl(path);
    final row = await _cliente
        .from('usuario')
        .update({'foto_perfil': url})
        .eq('id', userId)
        .select('id')
        .maybeSingle();
    if (row == null) {
      throw const AuthException(
        'La foto subió al storage pero no se guardó en el perfil.',
      );
    }
    await _cliente.auth.updateUser(
      UserAttributes(data: {'avatar_url': url}),
    );
    return url;
  }

  static String _normalizarNick(String raw) {
    var n = raw.trim();
    if (n.startsWith('@')) n = n.substring(1);
    return n;
  }
}
