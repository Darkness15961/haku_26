import '../modelos/modelo_perfil_usuario.dart';

abstract class RepositorioPerfilUsuario {
  Future<List<ModeloPerfilUsuario>> obtenerTodos();

  Future<ModeloPerfilUsuario?> obtenerPorId(String id);

  Future<void> crear(ModeloPerfilUsuario perfil);

  Future<void> actualizar(ModeloPerfilUsuario perfil);

  Future<void> eliminar(String id);
}
