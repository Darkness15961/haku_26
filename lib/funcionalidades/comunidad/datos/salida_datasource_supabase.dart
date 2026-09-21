import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../dominio/modelo_salida.dart';

/// CRUD de `public.salida` + `salida_participante`.
/// Solo columnas reales del schema.
class SalidaDataSourceSupabase {
  static const _selectListado = '''
id,
titulo,
organizador_id,
comunidad_id,
ruta_id,
fecha_hora_inicio,
punto_encuentro_lat,
punto_encuentro_lon,
punto_encuentro_lugar_id,
notas_grupales,
tipo,
cupos_totales,
minimo_para_salir,
estado,
inscripcion_abierta,
fecha_creacion,
salida_participante (
  usuario_id,
  estado
),
lugar:punto_encuentro_lugar_id (
  id,
  nombre,
  foto_portada,
  latitud,
  longitud
),
comunidad:comunidad_id (
  id,
  nombre
),
ruta:ruta_id (
  id,
  slug,
  nombre,
  resumen
),
organizador:usuario!organizador_id (
  id,
  nombre_nick
)
''';

  Future<List<ModeloSalidaRemota>> listarVisibles({
    String? lugarId,
    String? rutaId,
    String? comunidadId,
  }) async {
    if (!supabaseListo) return const [];

    final lugarNum = int.tryParse(lugarId?.trim() ?? '');
    final rutaNum = int.tryParse(rutaId?.trim() ?? '');
    final comNum = int.tryParse(comunidadId?.trim() ?? '');
    if (lugarId != null && lugarId.trim().isNotEmpty && lugarNum == null) {
      // Evita devolver el listado global cuando el filtro es un slug demo.
      return const [];
    }
    if (rutaId != null && rutaId.trim().isNotEmpty && rutaNum == null) {
      return const [];
    }
    if (comunidadId != null &&
        comunidadId.trim().isNotEmpty &&
        comNum == null) {
      // Evita listado global si llega slug demo / id no numérico.
      return const [];
    }

    final rows = await clienteSupabase.rpc(
      'listar_salidas_resumen',
      params: {
        'p_lugar_id': lugarNum,
        'p_ruta_id': rutaNum,
        'p_comunidad_id': comNum,
      },
    );
    final uid = clienteSupabase.auth.currentUser?.id;
    return (rows as List<dynamic>)
        .whereType<Map>()
        .map((raw) {
          final fila = Map<String, dynamic>.from(raw);
          fila['organizador'] = {
            'id': fila['organizador_id'],
            'nombre_nick': fila['organizador_nick'],
          };
          fila['lugar'] = {
            'id': fila['punto_encuentro_lugar_id'],
            'nombre': fila['lugar_nombre'],
            'foto_portada': fila['lugar_foto_portada'],
          };
          fila['comunidad'] = {
            'id': fila['comunidad_id'],
            'nombre': fila['comunidad_nombre'],
          };
          fila['ruta'] = {
            'id': fila['ruta_id'],
            'nombre': fila['ruta_nombre'],
            'resumen': fila['ruta_resumen'],
          };
          final miEstado = (fila['mi_estado_participante'] as String?)?.trim();
          fila['salida_participante'] = [
            if (uid != null && miEstado == 'confirmado')
              {'usuario_id': uid, 'estado': miEstado},
          ];
          return ModeloSalidaRemota.desdeFilaRemota(fila);
        })
        .where((s) => s.id.isNotEmpty && s.titulo.isNotEmpty)
        .toList(growable: false);
  }

  Future<ModeloSalidaRemota?> porId(String id) async {
    if (!supabaseListo) return null;
    final idNum = int.tryParse(id.trim());
    if (idNum == null) return null;

    final row = await clienteSupabase
        .from('salida')
        .select(_selectListado)
        .eq('id', idNum)
        .maybeSingle();

    if (row == null) return null;
    return ModeloSalidaRemota.desdeFilaRemota(Map<String, dynamic>.from(row));
  }

  /// Inserta salida. Lat/lon obligatorios en BD.
  /// [notasGrupales] vacío → NULL. [lugarId] opcional.
  /// Tras crear, inscribe al organizador como participante confirmado.
  Future<ModeloSalidaRemota> crear({
    required String titulo,
    required DateTime fechaHoraInicio,
    required double latitud,
    required double longitud,
    required int cuposTotales,
    int minimoParaSalir = 1,
    String? lugarId,
    String? rutaId,
    String? comunidadId,
    String? notasGrupales,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('No hay conexión con el servidor.');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Inicia sesión para crear una salida.');
    }
    final tituloTrim = titulo.trim();
    if (tituloTrim.isEmpty) {
      throw const AuthException('El título es obligatorio.');
    }
    if (cuposTotales < 1) {
      throw const AuthException('Cupos debe ser al menos 1.');
    }
    if (minimoParaSalir < 1 || minimoParaSalir > cuposTotales) {
      throw const AuthException('Mínimo inválido respecto a cupos.');
    }

    final comNum = int.tryParse(comunidadId?.trim() ?? '');
    final lugarNum = int.tryParse(lugarId?.trim() ?? '');
    final rutaNum = int.tryParse(rutaId?.trim() ?? '');
    if (comunidadId != null &&
        comunidadId.trim().isNotEmpty &&
        comNum == null) {
      throw const AuthException('Comunidad inválida.');
    }
    if (lugarId != null && lugarId.trim().isNotEmpty && lugarNum == null) {
      throw const AuthException('Lugar inválido.');
    }
    if (rutaId != null && rutaId.trim().isNotEmpty && rutaNum == null) {
      throw const AuthException('Ruta inválida.');
    }
    final notas = notasGrupales?.trim();

    try {
      final raw = await clienteSupabase.rpc(
        'crear_salida_con_organizador',
        params: {
          'p_titulo': tituloTrim,
          'p_fecha_hora_inicio': fechaHoraInicio.toUtc().toIso8601String(),
          'p_latitud': latitud,
          'p_longitud': longitud,
          'p_cupos_totales': cuposTotales,
          'p_minimo_para_salir': minimoParaSalir,
          'p_lugar_id': lugarNum,
          'p_ruta_id': rutaNum,
          'p_comunidad_id': comNum,
          'p_notas_grupales': (notas == null || notas.isEmpty) ? null : notas,
        },
      );
      final idNum = raw is int ? raw : int.tryParse('$raw');
      if (idNum == null) {
        throw const AuthException('Respuesta inválida al crear la salida.');
      }

      final creada = await porId('$idNum');
      if (creada == null) {
        return ModeloSalidaRemota(
          id: '$idNum',
          titulo: tituloTrim,
          organizadorId: user.id,
          comunidadId: comNum?.toString(),
          rutaId: rutaNum?.toString(),
          fechaHoraInicio: fechaHoraInicio,
          latitud: latitud,
          longitud: longitud,
          lugarId: lugarNum?.toString(),
          notasGrupales: notas,
          tipo: comNum == null ? 'publica' : 'comunidad',
          cuposTotales: cuposTotales,
          minimoParaSalir: minimoParaSalir,
          participanteIds: [user.id],
          inscritosCantidad: 1,
        );
      }
      return creada;
    } on PostgrestException catch (e) {
      throw AuthException(
        e.message.trim().isEmpty ? 'No se pudo crear la salida.' : e.message,
      );
    }
  }

  Future<void> inscribirse(String salidaId) async {
    if (!supabaseListo) {
      throw const AuthException('No hay conexión con el servidor.');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Inicia sesión para inscribirte.');
    }
    final idNum = int.tryParse(salidaId.trim());
    if (idNum == null) {
      throw const AuthException('Salida inválida.');
    }

    final salida = await porId('$idNum');
    if (salida == null) {
      throw const AuthException('Salida no encontrada.');
    }
    if (salida.estado != 'programada') {
      throw const AuthException('Esta salida no admite inscripciones.');
    }
    if (salida.inscrito(user.id)) return;
    if (salida.llena) {
      throw const AuthException('No hay cupos disponibles.');
    }

    try {
      // PK (salida_id, usuario_id): si ya canceló, reactivar — no INSERT duplicado.
      final previa = await clienteSupabase
          .from('salida_participante')
          .select('estado')
          .eq('salida_id', idNum)
          .eq('usuario_id', user.id)
          .maybeSingle();

      if (previa != null) {
        final est = (previa['estado'] as String?)?.toLowerCase() ?? '';
        if (est == 'confirmado') return;
        await clienteSupabase
            .from('salida_participante')
            .update({'estado': 'confirmado'})
            .eq('salida_id', idNum)
            .eq('usuario_id', user.id);
        return;
      }

      await clienteSupabase.from('salida_participante').insert({
        'salida_id': idNum,
        'usuario_id': user.id,
        'estado': 'confirmado',
      });
    } on PostgrestException catch (e) {
      final msg = e.message.trim();
      if (msg.isEmpty) {
        throw const AuthException('No se pudo completar la inscripción.');
      }
      throw AuthException(msg);
    }
  }

  /// Marca participación como `cancelado` (columna real; no borra la fila).
  Future<void> cancelarInscripcion(String salidaId) async {
    if (!supabaseListo) {
      throw const AuthException('No hay conexión con el servidor.');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Inicia sesión.');
    }
    final idNum = int.tryParse(salidaId.trim());
    if (idNum == null) {
      throw const AuthException('Salida inválida.');
    }

    // Organizador no se baja: dejaría la salida sin dueño confirmado.
    final salida = await porId('$idNum');
    if (salida != null && salida.organizadorId == user.id) {
      throw const AuthException(
        'El organizador no puede cancelar su inscripción.',
      );
    }

    final row = await clienteSupabase
        .from('salida_participante')
        .update({'estado': 'cancelado'})
        .eq('salida_id', idNum)
        .eq('usuario_id', user.id)
        .select('salida_id')
        .maybeSingle();
    if (row == null) {
      throw const AuthException('No se pudo cancelar la inscripción.');
    }
  }

  Future<void> cambiarEstadoInscripcionSalida(String salidaId, bool abierta) async {
    if (!supabaseListo) {
      throw const AuthException('No hay conexión con el servidor.');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Inicia sesión.');
    }
    final idNum = int.tryParse(salidaId.trim());
    if (idNum == null) {
      throw const AuthException('Salida inválida.');
    }

    try {
      await clienteSupabase
          .from('salida')
          .update({'inscripcion_abierta': abierta})
          .eq('id', idNum)
          .eq('organizador_id', user.id);
    } on PostgrestException catch (e) {
      throw AuthException(e.message.trim());
    }
  }
}
