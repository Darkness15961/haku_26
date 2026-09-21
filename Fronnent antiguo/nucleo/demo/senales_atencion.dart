import '../../funcionalidades/comunidad/datos/salidas_datasource_local.dart';
import '../../funcionalidades/inicio/datos/mensajes_datasource_local.dart';
import '../../funcionalidades/inicio/proveedores/proveedor_almacen_feed.dart';
import '../../funcionalidades/rutas/dominio/modelos/modelo_ruta.dart';

/// Señales demo de «hay algo interesante aquí» (sin backend).
abstract final class SenalesAtencion {
  static String get _uid => AlmacenFeedNotifier.idUsuarioLocal;

  static int mensajesSinLeer() => MensajesDataSourceLocal.chats
      .fold<int>(0, (sum, c) => sum + c.noLeidos);

  static int salidasAbiertas() => SalidasDataSourceLocal.instancia
      .todas()
      .where((s) => !s.llena && !s.unido(_uid))
      .length;

  static int totalPendientesComunidad() =>
      mensajesSinLeer() + salidasAbiertas();

  static int contadorMenuDetalleLugar(String lugarId) =>
      SalidasDataSourceLocal.instancia.todas(lugarId: lugarId).length;

  static int contadorMenuDetalleRuta(ModeloRuta ruta) => ruta.puntos.length;

  static String? contadorSalidasLugar(String lugarId) {
    final n =
        SalidasDataSourceLocal.instancia.todas(lugarId: lugarId).length;
    return n > 0 ? '$n' : null;
  }
}
