import '../dominio/dominio_autenticacion.dart';

class ProveedorAutenticacion {
  final RepositorioAutenticacion repositorio;

  ProveedorAutenticacion({required this.repositorio});

  bool estaCargando = false;
  String? mensajeError;
  List<ModeloAutenticacion> autenticaciones = [];

  Future<void> cargarElementos() async {
    estaCargando = true;
    mensajeError = null;

    try {
      autenticaciones = await repositorio.obtenerTodos();
    } catch (error) {
      mensajeError = error.toString();
    } finally {
      estaCargando = false;
    }
  }
}
