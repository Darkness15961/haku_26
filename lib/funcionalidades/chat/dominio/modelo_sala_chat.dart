/// Fila de `public.sala_chat`.
class ModeloSalaChat {
  final String id;

  /// `comunidad` | `salida` | `privado`
  final String tipo;
  final String? comunidadId;
  final String? salidaId;
  final bool estado;
  final DateTime fechaCreacion;

  const ModeloSalaChat({
    required this.id,
    required this.tipo,
    this.comunidadId,
    this.salidaId,
    this.estado = true,
    required this.fechaCreacion,
  });

  factory ModeloSalaChat.desdeFilaRemota(Map<String, dynamic> m) {
    DateTime fecha = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final f = m['fecha_creacion'];
    if (f is String) {
      fecha = DateTime.tryParse(f) ?? fecha;
    } else if (f is DateTime) {
      fecha = f;
    }

    final com = m['comunidad_id'];
    final sal = m['salida_id'];
    final est = m['estado'];

    return ModeloSalaChat(
      id: m['id'] == null ? '' : '${m['id']}',
      tipo: (m['tipo'] as String?)?.trim() ?? '',
      comunidadId: com == null ? null : '$com',
      salidaId: sal == null ? null : '$sal',
      estado: est is bool ? est : true,
      fechaCreacion: fecha.toLocal(),
    );
  }
}
