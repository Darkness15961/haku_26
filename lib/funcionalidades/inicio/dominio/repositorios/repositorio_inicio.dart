import '../modelos/modelo_inicio.dart';

abstract class RepositorioInicio {
  Future<List<ModeloInicio>> obtenerTodos();

  Future<ModeloInicio?> obtenerPorId(String id);

  Future<void> crear(ModeloInicio elemento);

  Future<void> actualizar(ModeloInicio elemento);

  Future<void> eliminar(String id);
}
