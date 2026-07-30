import '../modelos/modelo_destino.dart';
import '../repositorios/repositorio_destinos.dart';

class ServicioDestinos implements RepositorioDestinos {
  @override
  Future<List<ModeloDestino>> obtenerTodos() async {
    throw UnimplementedError();
  }

  @override
  Future<ModeloDestino?> obtenerPorId(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> crear(ModeloDestino elemento) async {
    throw UnimplementedError();
  }

  @override
  Future<void> actualizar(ModeloDestino elemento) async {
    throw UnimplementedError();
  }

  @override
  Future<void> eliminar(String id) async {
    throw UnimplementedError();
  }
}
