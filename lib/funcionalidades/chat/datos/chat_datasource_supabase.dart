import 'dart:async';
import 'dart:typed_data';

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../comunidad/dominio/modelo_comunidad.dart';
import '../../lugares/dominio/logica_ubicacion_lugar.dart';
import '../dominio/contenido_chat_especial.dart';
import '../dominio/modelo_mensaje_chat.dart';

/// Cursor keyset para paginación hacia mensajes más antiguos.
class CursorMensajeChat {
  const CursorMensajeChat({required this.fechaEnvio, required this.id});

  final DateTime fechaEnvio;
  final String id;
}

/// Capa unificada `sala_chat` + `mensaje` + `sala_participante` + reacciones.
class ChatDataSourceSupabase {
  static const bucketChatPrivado = 'haku-chat-privado';
  static const int maxLenMensaje = 2000;
  static const int pageSizeDefault = 40;
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-'
    r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  static const _selectMensaje = '''
id,
sala_id,
usuario_id,
contenido,
tipo_mensaje,
fecha_envio,
editado_en,
eliminado_en,
usuario:usuario_id (
  id,
  nombre_nick
),
mensaje_reaccion (
  usuario_id,
  emoji
)
''';

  String? get _uid => clienteSupabase.auth.currentUser?.id;

  Future<ModeloMensajeChat> _resolverAdjunto(ModeloMensajeChat mensaje) async {
    if (!mensaje.esImagen || !mensaje.contenido.startsWith('chat://')) {
      return mensaje;
    }
    final path = mensaje.contenido.substring('chat://'.length);
    if (path.isEmpty) return mensaje;
    try {
      final url = await clienteSupabase.storage
          .from(bucketChatPrivado)
          .createSignedUrl(path, 3600);
      return mensaje.copyWith(contenido: url);
    } catch (_) {
      return mensaje;
    }
  }

  Map<String, dynamic> _filaRpc(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    throw const AuthException('Respuesta inválida del servidor');
  }

  /// Obtiene el DM existente o lo crea desde una sala grupal compartida.
  Future<String> asegurarSalaPrivada({
    required String otroUsuarioId,
    String? salaOrigenId,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('Supabase no disponible');
    }
    final otro = otroUsuarioId.trim();
    final origen = int.tryParse(salaOrigenId?.trim() ?? '');
    if (!_uuid.hasMatch(otro)) {
      throw const AuthException(
        'Este perfil todavía no está conectado a Mensajes',
      );
    }
    try {
      final raw = await clienteSupabase.rpc(
        'asegurar_sala_privada',
        params: {'p_otro_usuario_id': otro, 'p_sala_origen': origen},
      );
      if (raw == null) {
        throw const AuthException('No se pudo abrir el chat privado');
      }
      return '$raw';
    } on PostgrestException catch (e) {
      throw AuthException(_msgPg(e));
    }
  }

  Future<PerfilChatBasico?> perfilChat(String usuarioId) async {
    if (!supabaseListo || usuarioId.trim().isEmpty) return null;
    try {
      final fila = await clienteSupabase
          .from('usuario')
          .select('id, nombres, apellidos, nombre_nick, foto_perfil')
          .eq('id', usuarioId.trim())
          .maybeSingle();
      if (fila == null) return null;
      return PerfilChatBasico.desdeFila(Map<String, dynamic>.from(fila));
    } catch (_) {
      return null;
    }
  }

  Future<List<PreviewChatSala>> listarChatsPrivados() async {
    if (!supabaseListo || _uid == null) return const [];
    try {
      final raw = await clienteSupabase.rpc('listar_chats_privados');
      final out = <PreviewChatSala>[];
      for (final item in (raw as List<dynamic>)) {
        if (item is! Map) continue;
        final fila = Map<String, dynamic>.from(item);
        final perfil = PerfilChatBasico.desdeFila(fila);
        final salaId = '${fila['sala_id'] ?? ''}'.trim();
        if (salaId.isEmpty || perfil.id.isEmpty) continue;

        ModeloMensajeChat? ultimo;
        final ultimoId = fila['ultimo_id'];
        final fechaRaw = fila['ultimo_fecha'];
        if (ultimoId != null && fechaRaw != null) {
          final fecha = DateTime.tryParse('$fechaRaw')?.toLocal();
          if (fecha != null) {
            ultimo = ModeloMensajeChat(
              id: '$ultimoId',
              salaId: salaId,
              usuarioId: '',
              contenido: '${fila['ultimo_contenido'] ?? ''}',
              tipoMensaje: '${fila['ultimo_tipo'] ?? 'texto'}',
              fechaEnvio: fecha,
            );
          }
        }

        out.add(
          PreviewChatSala(
            salaId: salaId,
            titulo: perfil.nombreCompleto,
            fotoPortada: perfil.fotoPerfil,
            usuarioId: perfil.id,
            tipo: 'privado',
            ultimo: ultimo,
            noLeidos: (fila['no_leidos'] as num?)?.toInt() ?? 0,
          ),
        );
      }
      return out;
    } on PostgrestException catch (e) {
      throw AuthException(_msgPg(e));
    }
  }

  Future<String> asegurarSalaComunidad(
    String comunidadId, {
    bool seedAprobados = true,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('Supabase no disponible');
    }
    final idNum = int.tryParse(comunidadId.trim());
    if (idNum == null) {
      throw const AuthException('Comunidad inválida');
    }
    try {
      final raw = await clienteSupabase.rpc(
        'asegurar_sala_comunidad',
        params: {'p_comunidad_id': idNum, 'p_seed_aprobados': seedAprobados},
      );
      if (raw == null) {
        throw const AuthException('No se pudo abrir la sala de chat');
      }
      return '$raw';
    } on PostgrestException catch (e) {
      throw AuthException(_msgPg(e));
    }
  }

  Future<String> asegurarSalaSalida(
    String salidaId, {
    bool seedConfirmados = true,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('Supabase no disponible');
    }
    final idNum = int.tryParse(salidaId.trim());
    if (idNum == null) {
      throw const AuthException('Salida inválida');
    }
    try {
      final raw = await clienteSupabase.rpc(
        'asegurar_sala_salida',
        params: {'p_salida_id': idNum, 'p_seed_confirmados': seedConfirmados},
      );
      if (raw == null) {
        throw const AuthException('No se pudo abrir el chat de la salida');
      }
      return '$raw';
    } on PostgrestException catch (e) {
      throw AuthException(_msgPg(e));
    }
  }

  Future<void> setParticipanteComunidad({
    required String salaId,
    required String usuarioId,
    required bool activo,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('Supabase no disponible');
    }
    final salaNum = int.tryParse(salaId.trim());
    if (salaNum == null || usuarioId.trim().isEmpty) {
      throw const AuthException('Datos de participante inválidos');
    }
    try {
      await clienteSupabase.rpc(
        'sala_comunidad_set_participante',
        params: {
          'p_sala_id': salaNum,
          'p_usuario_id': usuarioId.trim(),
          'p_activo': activo,
        },
      );
    } on PostgrestException catch (e) {
      throw AuthException(_msgPg(e));
    }
  }

  Future<String> crearSalaComunidadConParticipantes({
    required String comunidadId,
    required Iterable<String> participantes,
  }) async {
    final id = int.tryParse(comunidadId.trim());
    if (!supabaseListo || id == null) {
      throw const AuthException('Comunidad inválida');
    }
    try {
      final raw = await clienteSupabase.rpc(
        'crear_sala_comunidad_con_participantes',
        params: {
          'p_comunidad_id': id,
          'p_participantes': participantes
              .where((e) => e.trim().isNotEmpty)
              .toList(),
        },
      );
      if (raw == null) throw const AuthException('No se pudo crear el chat');
      return '$raw';
    } on PostgrestException catch (e) {
      throw AuthException(_msgPg(e));
    }
  }

  Future<String> crearSalaSalidaConParticipantes({
    required String salidaId,
    required Iterable<String> participantes,
  }) async {
    final id = int.tryParse(salidaId.trim());
    if (!supabaseListo || id == null) {
      throw const AuthException('Salida inválida');
    }
    try {
      final raw = await clienteSupabase.rpc(
        'crear_sala_salida_con_participantes',
        params: {
          'p_salida_id': id,
          'p_participantes': participantes
              .where((e) => e.trim().isNotEmpty)
              .toList(),
        },
      );
      if (raw == null) throw const AuthException('No se pudo crear el chat');
      return '$raw';
    } on PostgrestException catch (e) {
      throw AuthException(_msgPg(e));
    }
  }

  /// Alta/baja masiva (admin). No auto-quita al caller (RPC).
  Future<void> setParticipantesComunidadBatch({
    required String salaId,
    List<String> agregar = const [],
    List<String> quitar = const [],
  }) async {
    if (!supabaseListo) {
      throw const AuthException('Supabase no disponible');
    }
    final salaNum = int.tryParse(salaId.trim());
    if (salaNum == null) {
      throw const AuthException('Sala inválida');
    }
    try {
      await clienteSupabase.rpc(
        'sala_comunidad_set_participantes_batch',
        params: {
          'p_sala_id': salaNum,
          'p_agregar': agregar.where((e) => e.trim().isNotEmpty).toList(),
          'p_quitar': quitar.where((e) => e.trim().isNotEmpty).toList(),
        },
      );
    } on PostgrestException catch (e) {
      throw AuthException(_msgPg(e));
    }
  }

  /// Alta/baja masiva (organizador de salida).
  Future<void> setParticipantesSalidaBatch({
    required String salaId,
    List<String> agregar = const [],
    List<String> quitar = const [],
  }) async {
    if (!supabaseListo) {
      throw const AuthException('Supabase no disponible');
    }
    final salaNum = int.tryParse(salaId.trim());
    if (salaNum == null) {
      throw const AuthException('Sala inválida');
    }
    try {
      await clienteSupabase.rpc(
        'sala_salida_set_participantes_batch',
        params: {
          'p_sala_id': salaNum,
          'p_agregar': agregar.where((e) => e.trim().isNotEmpty).toList(),
          'p_quitar': quitar.where((e) => e.trim().isNotEmpty).toList(),
        },
      );
    } on PostgrestException catch (e) {
      throw AuthException(_msgPg(e));
    }
  }

  /// Solo lectura: ¿existe la sala? (SECURITY DEFINER: no confunde con roster).
  Future<String?> idSalaComunidadSiExiste(String comunidadId) async {
    if (!supabaseListo) return null;
    final idNum = int.tryParse(comunidadId.trim());
    if (idNum == null) return null;
    try {
      final raw = await clienteSupabase.rpc(
        'sala_comunidad_id_si_existe',
        params: {'p_comunidad_id': idNum},
      );
      if (raw == null) return null;
      return '$raw';
    } catch (_) {
      return null;
    }
  }

  Future<String?> idSalaSalidaSiExiste(String salidaId) async {
    if (!supabaseListo) return null;
    final idNum = int.tryParse(salidaId.trim());
    if (idNum == null) return null;
    try {
      final raw = await clienteSupabase.rpc(
        'sala_salida_id_si_existe',
        params: {'p_salida_id': idNum},
      );
      if (raw == null) return null;
      return '$raw';
    } catch (_) {
      return null;
    }
  }

  /// ¿Estoy en el roster de la sala? (SECURITY DEFINER, sin recursión RLS).
  Future<bool> soyParticipanteSala(String salaId) async {
    if (!supabaseListo) return false;
    final idNum = int.tryParse(salaId.trim());
    if (idNum == null) return false;
    try {
      final raw = await clienteSupabase.rpc(
        'es_participante_sala',
        params: {'p_sala_id': idNum},
      );
      return raw == true;
    } catch (_) {
      return false;
    }
  }

  /// IDs en `sala_participante` (quien puede ver/escribir).
  Future<Set<String>> idsParticipantesSala(String salaId) async {
    if (!supabaseListo) return {};
    final idNum = int.tryParse(salaId.trim());
    if (idNum == null) return {};
    try {
      final rows = await clienteSupabase
          .from('sala_participante')
          .select('usuario_id')
          .eq('sala_id', idNum);
      return {
        for (final e in (rows as List<dynamic>))
          if (e is Map && e['usuario_id'] != null) '${e['usuario_id']}'.trim(),
      }..removeWhere((e) => e.isEmpty);
    } catch (_) {
      return {};
    }
  }

  /// Roster picker: miembros aprobados × presencia en chat.
  /// Si [salaId] vacío (modo creación), nadie está en chat aún.
  Future<List<ParticipanteSalaChat>> rosterComunidadParaPicker({
    required String salaId,
    required List<MiembroComunidadRemoto> miembrosAprobados,
  }) async {
    final enChat = salaId.trim().isEmpty
        ? <String>{}
        : await idsParticipantesSala(salaId);
    final out = <ParticipanteSalaChat>[
      for (final m in miembrosAprobados)
        if (m.usuarioId.trim().isNotEmpty)
          ParticipanteSalaChat(
            usuarioId: m.usuarioId.trim(),
            etiqueta: m.etiqueta,
            fotoPerfil: m.fotoPerfil,
            enChat: enChat.contains(m.usuarioId.trim()),
            rolComunidad: m.rol,
          ),
    ];
    out.sort((a, b) {
      if (a.enChat != b.enChat) return a.enChat ? -1 : 1;
      return a.etiqueta.toLowerCase().compareTo(b.etiqueta.toLowerCase());
    });
    return out;
  }

  /// Roster salida: organizador + confirmados × presencia en chat.
  /// Si [salaId] vacío (modo creación), nadie está en chat aún.
  Future<List<ParticipanteSalaChat>> rosterSalidaParaPicker({
    required String salaId,
    required String organizadorId,
    required String organizadorNick,
    required List<String> confirmadoIds,
  }) async {
    final enChat = salaId.trim().isEmpty
        ? <String>{}
        : await idsParticipantesSala(salaId);
    final ids = <String>{
      if (organizadorId.trim().isNotEmpty) organizadorId.trim(),
      ...confirmadoIds.map((e) => e.trim()).where((e) => e.isNotEmpty),
    };
    final nicks = <String, String>{};
    if (ids.isNotEmpty && supabaseListo) {
      try {
        final rows = await clienteSupabase
            .from('usuario')
            .select('id, nombre_nick')
            .inFilter('id', ids.toList());
        for (final e in (rows as List<dynamic>)) {
          if (e is! Map) continue;
          final id = '${e['id'] ?? ''}'.trim();
          if (id.isEmpty) continue;
          final nick = (e['nombre_nick'] as String?)?.trim() ?? '';
          if (nick.isNotEmpty) {
            nicks[id] = nick.startsWith('@') ? nick : '@$nick';
          }
        }
      } catch (_) {}
    }
    final org = organizadorId.trim();
    final out = <ParticipanteSalaChat>[
      for (final id in ids)
        ParticipanteSalaChat(
          usuarioId: id,
          etiqueta:
              nicks[id] ??
              (id == org && organizadorNick.trim().isNotEmpty
                  ? (organizadorNick.trim().startsWith('@')
                        ? organizadorNick.trim()
                        : '@${organizadorNick.trim()}')
                  : (id.length >= 8 ? id.substring(0, 8) : id)),
          enChat: enChat.contains(id),
          rolComunidad: id == org ? 'admin' : 'miembro',
        ),
    ];
    out.sort((a, b) {
      if (a.enChat != b.enChat) return a.enChat ? -1 : 1;
      return a.etiqueta.toLowerCase().compareTo(b.etiqueta.toLowerCase());
    });
    return out;
  }

  /// Últimos [limite] (más recientes), orden cronológico viejo→nuevo.
  /// Incluye soft-deleted (UI muestra placeholder).
  Future<List<ModeloMensajeChat>> listarMensajes(
    String salaId, {
    int limite = pageSizeDefault,
    CursorMensajeChat? antesDe,
    String? comunidadId,
    String? salidaId,
  }) async {
    if (!supabaseListo) return const [];
    final idNum = int.tryParse(salaId.trim());
    if (idNum == null) return const [];
    final uid = _uid;

    try {
      var query = clienteSupabase
          .from('mensaje')
          .select(_selectMensaje)
          .eq('sala_id', idNum);

      if (antesDe != null) {
        final ts = antesDe.fechaEnvio.toUtc().toIso8601String();
        final cid = int.tryParse(antesDe.id);
        if (cid != null) {
          query = query.or(
            'fecha_envio.lt.$ts,and(fecha_envio.eq.$ts,id.lt.$cid)',
          );
        } else {
          query = query.lt('fecha_envio', ts);
        }
      }

      final rows = await query
          .order('fecha_envio', ascending: false)
          .order('id', ascending: false)
          .limit(limite);

      final list = (rows as List<dynamic>)
          .map(
            (e) => ModeloMensajeChat.desdeFilaRemota(
              Map<String, dynamic>.from(e as Map),
              comunidadIdFallback: comunidadId,
              salidaIdFallback: salidaId,
              uidSesion: uid,
            ),
          )
          .where((m) => m.id.isNotEmpty)
          .toList();
      final resueltos = await Future.wait(list.map(_resolverAdjunto));
      return resueltos.reversed.toList();
    } catch (e) {
      if (e is PostgrestException || e is AuthException) rethrow;
      throw AuthException('No se pudieron cargar los mensajes');
    }
  }

  Future<ModeloMensajeChat?> ultimoMensajeSala(
    String salaId, {
    String? comunidadId,
  }) async {
    if (!supabaseListo) return null;
    final idNum = int.tryParse(salaId.trim());
    if (idNum == null) return null;
    try {
      final rows = await clienteSupabase
          .from('mensaje')
          .select(_selectMensaje)
          .eq('sala_id', idNum)
          .isFilter('eliminado_en', null)
          .order('fecha_envio', ascending: false)
          .order('id', ascending: false)
          .limit(1);
      final list = rows as List<dynamic>;
      if (list.isEmpty) return null;
      return ModeloMensajeChat.desdeFilaRemota(
        Map<String, dynamic>.from(list.first as Map),
        comunidadIdFallback: comunidadId,
        uidSesion: _uid,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ModeloMensajeChat> enviarTexto({
    required String salaId,
    required String texto,
    String? comunidadId,
    String? salidaId,
  }) async {
    return _insertMensaje(
      salaId: salaId,
      contenido: texto,
      tipo: 'texto',
      comunidadId: comunidadId,
      salidaId: salidaId,
    );
  }

  Future<ModeloMensajeChat> enviarImagen({
    required String salaId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String extension = 'jpg',
    String? comunidadId,
    String? salidaId,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('Supabase no disponible');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión');
    }
    if (bytes.isEmpty) {
      throw const AuthException('Imagen vacía');
    }
    final sala = salaId.trim();
    final path =
        '${user.id}/$sala/${DateTime.now().millisecondsSinceEpoch}.$extension';
    try {
      await clienteSupabase.storage
          .from(bucketChatPrivado)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );
    } on StorageException catch (e) {
      throw AuthException(
        e.message.trim().isEmpty
            ? 'No se pudo subir la imagen'
            : 'Storage: ${e.message}',
      );
    }
    try {
      return await _insertMensaje(
        salaId: sala,
        contenido: 'chat://$path',
        tipo: 'imagen',
        comunidadId: comunidadId,
        salidaId: salidaId,
      );
    } catch (_) {
      try {
        await clienteSupabase.storage.from(bucketChatPrivado).remove([path]);
      } catch (_) {}
      rethrow;
    }
  }

  /// GPS actual del dispositivo → mensaje `ubicacion` (JSON en contenido).
  Future<ModeloMensajeChat> enviarUbicacionActual({
    required String salaId,
    String label = 'Mi ubicación',
    String? comunidadId,
    String? salidaId,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('Supabase no disponible');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión');
    }

    final servicio = await Geolocator.isLocationServiceEnabled();
    if (!servicio) {
      throw const AuthException('Activá el GPS para compartir ubicación');
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied) {
      throw const AuthException('Permiso de ubicación denegado');
    }
    if (permiso == LocationPermission.deniedForever) {
      throw const AuthException(
        'Ubicación bloqueada. Habilitála en ajustes de la app',
      );
    }

    Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      throw const AuthException('No se pudo obtener la ubicación a tiempo');
    } catch (_) {
      throw const AuthException('No se pudo obtener la ubicación');
    }

    final err = LogicaUbicacionLugar.mensajeErrorUbicacion(
      pos.latitude,
      pos.longitude,
    );
    if (err != null) {
      throw AuthException(err);
    }

    final payload = ContenidoUbicacionChat(
      lat: pos.latitude,
      lng: pos.longitude,
      label: label,
    );
    if (!payload.esValida) {
      throw const AuthException('Ubicación inválida');
    }

    return _insertMensaje(
      salaId: salaId,
      contenido: payload.aContenido(),
      tipo: 'ubicacion',
      comunidadId: comunidadId,
      salidaId: salidaId,
    );
  }

  Future<ModeloMensajeChat> enviarSticker({
    required String salaId,
    required String stickerId,
    String? comunidadId,
    String? salidaId,
  }) async {
    final id = stickerId.trim();
    if (!PackStickersChat.esValido(id)) {
      throw const AuthException('Sticker no válido');
    }
    return _insertMensaje(
      salaId: salaId,
      contenido: id,
      tipo: 'sticker',
      comunidadId: comunidadId,
      salidaId: salidaId,
    );
  }

  Future<ModeloMensajeChat> editarTexto({
    required String mensajeId,
    required String nuevoTexto,
    String? comunidadId,
    String? salidaId,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('Supabase no disponible');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión');
    }
    final texto = nuevoTexto.trim();
    if (texto.isEmpty) {
      throw const AuthException('Mensaje vacío');
    }
    if (texto.length > maxLenMensaje) {
      throw const AuthException('Mensaje demasiado largo');
    }
    final idNum = int.tryParse(mensajeId.trim());
    if (idNum == null) {
      throw const AuthException('Mensaje inválido');
    }
    try {
      final raw = await clienteSupabase.rpc(
        'editar_mensaje_chat',
        params: {'p_mensaje_id': idNum, 'p_contenido': texto},
      );
      return ModeloMensajeChat.desdeFilaRemota(
        _filaRpc(raw),
        comunidadIdFallback: comunidadId,
        salidaIdFallback: salidaId,
        uidSesion: user.id,
      );
    } on PostgrestException catch (e) {
      throw AuthException(_msgPg(e));
    }
  }

  Future<ModeloMensajeChat> softDeleteMensaje({
    required String mensajeId,
    String? comunidadId,
    String? salidaId,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('Supabase no disponible');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión');
    }
    final idNum = int.tryParse(mensajeId.trim());
    if (idNum == null) {
      throw const AuthException('Mensaje inválido');
    }
    try {
      final raw = await clienteSupabase.rpc(
        'eliminar_mensaje_chat',
        params: {'p_mensaje_id': idNum},
      );
      return ModeloMensajeChat.desdeFilaRemota(
        _filaRpc(raw),
        comunidadIdFallback: comunidadId,
        salidaIdFallback: salidaId,
        uidSesion: user.id,
      );
    } on PostgrestException catch (e) {
      throw AuthException(_msgPg(e));
    }
  }

  /// Toggle: mismo emoji otra vez → quita; otro emoji → reemplaza.
  Future<void> toggleReaccion({
    required String mensajeId,
    required String emoji,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('Supabase no disponible');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión');
    }
    final idNum = int.tryParse(mensajeId.trim());
    final em = emoji.trim();
    if (idNum == null || em.isEmpty || em.length > 16) {
      throw const AuthException('Reacción inválida');
    }
    if (!EmojisReaccionChat.pack.contains(em)) {
      throw const AuthException('Emoji no permitido');
    }
    try {
      final actual = await clienteSupabase
          .from('mensaje_reaccion')
          .select('emoji')
          .eq('mensaje_id', idNum)
          .eq('usuario_id', user.id)
          .maybeSingle();
      if (actual != null && (actual['emoji'] as String?)?.trim() == em) {
        await clienteSupabase
            .from('mensaje_reaccion')
            .delete()
            .eq('mensaje_id', idNum)
            .eq('usuario_id', user.id);
        return;
      }
      await clienteSupabase.from('mensaje_reaccion').upsert({
        'mensaje_id': idNum,
        'usuario_id': user.id,
        'emoji': em,
        'fecha': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'mensaje_id,usuario_id');
    } on PostgrestException catch (e) {
      throw AuthException(_msgPg(e));
    }
  }

  Future<ModeloMensajeChat?> recargarMensaje(
    String mensajeId, {
    String? comunidadId,
    String? salidaId,
  }) async {
    if (!supabaseListo) return null;
    final idNum = int.tryParse(mensajeId.trim());
    if (idNum == null) return null;
    try {
      final row = await clienteSupabase
          .from('mensaje')
          .select(_selectMensaje)
          .eq('id', idNum)
          .maybeSingle();
      if (row == null) return null;
      final mensaje = ModeloMensajeChat.desdeFilaRemota(
        Map<String, dynamic>.from(row),
        comunidadIdFallback: comunidadId,
        salidaIdFallback: salidaId,
        uidSesion: _uid,
      );
      return _resolverAdjunto(mensaje);
    } catch (_) {
      return null;
    }
  }

  Future<ModeloMensajeChat> _insertMensaje({
    required String salaId,
    required String contenido,
    required String tipo,
    String? comunidadId,
    String? salidaId,
  }) async {
    if (!supabaseListo) {
      throw const AuthException('Supabase no disponible');
    }
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión para enviar mensajes');
    }
    final texto = contenido.trim();
    if (texto.isEmpty) {
      throw const AuthException('Mensaje vacío');
    }
    if (texto.length > maxLenMensaje) {
      throw const AuthException('Mensaje demasiado largo');
    }
    final salaNum = int.tryParse(salaId.trim());
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
            'tipo_mensaje': tipo,
          })
          .select(_selectMensaje)
          .single();
      final mensaje = ModeloMensajeChat.desdeFilaRemota(
        Map<String, dynamic>.from(row),
        comunidadIdFallback: comunidadId,
        salidaIdFallback: salidaId,
        uidSesion: user.id,
      );
      return _resolverAdjunto(mensaje);
    } on PostgrestException catch (e) {
      throw AuthException(_msgPg(e));
    }
  }

  Future<void> marcarLeido(String salaId) async {
    if (!supabaseListo) return;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) return;
    final salaNum = int.tryParse(salaId.trim());
    if (salaNum == null) return;
    try {
      await clienteSupabase.rpc(
        'marcar_sala_leida',
        params: {'p_sala_id': salaNum},
      );
    } catch (_) {}
  }

  Future<int> contarNoLeidos(String salaId) async {
    if (!supabaseListo) return 0;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) return 0;
    final salaNum = int.tryParse(salaId.trim());
    if (salaNum == null) return 0;
    try {
      final part = await clienteSupabase
          .from('sala_participante')
          .select('ultima_lectura')
          .eq('sala_id', salaNum)
          .eq('usuario_id', user.id)
          .maybeSingle();
      if (part == null) return 0;
      final ul = part['ultima_lectura'];
      // Count head: no traer filas (escala con el historial).
      var query = clienteSupabase
          .from('mensaje')
          .select('id')
          .eq('sala_id', salaNum)
          .neq('usuario_id', user.id)
          .isFilter('eliminado_en', null);
      if (ul is String && ul.isNotEmpty) {
        query = query.gt('fecha_envio', ul);
      }
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  /// INSERT + UPDATE de mensajes + cambios de reacción de la sala.
  RealtimeChannel suscribirSala({
    required String salaId,
    required void Function(
      ModeloMensajeChat mensaje, {
      required bool traeReacciones,
    })
    onInsert,
    required void Function(
      ModeloMensajeChat mensaje, {
      required bool traeReacciones,
    })
    onUpdate,
    required void Function(String mensajeId) onReaccionCambio,
    String? comunidadId,
    String? salidaId,
    void Function(RealtimeSubscribeStatus status, Object? error)? onEstado,
  }) {
    final idNum = int.tryParse(salaId.trim());
    if (idNum == null) {
      throw ArgumentError('sala_id inválido');
    }
    final channel = clienteSupabase.channel(
      'mensaje_sala_${idNum}_${DateTime.now().millisecondsSinceEpoch}',
    );
    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'sala_id',
      value: idNum,
    );

    void handleMensaje(
      Map<String, dynamic> raw,
      void Function(ModeloMensajeChat mensaje, {required bool traeReacciones})
      sink,
    ) {
      if (raw.isEmpty) return;
      final trae = ModeloMensajeChat.filaTraeReacciones(raw);
      final m = ModeloMensajeChat.desdeFilaRemota(
        raw,
        comunidadIdFallback: comunidadId,
        salidaIdFallback: salidaId,
        uidSesion: _uid,
      );
      if (m.id.isEmpty) return;
      // Realtime sin embed: no pisa reacciones en el caller.
      sink(m, traeReacciones: trae);
    }

    void handleReaccion(PostgresChangePayload payload) {
      final neo = payload.newRecord;
      final old = payload.oldRecord;
      final rawId = neo['mensaje_id'] ?? old['mensaje_id'];
      if (rawId == null) return;
      onReaccionCambio('$rawId');
    }

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensaje',
          filter: filter,
          callback: (payload) {
            handleMensaje(
              Map<String, dynamic>.from(payload.newRecord),
              onInsert,
            );
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'mensaje',
          filter: filter,
          callback: (payload) {
            handleMensaje(
              Map<String, dynamic>.from(payload.newRecord),
              onUpdate,
            );
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensaje_reaccion',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'sala_id',
            value: idNum,
          ),
          callback: handleReaccion,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'mensaje_reaccion',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'sala_id',
            value: idNum,
          ),
          callback: handleReaccion,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'mensaje_reaccion',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'sala_id',
            value: idNum,
          ),
          callback: handleReaccion,
        )
        .subscribe((status, error) {
          onEstado?.call(status, error);
        });
    return channel;
  }

  @Deprecated('Usá suscribirSala')
  RealtimeChannel suscribirInserts({
    required String salaId,
    required void Function(ModeloMensajeChat mensaje) onInsert,
    String? comunidadId,
    String? salidaId,
    void Function(RealtimeSubscribeStatus status, Object? error)? onEstado,
  }) {
    return suscribirSala(
      salaId: salaId,
      onInsert: (m, {required traeReacciones}) => onInsert(m),
      onUpdate: (_, {required traeReacciones}) {},
      onReaccionCambio: (_) {},
      comunidadId: comunidadId,
      salidaId: salidaId,
      onEstado: onEstado,
    );
  }

  String _msgPg(PostgrestException e) {
    final msg = e.message.trim();
    return msg.isEmpty ? 'Error de chat' : msg;
  }
}
