import '../modelos/modelo_destino.dart';

abstract class RepositorioDestinos {
  Future<List<ModeloDestino>> obtenerTodos();

  Future<ModeloDestino?> obtenerPorId(String id);

  Future<void> crear(ModeloDestino destino);

  Future<void> actualizar(ModeloDestino destino);

  Future<void> eliminar(String id);
}
