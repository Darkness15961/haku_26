import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// Contorno del departamento de Cusco (GeoJSON local, INEI simplificado).
///
/// Fuente del asset: `assets/mapas/departamento_cusco.geojson`
/// (recorte de peru_departamental_simple · juaneladio/peru-geojson).
abstract final class ContornoDepartamentoCusco {
  static const assetPath = 'assets/mapas/departamento_cusco.geojson';

  /// Anillo exterior en orden GeoJSON (lon, lat) → [LatLng].
  static Future<List<LatLng>> cargar() async {
    final raw = await rootBundle.loadString(assetPath);
    return parsear(raw);
  }

  /// Parseo puro (tests / sin asset).
  static List<LatLng> parsear(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const [];

    Map<String, dynamic>? geometry;
    if (decoded['type'] == 'FeatureCollection') {
      final features = decoded['features'];
      if (features is List && features.isNotEmpty) {
        final f0 = features.first;
        if (f0 is Map) {
          final g = f0['geometry'];
          if (g is Map) geometry = Map<String, dynamic>.from(g);
        }
      }
    } else if (decoded['type'] == 'Feature') {
      final g = decoded['geometry'];
      if (g is Map) geometry = Map<String, dynamic>.from(g);
    } else if (decoded['type'] == 'Polygon' ||
        decoded['type'] == 'MultiPolygon') {
      geometry = Map<String, dynamic>.from(decoded);
    }

    if (geometry == null) return const [];
    return _anilloDesdeGeometry(geometry);
  }

  static List<LatLng> _anilloDesdeGeometry(Map<String, dynamic> geometry) {
    final type = geometry['type'] as String?;
    final coords = geometry['coordinates'];
    if (coords is! List || coords.isEmpty) return const [];

    List? ring;
    if (type == 'Polygon') {
      ring = coords.first as List?;
    } else if (type == 'MultiPolygon') {
      final firstPoly = coords.first;
      if (firstPoly is List && firstPoly.isNotEmpty) {
        ring = firstPoly.first as List?;
      }
    }
    if (ring == null || ring.isEmpty) return const [];

    final out = <LatLng>[];
    for (final p in ring) {
      if (p is! List || p.length < 2) continue;
      final lon = (p[0] as num).toDouble();
      final lat = (p[1] as num).toDouble();
      out.add(LatLng(lat, lon));
    }
    return out;
  }
}
