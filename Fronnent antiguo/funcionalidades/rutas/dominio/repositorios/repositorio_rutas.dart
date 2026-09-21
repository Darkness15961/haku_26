import '../modelos/modelo_ruta.dart';

abstract class RepositorioRutas {
  Future<List<ModeloRuta>> obtenerTodos();

  Future<ModeloRuta?> obtenerPorId(String id);

  Future<void> crear(ModeloRuta ruta);

  Future<void> actualizar(ModeloRuta ruta);

  Future<void> eliminar(String id);
}
