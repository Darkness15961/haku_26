import '../modelos/modelo_perfil_usuario.dart';
import '../repositorios/repositorio_perfil_usuario.dart';

class ServicioPerfilUsuario implements RepositorioPerfilUsuario {
  @override
  Future<List<ModeloPerfilUsuario>> obtenerTodos() async {
    throw UnimplementedError();
  }

  @override
  Future<ModeloPerfilUsuario?> obtenerPorId(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> crear(ModeloPerfilUsuario elemento) async {
    throw UnimplementedError();
  }

  @override
  Future<void> actualizar(ModeloPerfilUsuario elemento) async {
    throw UnimplementedError();
  }

  @override
  Future<void> eliminar(String id) async {
    throw UnimplementedError();
  }
}
