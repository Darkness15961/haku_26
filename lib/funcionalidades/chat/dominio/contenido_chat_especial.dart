import 'dart:convert';

/// Payload estable de `tipo_mensaje = ubicacion` en `mensaje.contenido`.
/// Formato JSON v1: {"v":1,"lat":..,"lng":..,"label":"..."}.
class ContenidoUbicacionChat {
  static const version = 1;

  final double lat;
  final double lng;
  final String label;

  const ContenidoUbicacionChat({
    required this.lat,
    required this.lng,
    this.label = 'Mi ubicación',
  });

  bool get esValida =>
      lat.isFinite &&
      lng.isFinite &&
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180 &&
      !(lat.abs() < 0.0001 && lng.abs() < 0.0001);

  String aContenido() {
    final map = <String, dynamic>{
      'v': version,
      'lat': double.parse(lat.toStringAsFixed(6)),
      'lng': double.parse(lng.toStringAsFixed(6)),
      'label': label.trim().isEmpty ? 'Mi ubicación' : label.trim(),
    };
    return jsonEncode(map);
  }

  static ContenidoUbicacionChat? desdeContenido(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    try {
      final decoded = jsonDecode(t);
      if (decoded is! Map) return null;
      final lat = (decoded['lat'] as num?)?.toDouble();
      final lng = (decoded['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final label = (decoded['label'] as String?)?.trim() ?? 'Mi ubicación';
      final u = ContenidoUbicacionChat(
        lat: lat,
        lng: lng,
        label: label.isEmpty ? 'Mi ubicación' : label,
      );
      return u.esValida ? u : null;
    } catch (_) {
      return null;
    }
  }
}

/// Pack fijo de stickers (emoji IDs). Sin uploads; escalable y offline.
abstract final class PackStickersChat {
  /// id → glyph. El `contenido` del mensaje es el id.
  static const Map<String, String> porId = {
    'llama': '🦙',
    'montana': '🏔️',
    'sol': '☀️',
    'fogata': '🔥',
    'mapa': '🗺️',
    'camara': '📷',
    'fuerza': '💪',
    'ok': '👌',
    'saludo': '👋',
    'corazon': '💛',
    'estrella': '⭐',
    'fiesta': '🎉',
  };

  static List<String> get ids => porId.keys.toList(growable: false);

  static String? glyph(String id) => porId[id.trim()];

  static bool esValido(String id) => porId.containsKey(id.trim());
}
