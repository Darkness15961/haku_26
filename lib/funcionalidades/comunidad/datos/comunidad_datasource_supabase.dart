import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../dominio/modelo_comunidad.dart';

/// Lectura/escritura de `public.comunidad` + `comunidad_miembro`.
/// Solo columnas reales del schema. Sin categorías / provincia / invitados fantasma.
class ComunidadDataSourceSupabase {
  static const bucketMedia = 'haku-storage-produccion-2026';

  static const _selectListado = '''
id,
nombre,
descripcion,
foto_portada,
usuario_creador_id,
estado,
tipo,
fecha_creacion,
comunidad_miembro (
  usuario_id,
  rol,
  estado
)
''';

  static const _selectMiembros = '''
usuario_id,
rol,
estado,
fecha_union,
usuario:usuario_id (
  id,
  nombre_nick,
  nombres,
  foto_perfil
)
''';

  Future<List<ComunidadHaku>> listarVisibles() async {
    if (!supabaseListo) return const [];

    final rows = await clienteSupabase
        .from('comunidad')
        .select(_selectListado)
        .eq('estado', true)
        .order('nombre', ascending: true);

    return (rows as List<dynamic>)
        .map(
          (e) => ComunidadHaku.desdeFilaRemota(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .where((c) => c.id.isNotEmpty && c.nombre.isNotEmpty)
        .toList();
  }

  Future<ComunidadHaku?> porId(String id) async {
    if (!supabaseListo) return null;
    final idNum = int.tryParse(id.trim());
    if (idNum == null) return null;

    final row = await clienteSupabase
        .from('comunidad')
        .select(_selectListado)
        .eq('id', idNum)
        .maybeSingle();

    if (row == null) return null;
    return ComunidadHaku.desdeFilaRemota(Map<String, dynamic>.from(row));
  }

  /// Sube portada solo si el usuario eligió archivo. Path tipado comunidades/.
  Future<String> subirFotoPortada({
    required String userId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String extension = 'jpg',
  }) async {
    final path =
        '$userId/comunidades/portada_${DateTime.now().millisecondsSinceEpoch}.$extension';
    await clienteSupabase.storage.from(bucketMedia).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );
    return clienteSupabase.storage.from(bucketMedia).getPublicUrl(path);
  }

  /// Insert `comunidad` + fila admin en `comunidad_miembro`.
  /// [descripcion] vacía → NULL. [fotoPortadaUrl] null → NULL (sin inventar).
  Future<ComunidadHaku> crear({
    required String nombre,
    String? descripcion,
    String tipo = 'publico',
    String? fotoPortadaUrl,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('No hay conexión con el servidor.');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Inicia sesión para crear una comunidad.');
    }
    final nombreTrim = nombre.trim();
    if (nombreTrim.isEmpty) {
      throw const AuthException('El nombre es obligatorio.');
    }
    final tipoNorm = tipo.trim().toLowerCase() == 'privado' ? 'privado' : 'publico';
    final desc = descripcion?.trim();
    final foto = fotoPortadaUrl?.trim();

    final insertado = await clienteSupabase
        .from('comunidad')
        .insert({
          'nombre': nombreTrim,
          'descripcion': (desc == null || desc.isEmpty) ? null : desc,
          'foto_portada': (foto == null || foto.isEmpty) ? null : foto,
          'usuario_creador_id': user.id,
          'tipo': tipoNorm,
          'estado': true,
        })
        .select('id')
        .single();

    final idRaw = insertado['id'];
    final idNum = idRaw is int ? idRaw : int.parse('$idRaw');

    try {
      await clienteSupabase.from('comunidad_miembro').insert({
        'comunidad_id': idNum,
        'usuario_id': user.id,
        'rol': 'admin',
        'estado': 'aprobado',
      });
    } catch (_) {
      // Evita comunidad huérfana sin admin.
      final revertida = await clienteSupabase
          .from('comunidad')
          .update({'estado': false})
          .eq('id', idNum)
          .eq('usuario_creador_id', user.id)
          .select('id')
          .maybeSingle();
      if (revertida == null) {
        throw const AuthException(
          'La comunidad quedó a medias y no se pudo desactivar. Reintentá.',
        );
      }
      throw const AuthException(
        'La comunidad se creó pero falló el alta de admin. Quedó inactiva.',
      );
    }

    final creada = await porId('$idNum');
    if (creada == null) {
      throw const AuthException(
        'La comunidad se creó pero no se pudo recargar.',
      );
    }
    return creada;
  }

  /// Público → `aprobado`. Privado → `pendiente`.
  /// [conocida] evita un segundo `porId` (y falla RLS en privadas ya vistas en UI).
  Future<void> unirse(String comunidadId, {ComunidadHaku? conocida}) async {
    if (!supabaseListo) {
      throw const AuthException('No hay conexión con el servidor.');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Inicia sesión para unirte.');
    }
    final idNum = int.tryParse(comunidadId.trim());
    if (idNum == null) {
      throw const AuthException('Comunidad inválida.');
    }

    final comunidad = (conocida != null && conocida.id == '$idNum')
        ? conocida
        : await porId('$idNum');
    if (comunidad == null) {
      throw const AuthException(
        'Comunidad no encontrada o no visible para tu sesión.',
      );
    }
    if (comunidad.esMiembro(user.id)) {
      return;
    }
    final ya = comunidad.estadoMembresiaDe(user.id);
    if (ya == 'pendiente') {
      return;
    }
    if (ya == 'bloqueado') {
      throw const AuthException(
        'Estás bloqueado en esta comunidad. No podés volver a unirte.',
      );
    }

    final estadoMembresia = comunidad.esPrivada ? 'pendiente' : 'aprobado';

    // Tras rechazo la PK sigue ocupada: borrar fila propia y reinsertar.
    if (ya == 'rechazado') {
      await clienteSupabase
          .from('comunidad_miembro')
          .delete()
          .eq('comunidad_id', idNum)
          .eq('usuario_id', user.id);
    }

    await clienteSupabase.from('comunidad_miembro').insert({
      'comunidad_id': idNum,
      'usuario_id': user.id,
      'rol': 'miembro',
      'estado': estadoMembresia,
    });
  }

  Future<void> salir(String comunidadId) async {
    if (!supabaseListo) {
      throw const AuthException('No hay conexión con el servidor.');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Inicia sesión.');
    }
    final idNum = int.tryParse(comunidadId.trim());
    if (idNum == null) {
      throw const AuthException('Comunidad inválida.');
    }

    final com = await clienteSupabase
        .from('comunidad')
        .select('usuario_creador_id')
        .eq('id', idNum)
        .maybeSingle();
    if (com != null && '${com['usuario_creador_id'] ?? ''}' == user.id) {
      throw const AuthException(
        'El creador no puede salir. La comunidad quedaría sin dueño.',
      );
    }

    final row = await clienteSupabase
        .from('comunidad_miembro')
        .delete()
        .eq('comunidad_id', idNum)
        .eq('usuario_id', user.id)
        .select('comunidad_id')
        .maybeSingle();
    if (row == null) {
      throw const AuthException('No se pudo salir de la comunidad.');
    }
  }

  Future<List<MiembroComunidadRemoto>> listarMiembros(String comunidadId) async {
    if (!supabaseListo) return const [];
    final idNum = int.tryParse(comunidadId.trim());
    if (idNum == null) return const [];

    final rows = await clienteSupabase
        .from('comunidad_miembro')
        .select(_selectMiembros)
        .eq('comunidad_id', idNum)
        .eq('estado', 'aprobado')
        .order('fecha_union', ascending: true);

    return (rows as List<dynamic>)
        .map(
          (e) => MiembroComunidadRemoto.desdeFila(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .where((m) => m.usuarioId.isNotEmpty)
        .toList();
  }

  /// Solicitudes pendientes (solo visibles si RLS permite: admin/aprobado).
  Future<List<MiembroComunidadRemoto>> listarPendientes(
    String comunidadId,
  ) async {
    if (!supabaseListo) return const [];
    final idNum = int.tryParse(comunidadId.trim());
    if (idNum == null) return const [];

    final rows = await clienteSupabase
        .from('comunidad_miembro')
        .select(_selectMiembros)
        .eq('comunidad_id', idNum)
        .eq('estado', 'pendiente')
        .order('fecha_union', ascending: true);

    return (rows as List<dynamic>)
        .map(
          (e) => MiembroComunidadRemoto.desdeFila(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .where((m) => m.usuarioId.isNotEmpty)
        .toList();
  }

  /// Admin aprueba o rechaza solicitud (UPDATE permitido solo admin — mig 900).
  Future<void> resolverSolicitud({
    required String comunidadId,
    required String usuarioId,
    required bool aprobar,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('No hay conexión con el servidor.');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Inicia sesión.');
    }
    final idNum = int.tryParse(comunidadId.trim());
    if (idNum == null || usuarioId.trim().isEmpty) {
      throw const AuthException('Solicitud inválida.');
    }

    final nuevo = aprobar ? 'aprobado' : 'rechazado';
    final row = await clienteSupabase
        .from('comunidad_miembro')
        .update({'estado': nuevo})
        .eq('comunidad_id', idNum)
        .eq('usuario_id', usuarioId.trim())
        .eq('estado', 'pendiente')
        .select('usuario_id')
        .maybeSingle();
    if (row == null) {
      throw const AuthException(
        'No se pudo resolver la solicitud. ¿Sos admin de la comunidad?',
      );
    }
  }
}
