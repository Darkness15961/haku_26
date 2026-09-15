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
organizador:usuario!organizador_id (
  id,
  nombre_nick
)
''';

  Future<List<ModeloSalidaRemota>> listarVisibles({
    String? lugarId,
    String? comunidadId,
  }) async {
    if (!supabaseListo) return const [];

    var query = clienteSupabase
        .from('salida')
        .select(_selectListado)
        .neq('estado', 'cancelada');

    final lugarNum = int.tryParse(lugarId?.trim() ?? '');
    if (lugarId != null &&
        lugarId.trim().isNotEmpty &&
        lugarNum == null) {
      // Evita devolver el listado global cuando el filtro es un slug demo.
      return const [];
    }
    if (lugarNum != null) {
      query = query.eq('punto_encuentro_lugar_id', lugarNum);
    }
    final comNum = int.tryParse(comunidadId?.trim() ?? '');
    if (comunidadId != null &&
        comunidadId.trim().isNotEmpty &&
        comNum == null) {
      // Evita listado global si llega slug demo / id no numérico.
      return const [];
    }
    if (comNum != null) {
      query = query.eq('comunidad_id', comNum);
    }

    final rows = await query.order('fecha_hora_inicio', ascending: true);

    return (rows as List<dynamic>)
        .map(
          (e) => ModeloSalidaRemota.desdeFilaRemota(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .where((s) => s.id.isNotEmpty && s.titulo.isNotEmpty)
        .toList();
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
    final tipo = comNum != null ? 'comunidad' : 'publica';
    final notas = notasGrupales?.trim();

    final insertado = await clienteSupabase
        .from('salida')
        .insert({
          'titulo': tituloTrim,
          'organizador_id': user.id,
          'comunidad_id': comNum,
          'fecha_hora_inicio': fechaHoraInicio.toUtc().toIso8601String(),
          'punto_encuentro_lat': latitud,
          'punto_encuentro_lon': longitud,
          'punto_encuentro_lugar_id': lugarNum,
          'notas_grupales': (notas == null || notas.isEmpty) ? null : notas,
          'tipo': tipo,
          'cupos_totales': cuposTotales,
          'minimo_para_salir': minimoParaSalir,
          'estado': 'programada',
        })
        .select('id')
        .single();

    final idRaw = insertado['id'];
    final idNum = idRaw is int ? idRaw : int.parse('$idRaw');

    try {
      await clienteSupabase.from('salida_participante').insert({
        'salida_id': idNum,
        'usuario_id': user.id,
        'estado': 'confirmado',
      });
    } catch (_) {
      // Evita salida huérfana sin organizador inscrito.
      final revertida = await clienteSupabase
          .from('salida')
          .update({'estado': 'cancelada'})
          .eq('id', idNum)
          .eq('organizador_id', user.id)
          .select('id')
          .maybeSingle();
      if (revertida == null) {
        throw const AuthException(
          'La salida quedó a medias y no se pudo cancelar. Contactá soporte o reintentá.',
        );
      }
      throw const AuthException(
        'La salida se creó pero no se pudo inscribir al organizador. Quedó cancelada.',
      );
    }

    final creada = await porId('$idNum');
    if (creada == null) {
      throw const AuthException('La salida se creó pero no se pudo recargar.');
    }
    return creada;
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
}
