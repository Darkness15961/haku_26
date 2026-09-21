import '../modelos/modelo_autenticacion.dart';

abstract class RepositorioAutenticacion {
  Future<List<ModeloAutenticacion>> obtenerTodos();

  Future<ModeloAutenticacion?> obtenerPorId(String id);

  Future<void> crear(ModeloAutenticacion autenticacion);

  Future<void> actualizar(ModeloAutenticacion autenticacion);

  Future<void> eliminar(String id);
}
