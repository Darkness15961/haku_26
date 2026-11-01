import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../dominio/modelos/modelo_lugar.dart';
import '../dominio/modelos/modelo_lugar_propio.dart';

/// Lugares activos desde `public.lugar` (distrito obligatorio; provincia vía join).
class LugarDataSourceSupabase {
  static const bucketMedia = 'haku-storage-produccion-2026';

  /// Provincia solo a través de distrito → provincia (sin provincia_id en lugar).
  static const _selectFicha = '''
id,
nombre,
descripcion,
altitud,
latitud,
longitud,
foto_portada,
estado,
estado_editorial,
fecha_creacion,
updated_at,
usuario_id,
distrito_id,
distrito:distrito_id (
  id,
  nombre,
  codigo,
  provincia_id,
  provincia:provincia_id ( id, nombre, codigo )
),
lugar_categoria (
  categoria:categoria_id ( id, nombre, tipo )
),
lugar_guardado_por_mi
''';

  Future<List<ModeloLugar>> listarActivos() async {
    if (!supabaseListo) return const [];

    final rows = await clienteSupabase
        .from('lugar')
        .select(_selectFicha)
        .eq('estado', true)
        .eq('estado_editorial', EstadoEditorialLugar.publicado.valor)
        .order('nombre', ascending: true);

    return (rows as List<dynamic>)
        .map(
          (e) =>
              ModeloLugar.desdeFilaRemota(Map<String, dynamic>.from(e as Map)),
        )
        .where((l) => l.id.isNotEmpty && l.nombre.isNotEmpty)
        .toList();
  }

  /// Lugares registrados por el usuario (perfil).
  Future<List<ModeloLugar>> listarDeUsuario(String usuarioId) async {
    if (!supabaseListo) return const [];
    final uid = usuarioId.trim();
    if (uid.isEmpty) return const [];

    final rows = await clienteSupabase
        .from('lugar')
        .select(_selectFicha)
        .eq('usuario_id', uid)
        .eq('estado', true)
        .eq('estado_editorial', EstadoEditorialLugar.publicado.valor)
        .order('fecha_creacion', ascending: false);

    return (rows as List<dynamic>)
        .map(
          (e) =>
              ModeloLugar.desdeFilaRemota(Map<String, dynamic>.from(e as Map)),
        )
        .where((l) => l.id.isNotEmpty && l.nombre.isNotEmpty)
        .toList();
  }

  Future<List<ModeloLugarPropio>> listarPropios() async {
    if (!supabaseListo) return const [];
    final user = clienteSupabase.auth.currentUser;
    if (user == null) return const [];

    final rows = await clienteSupabase
        .from('lugar')
        .select(_selectFicha)
        .eq('usuario_id', user.id)
        .order('updated_at', ascending: false);

    return (rows as List<dynamic>)
        .whereType<Map>()
        .map(
          (row) => ModeloLugarPropio.desdeJson(Map<String, dynamic>.from(row)),
        )
        .where((propio) => propio.id.isNotEmpty)
        .toList();
  }

  Future<List<ModeloLugar>> listarPorProvinciaCodigo(String codigo) async {
    final codigoNorm = codigo.trim().toLowerCase();
    if (codigoNorm.isEmpty) return const [];
    final todos = await listarActivos();
    return todos
        .where((l) => l.provinciaCodigo.toLowerCase() == codigoNorm)
        .toList();
  }

  Future<ModeloLugar?> porId(String id) async {
    if (!supabaseListo) return null;
    final idNum = int.tryParse(id.trim());
    if (idNum == null) return null;

    final row = await clienteSupabase
        .from('lugar')
        .select(_selectFicha)
        .eq('id', idNum)
        .maybeSingle();

    if (row == null) return null;
    return ModeloLugar.desdeFilaRemota(Map<String, dynamic>.from(row));
  }

  Future<String> subirFotoPortada({
    required String userId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String extension = 'jpg',
  }) async {
    final path =
        '$userId/lugares/portada_${DateTime.now().millisecondsSinceEpoch}.$extension';
    await clienteSupabase.storage
        .from(bucketMedia)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return clienteSupabase.storage.from(bucketMedia).getPublicUrl(path);
  }

  Future<List<ModeloLugar>> listarCerca({
    required double latitud,
    required double longitud,
    double radioM = 50000,
  }) async {
    if (!supabaseListo) return const [];

    final rows = await clienteSupabase.rpc(
      'lugares_cerca',
      params: {'p_lat': latitud, 'p_lon': longitud, 'p_radio_m': radioM},
    );

    final distKmPorId = <String, double>{};
    for (final raw in (rows as List<dynamic>)) {
      final m = Map<String, dynamic>.from(raw as Map);
      final idNum = m['id'];
      final id = idNum is int ? '$idNum' : '$idNum';
      if (id.isEmpty) continue;
      final distM = (m['distancia_m'] as num?)?.toDouble() ?? 0;
      distKmPorId[id] = distM / 1000.0;
    }
    if (distKmPorId.isEmpty) return const [];

    final todos = await listarActivos();
    final out = <ModeloLugar>[];
    for (final l in todos) {
      final d = distKmPorId[l.id];
      if (d == null) continue;
      out.add(l.copyWith(distanciaKm: d));
    }
    out.sort((a, b) => a.distanciaKm.compareTo(b.distanciaKm));
    return out;
  }

  /// Inserta el Lugar y sus categorías en una sola transacción remota.
  Future<ModeloLugar> crear({
    required String nombre,
    required String descripcion,
    required int distritoId,
    List<int> categoriaIds = const [],
    String? fotoPortadaUrl,
    double latitud = -13.5319,
    double longitud = -71.9675,
    int? altitud,
    EstadoEditorialLugar estadoInicial = EstadoEditorialLugar.publicado,
  }) async {
    return _guardarFicha(
      nombre: nombre,
      descripcion: descripcion,
      distritoId: distritoId,
      categoriaIds: categoriaIds,
      fotoPortadaUrl: fotoPortadaUrl,
      latitud: latitud,
      longitud: longitud,
      altitud: altitud,
      estadoInicial: estadoInicial,
    );
  }

  Future<ModeloLugar> actualizar({
    required String lugarId,
    required String nombre,
    required String descripcion,
    required int distritoId,
    required List<int> categoriaIds,
    String? fotoPortadaUrl,
    required double latitud,
    required double longitud,
    int? altitud,
  }) async {
    return _guardarFicha(
      lugarId: lugarId,
      nombre: nombre,
      descripcion: descripcion,
      distritoId: distritoId,
      categoriaIds: categoriaIds,
      fotoPortadaUrl: fotoPortadaUrl,
      latitud: latitud,
      longitud: longitud,
      altitud: altitud,
      estadoInicial: EstadoEditorialLugar.borrador,
    );
  }

  Future<ModeloLugar> _guardarFicha({
    String? lugarId,
    required String nombre,
    required String descripcion,
    required int distritoId,
    required List<int> categoriaIds,
    required String? fotoPortadaUrl,
    required double latitud,
    required double longitud,
    required int? altitud,
    required EstadoEditorialLugar estadoInicial,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('No hay conexión con el servidor.');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Inicia sesión para registrar un lugar.');
    }
    if (distritoId <= 0) {
      throw const AuthException('Elige un distrito.');
    }
    if (categoriaIds.isEmpty) {
      throw const AuthException('Elige al menos una categoría.');
    }

    final idNumerico = lugarId == null ? null : int.tryParse(lugarId.trim());
    if (lugarId != null && idNumerico == null) {
      throw const AuthException('Lugar inválido.');
    }

    final raw = await clienteSupabase.rpc(
      'guardar_lugar_propio',
      params: {
        'p_nombre': nombre.trim(),
        'p_descripcion': descripcion.trim(),
        'p_distrito_id': distritoId,
        'p_categoria_ids': categoriaIds.toSet().toList(),
        'p_foto_portada': fotoPortadaUrl,
        'p_latitud': latitud,
        'p_longitud': longitud,
        'p_altitud': altitud,
        'p_estado_editorial': estadoInicial.valor,
        'p_lugar_id': idNumerico,
      },
    );

    final idNum = raw is num ? raw.toInt() : int.tryParse('$raw');
    if (idNum == null) {
      throw const AuthException('El Lugar se guardó, pero llegó sin ID.');
    }

    final creado = await porId('$idNum');
    if (creado == null) {
      throw const AuthException('El Lugar se guardó pero no se pudo recargar.');
    }
    return creado;
  }

  Future<ModeloLugarPropio> publicarPropio(String lugarId) {
    return _cambiarEstado(lugarId, EstadoEditorialLugar.publicado);
  }

  Future<ModeloLugarPropio> archivarPropio(String lugarId) {
    return _cambiarEstado(lugarId, EstadoEditorialLugar.archivado);
  }

  Future<ModeloLugarPropio> restaurarPropio(String lugarId) {
    return _cambiarEstado(lugarId, EstadoEditorialLugar.borrador);
  }

  Future<ModeloLugarPropio> _cambiarEstado(
    String lugarId,
    EstadoEditorialLugar estado,
  ) async {
    final idNum = _idPropioValido(lugarId);
    await clienteSupabase.rpc(
      'cambiar_estado_lugar_propio',
      params: {'p_lugar_id': idNum, 'p_estado_editorial': estado.valor},
    );

    final actualizado = await _propioPorId(idNum);
    if (actualizado == null) {
      throw const AuthException(
        'El estado cambió, pero no se pudo recargar el Lugar.',
      );
    }
    return actualizado;
  }

  Future<void> eliminarPropio(String lugarId) async {
    final idNum = _idPropioValido(lugarId);
    final eliminado = await clienteSupabase
        .from('lugar')
        .delete()
        .eq('id', idNum)
        .eq('usuario_id', clienteSupabase.auth.currentUser!.id)
        .neq('estado_editorial', EstadoEditorialLugar.publicado.valor)
        .select('id')
        .maybeSingle();
    if (eliminado == null) {
      throw const AuthException(
        'Solo puedes eliminar tus Lugares borradores o desactivados.',
      );
    }
  }

  Future<ModeloLugarPropio?> _propioPorId(int id) async {
    final user = clienteSupabase.auth.currentUser;
    if (user == null) return null;
    final row = await clienteSupabase
        .from('lugar')
        .select(_selectFicha)
        .eq('id', id)
        .eq('usuario_id', user.id)
        .maybeSingle();
    if (row == null) return null;
    return ModeloLugarPropio.desdeJson(Map<String, dynamic>.from(row));
  }

  int _idPropioValido(String lugarId) {
    if (!supabaseListo || clienteSupabase.auth.currentUser == null) {
      throw const AuthException('Inicia sesión para administrar Lugares.');
    }
    final id = int.tryParse(lugarId.trim());
    if (id == null) throw const AuthException('Lugar inválido.');
    return id;
  }

  Future<void> guardarLugar(String lugarId) async {
    if (!supabaseListo) return;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión para guardar');
    }

    final idNum = int.tryParse(lugarId.trim());
    if (idNum == null) return;

    try {
      await clienteSupabase.from('lugar_guardado').insert({
        'lugar_id': idNum,
        'usuario_id': user.id,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') return;
      throw AuthException(
        e.message.trim().isEmpty ? 'No se pudo guardar el lugar' : e.message,
      );
    }
  }

  Future<void> quitarGuardadoLugar(String lugarId) async {
    if (!supabaseListo) return;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) return;

    final idNum = int.tryParse(lugarId.trim());
    if (idNum == null) return;

    await clienteSupabase
        .from('lugar_guardado')
        .delete()
        .eq('lugar_id', idNum)
        .eq('usuario_id', user.id);
  }

  Future<List<ModeloLugar>> listarLugaresGuardados() async {
    if (!supabaseListo) return const [];
    final user = clienteSupabase.auth.currentUser;
    if (user == null) return const [];

    final rows = await clienteSupabase
        .from('lugar_guardado')
        .select('lugar:lugar_id!inner($_selectFicha)')
        .eq('usuario_id', user.id)
        .eq('lugar.estado', true)
        .eq('lugar.estado_editorial', EstadoEditorialLugar.publicado.valor)
        .order('fecha_creacion', ascending: false);

    return (rows as List<dynamic>)
        .whereType<Map>()
        .map((row) => row['lugar'])
        .whereType<Map>()
        .map((l) => ModeloLugar.desdeFilaRemota(Map<String, dynamic>.from(l)))
        .toList();
  }
}
