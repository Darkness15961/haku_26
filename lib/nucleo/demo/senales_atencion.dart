import '../../funcionalidades/rutas/dominio/modelos/modelo_ruta.dart';

/// Señales de atención. No mezcla badges demo con tabs remotos de Comunidad.
abstract final class SenalesAtencion {
  /// Sin tabla de no-leídos remotos → 0 (no inventar desde DMs demo).
  static int mensajesSinLeer() => 0;

  /// Tab Salidas es remoto; no contar demo local.
  static int salidasAbiertas() => 0;

  static int totalPendientesComunidad() =>
      mensajesSinLeer() + salidasAbiertas();

  static int contadorMenuDetalleLugar(String lugarId) => 0;

  static int contadorMenuDetalleRuta(ModeloRuta ruta) => ruta.puntos.length;

  static String? contadorSalidasLugar(String lugarId) => null;
}
