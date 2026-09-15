/// Salida alineada a `public.salida` + participantes.
/// Sin columnas inventadas: no dificultad, no cuposGrupo, no check-in.
class ModeloSalidaRemota {
  final String id;
  final String titulo;
  final String organizadorId;
  /// De `usuario.nombre_nick` si el embed lo trae; vacío si no.
  final String organizadorNick;
  final String? comunidadId;
  final String? comunidadNombre;
  final DateTime fechaHoraInicio;
  final double latitud;
  final double longitud;
  final String? lugarId;
  final String? lugarNombre;
  /// Solo si `lugar.foto_portada` existe en BD.
  final String? lugarFotoPortada;
  final String? notasGrupales;
  /// `publica` | `comunidad`
  final String tipo;
  final int cuposTotales;
  final int minimoParaSalir;
  /// `programada` | `en_curso` | `finalizada` | `cancelada`
  final String estado;
  /// usuario_id con `estado_participante = confirmado`
  final List<String> participanteIds;

  const ModeloSalidaRemota({
    required this.id,
    required this.titulo,
    required this.organizadorId,
    this.organizadorNick = '',
    this.comunidadId,
    this.comunidadNombre,
    required this.fechaHoraInicio,
    required this.latitud,
    required this.longitud,
    this.lugarId,
    this.lugarNombre,
    this.lugarFotoPortada,
    this.notasGrupales,
    this.tipo = 'publica',
    required this.cuposTotales,
    this.minimoParaSalir = 1,
    this.estado = 'programada',
    this.participanteIds = const [],
  });

  int get inscritos => participanteIds.length;

  bool get llena => inscritos >= cuposTotales;

  bool get esDeComunidad =>
      tipo == 'comunidad' && (comunidadId?.isNotEmpty ?? false);

  bool inscrito(String usuarioId) =>
      usuarioId.isNotEmpty && participanteIds.contains(usuarioId);

  /// Título de card: nombre de lugar si hay FK; si no, `titulo` de BD.
  String get etiquetaPrincipal {
    final lugar = lugarNombre?.trim() ?? '';
    if (lugar.isNotEmpty) return lugar;
    return titulo;
  }

  /// Punto de encuentro honesto: lugar o coordenadas (no texto inventado).
  String get puntoEncuentroEtiqueta {
    final lugar = lugarNombre?.trim() ?? '';
    if (lugar.isNotEmpty) return lugar;
    return '${latitud.toStringAsFixed(5)}, ${longitud.toStringAsFixed(5)}';
  }

  String get fechaHoraEtiqueta {
    final d = fechaHoraInicio.toLocal();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month} · $hh:$mm';
  }

  factory ModeloSalidaRemota.desdeFilaRemota(Map<String, dynamic> m) {
    final idRaw = m['id'];
    final id = idRaw == null ? '' : '$idRaw';

    DateTime fecha = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final fh = m['fecha_hora_inicio'];
    if (fh is String) {
      fecha = DateTime.tryParse(fh) ?? fecha;
    } else if (fh is DateTime) {
      fecha = fh;
    }

    Map<String, dynamic>? lugarMap;
    final lugarRaw = m['lugar'];
    if (lugarRaw is Map) {
      lugarMap = Map<String, dynamic>.from(lugarRaw);
    }

    Map<String, dynamic>? comMap;
    final comRaw = m['comunidad'];
    if (comRaw is Map) {
      comMap = Map<String, dynamic>.from(comRaw);
    }

    Map<String, dynamic>? orgMap;
    final orgRaw = m['organizador'];
    if (orgRaw is Map) {
      orgMap = Map<String, dynamic>.from(orgRaw);
    }

    final participanteIds = <String>[];
    final parts = m['salida_participante'];
    if (parts is List) {
      for (final raw in parts) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        final est = (row['estado'] as String?)?.toLowerCase() ?? 'confirmado';
        if (est != 'confirmado') continue;
        final uid = row['usuario_id'];
        if (uid == null) continue;
        final s = '$uid'.trim();
        if (s.isNotEmpty && !participanteIds.contains(s)) {
          participanteIds.add(s);
        }
      }
    }

    final comIdRaw = m['comunidad_id'] ?? comMap?['id'];
    final lugarIdRaw = m['punto_encuentro_lugar_id'] ?? lugarMap?['id'];
    final foto = (lugarMap?['foto_portada'] as String?)?.trim();

    return ModeloSalidaRemota(
      id: id,
      titulo: (m['titulo'] as String?)?.trim() ?? '',
      organizadorId: '${m['organizador_id'] ?? ''}',
      organizadorNick: (orgMap?['nombre_nick'] as String?)?.trim() ?? '',
      comunidadId: comIdRaw == null ? null : '$comIdRaw',
      comunidadNombre: (comMap?['nombre'] as String?)?.trim(),
      fechaHoraInicio: fecha.toLocal(),
      latitud: (m['punto_encuentro_lat'] as num?)?.toDouble() ?? 0,
      longitud: (m['punto_encuentro_lon'] as num?)?.toDouble() ?? 0,
      lugarId: lugarIdRaw == null ? null : '$lugarIdRaw',
      lugarNombre: (lugarMap?['nombre'] as String?)?.trim(),
      lugarFotoPortada: (foto == null || foto.isEmpty) ? null : foto,
      notasGrupales: (m['notas_grupales'] as String?)?.trim(),
      tipo: (m['tipo'] as String?)?.trim() ?? 'publica',
      cuposTotales: (m['cupos_totales'] as num?)?.toInt() ?? 0,
      minimoParaSalir: (m['minimo_para_salir'] as num?)?.toInt() ?? 1,
      estado: (m['estado'] as String?)?.trim() ?? 'programada',
      participanteIds: participanteIds,
    );
  }
}
