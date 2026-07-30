import '../dominio/dominio_destinos.dart';

class ProveedorDestinos {
  final RepositorioDestinos repositorio;

  ProveedorDestinos({required this.repositorio});

  bool estaCargando = false;
  String? mensajeError;
  List<ModeloDestino> destinos = [];

  Future<void> cargarElementos() async {
    estaCargando = true;
    mensajeError = null;

    try {
      destinos = await repositorio.obtenerTodos();
    } catch (error) {
      mensajeError = error.toString();
    } finally {
      estaCargando = false;
    }
  }
}
