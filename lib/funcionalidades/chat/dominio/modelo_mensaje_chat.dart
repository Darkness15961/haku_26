import 'contenido_chat_especial.dart';

/// Reacción agregada sobre un mensaje (emoji → conteo + si yo reaccioné).
class ReaccionMensajeAgregada {
  final String emoji;
  final int cantidad;
  final bool mia;

  const ReaccionMensajeAgregada({
    required this.emoji,
    required this.cantidad,
    this.mia = false,
  });
}

/// Mensaje de `public.mensaje` (+ soft edit/delete + reacciones).
class ModeloMensajeChat {
  final String id;
  final String salaId;
  final String? comunidadId;
  final String? salidaId;
  final String usuarioId;
  final String autorNick;
  final String contenido;

  /// `texto` | `imagen` | `audio` | `ubicacion` | `sticker`
  final String tipoMensaje;
  final DateTime fechaEnvio;
  final DateTime? editadoEn;
  final DateTime? eliminadoEn;
  final List<ReaccionMensajeAgregada> reacciones;

  const ModeloMensajeChat({
    required this.id,
    required this.salaId,
    this.comunidadId,
    this.salidaId,
    required this.usuarioId,
    this.autorNick = '',
    required this.contenido,
    this.tipoMensaje = 'texto',
    required this.fechaEnvio,
    this.editadoEn,
    this.eliminadoEn,
    this.reacciones = const [],
  });

  bool get esImagen => tipoMensaje == 'imagen';
  bool get esUbicacion => tipoMensaje == 'ubicacion';
  bool get esSticker => tipoMensaje == 'sticker';
  bool get eliminado => eliminadoEn != null;
  bool get editado => editadoEn != null && !eliminado;
  bool get esTextoEditable => tipoMensaje == 'texto' && !eliminado;

  ContenidoUbicacionChat? get ubicacion =>
      esUbicacion ? ContenidoUbicacionChat.desdeContenido(contenido) : null;

  String? get stickerGlyph =>
      esSticker ? PackStickersChat.glyph(contenido) : null;

  String get etiquetaAutor {
    final nick = autorNick.trim();
    if (nick.isNotEmpty) return nick.startsWith('@') ? nick : '@$nick';
    if (usuarioId.length >= 8) return usuarioId.substring(0, 8);
    return usuarioId;
  }

  /// Texto visible (placeholder si soft-delete; preview amigable).
  String get contenidoVisible {
    if (eliminado) return 'Mensaje eliminado';
    if (esUbicacion) return '📍 ${ubicacion?.label ?? 'Ubicación'}';
    if (esSticker) return stickerGlyph ?? 'Sticker';
    if (esImagen) return '📷 Imagen';
    return contenido;
  }

  ModeloMensajeChat copyWith({
    String? autorNick,
    String? comunidadId,
    String? salidaId,
    String? contenido,
    DateTime? editadoEn,
    DateTime? eliminadoEn,
    List<ReaccionMensajeAgregada>? reacciones,
    bool clearEditado = false,
    bool clearEliminado = false,
  }) {
    return ModeloMensajeChat(
      id: id,
      salaId: salaId,
      comunidadId: comunidadId ?? this.comunidadId,
      salidaId: salidaId ?? this.salidaId,
      usuarioId: usuarioId,
      autorNick: autorNick ?? this.autorNick,
      contenido: contenido ?? this.contenido,
      tipoMensaje: tipoMensaje,
      fechaEnvio: fechaEnvio,
      editadoEn: clearEditado ? null : (editadoEn ?? this.editadoEn),
      eliminadoEn: clearEliminado ? null : (eliminadoEn ?? this.eliminadoEn),
      reacciones: reacciones ?? this.reacciones,
    );
  }

  /// ¿El [live] del stream ya refleja el cuerpo de este parche local?
  ///
  /// Las reacciones NO entran: viven en el stream (Realtime). Si el overlay
  /// local exigiera igualdad de reacciones, tapa updates ajenos y frena el chat.
  bool cubiertoPor(ModeloMensajeChat live) {
    if (id != live.id) return false;
    // Una imagen privada alterna entre `chat://ruta` y URL firmada temporal.
    // El objeto es inmutable; el id/tipo identifica el mismo cuerpo.
    if (esImagen && live.esImagen && live.contenido.startsWith('chat://')) {
      return false;
    }
    if (!(esImagen && live.esImagen) && contenido != live.contenido) {
      return false;
    }
    if (!_mismoInstante(eliminadoEn, live.eliminadoEn)) return false;
    if (!_mismoInstante(editadoEn, live.editadoEn)) return false;
    return true;
  }

  static bool _mismoInstante(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.toUtc().millisecondsSinceEpoch == b.toUtc().millisecondsSinceEpoch;
  }

  /// Une payload realtime (sin embeds) con el mensaje previo en buffer.
  static ModeloMensajeChat fusionarConPrevio(
    ModeloMensajeChat previo,
    ModeloMensajeChat entrante, {
    required bool entranteTraeReacciones,
  }) {
    return entrante.copyWith(
      autorNick: entrante.autorNick.isNotEmpty
          ? entrante.autorNick
          : previo.autorNick,
      reacciones: entranteTraeReacciones
          ? entrante.reacciones
          : previo.reacciones,
    );
  }

  static DateTime? _parseFecha(dynamic f) {
    if (f is String) return DateTime.tryParse(f)?.toLocal();
    if (f is DateTime) return f.toLocal();
    return null;
  }

  static List<ReaccionMensajeAgregada> _reaccionesDeFila(
    Map<String, dynamic> m,
    String? uidSesion,
  ) {
    final raw = m['mensaje_reaccion'];
    if (raw is! List || raw.isEmpty) return const [];

    final counts = <String, int>{};
    final mias = <String>{};
    for (final e in raw) {
      if (e is! Map) continue;
      final emoji = (e['emoji'] as String?)?.trim() ?? '';
      if (emoji.isEmpty) continue;
      counts[emoji] = (counts[emoji] ?? 0) + 1;
      final uid = '${e['usuario_id'] ?? ''}'.trim();
      if (uidSesion != null && uid.isNotEmpty && uid == uidSesion) {
        mias.add(emoji);
      }
    }
    final out = [
      for (final e in counts.entries)
        ReaccionMensajeAgregada(
          emoji: e.key,
          cantidad: e.value,
          mia: mias.contains(e.key),
        ),
    ];
    out.sort((a, b) => b.cantidad.compareTo(a.cantidad));
    return out;
  }

  factory ModeloMensajeChat.desdeFilaRemota(
    Map<String, dynamic> m, {
    String? comunidadIdFallback,
    String? salidaIdFallback,
    String? uidSesion,
  }) {
    final idRaw = m['id'];
    final salaRaw = m['sala_id'];
    final uidRaw = m['usuario_id'];

    String nick = '';
    final embed = m['usuario'];
    if (embed is Map) {
      nick = (embed['nombre_nick'] as String?)?.trim() ?? '';
    }

    String? comId = comunidadIdFallback?.trim();
    String? salId = salidaIdFallback?.trim();
    final salaEmbed = m['sala_chat'] ?? m['sala'];
    if (salaEmbed is Map) {
      if (salaEmbed['comunidad_id'] != null) {
        comId = '${salaEmbed['comunidad_id']}';
      }
      if (salaEmbed['salida_id'] != null) {
        salId = '${salaEmbed['salida_id']}';
      }
    }

    DateTime fecha = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final f = m['fecha_envio'];
    if (f is String) {
      fecha = DateTime.tryParse(f) ?? fecha;
    } else if (f is DateTime) {
      fecha = f;
    }

    final tipo =
        (m['tipo_mensaje'] as String?)?.trim().toLowerCase() ?? 'texto';
    final eliminado = _parseFecha(m['eliminado_en']);
    final traeReacciones = m.containsKey('mensaje_reaccion');

    final msg = ModeloMensajeChat(
      id: idRaw == null ? '' : '$idRaw',
      salaId: salaRaw == null ? '' : '$salaRaw',
      comunidadId: (comId == null || comId.isEmpty) ? null : comId,
      salidaId: (salId == null || salId.isEmpty) ? null : salId,
      usuarioId: uidRaw == null ? '' : '$uidRaw'.trim(),
      autorNick: nick,
      contenido: (m['contenido'] as String?)?.trim() ?? '',
      tipoMensaje: tipo.isEmpty ? 'texto' : tipo,
      fechaEnvio: fecha.toLocal(),
      editadoEn: _parseFecha(m['editado_en']),
      eliminadoEn: eliminado,
      reacciones: traeReacciones ? _reaccionesDeFila(m, uidSesion) : const [],
    );
    return msg;
  }

  /// True si la fila remota incluía el embed de reacciones (aunque vacío).
  static bool filaTraeReacciones(Map<String, dynamic> m) =>
      m.containsKey('mensaje_reaccion');
}

/// Preview de chat (tab Mensajes / listas).
class PreviewChatSala {
  final String salaId;
  final String titulo;
  final String? fotoPortada;
  final String? comunidadId;
  final String? salidaId;

  /// Contraparte cuando [tipo] es `privado`.
  final String? usuarioId;

  /// `comunidad` | `salida` | `privado`
  final String tipo;
  final ModeloMensajeChat? ultimo;
  final int noLeidos;

  /// Admin (comunidad) u organizador (salida): puede crear la sala.
  final bool puedeCrearSala;

  const PreviewChatSala({
    required this.salaId,
    required this.titulo,
    this.fotoPortada,
    this.comunidadId,
    this.salidaId,
    this.usuarioId,
    this.tipo = 'comunidad',
    this.ultimo,
    this.noLeidos = 0,
    this.puedeCrearSala = false,
  });

  bool get esComunidad => tipo == 'comunidad';
  bool get esSalida => tipo == 'salida';
  bool get esPrivado => tipo == 'privado';

  /// Alineado a RPC: abrir solo si hay sala visible o podés crearla.
  bool get puedeAbrir => salaId.trim().isNotEmpty || puedeCrearSala;

  String get etiquetaTipo {
    switch (tipo) {
      case 'salida':
        return 'Salida';
      case 'privado':
        return 'Privado';
      default:
        return 'Comunidad';
    }
  }

  String get previewVacioEtiqueta {
    if (salaId.trim().isNotEmpty) return 'Sin mensajes aún';
    if (puedeCrearSala) {
      return 'Tocá para abrir el chat';
    }
    if (esSalida) {
      return 'El organizador aún no abrió el chat';
    }
    return 'El admin aún no activó el chat';
  }
}

/// Identidad pública mínima mostrada al tocar un autor del chat.
class PerfilChatBasico {
  final String id;
  final String nombres;
  final String apellidos;
  final String nombreNick;
  final String? fotoPerfil;

  const PerfilChatBasico({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.nombreNick,
    this.fotoPerfil,
  });

  String get nombreCompleto {
    final valor = '$nombres $apellidos'.trim();
    return valor.isEmpty ? nombreNick : valor;
  }

  String get etiquetaNick {
    final valor = nombreNick.trim();
    if (valor.isEmpty) return '';
    return valor.startsWith('@') ? valor : '@$valor';
  }

  factory PerfilChatBasico.desdeFila(Map<String, dynamic> fila) {
    return PerfilChatBasico(
      id: '${fila['id'] ?? fila['otro_usuario_id'] ?? ''}'.trim(),
      nombres: '${fila['nombres'] ?? ''}'.trim(),
      apellidos: '${fila['apellidos'] ?? ''}'.trim(),
      nombreNick: '${fila['nombre_nick'] ?? ''}'.trim(),
      fotoPerfil: (fila['foto_perfil'] as String?)?.trim(),
    );
  }
}

/// Fila de roster para el picker admin.
class ParticipanteSalaChat {
  final String usuarioId;
  final String etiqueta;
  final String? fotoPerfil;
  final bool enChat;
  final String rolComunidad;

  const ParticipanteSalaChat({
    required this.usuarioId,
    required this.etiqueta,
    this.fotoPerfil,
    required this.enChat,
    this.rolComunidad = 'miembro',
  });
}

/// Emojis fijos de reacción (pack estable; no stickers custom).
abstract final class EmojisReaccionChat {
  static const List<String> pack = ['👍', '❤️', '😂', '😮', '😢', '🔥'];
}
