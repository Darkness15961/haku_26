import '../modelos/modelo_ruta.dart';
import '../repositorios/repositorio_rutas.dart';

class ServicioRutas implements RepositorioRutas {
  @override
  Future<List<ModeloRuta>> obtenerTodos() async {
    throw UnimplementedError();
  }

  @override
  Future<ModeloRuta?> obtenerPorId(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> crear(ModeloRuta elemento) async {
    throw UnimplementedError();
  }

  @override
  Future<void> actualizar(ModeloRuta elemento) async {
    throw UnimplementedError();
  }

  @override
  Future<void> eliminar(String id) async {
    throw UnimplementedError();
  }
}
