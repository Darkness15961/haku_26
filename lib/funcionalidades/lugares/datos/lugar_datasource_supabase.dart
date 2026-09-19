import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../dominio/modelos/modelo_lugar.dart';

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
acceso,
estado,
fecha_creacion,
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
        .order('nombre', ascending: true);

    return (rows as List<dynamic>)
        .map((e) => ModeloLugar.desdeFilaRemota(Map<String, dynamic>.from(e as Map)))
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
        .order('fecha_creacion', ascending: false);

    return (rows as List<dynamic>)
        .map((e) => ModeloLugar.desdeFilaRemota(Map<String, dynamic>.from(e as Map)))
        .where((l) => l.id.isNotEmpty && l.nombre.isNotEmpty)
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

  Future<List<ModeloLugar>> listarCerca({
    required double latitud,
    required double longitud,
    double radioM = 50000,
  }) async {
    if (!supabaseListo) return const [];

    final rows = await clienteSupabase.rpc(
      'lugares_cerca',
      params: {
        'p_lat': latitud,
        'p_lon': longitud,
        'p_radio_m': radioM,
      },
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

  /// Inserta lugar. Requiere [distritoId] (provincia se deriva del distrito).
  Future<ModeloLugar> crear({
    required String nombre,
    required String descripcion,
    required int distritoId,
    List<int> categoriaIds = const [],
    String? acceso,
    String? fotoPortadaUrl,
    double latitud = -13.5319,
    double longitud = -71.9675,
    int? altitud,
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

    final insertado = await clienteSupabase
        .from('lugar')
        .insert({
          'nombre': nombre.trim(),
          'descripcion': descripcion.trim().isEmpty ? null : descripcion.trim(),
          'distrito_id': distritoId,
          'usuario_id': user.id,
          'latitud': latitud,
          'longitud': longitud,
          'altitud': altitud,
          'acceso':
              (acceso == null || acceso.trim().isEmpty) ? null : acceso.trim(),
          'foto_portada': fotoPortadaUrl,
          'estado': true,
        })
        .select('id')
        .single();

    final lugarId = insertado['id'];
    final idNum = lugarId is int ? lugarId : int.parse('$lugarId');

    if (categoriaIds.isNotEmpty) {
      try {
        final filasCat = categoriaIds
            .toSet()
            .map((cid) => {'lugar_id': idNum, 'categoria_id': cid})
            .toList();
        await clienteSupabase.from('lugar_categoria').insert(filasCat);
      } catch (_) {
        final revertida = await clienteSupabase
            .from('lugar')
            .update({'estado': false})
            .eq('id', idNum)
            .eq('usuario_id', user.id)
            .select('id')
            .maybeSingle();
        if (revertida == null) {
          throw const AuthException(
            'El lugar quedó a medias y no se pudo desactivar. Reintentá.',
          );
        }
        throw const AuthException(
          'El lugar se creó pero fallaron las categorías. Quedó inactivo.',
        );
      }
    }

    final creado = await porId('$idNum');
    if (creado == null) {
      throw const AuthException('El lugar se creó pero no se pudo recargar.');
    }
    return creado;
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
        .order('fecha_creacion', ascending: false);

    return (rows as List<dynamic>)
        .whereType<Map>()
        .map((row) => row['lugar'])
        .whereType<Map>()
        .map((l) => ModeloLugar.desdeFilaRemota(Map<String, dynamic>.from(l)))
        .toList();
  }
}
