class ModeloAutenticacion {
  final String id;

  const ModeloAutenticacion({required this.id});

  factory ModeloAutenticacion.fromJson(Map<String, dynamic> json) {
    return ModeloAutenticacion(id: json['id'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id};
  }

  ModeloAutenticacion copyWith({String? id}) {
    return ModeloAutenticacion(id: id ?? this.id);
  }
}
