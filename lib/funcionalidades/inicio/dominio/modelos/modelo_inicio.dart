class ModeloInicio {
  final String id;

  const ModeloInicio({required this.id});

  factory ModeloInicio.fromJson(Map<String, dynamic> json) {
    return ModeloInicio(id: json['id'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id};
  }

  ModeloInicio copyWith({String? id}) {
    return ModeloInicio(id: id ?? this.id);
  }
}
