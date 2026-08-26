class ModeloSalida {
  final String id;
  final String lugarId;
  final String lugarNombre;
  final String organizador;
  final DateTime fecha;
  final String hora;
  final String puntoEncuentro;
  /// Cupos abiertos para quien se enrola (público).
  final int cupos;
  final int inscritos;
  final int minimo;
  final String dificultad;
  /// Nombre del grupo; vacío si la crea una persona.
  final String grupo;
  final String comunidadId;
  /// Cupos reservados solo para miembros del grupo (0 si es personal).
  final int cuposGrupo;
  final List<String> inscritoIds;
  final List<String> checkinIds;

  const ModeloSalida({
    required this.id,
    required this.lugarId,
    required this.lugarNombre,
    required this.organizador,
    required this.fecha,
    required this.hora,
    required this.puntoEncuentro,
    this.cupos = 10,
    this.inscritos = 0,
    this.minimo = 4,
    this.dificultad = 'Moderada',
    this.grupo = '',
    this.comunidadId = '',
    this.cuposGrupo = 0,
    this.inscritoIds = const [],
    this.checkinIds = const [],
  });

  bool get esDeGrupo => grupo.trim().isNotEmpty;

  int get cuposTotales => cupos + cuposGrupo;

  bool get llena => inscritos >= cuposTotales;

  bool unido(String usuarioId) => inscritoIds.contains(usuarioId);

  bool presente(String usuarioId) => checkinIds.contains(usuarioId);

  ModeloSalida copyWith({
    int? inscritos,
    List<String>? inscritoIds,
    List<String>? checkinIds,
    int? cupos,
    int? cuposGrupo,
    String? grupo,
    String? comunidadId,
    String? organizador,
  }) {
    return ModeloSalida(
      id: id,
      lugarId: lugarId,
      lugarNombre: lugarNombre,
      organizador: organizador ?? this.organizador,
      fecha: fecha,
      hora: hora,
      puntoEncuentro: puntoEncuentro,
      cupos: cupos ?? this.cupos,
      inscritos: inscritos ?? this.inscritos,
      minimo: minimo,
      dificultad: dificultad,
      grupo: grupo ?? this.grupo,
      comunidadId: comunidadId ?? this.comunidadId,
      cuposGrupo: cuposGrupo ?? this.cuposGrupo,
      inscritoIds: inscritoIds ?? this.inscritoIds,
      checkinIds: checkinIds ?? this.checkinIds,
    );
  }

  Map<String, dynamic> aMapa() => {
        'id': id,
        'lugar_id': lugarId,
        'lugar_nombre': lugarNombre,
        'organizador_nombre': organizador,
        'fecha': fecha.toIso8601String(),
        'hora': hora,
        'punto_encuentro': puntoEncuentro,
        'cupos': cupos,
        'inscritos': inscritos,
        'minimo': minimo,
        'dificultad': dificultad,
        'grupo': grupo,
        'comunidad_id': comunidadId,
        'cupos_grupo': cuposGrupo,
        'inscrito_ids': inscritoIds,
        'checkin_ids': checkinIds,
      };

  factory ModeloSalida.desdeMapa(Map<String, dynamic> m) {
    final inscritoIds = [
      for (final x in (m['inscrito_ids'] as List<dynamic>? ?? [])) x.toString(),
    ];
    final checkinIds = [
      for (final x in (m['checkin_ids'] as List<dynamic>? ?? [])) x.toString(),
    ];
    final grupo = m['grupo'] as String? ?? '';
    return ModeloSalida(
      id: m['id'] as String? ?? '',
      lugarId: m['lugar_id'] as String? ?? '',
      lugarNombre: m['lugar_nombre'] as String? ?? '',
      organizador: m['organizador_nombre'] as String? ?? '',
      fecha: DateTime.tryParse(m['fecha'] as String? ?? '') ?? DateTime.now(),
      hora: m['hora'] as String? ?? '',
      puntoEncuentro: m['punto_encuentro'] as String? ?? '',
      cupos: (m['cupos'] as num?)?.toInt() ?? 10,
      inscritos: (m['inscritos'] as num?)?.toInt() ?? inscritoIds.length,
      minimo: (m['minimo'] as num?)?.toInt() ?? 4,
      dificultad: m['dificultad'] as String? ?? 'Moderada',
      grupo: grupo,
      comunidadId: m['comunidad_id'] as String? ?? '',
      cuposGrupo: (m['cupos_grupo'] as num?)?.toInt() ??
          (grupo.trim().isNotEmpty ? 4 : 0),
      inscritoIds: inscritoIds,
      checkinIds: checkinIds,
    );
  }
}

class SalidasDataSourceLocal {
  SalidasDataSourceLocal._();
  static final instancia = SalidasDataSourceLocal._();

  late final List<ModeloSalida> _salidas = [
    ModeloSalida(
      id: 's1',
      lugarId: 'laguna_humantay',
      lugarNombre: 'Laguna Humantay',
      organizador: 'Carlos',
      fecha: DateTime.now().add(const Duration(days: 3)),
      hora: '5:30 AM',
      puntoEncuentro: 'Plaza de Armas',
      cupos: 10,
      inscritos: 3,
      minimo: 4,
      dificultad: 'Moderada',
      grupo: 'Trekkers Cusco',
      comunidadId: 'com_trekkers',
      cuposGrupo: 4,
      inscritoIds: const ['s1', 's2', 'diegoandes'],
      checkinIds: const ['s1'],
    ),
    ModeloSalida(
      id: 's2',
      lugarId: 'moray',
      lugarNombre: 'Moray',
      organizador: 'Ana',
      fecha: DateTime.now().add(const Duration(days: 5)),
      hora: '7:00 AM',
      puntoEncuentro: 'Cristo Blanco',
      cupos: 8,
      inscritos: 3,
      minimo: 3,
      dificultad: 'Fácil',
      grupo: 'Fotógrafos Andinos',
      comunidadId: 'com_fotos',
      cuposGrupo: 3,
      inscritoIds: const ['s2', 'sofiatrek'],
      checkinIds: const [],
    ),
    ModeloSalida(
      id: 's3',
      lugarId: 'cementerio_almudena_noche',
      lugarNombre: 'Tour nocturno Cementerio Almudena',
      organizador: 'Lucía',
      fecha: DateTime.now().add(const Duration(days: 2)),
      hora: '8:00 PM',
      puntoEncuentro: 'Plaza San Francisco',
      cupos: 12,
      inscritos: 5,
      minimo: 4,
      dificultad: 'Fácil',
      grupo: 'Misterios Cusco',
      comunidadId: 'com_fogon',
      cuposGrupo: 4,
      inscritoIds: const ['mariaq', 's1', 's3', 'yo', 'camilarios'],
      checkinIds: const [],
    ),
    ModeloSalida(
      id: 's4',
      lugarId: 'canon_qeswachaka',
      lugarNombre: 'Cañón Q\'eswachaka',
      organizador: 'Diego',
      fecha: DateTime.now().add(const Duration(days: 4)),
      hora: '6:00 AM',
      puntoEncuentro: 'Terminal Oropesa',
      cupos: 15,
      inscritos: 7,
      minimo: 5,
      dificultad: 'Moderada',
      grupo: 'Trekkers Cusco',
      comunidadId: 'com_trekkers',
      cuposGrupo: 5,
      inscritoIds: const ['diegoandes', 's2', 's3', 'sofiatrek', 's1', 'yo', 'haku'],
      checkinIds: const ['diegoandes'],
    ),
    ModeloSalida(
      id: 's5',
      lugarId: 'astro_foto_maras',
      lugarNombre: 'Astrofoto en Maras',
      organizador: 'Camila',
      fecha: DateTime.now().add(const Duration(days: 6)),
      hora: '9:00 PM',
      puntoEncuentro: 'Plaza de Armas',
      cupos: 8,
      inscritos: 4,
      minimo: 3,
      dificultad: 'Fácil',
      grupo: 'Fotógrafos Andinos',
      comunidadId: 'com_fotos',
      cuposGrupo: 3,
      inscritoIds: const ['camilarios', 'mariaq', 's2', 'yo'],
      checkinIds: const [],
    ),
    ModeloSalida(
      id: 's6',
      lugarId: 'laguna_sibinacocha',
      lugarNombre: 'Laguna Sibinacocha',
      organizador: 'Carlos',
      fecha: DateTime.now().add(const Duration(days: 8)),
      hora: '4:30 AM',
      puntoEncuentro: 'Cusco centro',
      cupos: 6,
      inscritos: 2,
      minimo: 4,
      dificultad: 'Exigente',
      grupo: 'Trekkers Cusco',
      comunidadId: 'com_trekkers',
      cuposGrupo: 3,
      inscritoIds: const ['s1', 'diegoandes'],
      checkinIds: const [],
    ),
    ModeloSalida(
      id: 's7',
      lugarId: 'salineras_luna_llena',
      lugarNombre: 'Salineras en luna llena',
      organizador: 'Sofía',
      fecha: DateTime.now().add(const Duration(days: 7)),
      hora: '7:30 PM',
      puntoEncuentro: 'Maras plaza',
      cupos: 10,
      inscritos: 6,
      minimo: 4,
      dificultad: 'Fácil',
      grupo: 'Fotógrafos Andinos',
      comunidadId: 'com_fotos',
      cuposGrupo: 4,
      inscritoIds: const ['sofiatrek', 'mariaq', 'camilarios', 's2', 'yo', 'haku'],
      checkinIds: const [],
    ),
    ModeloSalida(
      id: 's8',
      lugarId: 'qoricancha_noche',
      lugarNombre: 'Qorikancha bajo la luna',
      organizador: 'María',
      fecha: DateTime.now().add(const Duration(days: 3)),
      hora: '7:00 PM',
      puntoEncuentro: 'Entrada Qorikancha',
      cupos: 14,
      inscritos: 8,
      minimo: 5,
      dificultad: 'Fácil',
      grupo: 'Misterios Cusco',
      comunidadId: 'com_fogon',
      cuposGrupo: 4,
      inscritoIds: const ['mariaq', 's1', 's2', 's3', 'yo', 'haku', 'camilarios', 'sofiatrek'],
      checkinIds: const ['mariaq'],
    ),
  ];

  List<ModeloSalida> todas({String? lugarId}) {
    if (lugarId == null) return List.unmodifiable(_salidas);
    return _salidas.where((s) => s.lugarId == lugarId).toList();
  }

  ModeloSalida? porId(String id) {
    for (final s in _salidas) {
      if (s.id == id) return s;
    }
    return null;
  }

  bool enrolar(String id, {String usuarioId = 'yo'}) {
    final i = _salidas.indexWhere((s) => s.id == id);
    if (i < 0) return false;
    final s = _salidas[i];
    if (s.unido(usuarioId)) return false;
    if (s.llena) return false;
    final ids = [...s.inscritoIds, usuarioId];
    final n = s.inscritoIds.isEmpty ? s.inscritos + 1 : ids.length;
    _salidas[i] = s.copyWith(inscritos: n, inscritoIds: ids);
    return true;
  }

  bool checkIn(String id, {String usuarioId = 'yo'}) {
    final i = _salidas.indexWhere((s) => s.id == id);
    if (i < 0) return false;
    var s = _salidas[i];
    if (!s.unido(usuarioId)) {
      if (!enrolar(id, usuarioId: usuarioId)) return false;
      s = _salidas[i];
    }
    if (s.presente(usuarioId)) return true;
    _salidas[i] = s.copyWith(checkinIds: [...s.checkinIds, usuarioId]);
    return true;
  }

  void crear(ModeloSalida salida) {
    _salidas.insert(0, salida);
  }

  List<ModeloSalida> get snapshot => List.unmodifiable(_salidas);

  void reemplazarTodas(List<ModeloSalida> lista) {
    _salidas
      ..clear()
      ..addAll(lista);
  }
}
