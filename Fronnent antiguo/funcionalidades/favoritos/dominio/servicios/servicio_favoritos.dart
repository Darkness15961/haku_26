import '../modelos/modelo_favorito.dart';
import '../repositorios/repositorio_favoritos.dart';

class ServicioFavoritos implements RepositorioFavoritos {
  @override
  Future<List<ModeloFavorito>> obtenerTodos() async {
    throw UnimplementedError();
  }

  @override
  Future<ModeloFavorito?> obtenerPorId(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> crear(ModeloFavorito favorito) async {
    throw UnimplementedError();
  }

  @override
  Future<void> actualizar(ModeloFavorito favorito) async {
    throw UnimplementedError();
  }

  @override
  Future<void> eliminar(String id) async {
    throw UnimplementedError();
  }
}
