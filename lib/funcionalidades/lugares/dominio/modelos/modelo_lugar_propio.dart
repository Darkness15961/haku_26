import 'modelo_lugar.dart';

enum EstadoEditorialLugar {
  borrador('borrador', 'Borradores', 'Borrador'),
  publicado('publicado', 'Publicados', 'Publicado'),
  archivado('archivado', 'Desactivados', 'Desactivado');

  const EstadoEditorialLugar(this.valor, this.etiquetaPlural, this.etiqueta);

  final String valor;
  final String etiquetaPlural;
  final String etiqueta;

  static EstadoEditorialLugar desdeValor(Object? raw) {
    final valor = '$raw'.trim().toLowerCase();
    return EstadoEditorialLugar.values.firstWhere(
      (estado) => estado.valor == valor,
      orElse: () => EstadoEditorialLugar.borrador,
    );
  }
}

class ModeloLugarPropio {
  const ModeloLugarPropio({
    required this.lugar,
    required this.estado,
    this.actualizadoEn,
  });

  factory ModeloLugarPropio.desdeJson(Map<String, dynamic> json) {
    return ModeloLugarPropio(
      lugar: ModeloLugar.desdeFilaRemota(json),
      estado: EstadoEditorialLugar.desdeValor(json['estado_editorial']),
      actualizadoEn: DateTime.tryParse('${json['updated_at'] ?? ''}'),
    );
  }

  final ModeloLugar lugar;
  final EstadoEditorialLugar estado;
  final DateTime? actualizadoEn;

  String get id => lugar.id;
  bool get publicado => estado == EstadoEditorialLugar.publicado;
  bool get archivado => estado == EstadoEditorialLugar.archivado;
  bool get borrador => estado == EstadoEditorialLugar.borrador;
}
