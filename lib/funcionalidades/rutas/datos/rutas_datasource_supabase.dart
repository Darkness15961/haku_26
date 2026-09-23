import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../dominio/modelos/modelo_ruta.dart';
import '../dominio/modelos/modelo_ruta_propia.dart';
import '../dominio/modelos/solicitud_crear_ruta.dart';
import '../dominio/modelos/trazado_ruta_importado.dart';

/// Resultado de una portada subida antes de publicar la Ruta.
class FotoRutaSubida {
  const FotoRutaSubida({required this.url, required this.path});

  final String url;
  final String path;
}

class RutasDataSourceSupabase {
  static const bucketMedia = 'haku-storage-produccion-2026';

  Future<List<ModeloRuta>> listarPublicadas({int limite = 50}) async {
    if (!supabaseListo) return const [];
    final reloj = Stopwatch()..start();
    final rows = await clienteSupabase
        .from('rutas_publicadas_lista')
        .select('*, ruta_guardada_por_mi')
        .order('publicada_en', ascending: false)
        .limit(limite);
    reloj.stop();
    _medir('rutas.listado', reloj.elapsed);

    return _mapearListado(rows);
  }

  Future<List<ModeloRuta>> listarPublicadasPorIds(Iterable<String> ids) async {
    if (!supabaseListo) return const [];
    final numericos = ids
        .map((id) => int.tryParse(id.trim()))
        .whereType<int>()
        .toSet()
        .toList(growable: false);
    if (numericos.isEmpty) return const [];

    final rows = await clienteSupabase
        .from('rutas_publicadas_lista')
        .select('*, ruta_guardada_por_mi')
        .inFilter('id', numericos);
    return _mapearListado(rows);
  }

  List<ModeloRuta> _mapearListado(List<dynamic> rows) {
    return rows
        .whereType<Map>()
        .map(
          (row) => ModeloRuta.desdeFilaRemota(Map<String, dynamic>.from(row)),
        )
        .where((ruta) => ruta.id.isNotEmpty && ruta.titulo.isNotEmpty)
        .toList(growable: false);
  }

  Future<ModeloRuta?> detallePublicada(String id) async {
    if (!supabaseListo) return null;
    final idNumerico = int.tryParse(id.trim());
    if (idNumerico == null) return null;

    final reloj = Stopwatch()..start();
    final raw = await clienteSupabase.rpc(
      'ruta_publicada_detalle',
      params: {'p_ruta_id': idNumerico},
    );
    reloj.stop();
    _medir('rutas.detalle', reloj.elapsed);

    if (raw is! Map) return null;
    final ruta = ModeloRuta.desdeFilaRemota(Map<String, dynamic>.from(raw));
    return ruta.id.isEmpty ? null : ruta;
  }

  void _medir(String operacion, Duration duracion) {
    assert(() {
      debugPrint('[rendimiento] $operacion ${duracion.inMilliseconds} ms');
      return true;
    }());
  }

  Future<FotoRutaSubida> subirFotoPortada({
    required String userId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String extension = 'jpg',
  }) async {
    final limpia = extension.replaceAll('.', '').trim().toLowerCase();
    final ext = limpia.isEmpty ? 'jpg' : limpia;
    final path =
        '$userId/rutas/portada_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await clienteSupabase.storage
        .from(bucketMedia)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return FotoRutaSubida(
      url: clienteSupabase.storage.from(bucketMedia).getPublicUrl(path),
      path: path,
    );
  }

  Future<void> eliminarFotoSubida(String path) async {
    final p = path.trim();
    if (p.isEmpty) return;
    await clienteSupabase.storage.from(bucketMedia).remove([p]);
  }

  Future<ModeloRuta> crearPublicada(SolicitudCrearRuta solicitud) async {
    if (!supabaseListo) {
      throw const AuthException('No hay conexion con el servidor.');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Inicia sesion para crear una Ruta.');
    }

    final error = solicitud.validar();
    if (error != null) throw AuthException(error);

    final raw = await clienteSupabase.rpc(
      'crear_ruta_publicada',
      params: solicitud.toRpcParams(),
    );

    if (raw is! Map) {
      throw const AuthException('La Ruta se publico, pero no se pudo leer.');
    }
    final ruta = ModeloRuta.desdeFilaRemota(Map<String, dynamic>.from(raw));
    if (ruta.id.isEmpty) {
      throw const AuthException('La Ruta se publico, pero llego sin ID.');
    }
    return ruta;
  }

  Future<List<ModeloRutaPropia>> listarPropias() async {
    if (!supabaseListo) return const [];
    final user = clienteSupabase.auth.currentUser;
    if (user == null) return const [];

    final raw = await clienteSupabase.rpc('mis_rutas');
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((r) => ModeloRutaPropia.desdeJson(Map<String, dynamic>.from(r)))
        .where((r) => r.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<ModeloRutaPropia?> detallePropia(String rutaId) async {
    if (!supabaseListo) return null;
    final idNum = int.tryParse(rutaId.trim());
    if (idNum == null) return null;

    final raw = await clienteSupabase.rpc(
      'ruta_propia_detalle',
      params: {'p_ruta_id': idNum},
    );
    if (raw is! Map) return null;

    final ruta = ModeloRutaPropia.desdeJson(Map<String, dynamic>.from(raw));
    return ruta.id.isEmpty ? null : ruta;
  }

  Future<ModeloRutaPropia> guardarPropia({
    required String? rutaId,
    required SolicitudCrearRuta solicitud,
    required bool publicar,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('No hay conexion con el servidor.');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Inicia sesion para editar una Ruta.');
    }

    final error = solicitud.validar();
    if (error != null) throw AuthException(error);

    final raw = await clienteSupabase.rpc(
      'guardar_ruta_propia',
      params: solicitud.toGuardarRpcParams(rutaId: rutaId, publicar: publicar),
    );
    if (raw is! Map) {
      throw const AuthException('La Ruta se guardo, pero no se pudo leer.');
    }
    final ruta = ModeloRutaPropia.desdeJson(Map<String, dynamic>.from(raw));
    if (ruta.id.isEmpty) {
      throw const AuthException('La Ruta se guardo, pero llego sin ID.');
    }
    return ruta;
  }

  Future<ModeloRutaPropia> guardarTrazadoPropio({
    required String rutaId,
    required TrazadoRutaImportado? trazado,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('No hay conexion con el servidor.');
    }
    final idNum = int.tryParse(rutaId.trim());
    if (idNum == null) throw const AuthException('Ruta invalida.');

    final raw = await clienteSupabase.rpc(
      'guardar_trazado_ruta_propia',
      params: {
        'p_ruta_id': idNum,
        'p_trazado_geojson': trazado?.toLineStringGeoJson(),
      },
    );
    if (raw is! Map) {
      throw const AuthException('El trazado se guardo, pero no se pudo leer.');
    }
    final ruta = ModeloRutaPropia.desdeJson(Map<String, dynamic>.from(raw));
    if (ruta.id.isEmpty) {
      throw const AuthException('El trazado se guardo, pero llego sin ID.');
    }
    return ruta;
  }

  Future<ModeloRutaPropia> archivarPropia(String rutaId) async {
    if (!supabaseListo) {
      throw const AuthException('No hay conexion con el servidor.');
    }
    final idNum = int.tryParse(rutaId.trim());
    if (idNum == null) throw const AuthException('Ruta invalida.');

    final raw = await clienteSupabase.rpc(
      'archivar_ruta_propia',
      params: {'p_ruta_id': idNum},
    );
    if (raw is! Map) {
      throw const AuthException('La Ruta se archivo, pero no se pudo leer.');
    }
    return ModeloRutaPropia.desdeJson(Map<String, dynamic>.from(raw));
  }

  Future<ModeloRutaPropia> publicarPropia(String rutaId) async {
    if (!supabaseListo) {
      throw const AuthException('No hay conexion con el servidor.');
    }
    final idNum = int.tryParse(rutaId.trim());
    if (idNum == null) throw const AuthException('Ruta invalida.');

    final raw = await clienteSupabase.rpc(
      'publicar_ruta_propia',
      params: {'p_ruta_id': idNum},
    );
    if (raw is! Map) {
      throw const AuthException('La Ruta se publico, pero no se pudo leer.');
    }
    return ModeloRutaPropia.desdeJson(Map<String, dynamic>.from(raw));
  }

  Future<ModeloRutaPropia> restaurarPropia(String rutaId) async {
    if (!supabaseListo) {
      throw const AuthException('No hay conexion con el servidor.');
    }
    final idNum = int.tryParse(rutaId.trim());
    if (idNum == null) throw const AuthException('Ruta invalida.');

    final raw = await clienteSupabase.rpc(
      'restaurar_ruta_propia',
      params: {'p_ruta_id': idNum},
    );
    if (raw is! Map) {
      throw const AuthException('La Ruta se restauro, pero no se pudo leer.');
    }
    return ModeloRutaPropia.desdeJson(Map<String, dynamic>.from(raw));
  }

  Future<void> eliminarPropia(String rutaId) async {
    if (!supabaseListo) {
      throw const AuthException('No hay conexion con el servidor.');
    }
    final idNum = int.tryParse(rutaId.trim());
    if (idNum == null) throw const AuthException('Ruta invalida.');

    await clienteSupabase.rpc(
      'eliminar_ruta_propia',
      params: {'p_ruta_id': idNum},
    );
  }

  Future<void> guardarRuta(String rutaId) async {
    if (!supabaseListo) return;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión para guardar');
    }

    final idNum = int.tryParse(rutaId.trim());
    if (idNum == null) return;

    try {
      await clienteSupabase.from('ruta_guardada').insert({
        'ruta_id': idNum,
        'usuario_id': user.id,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') return;
      throw AuthException(
        e.message.trim().isEmpty ? 'No se pudo guardar la ruta' : e.message,
      );
    }
  }

  Future<void> quitarGuardadoRuta(String rutaId) async {
    if (!supabaseListo) return;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) return;

    final idNum = int.tryParse(rutaId.trim());
    if (idNum == null) return;

    await clienteSupabase
        .from('ruta_guardada')
        .delete()
        .eq('ruta_id', idNum)
        .eq('usuario_id', user.id);
  }

  Future<int?> miValoracionRuta(String rutaId) async {
    if (!supabaseListo) return null;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) return null;

    final idNum = int.tryParse(rutaId.trim());
    if (idNum == null) return null;

    final row = await clienteSupabase
        .from('ruta_valoracion')
        .select('puntuacion')
        .eq('ruta_id', idNum)
        .eq('usuario_id', user.id)
        .maybeSingle();
    return (row?['puntuacion'] as num?)?.toInt();
  }

  Future<void> valorarRuta(String rutaId, int puntuacion) async {
    if (!supabaseListo) return;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Inicia sesion para valorar esta Ruta.');
    }
    final idNum = int.tryParse(rutaId.trim());
    if (idNum == null) throw const AuthException('Ruta invalida.');
    if (puntuacion < 1 || puntuacion > 5) {
      throw const AuthException('La valoracion debe estar entre 1 y 5.');
    }

    await clienteSupabase.rpc(
      'valorar_ruta',
      params: {'p_ruta_id': idNum, 'p_puntuacion': puntuacion},
    );
  }

  Future<List<ModeloRuta>> listarRutasGuardadas() async {
    if (!supabaseListo) return const [];
    final user = clienteSupabase.auth.currentUser;
    if (user == null) return const [];

    final rows = await clienteSupabase
        .from('ruta_guardada')
        .select('ruta_id')
        .eq('usuario_id', user.id)
        .order('fecha_creacion', ascending: false);

    final ids = rows.map((r) => '${r['ruta_id']}').toList();
    if (ids.isEmpty) return const [];

    final rutas = await listarPublicadasPorIds(ids);
    // Preservar orden cronológico de guardado
    rutas.sort((a, b) {
      final indexA = ids.indexOf(a.id);
      final indexB = ids.indexOf(b.id);
      return indexA.compareTo(indexB);
    });
    return rutas;
  }
}
