import '../dominio/dominio_inicio.dart';

class ProveedorInicio {
  final RepositorioInicio repositorio;

  ProveedorInicio({required this.repositorio});

  bool estaCargando = false;
  String? mensajeError;
  List<ModeloInicio> elementos = [];

  Future<void> cargarElementos() async {
    estaCargando = true;
    mensajeError = null;

    try {
      elementos = await repositorio.obtenerTodos();
    } catch (error) {
      mensajeError = error.toString();
    } finally {
      estaCargando = false;
    }
  }
}
