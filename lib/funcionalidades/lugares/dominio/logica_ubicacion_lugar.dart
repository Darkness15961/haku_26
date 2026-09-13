/// Validación de coordenadas al registrar un lugar (GPS o mapa).
abstract final class LogicaUbicacionLugar {
  /// Cusco centro (fallback de mapa).
  static const latCusco = -13.5167;
  static const lonCusco = -71.9788;

  static bool esLatitudValida(double? lat) =>
      lat != null && lat.isFinite && lat >= -90 && lat <= 90;

  static bool esLongitudValida(double? lon) =>
      lon != null && lon.isFinite && lon >= -180 && lon <= 180;

  static bool esUbicacionValida(double? lat, double? lon) =>
      esLatitudValida(lat) && esLongitudValida(lon);

  /// Evita puntos basura (0,0) que no son Cusco ni un pin real.
  static bool esPuntoSospechoso(double lat, double lon) =>
      lat.abs() < 0.0001 && lon.abs() < 0.0001;

  static String? mensajeErrorUbicacion(double? lat, double? lon) {
    if (!esUbicacionValida(lat, lon)) {
      return 'Marca el punto: GPS, mapa o coordenadas';
    }
    if (esPuntoSospechoso(lat!, lon!)) {
      return 'Esa ubicación no parece válida. Elige otra.';
    }
    return null;
  }
}
