class ModeloRuta {
  final String id;

  const ModeloRuta({required this.id});

  factory ModeloRuta.fromJson(Map<String, dynamic> json) {
    return ModeloRuta(id: json['id'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id};
  }

  ModeloRuta copyWith({String? id}) {
    return ModeloRuta(id: id ?? this.id);
  }
}
