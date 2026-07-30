import '../modelos/modelo_favorito.dart';

abstract class RepositorioFavoritos {
  Future<List<ModeloFavorito>> obtenerTodos();

  Future<ModeloFavorito?> obtenerPorId(String id);

  Future<void> crear(ModeloFavorito favorito);

  Future<void> actualizar(ModeloFavorito favorito);

  Future<void> eliminar(String id);
}
