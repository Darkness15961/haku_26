import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Busca un lugar por nombre (OpenStreetMap Nominatim) y devuelve un punto.
/// Solo para ayudar a centrar el mapa; el usuario confirma el pin.
abstract final class GeocodificadorLugar {
  static const _userAgent = 'HakuApp/1.0 (explora; contacto@haku.best)';

  /// Ej.: "Ollantaytambo, Urubamba, Cusco, Peru"
  static Future<LatLng?> buscar({
    required String consulta,
    String? distrito,
    String? provincia,
  }) async {
    final q = consulta.trim();
    if (q.isEmpty) return null;

    final partes = <String>[q];
    if (distrito != null &&
        distrito.trim().isNotEmpty &&
        !q.toLowerCase().contains(distrito.trim().toLowerCase())) {
      partes.add(distrito.trim());
    }
    if (provincia != null &&
        provincia.trim().isNotEmpty &&
        !q.toLowerCase().contains(provincia.trim().toLowerCase())) {
      partes.add(provincia.trim());
    }
    if (!q.toLowerCase().contains('peru') &&
        !q.toLowerCase().contains('perú')) {
      partes.add('Cusco');
      partes.add('Peru');
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': partes.join(', '),
      'format': 'json',
      'limit': '1',
      'countrycodes': 'pe',
    });

    final res = await http.get(
      uri,
      headers: {
        'User-Agent': _userAgent,
        'Accept-Language': 'es',
      },
    );
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body);
    if (data is! List || data.isEmpty) return null;
    final first = data.first;
    if (first is! Map) return null;
    final lat = double.tryParse('${first['lat']}');
    final lon = double.tryParse('${first['lon']}');
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

  /// Centra cerca del distrito/provincia ya elegidos (sin texto libre).
  static Future<LatLng?> centrarTerritorio({
    required String distrito,
    required String provincia,
  }) {
    return buscar(
      consulta: distrito,
      distrito: distrito,
      provincia: provincia,
    );
  }
}
