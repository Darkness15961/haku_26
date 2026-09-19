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
  orden,
  tipo,
  proveedor_video_id,
  miniatura_url,
  video_estado
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
),
publicacion_salida (
  salida_id,
  salida:salida_id (
    id,
    titulo
  )
),
publicacion_me_gusta(count),
le_di_me_gusta,
publicacion_guardada_por_mi
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
    String estado = 'publico',
    String? comunidadId,
    String? lugarId,
    String? rutaId,
    String? salidaId,
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
        estado: estado,
        comunidadId: comunidadId,
        lugarId: lugarId,
        rutaId: rutaId,
        salidaId: salidaId,
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

  /// Insert publicación + opcionales (comunidad / lugar / ruta / salida / imagen).
  /// [contenido] obligatorio (CHECK BD 1..4000).
  Future<ModeloPublicacionRemota> crear({
    required String contenido,
    String estado = 'publico',
    String? comunidadId,
    String? lugarId,
    String? rutaId,
    String? salidaId,
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
    final salidaNum = int.tryParse(salidaId?.trim() ?? '');
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
    if (salidaId != null && salidaId.trim().isNotEmpty && salidaNum == null) {
      throw const AuthException('Salida inválida');
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
          'p_salida_id': salidaNum,
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

  /// Hard-delete: Borrado permanente de la base de datos.
  /// Se usa para limpiar registros creados cuando falla la subida de un archivo.
  Future<void> eliminarFisica(String id) async {
    if (!supabaseListo) return;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) return;
    
    final idNum = int.tryParse(id.trim());
    if (idNum == null) return;
    await clienteSupabase
        .from('publicacion')
        .delete()
        .eq('id', idNum)
        .eq('usuario_id', user.id);
  }

  Future<void> darMeGusta(String publicacionId) async {
    if (!supabaseListo) return;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión para dar me gusta');
    }

    final idNum = int.tryParse(publicacionId.trim());
    if (idNum == null) return;

    try {
      await clienteSupabase.from('publicacion_me_gusta').insert({
        'publicacion_id': idNum,
        'usuario_id': user.id,
      });
    } on PostgrestException catch (e) {
      // Si ya le dio me gusta, ignoramos el error de clave primaria duplicada (23505)
      if (e.code == '23505') return;
      throw AuthException(
        e.message.trim().isEmpty ? 'No se pudo dar me gusta' : e.message,
      );
    }
  }

  Future<void> quitarMeGusta(String publicacionId) async {
    if (!supabaseListo) return;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) return;

    final idNum = int.tryParse(publicacionId.trim());
    if (idNum == null) return;

    await clienteSupabase
        .from('publicacion_me_gusta')
        .delete()
        .eq('publicacion_id', idNum)
        .eq('usuario_id', user.id);
  }

  Future<void> guardarPublicacion(String publicacionId) async {
    if (!supabaseListo) return;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión para guardar');
    }

    final idNum = int.tryParse(publicacionId.trim());
    if (idNum == null) return;

    try {
      await clienteSupabase.from('publicacion_guardada').insert({
        'publicacion_id': idNum,
        'usuario_id': user.id,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') return;
      throw AuthException(
        e.message.trim().isEmpty ? 'No se pudo guardar la publicación' : e.message,
      );
    }
  }

  Future<void> quitarGuardadoPublicacion(String publicacionId) async {
    if (!supabaseListo) return;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) return;

    final idNum = int.tryParse(publicacionId.trim());
    if (idNum == null) return;

    await clienteSupabase
        .from('publicacion_guardada')
        .delete()
        .eq('publicacion_id', idNum)
        .eq('usuario_id', user.id);
  }

  Future<List<ModeloPublicacionRemota>> listarPublicacionesGuardadas() async {
    if (!supabaseListo) return const [];
    final user = clienteSupabase.auth.currentUser;
    if (user == null) return const [];

    final rows = await clienteSupabase
        .from('publicacion_guardada')
        .select('publicacion:publicacion_id!inner($_selectFeed)')
        .eq('usuario_id', user.id)
        .eq('publicacion.estado', 'publico')
        .order('fecha_creacion', ascending: false);

    return _mapearVinculadas(rows);
  }
}
