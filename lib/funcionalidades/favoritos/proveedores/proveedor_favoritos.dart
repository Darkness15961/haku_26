import '../dominio/dominio_favoritos.dart';

class ProveedorFavoritos {
  final RepositorioFavoritos repositorio;

  ProveedorFavoritos({required this.repositorio});

  bool estaCargando = false;
  String? mensajeError;
  List<ModeloFavorito> favoritos = [];

  Future<void> cargarFavoritos() async {
    estaCargando = true;
    mensajeError = null;

    try {
      favoritos = await repositorio.obtenerTodos();
    } catch (error) {
      mensajeError = error.toString();
    } finally {
      estaCargando = false;
    }
  }
}
