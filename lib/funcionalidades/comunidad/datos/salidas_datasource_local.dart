class ModeloSalida {
  final String id;
  final String lugarId;
  final String lugarNombre;
  final String organizador;
  final DateTime fecha;
  final String hora;
  final String puntoEncuentro;
  final int cupos;
  final int inscritos;
  final int minimo;
  final String dificultad;
  final String grupo;
  final String comunidadId;

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
  });

  bool get llena => inscritos >= cupos;

  ModeloSalida copyWith({int? inscritos}) {
    return ModeloSalida(
      id: id,
      lugarId: lugarId,
      lugarNombre: lugarNombre,
      organizador: organizador,
      fecha: fecha,
      hora: hora,
      puntoEncuentro: puntoEncuentro,
      cupos: cupos,
      inscritos: inscritos ?? this.inscritos,
      minimo: minimo,
      dificultad: dificultad,
      grupo: grupo,
      comunidadId: comunidadId,
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
      inscritos: 7,
      minimo: 4,
      dificultad: 'Moderada',
      grupo: 'Trekkers Cusco',
      comunidadId: 'com_trekkers',
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

  bool enrolar(String id) {
    final i = _salidas.indexWhere((s) => s.id == id);
    if (i < 0) return false;
    final s = _salidas[i];
    if (s.llena) return false;
    _salidas[i] = s.copyWith(inscritos: s.inscritos + 1);
    return true;
  }

  void crear(ModeloSalida salida) {
    _salidas.insert(0, salida);
  }
}
