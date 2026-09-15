/// Mensaje de `public.mensaje` (sala de chat).
/// Solo columnas reales. Sin leídos, adjuntos ni reacciones en MVP.
class ModeloMensajeComunidad {
  final String id;
  final String salaId;
  /// Comunidad dueña de la sala (si se conoce vía join / contexto).
  final String comunidadId;
  final String usuarioId;
  /// De embed `usuario.nombre_nick` si viene; vacío si no.
  final String autorNick;
  final String contenido;
  /// `texto` | `imagen` | `audio` | `ubicacion` (MVP: texto).
  final String tipoMensaje;
  final DateTime fechaEnvio;

  const ModeloMensajeComunidad({
    required this.id,
    required this.salaId,
    this.comunidadId = '',
    required this.usuarioId,
    this.autorNick = '',
    required this.contenido,
    this.tipoMensaje = 'texto',
    required this.fechaEnvio,
  });

  /// Alias UI legacy.
  String get mensaje => contenido;

  String get etiquetaAutor {
    final nick = autorNick.trim();
    if (nick.isNotEmpty) return nick.startsWith('@') ? nick : '@$nick';
    if (usuarioId.length >= 8) return usuarioId.substring(0, 8);
    return usuarioId;
  }

  ModeloMensajeComunidad copyWith({
    String? autorNick,
    String? comunidadId,
  }) {
    return ModeloMensajeComunidad(
      id: id,
      salaId: salaId,
      comunidadId: comunidadId ?? this.comunidadId,
      usuarioId: usuarioId,
      autorNick: autorNick ?? this.autorNick,
      contenido: contenido,
      tipoMensaje: tipoMensaje,
      fechaEnvio: fechaEnvio,
    );
  }

  factory ModeloMensajeComunidad.desdeFilaRemota(
    Map<String, dynamic> m, {
    String? comunidadIdFallback,
  }) {
    final idRaw = m['id'];
    final salaRaw = m['sala_id'];
    final uidRaw = m['usuario_id'];

    String nick = '';
    final embed = m['usuario'];
    if (embed is Map) {
      nick = (embed['nombre_nick'] as String?)?.trim() ?? '';
    }

    String comId = comunidadIdFallback?.trim() ?? '';
    final salaEmbed = m['sala_chat'] ?? m['sala'];
    if (salaEmbed is Map && salaEmbed['comunidad_id'] != null) {
      comId = '${salaEmbed['comunidad_id']}';
    }

    // No inventar "ahora" si falta fecha: epoch → UI muestra 00:00.
    DateTime fecha = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final f = m['fecha_envio'];
    if (f is String) {
      fecha = DateTime.tryParse(f) ?? fecha;
    } else if (f is DateTime) {
      fecha = f;
    }

    final tipo = (m['tipo_mensaje'] as String?)?.trim().toLowerCase() ?? 'texto';

    return ModeloMensajeComunidad(
      id: idRaw == null ? '' : '$idRaw',
      salaId: salaRaw == null ? '' : '$salaRaw',
      comunidadId: comId,
      usuarioId: uidRaw == null ? '' : '$uidRaw'.trim(),
      autorNick: nick,
      contenido: (m['contenido'] as String?)?.trim() ?? '',
      tipoMensaje: tipo.isEmpty ? 'texto' : tipo,
      fechaEnvio: fecha.toLocal(),
    );
  }
}

/// Fila del tab Mensajes: comunidad + último mensaje (si hay).
class PreviewChatComunidad {
  final String comunidadId;
  final String comunidadNombre;
  final String? fotoPortada;
  final String? salaId;
  final ModeloMensajeComunidad? ultimo;

  const PreviewChatComunidad({
    required this.comunidadId,
    required this.comunidadNombre,
    this.fotoPortada,
    this.salaId,
    this.ultimo,
  });
}
