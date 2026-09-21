class ModeloPerfilUsuario {
  final String id;

  const ModeloPerfilUsuario({required this.id});

  factory ModeloPerfilUsuario.fromJson(Map<String, dynamic> json) {
    return ModeloPerfilUsuario(id: json['id'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id};
  }

  ModeloPerfilUsuario copyWith({String? id}) {
    return ModeloPerfilUsuario(id: id ?? this.id);
  }
}
