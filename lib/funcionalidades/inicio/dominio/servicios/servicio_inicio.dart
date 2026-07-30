import '../modelos/modelo_inicio.dart';
import '../repositorios/repositorio_inicio.dart';

class ServicioInicio implements RepositorioInicio {
  @override
  Future<List<ModeloInicio>> obtenerTodos() async {
    throw UnimplementedError();
  }

  @override
  Future<ModeloInicio?> obtenerPorId(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> crear(ModeloInicio elemento) async {
    throw UnimplementedError();
  }

  @override
  Future<void> actualizar(ModeloInicio elemento) async {
    throw UnimplementedError();
  }

  @override
  Future<void> eliminar(String id) async {
    throw UnimplementedError();
  }
}
