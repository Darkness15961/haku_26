import 'dart:convert';
import 'dart:math' as math;

import 'modelo_ruta.dart';

enum OrigenTrazadoRuta { geojson, gpx }

class TrazadoRutaImportado {
  const TrazadoRutaImportado({
    required this.origen,
    required this.coordenadas,
    required this.distanciaM,
  });

  factory TrazadoRutaImportado.desdeCoordenadas(
    List<CoordenadaRuta> coordenadas, {
    OrigenTrazadoRuta origen = OrigenTrazadoRuta.geojson,
  }) {
    final limpias = _validarCoordenadas(coordenadas);
    return TrazadoRutaImportado(
      origen: origen,
      coordenadas: limpias,
      distanciaM: _distanciaTotalM(limpias),
    );
  }

  final OrigenTrazadoRuta origen;
  final List<CoordenadaRuta> coordenadas;
  final int distanciaM;

  int get cantidadPuntos => coordenadas.length;

  String get etiquetaOrigen => switch (origen) {
    OrigenTrazadoRuta.geojson => 'GeoJSON',
    OrigenTrazadoRuta.gpx => 'GPX',
  };

  String get distanciaLegible {
    if (distanciaM < 1000) return '$distanciaM m';
    final km = distanciaM / 1000;
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
  }

  Map<String, dynamic> toLineStringGeoJson() {
    return {
      'type': 'LineString',
      'coordinates': [
        for (final c in coordenadas) [c.lng, c.lat],
      ],
    };
  }
}

class ErrorTrazadoRuta implements Exception {
  const ErrorTrazadoRuta(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

TrazadoRutaImportado parsearTrazadoRuta(String raw) {
  final texto = raw.trim();
  if (texto.isEmpty) {
    throw const ErrorTrazadoRuta('Pega un GPX o GeoJSON valido.');
  }
  if (texto.startsWith('{') || texto.startsWith('[')) {
    return _parsearGeoJson(texto);
  }
  if (texto.contains('<gpx') || texto.contains('<trkpt')) {
    return _parsearGpx(texto);
  }
  throw const ErrorTrazadoRuta('Formato no reconocido. Usa GPX o GeoJSON.');
}

TrazadoRutaImportado _parsearGeoJson(String texto) {
  Object? data;
  try {
    data = jsonDecode(texto);
  } catch (_) {
    throw const ErrorTrazadoRuta('El GeoJSON no se pudo leer.');
  }

  final geometry = _extraerGeometryLineString(data);
  final coordinates = geometry['coordinates'];
  if (coordinates is! List) {
    throw const ErrorTrazadoRuta('El LineString no tiene coordenadas.');
  }

  final puntos = <CoordenadaRuta>[];
  for (final raw in coordinates) {
    if (raw is! List || raw.length < 2) {
      throw const ErrorTrazadoRuta('Hay una coordenada GeoJSON invalida.');
    }
    final lng = _num(raw[0]);
    final lat = _num(raw[1]);
    puntos.add(CoordenadaRuta(lat: lat, lng: lng));
  }

  return TrazadoRutaImportado.desdeCoordenadas(
    puntos,
    origen: OrigenTrazadoRuta.geojson,
  );
}

Map<String, dynamic> _extraerGeometryLineString(Object? data) {
  if (data is! Map) {
    throw const ErrorTrazadoRuta('El GeoJSON debe ser un objeto.');
  }
  final map = Map<String, dynamic>.from(data);
  final type = '${map['type'] ?? ''}'.toLowerCase();
  if (type == 'linestring') return map;

  if (type == 'feature') {
    final geometry = map['geometry'];
    if (geometry is Map &&
        '${geometry['type'] ?? ''}'.toLowerCase() == 'linestring') {
      return Map<String, dynamic>.from(geometry);
    }
  }

  if (type == 'featurecollection') {
    final features = map['features'];
    if (features is List) {
      for (final feature in features.whereType<Map>()) {
        final geometry = feature['geometry'];
        if (geometry is Map &&
            '${geometry['type'] ?? ''}'.toLowerCase() == 'linestring') {
          return Map<String, dynamic>.from(geometry);
        }
      }
    }
  }

  throw const ErrorTrazadoRuta('El GeoJSON debe contener un LineString.');
}

TrazadoRutaImportado _parsearGpx(String texto) {
  final puntos = <CoordenadaRuta>[];
  final patron = RegExp(
    r'<(?:trkpt|rtept)\b[^>]*\b(?:lat)="([^"]+)"[^>]*\b(?:lon)="([^"]+)"[^>]*>',
    caseSensitive: false,
  );

  for (final match in patron.allMatches(texto)) {
    final lat = double.tryParse(match.group(1) ?? '');
    final lng = double.tryParse(match.group(2) ?? '');
    if (lat == null || lng == null) {
      throw const ErrorTrazadoRuta(
        'Hay un punto GPX con coordenadas invalidas.',
      );
    }
    puntos.add(CoordenadaRuta(lat: lat, lng: lng));
  }

  if (puntos.isEmpty) {
    throw const ErrorTrazadoRuta('El GPX no tiene trkpt/rtept legibles.');
  }

  return TrazadoRutaImportado.desdeCoordenadas(
    puntos,
    origen: OrigenTrazadoRuta.gpx,
  );
}

List<CoordenadaRuta> _validarCoordenadas(List<CoordenadaRuta> coordenadas) {
  if (coordenadas.length < 2) {
    throw const ErrorTrazadoRuta('El trazado necesita al menos dos puntos.');
  }
  if (coordenadas.length > 2000) {
    throw const ErrorTrazadoRuta('El trazado supera el limite de 2000 puntos.');
  }

  final limpias = <CoordenadaRuta>[];
  for (final c in coordenadas) {
    if (!c.lat.isFinite ||
        !c.lng.isFinite ||
        c.lat < -90 ||
        c.lat > 90 ||
        c.lng < -180 ||
        c.lng > 180) {
      throw const ErrorTrazadoRuta(
        'El trazado contiene coordenadas invalidas.',
      );
    }
    if (limpias.isEmpty ||
        limpias.last.lat != c.lat ||
        limpias.last.lng != c.lng) {
      limpias.add(c);
    }
  }

  if (limpias.length < 2) {
    throw const ErrorTrazadoRuta('El trazado necesita dos puntos distintos.');
  }
  return List.unmodifiable(limpias);
}

double _num(Object? raw) {
  if (raw is num) return raw.toDouble();
  final parsed = double.tryParse('$raw');
  if (parsed == null) {
    throw const ErrorTrazadoRuta('Hay una coordenada no numerica.');
  }
  return parsed;
}

int _distanciaTotalM(List<CoordenadaRuta> puntos) {
  var total = 0.0;
  for (var i = 1; i < puntos.length; i++) {
    total += _distanciaM(puntos[i - 1], puntos[i]);
  }
  return total.round();
}

double _distanciaM(CoordenadaRuta a, CoordenadaRuta b) {
  const radioTierra = 6371000.0;
  final dLat = _rad(b.lat - a.lat);
  final dLng = _rad(b.lng - a.lng);
  final x =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(a.lat)) *
          math.cos(_rad(b.lat)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return radioTierra * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
}

double _rad(double grados) => grados * math.pi / 180;
