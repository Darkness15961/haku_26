import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../dominio/modelo_mensaje_comunidad.dart';

/// Lectura/escritura de chat vía `sala_chat` + `mensaje` + `sala_participante`.
/// Comunidad: RPC `asegurar_sala_comunidad` (SECURITY DEFINER).
class MensajeComunidadDataSourceSupabase {
  /// Alineado al CHECK `mensaje_contenido_valido` en BD.
  static const int maxLenMensaje = 2000;

  static const _selectMensaje = '''
id,
sala_id,
usuario_id,
contenido,
tipo_mensaje,
fecha_envio,
usuario:usuario_id (
  id,
  nombre_nick
)
''';

  /// Crea/obtiene sala tipo=comunidad y sync de participantes.
  Future<String> asegurarSalaComunidad(String comunidadId) async {
    if (!supabaseListo) {
      throw const AuthException('Supabase no disponible');
    }
    final idNum = int.tryParse(comunidadId.trim());
    if (idNum == null) {
      throw const AuthException('Comunidad inválida');
    }
    final raw = await clienteSupabase.rpc(
      'asegurar_sala_comunidad',
      params: {'p_comunidad_id': idNum},
    );
    if (raw == null) {
      throw const AuthException('No se pudo abrir la sala de chat');
    }
    return '$raw';
  }

  /// Últimos [limite] mensajes de una sala, orden cronológico (viejo → nuevo).
  Future<List<ModeloMensajeComunidad>> listarUltimosPorSala(
    String salaId, {
    String? comunidadId,
    int limite = 80,
  }) async {
    if (!supabaseListo) return const [];
    final idNum = int.tryParse(salaId.trim());
    if (idNum == null) return const [];

    final rows = await clienteSupabase
        .from('mensaje')
        .select(_selectMensaje)
        .eq('sala_id', idNum)
        .order('fecha_envio', ascending: false)
        .order('id', ascending: false)
        .limit(limite);

    final list = (rows as List<dynamic>)
        .map(
          (e) => ModeloMensajeComunidad.desdeFilaRemota(
            Map<String, dynamic>.from(e as Map),
            comunidadIdFallback: comunidadId,
          ),
        )
        .where((m) => m.id.isNotEmpty && m.contenido.isNotEmpty)
        .toList();

    return list.reversed.toList();
  }

  /// Compat: asegura sala y lista por comunidad.
  Future<List<ModeloMensajeComunidad>> listarUltimos(
    String comunidadId, {
    int limite = 80,
  }) async {
    final salaId = await asegurarSalaComunidad(comunidadId);
    return listarUltimosPorSala(
      salaId,
      comunidadId: comunidadId,
      limite: limite,
    );
  }

  /// Un último mensaje por comunidad (solo lectura: no crea sala ni roster).
  Future<Map<String, ModeloMensajeComunidad>> ultimosPorComunidades(
    List<String> comunidadIds,
  ) async {
    if (!supabaseListo || comunidadIds.isEmpty) return const {};

    final nums = <int>[];
    final vistos = <int>{};
    for (final id in comunidadIds) {
      final n = int.tryParse(id.trim());
      if (n == null || !vistos.add(n)) continue;
      nums.add(n);
    }
    if (nums.isEmpty) return const {};

    final resultados = await Future.wait(
      nums.map((idNum) async {
        try {
          final sala = await clienteSupabase
              .from('sala_chat')
              .select('id')
              .eq('tipo', 'comunidad')
              .eq('comunidad_id', idNum)
              .maybeSingle();
          if (sala == null || sala['id'] == null) return null;
          final salaNum = sala['id'];
          final row = await clienteSupabase
              .from('mensaje')
              .select(_selectMensaje)
              .eq('sala_id', salaNum)
              .order('fecha_envio', ascending: false)
              .order('id', ascending: false)
              .limit(1)
              .maybeSingle();
          if (row == null) return null;
          return ModeloMensajeComunidad.desdeFilaRemota(
            Map<String, dynamic>.from(row),
            comunidadIdFallback: '$idNum',
          ).copyWith(comunidadId: '$idNum');
        } catch (_) {
          return null;
        }
      }),
    );

    final map = <String, ModeloMensajeComunidad>{};
    for (final m in resultados) {
      if (m == null || m.id.isEmpty || m.comunidadId.isEmpty) continue;
      map[m.comunidadId] = m;
    }
    return map;
  }

  Future<ModeloMensajeComunidad> enviar({
    required String comunidadId,
    required String mensaje,
    String? salaId,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('Supabase no disponible');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión para enviar mensajes');
    }
    final texto = mensaje.trim();
    if (texto.isEmpty) {
      throw const AuthException('Mensaje vacío');
    }
    if (texto.length > maxLenMensaje) {
      throw const AuthException('Mensaje demasiado largo');
    }

    final sala = (salaId != null && salaId.trim().isNotEmpty)
        ? salaId.trim()
        : await asegurarSalaComunidad(comunidadId);
    final salaNum = int.tryParse(sala);
    if (salaNum == null) {
      throw const AuthException('Sala de chat inválida');
    }

    try {
      final row = await clienteSupabase
          .from('mensaje')
          .insert({
            'sala_id': salaNum,
            'usuario_id': user.id,
            'contenido': texto,
            'tipo_mensaje': 'texto',
          })
          .select(_selectMensaje)
          .single();

      return ModeloMensajeComunidad.desdeFilaRemota(
        Map<String, dynamic>.from(row),
        comunidadIdFallback: comunidadId,
      );
    } on PostgrestException catch (e) {
      final msg = e.message.trim();
      throw AuthException(
        msg.isEmpty ? 'No se pudo enviar el mensaje' : msg,
      );
    }
  }

  /// Canal Realtime filtrado por `sala_id`.
  RealtimeChannel suscribirInserts({
    required String salaId,
    required void Function(ModeloMensajeComunidad mensaje) onInsert,
    String? comunidadId,
    void Function(RealtimeSubscribeStatus status, Object? error)? onEstado,
  }) {
    final idNum = int.tryParse(salaId.trim());
    if (idNum == null) {
      throw ArgumentError('sala_id inválido');
    }

    final channel = clienteSupabase.channel(
      'mensaje_sala_${idNum}_${DateTime.now().millisecondsSinceEpoch}',
    );
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensaje',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'sala_id',
            value: idNum,
          ),
          callback: (payload) {
            final raw = payload.newRecord;
            if (raw.isEmpty) return;
            final m = ModeloMensajeComunidad.desdeFilaRemota(
              Map<String, dynamic>.from(raw),
              comunidadIdFallback: comunidadId,
            );
            if (m.id.isEmpty || m.contenido.isEmpty) return;
            onInsert(m);
          },
        )
        .subscribe((status, error) {
          onEstado?.call(status, error);
        });
    return channel;
  }
}
