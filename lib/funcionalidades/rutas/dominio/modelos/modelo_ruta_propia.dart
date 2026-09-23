import 'modelo_ruta.dart';

enum EstadoEditorialRuta {
  borrador('borrador', 'Borradores', 'Borrador'),
  publicado('publicado', 'Publicadas', 'Publicada'),
  archivado('archivado', 'Desactivadas', 'Desactivada');

  const EstadoEditorialRuta(this.valor, this.etiquetaPlural, this.etiqueta);

  final String valor;
  final String etiquetaPlural;
  final String etiqueta;

  static EstadoEditorialRuta desdeValor(Object? raw) {
    final valor = '$raw'.trim().toLowerCase();
    return EstadoEditorialRuta.values.firstWhere(
      (e) => e.valor == valor,
      orElse: () => EstadoEditorialRuta.borrador,
    );
  }
}

class ModeloRutaPropia {
  const ModeloRutaPropia({
    required this.ruta,
    required this.estado,
    required this.version,
    this.updatedAt,
    this.publicadaEn,
  });

  factory ModeloRutaPropia.desdeJson(Map<String, dynamic> json) {
    return ModeloRutaPropia(
      ruta: ModeloRuta.desdeFilaRemota(json),
      estado: EstadoEditorialRuta.desdeValor(json['estado_editorial']),
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
      publicadaEn: DateTime.tryParse('${json['publicada_en'] ?? ''}'),
    );
  }

  final ModeloRuta ruta;
  final EstadoEditorialRuta estado;
  final int version;
  final DateTime? updatedAt;
  final DateTime? publicadaEn;

  String get id => ruta.id;
  bool get publicada => estado == EstadoEditorialRuta.publicado;
  bool get archivada => estado == EstadoEditorialRuta.archivado;
  bool get borrador => estado == EstadoEditorialRuta.borrador;
}
