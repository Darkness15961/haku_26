class ModeloDestino {
  final String id;

  const ModeloDestino({required this.id});

  factory ModeloDestino.fromJson(Map<String, dynamic> json) {
    return ModeloDestino(id: json['id'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id};
  }

  ModeloDestino copyWith({String? id}) {
    return ModeloDestino(id: id ?? this.id);
  }
}
