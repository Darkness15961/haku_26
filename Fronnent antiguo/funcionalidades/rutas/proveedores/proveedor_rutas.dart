import '../dominio/dominio_rutas.dart';

class ProveedorRutas {
  final RepositorioRutas repositorio;

  ProveedorRutas({required this.repositorio});

  bool estaCargando = false;
  String? mensajeError;
  List<ModeloRuta> rutas = [];

  Future<void> cargarElementos() async {
    estaCargando = true;
    mensajeError = null;

    try {
      rutas = await repositorio.obtenerTodos();
    } catch (error) {
      mensajeError = error.toString();
    } finally {
      estaCargando = false;
    }
  }
}
