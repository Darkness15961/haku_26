import 'package:flutter_test/flutter_test.dart';
import 'package:haku/funcionalidades/rutas/dominio/modelos/trazado_ruta_importado.dart';

void main() {
  test('importa LineString GeoJSON directo', () {
    final trazado = parsearTrazadoRuta('''
      {
        "type": "LineString",
        "coordinates": [
          [-71.9, -13.5],
          [-72.0, -13.6]
        ]
      }
    ''');

    expect(trazado.etiquetaOrigen, 'GeoJSON');
    expect(trazado.cantidadPuntos, 2);
    expect(trazado.coordenadas.first.lat, -13.5);
    expect(trazado.toLineStringGeoJson()['type'], 'LineString');
    expect(trazado.distanciaM, greaterThan(0));
  });

  test('importa primer LineString de FeatureCollection', () {
    final trazado = parsearTrazadoRuta('''
      {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {
              "type": "LineString",
              "coordinates": [[-71.9, -13.5], [-72.0, -13.6]]
            }
          }
        ]
      }
    ''');

    expect(trazado.cantidadPuntos, 2);
  });

  test('importa GPX con trkpt', () {
    final trazado = parsearTrazadoRuta('''
      <gpx>
        <trk><trkseg>
          <trkpt lat="-13.5" lon="-71.9"></trkpt>
          <trkpt lat="-13.6" lon="-72.0"></trkpt>
        </trkseg></trk>
      </gpx>
    ''');

    expect(trazado.etiquetaOrigen, 'GPX');
    expect(trazado.cantidadPuntos, 2);
  });

  test('rechaza coordenadas fuera de rango', () {
    expect(
      () => parsearTrazadoRuta('''
        {"type":"LineString","coordinates":[[-71.9,-13.5],[-72.0,95]]}
      '''),
      throwsA(isA<ErrorTrazadoRuta>()),
    );
  });

  test('rechaza trazado excesivo', () {
    final coords = List.generate(2001, (i) => [-72.0, -13.0 - i * 0.00001]);
    expect(
      () => parsearTrazadoRuta('{"type":"LineString","coordinates":$coords}'),
      throwsA(isA<ErrorTrazadoRuta>()),
    );
  });
}
