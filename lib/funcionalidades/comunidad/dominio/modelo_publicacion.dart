/// Publicación remota alineada a `public.publicacion` + embeds.
/// Sin likes/comentarios/música inventados (no hay tablas MVP).
class ModeloPublicacionRemota {
  final String id;
  final String usuarioId;
  final String autorNick;
  final String? autorFotoPerfil;
  final String contenido;
  final String estado;
  final DateTime fechaCreacion;
  /// Primera `url_archivo` de multimedia por `orden`, si existe.
  final String? imagenUrl;
  final List<EtiquetaComunidadPublicacion> comunidades;
  final String? lugarId;
  final String? lugarNombre;

  const ModeloPublicacionRemota({
    required this.id,
    required this.usuarioId,
    this.autorNick = '',
    this.autorFotoPerfil,
    required this.contenido,
    this.estado = 'publico',
    required this.fechaCreacion,
    this.imagenUrl,
    this.comunidades = const [],
    this.lugarId,
    this.lugarNombre,
  });

  String get etiquetaAutor {
    final nick = autorNick.trim();
    if (nick.isNotEmpty) return nick.startsWith('@') ? nick : '@$nick';
    if (usuarioId.length >= 8) return usuarioId.substring(0, 8);
    return usuarioId;
  }

  String get hace {
    final diff = DateTime.now().difference(fechaCreacion);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    final d = fechaCreacion;
    return '${d.day}/${d.month}';
  }

  factory ModeloPublicacionRemota.desdeFilaRemota(Map<String, dynamic> m) {
    final idRaw = m['id'];
    final uidRaw = m['usuario_id'];

    String nick = '';
    String? foto;
    final u = m['usuario'];
    if (u is Map) {
      nick = (u['nombre_nick'] as String?)?.trim() ?? '';
      final fp = (u['foto_perfil'] as String?)?.trim();
      if (fp != null && fp.isNotEmpty) foto = fp;
    }

    DateTime fecha = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final f = m['fecha_creacion'];
    if (f is String) {
      fecha = DateTime.tryParse(f) ?? fecha;
    } else if (f is DateTime) {
      fecha = f;
    }

    String? imagen;
    final media = m['publicacion_multimedia'];
    if (media is List) {
      final ordenados = <Map<String, dynamic>>[];
      for (final raw in media) {
        if (raw is! Map) continue;
        ordenados.add(Map<String, dynamic>.from(raw));
      }
      ordenados.sort((a, b) {
        final oa = a['orden'];
        final ob = b['orden'];
        final ia = oa is int ? oa : int.tryParse('$oa') ?? 0;
        final ib = ob is int ? ob : int.tryParse('$ob') ?? 0;
        return ia.compareTo(ib);
      });
      for (final row in ordenados) {
        final url = (row['url_archivo'] as String?)?.trim() ?? '';
        if (url.isNotEmpty) {
          imagen = url;
          break;
        }
      }
    }

    final comunidades = <EtiquetaComunidadPublicacion>[];
    final tags = m['publicacion_etiqueta_comunidad'];
    if (tags is List) {
      for (final raw in tags) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        final c = row['comunidad'];
        Map<String, dynamic>? com;
        if (c is Map) com = Map<String, dynamic>.from(c);
        final cid = row['comunidad_id'] ?? com?['id'];
        if (cid == null) continue;
        final nombre = (com?['nombre'] as String?)?.trim() ?? '';
        comunidades.add(
          EtiquetaComunidadPublicacion(
            comunidadId: '$cid',
            nombre: nombre,
          ),
        );
      }
    }

    String? lugarId;
    String? lugarNombre;
    final lugares = m['publicacion_lugar'];
    if (lugares is List && lugares.isNotEmpty) {
      final first = lugares.first;
      if (first is Map) {
        final row = Map<String, dynamic>.from(first);
        final lid = row['lugar_id'];
        final l = row['lugar'];
        Map<String, dynamic>? lugar;
        if (l is Map) lugar = Map<String, dynamic>.from(l);
        if (lid != null) lugarId = '$lid';
        lugarNombre = (lugar?['nombre'] as String?)?.trim();
        if ((lugarId == null || lugarId.isEmpty) && lugar?['id'] != null) {
          lugarId = '${lugar!['id']}';
        }
      }
    }

    return ModeloPublicacionRemota(
      id: idRaw == null ? '' : '$idRaw',
      usuarioId: uidRaw == null ? '' : '$uidRaw'.trim(),
      autorNick: nick,
      autorFotoPerfil: foto,
      contenido: (m['contenido'] as String?)?.trim() ?? '',
      estado: (m['estado'] as String?)?.trim() ?? 'publico',
      fechaCreacion: fecha.toLocal(),
      imagenUrl: imagen,
      comunidades: comunidades,
      lugarId: lugarId,
      lugarNombre: lugarNombre,
    );
  }
}

class EtiquetaComunidadPublicacion {
  final String comunidadId;
  final String nombre;

  const EtiquetaComunidadPublicacion({
    required this.comunidadId,
    required this.nombre,
  });
}
