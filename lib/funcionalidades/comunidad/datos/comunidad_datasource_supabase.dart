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

    final rows = await clienteSupabase.rpc('listar_comunidades_resumen');
    final uid = clienteSupabase.auth.currentUser?.id;

    return (rows as List<dynamic>)
        .whereType<Map>()
        .map((e) {
          final fila = Map<String, dynamic>.from(e);
          final miEstado = (fila['mi_estado'] as String?)?.trim();
          if (uid != null && miEstado != null && miEstado.isNotEmpty) {
            fila['comunidad_miembro'] = [
              {
                'usuario_id': uid,
                'rol': fila['mi_rol'] ?? 'miembro',
                'estado': miEstado,
              },
            ];
          }
          return ComunidadHaku.desdeFilaRemota(fila);
        })
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
    await clienteSupabase.storage
        .from(bucketMedia)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return clienteSupabase.storage.from(bucketMedia).getPublicUrl(path);
  }

  Future<ComunidadHaku> crearConPortada({
    required String userId,
    required Uint8List bytes,
    required String contentType,
    required String extension,
    required String nombre,
    String? descripcion,
    String tipo = 'publico',
  }) async {
    final url = await subirFotoPortada(
      userId: userId,
      bytes: bytes,
      contentType: contentType,
      extension: extension,
    );
    try {
      return await crear(
        nombre: nombre,
        descripcion: descripcion,
        tipo: tipo,
        fotoPortadaUrl: url,
      );
    } catch (_) {
      await _eliminarPortadaSubida(url);
      rethrow;
    }
  }

  Future<void> _eliminarPortadaSubida(String publicUrl) async {
    try {
      final segmentos = Uri.parse(publicUrl).pathSegments;
      final bucketIndex = segmentos.lastIndexOf(bucketMedia);
      if (bucketIndex < 0 || bucketIndex + 1 >= segmentos.length) return;
      final path = segmentos.sublist(bucketIndex + 1).join('/');
      if (path.isEmpty) return;
      await clienteSupabase.storage.from(bucketMedia).remove([path]);
    } catch (_) {
      // Mantener el error de creación original.
    }
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
    final tipoNorm = tipo.trim().toLowerCase() == 'privado'
        ? 'privado'
        : 'publico';
    final desc = descripcion?.trim();
    final foto = fotoPortadaUrl?.trim();

    final raw = await clienteSupabase.rpc(
      'crear_comunidad_con_admin',
      params: {
        'p_nombre': nombreTrim,
        'p_descripcion': (desc == null || desc.isEmpty) ? null : desc,
        'p_tipo': tipoNorm,
        'p_foto_portada': (foto == null || foto.isEmpty) ? null : foto,
      },
    );
    final idNum = raw is int ? raw : int.tryParse('$raw');
    if (idNum == null) {
      throw const AuthException('Respuesta inválida al crear la comunidad.');
    }

    final creada = await porId('$idNum');
    if (creada == null) {
      return ComunidadHaku(
        id: '$idNum',
        nombre: nombreTrim,
        descripcion: desc ?? '',
        imagenUrl: foto ?? '',
        creadorId: user.id,
        tipo: tipoNorm,
        miembroIds: [user.id],
        miembrosCantidad: 1,
        estadoMembresiaPorUsuario: {user.id: 'aprobado'},
        rolPorUsuario: {user.id: 'admin'},
        fechaCreacion: DateTime.now(),
        remoto: true,
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

  Future<List<MiembroComunidadRemoto>> listarMiembros(
    String comunidadId,
  ) async {
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
