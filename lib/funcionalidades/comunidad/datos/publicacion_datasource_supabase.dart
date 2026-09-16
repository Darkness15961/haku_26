import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../dominio/modelo_publicacion.dart';

/// CRUD de `public.publicacion` + etiquetas / multimedia / lugar.
/// Sin likes (no hay tabla). Soft-delete vía `estado = eliminado`.
class PublicacionDataSourceSupabase {
  static const bucketMedia = 'haku-storage-produccion-2026';
  static const int maxLenContenido = 4000;

  static const _selectFeed = '''
id,
usuario_id,
contenido,
estado,
fecha_creacion,
usuario:usuario_id (
  id,
  nombre_nick,
  foto_perfil
),
publicacion_multimedia (
  id,
  url_archivo,
  orden
),
publicacion_etiqueta_comunidad (
  comunidad_id,
  comunidad:comunidad_id (
    id,
    nombre
  )
),
publicacion_lugar (
  lugar_id,
  lugar:lugar_id (
    id,
    nombre
  )
)
''';

  Future<List<ModeloPublicacionRemota>> listarPublicas({int limite = 40}) async {
    if (!supabaseListo) return const [];

    final rows = await clienteSupabase
        .from('publicacion')
        .select(_selectFeed)
        .eq('estado', 'publico')
        .order('fecha_creacion', ascending: false)
        .limit(limite);

    // Defensivo: evita duplicados si el embed devolviera filas repetidas.
    final vistos = <String>{};
    final out = <ModeloPublicacionRemota>[];
    for (final e in rows as List<dynamic>) {
      final p = ModeloPublicacionRemota.desdeFilaRemota(
        Map<String, dynamic>.from(e as Map),
      );
      if (p.id.isEmpty || p.contenido.isEmpty) continue;
      if (!vistos.add(p.id)) continue;
      out.add(p);
    }
    return out;
  }

  /// Publicaciones propias (perfil): no eliminadas.
  Future<List<ModeloPublicacionRemota>> listarDeUsuario(
    String usuarioId, {
    int limite = 80,
  }) async {
    if (!supabaseListo) return const [];
    final uid = usuarioId.trim();
    if (uid.isEmpty) return const [];

    final rows = await clienteSupabase
        .from('publicacion')
        .select(_selectFeed)
        .eq('usuario_id', uid)
        .neq('estado', 'eliminado')
        .order('fecha_creacion', ascending: false)
        .limit(limite);

    final vistos = <String>{};
    final out = <ModeloPublicacionRemota>[];
    for (final e in rows as List<dynamic>) {
      final p = ModeloPublicacionRemota.desdeFilaRemota(
        Map<String, dynamic>.from(e as Map),
      );
      if (p.id.isEmpty) continue;
      if (!vistos.add(p.id)) continue;
      out.add(p);
    }
    return out;
  }

  Future<ModeloPublicacionRemota?> porId(String id) async {
    if (!supabaseListo) return null;
    final idNum = int.tryParse(id.trim());
    if (idNum == null) return null;

    final row = await clienteSupabase
        .from('publicacion')
        .select(_selectFeed)
        .eq('id', idNum)
        .maybeSingle();
    if (row == null) return null;
    return ModeloPublicacionRemota.desdeFilaRemota(
      Map<String, dynamic>.from(row),
    );
  }

  Future<String> subirImagen({
    required String userId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String extension = 'jpg',
  }) async {
    if (bytes.isEmpty) {
      throw const AuthException('La foto está vacía');
    }
    final path =
        '$userId/publicaciones/${DateTime.now().millisecondsSinceEpoch}.$extension';
    try {
      await clienteSupabase.storage.from(bucketMedia).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );
    } on StorageException catch (e) {
      throw AuthException(
        e.message.trim().isEmpty
            ? 'No se pudo subir la foto al storage'
            : 'Storage: ${e.message}',
      );
    }
    return clienteSupabase.storage.from(bucketMedia).getPublicUrl(path);
  }

  /// Insert publicación + opcionales (comunidad / lugar / imagen).
  /// [contenido] obligatorio (CHECK BD 1..4000).
  Future<ModeloPublicacionRemota> crear({
    required String contenido,
    String estado = 'publico',
    String? comunidadId,
    String? lugarId,
    String? imagenUrl,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('Supabase no disponible');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión para publicar');
    }

    final texto = contenido.trim();
    if (texto.isEmpty) {
      throw const AuthException('Escribe una descripción');
    }
    if (texto.length > maxLenContenido) {
      throw const AuthException('El texto es demasiado largo');
    }

    final estadoNorm =
        estado.trim().toLowerCase() == 'privado' ? 'privado' : 'publico';

    final comNum = int.tryParse(comunidadId?.trim() ?? '');
    final lugarNum = int.tryParse(lugarId?.trim() ?? '');
    final url = imagenUrl?.trim() ?? '';

    if (comunidadId != null &&
        comunidadId.trim().isNotEmpty &&
        comNum == null) {
      throw const AuthException('Comunidad inválida para etiquetar');
    }
    if (lugarId != null && lugarId.trim().isNotEmpty && lugarNum == null) {
      throw const AuthException('Lugar inválido');
    }

    // Pre-check: falla antes de crear fila huérfana.
    if (comNum != null) {
      await _assertPuedeEtiquetarComunidad(comNum);
    }
    if (lugarNum != null) {
      await _assertLugarActivo(lugarNum);
    }

    final insertado = await clienteSupabase
        .from('publicacion')
        .insert({
          'usuario_id': user.id,
          'contenido': texto,
          'estado': estadoNorm,
        })
        .select('id')
        .single();

    final idRaw = insertado['id'];
    final idNum = idRaw is int ? idRaw : int.parse('$idRaw');

    try {
      // Multimedia primero: si falla etiqueta, el rollback deja menos basura visible.
      if (url.isNotEmpty) {
        await clienteSupabase.from('publicacion_multimedia').insert({
          'publicacion_id': idNum,
          'url_archivo': url,
          'orden': 1,
          // Columna NOT NULL sin default en schema remoto.
          'tipo': 'imagen',
        });
      }
      if (comNum != null) {
        await clienteSupabase.from('publicacion_etiqueta_comunidad').insert({
          'publicacion_id': idNum,
          'comunidad_id': comNum,
        });
      }
      if (lugarNum != null) {
        await clienteSupabase.from('publicacion_lugar').insert({
          'publicacion_id': idNum,
          'lugar_id': lugarNum,
        });
      }
    } catch (e) {
      await _revertirCreacion(idNum, user.id);
      throw AuthException(_mensajeFalloExtra(e));
    }

    final creada = await porId('$idNum');
    if (creada == null) {
      await _revertirCreacion(idNum, user.id);
      throw const AuthException(
        'Se guardó mal la publicación; se revirtió. Probá de nuevo.',
      );
    }
    return creada;
  }

  Future<void> _assertPuedeEtiquetarComunidad(int comunidadId) async {
    final row = await clienteSupabase
        .from('comunidad')
        .select('id, tipo, estado, usuario_creador_id')
        .eq('id', comunidadId)
        .maybeSingle();
    if (row == null) {
      throw const AuthException(
        'No podés etiquetar esa comunidad (no visible o no existe).',
      );
    }
    if (row['estado'] != true) {
      throw const AuthException('Esa comunidad está inactiva.');
    }
    final tipo = (row['tipo'] as String?)?.toLowerCase() ?? 'publico';
    if (tipo == 'publico') return;

    final uid = clienteSupabase.auth.currentUser?.id;
    if (uid == null) {
      throw const AuthException('Inicia sesión para etiquetar.');
    }
    if ('${row['usuario_creador_id'] ?? ''}' == uid) return;

    final mem = await clienteSupabase
        .from('comunidad_miembro')
        .select('rol, estado')
        .eq('comunidad_id', comunidadId)
        .eq('usuario_id', uid)
        .maybeSingle();
    final est = (mem?['estado'] as String?)?.toLowerCase();
    final rol = (mem?['rol'] as String?)?.toLowerCase();
    if (est != 'aprobado' && rol != 'admin') {
      throw const AuthException(
        'Solo miembros aprobados pueden etiquetar esa comunidad privada.',
      );
    }
  }

  Future<void> _assertLugarActivo(int lugarId) async {
    final row = await clienteSupabase
        .from('lugar')
        .select('id, estado')
        .eq('id', lugarId)
        .maybeSingle();
    if (row == null || row['estado'] != true) {
      throw const AuthException(
        'Ese lugar no está activo en Explora. Elige otro o ninguno.',
      );
    }
  }

  /// Soft-delete verificado (exige fila devuelta). Sin eso quedan huérfanas.
  Future<void> _revertirCreacion(int idNum, String userId) async {
    try {
      final row = await clienteSupabase
          .from('publicacion')
          .update({'estado': 'eliminado'})
          .eq('id', idNum)
          .eq('usuario_id', userId)
          .select('id')
          .maybeSingle();
      if (row == null) {
        // Último recurso: sin filtro usuario (RLS igual limita a propias).
        await clienteSupabase
            .from('publicacion')
            .update({'estado': 'eliminado'})
            .eq('id', idNum)
            .select('id')
            .maybeSingle();
      }
    } catch (_) {
      // El caller ya va a lanzar el error de negocio.
    }
  }

  String _mensajeFalloExtra(Object e) {
    final raw = e is AuthException
        ? e.message
        : (e is StorageException
            ? e.message
            : (e is PostgrestException ? e.message : '$e'));
    final low = raw.toLowerCase();
    if (low.contains('tipo') && low.contains('null')) {
      return 'Falta el tipo de multimedia en el servidor. '
          'Hacé push de la migración 700 o reintentá tras actualizar.';
    }
    if (low.contains('bucket') ||
        low.contains('storage') ||
        low.contains('upload') ||
        low.contains('payload') ||
        low.contains('row size')) {
      return 'No se pudo subir la foto al storage. Revisá sesión y bucket.';
    }
    if (low.contains('etiqueta') ||
        low.contains('comunidad') ||
        low.contains('row-level security') ||
        low.contains('rls') ||
        low.contains('42501')) {
      return 'No se pudo etiquetar la comunidad. '
          'Publicá sin comunidad o uníte/aprobá membresía. '
          'La publicación fallida se revirtió.';
    }
    if (low.contains('lugar')) {
      return 'No se pudo asociar el lugar. Probá otro o ninguno. '
          'La publicación fallida se revirtió.';
    }
    if (raw.trim().isNotEmpty && raw.length < 160) {
      return 'No se pudo guardar la publicación: $raw';
    }
    return 'No se pudo guardar foto/etiqueta. '
        'La publicación fallida se revirtió.';
  }

  /// Soft-delete: `estado = eliminado` (no hard DELETE).
  Future<void> eliminarLogica(String id) async {
    if (!supabaseListo) return;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión');
    }
    final idNum = int.tryParse(id.trim());
    if (idNum == null) return;

    final row = await clienteSupabase
        .from('publicacion')
        .update({'estado': 'eliminado'})
        .eq('id', idNum)
        .eq('usuario_id', user.id)
        .select('id')
        .maybeSingle();
    if (row == null) {
      throw const AuthException('No se pudo eliminar la publicación');
    }
  }
}
