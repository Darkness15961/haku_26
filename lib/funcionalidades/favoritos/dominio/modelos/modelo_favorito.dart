class ModeloFavorito {
  final String id;

  const ModeloFavorito({required this.id});

  factory ModeloFavorito.fromJson(Map<String, dynamic> json) {
    return ModeloFavorito(id: json['id'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id};
  }

  ModeloFavorito copyWith({String? id}) {
    return ModeloFavorito(id: id ?? this.id);
  }
}
