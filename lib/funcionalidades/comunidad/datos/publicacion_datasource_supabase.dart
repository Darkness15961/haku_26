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
),
publicacion_ruta (
  ruta_id,
  ruta:ruta_id (
    id,
    nombre
  )
)
''';

  Future<List<ModeloPublicacionRemota>> listarPublicas({
    int limite = 40,
  }) async {
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

  Future<List<ModeloPublicacionRemota>> listarPorLugar(
    String lugarId, {
    int limite = 40,
  }) async {
    final id = int.tryParse(lugarId.trim());
    if (!supabaseListo || id == null) return const [];
    final rows = await clienteSupabase
        .from('publicacion_lugar')
        .select('''
publicacion:publicacion_id!inner (
  $_selectFeed
)
''')
        .eq('lugar_id', id)
        .eq('publicacion.estado', 'publico')
        .order('fecha_etiquetado', ascending: false)
        .limit(limite);
    return _mapearVinculadas(rows);
  }

  Future<List<ModeloPublicacionRemota>> listarPorRuta(
    String rutaId, {
    int limite = 40,
  }) async {
    final id = int.tryParse(rutaId.trim());
    if (!supabaseListo || id == null) return const [];
    final rows = await clienteSupabase
        .from('publicacion_ruta')
        .select('''
publicacion:publicacion_id!inner (
  $_selectFeed
)
''')
        .eq('ruta_id', id)
        .eq('publicacion.estado', 'publico')
        .order('fecha_etiquetado', ascending: false)
        .limit(limite);
    return _mapearVinculadas(rows);
  }

  Future<List<ModeloPublicacionRemota>> listarPorComunidad(
    String comunidadId, {
    int limite = 40,
  }) async {
    final id = int.tryParse(comunidadId.trim());
    if (!supabaseListo || id == null) return const [];
    final rows = await clienteSupabase
        .from('publicacion_etiqueta_comunidad')
        .select('''
publicacion:publicacion_id!inner (
  $_selectFeed
)
''')
        .eq('comunidad_id', id)
        // No filtrar estado: RLS decide entre comunidad pública/privada.
        .order('fecha_etiquetado', ascending: false)
        .limit(limite);
    return _mapearVinculadas(rows);
  }

  List<ModeloPublicacionRemota> _mapearVinculadas(List<dynamic> rows) {
    final out = <ModeloPublicacionRemota>[];
    final vistos = <String>{};
    for (final raw in rows) {
      if (raw is! Map) continue;
      final publicacion = raw['publicacion'];
      if (publicacion is! Map) continue;
      final modelo = ModeloPublicacionRemota.desdeFilaRemota(
        Map<String, dynamic>.from(publicacion),
      );
      if (modelo.id.isEmpty || !vistos.add(modelo.id)) continue;
      out.add(modelo);
    }
    return out;
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
      await clienteSupabase.storage
          .from(bucketMedia)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
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

  /// Compensa Storage si falla cualquier validación o relación posterior.
  Future<ModeloPublicacionRemota> crearConImagen({
    required String userId,
    required Uint8List bytes,
    required String contentType,
    required String extension,
    required String contenido,
    String? comunidadId,
    String? lugarId,
    String? rutaId,
  }) async {
    final url = await subirImagen(
      userId: userId,
      bytes: bytes,
      contentType: contentType,
      extension: extension,
    );
    try {
      return await crear(
        contenido: contenido,
        comunidadId: comunidadId,
        lugarId: lugarId,
        rutaId: rutaId,
        imagenUrl: url,
      );
    } catch (_) {
      await _eliminarImagenSubida(url);
      rethrow;
    }
  }

  Future<void> _eliminarImagenSubida(String publicUrl) async {
    try {
      final segmentos = Uri.parse(publicUrl).pathSegments;
      final bucketIndex = segmentos.lastIndexOf(bucketMedia);
      if (bucketIndex < 0 || bucketIndex + 1 >= segmentos.length) return;
      final path = segmentos.sublist(bucketIndex + 1).join('/');
      if (path.isEmpty) return;
      await clienteSupabase.storage.from(bucketMedia).remove([path]);
    } catch (_) {
      // La operación principal conserva su error original.
    }
  }

  /// Insert publicación + opcionales (comunidad / lugar / imagen).
  /// [contenido] obligatorio (CHECK BD 1..4000).
  Future<ModeloPublicacionRemota> crear({
    required String contenido,
    String estado = 'publico',
    String? comunidadId,
    String? lugarId,
    String? rutaId,
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

    final estadoNorm = estado.trim().toLowerCase() == 'privado'
        ? 'privado'
        : 'publico';

    final comNum = int.tryParse(comunidadId?.trim() ?? '');
    final lugarNum = int.tryParse(lugarId?.trim() ?? '');
    final rutaNum = int.tryParse(rutaId?.trim() ?? '');
    final url = imagenUrl?.trim() ?? '';

    if (comunidadId != null &&
        comunidadId.trim().isNotEmpty &&
        comNum == null) {
      throw const AuthException('Comunidad inválida para etiquetar');
    }
    if (lugarId != null && lugarId.trim().isNotEmpty && lugarNum == null) {
      throw const AuthException('Lugar inválido');
    }
    if (rutaId != null && rutaId.trim().isNotEmpty && rutaNum == null) {
      throw const AuthException('Ruta inválida');
    }

    try {
      final raw = await clienteSupabase.rpc(
        'crear_publicacion_completa',
        params: {
          'p_contenido': texto,
          'p_estado': estadoNorm,
          'p_comunidad_id': comNum,
          'p_lugar_id': lugarNum,
          'p_ruta_id': rutaNum,
          'p_imagen_url': url.isEmpty ? null : url,
        },
      );
      final idNum = raw is int ? raw : int.tryParse('$raw');
      if (idNum == null) {
        throw const AuthException(
          'Respuesta inválida al crear la publicación.',
        );
      }

      final creada = await porId('$idNum');
      if (creada == null) {
        return ModeloPublicacionRemota(
          id: '$idNum',
          usuarioId: user.id,
          contenido: texto,
          estado: estadoNorm,
          fechaCreacion: DateTime.now(),
          imagenUrl: url.isEmpty ? null : url,
          lugarId: lugarNum?.toString(),
          rutaId: rutaNum?.toString(),
        );
      }
      return creada;
    } on PostgrestException catch (e) {
      throw AuthException(
        e.message.trim().isEmpty
            ? 'No se pudo crear la publicación.'
            : e.message,
      );
    }
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
