import '../dominio/dominio_perfil_usuario.dart';

class ProveedorPerfilUsuario {
  final RepositorioPerfilUsuario repositorio;

  ProveedorPerfilUsuario({required this.repositorio});

  bool estaCargando = false;
  String? mensajeError;
  List<ModeloPerfilUsuario> perfiles = [];

  Future<void> cargarElementos() async {
    estaCargando = true;
    mensajeError = null;

    try {
      perfiles = await repositorio.obtenerTodos();
    } catch (error) {
      mensajeError = error.toString();
    } finally {
      estaCargando = false;
    }
  }
}
