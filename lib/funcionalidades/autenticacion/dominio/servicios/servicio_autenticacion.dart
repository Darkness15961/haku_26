import '../modelos/modelo_autenticacion.dart';
import '../repositorios/repositorio_autenticacion.dart';

class ServicioAutenticacion implements RepositorioAutenticacion {
  @override
  Future<List<ModeloAutenticacion>> obtenerTodos() async {
    throw UnimplementedError();
  }

  @override
  Future<ModeloAutenticacion?> obtenerPorId(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> crear(ModeloAutenticacion elemento) async {
    throw UnimplementedError();
  }

  @override
  Future<void> actualizar(ModeloAutenticacion elemento) async {
    throw UnimplementedError();
  }

  @override
  Future<void> eliminar(String id) async {
    throw UnimplementedError();
  }
}
