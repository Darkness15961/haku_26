import 'package:flutter_test/flutter_test.dart';

import 'package:haku/funcionalidades/lugares/datos/contorno_departamento_cusco.dart';
import 'package:haku/funcionalidades/lugares/dominio/logica_ubicacion_lugar.dart';
import 'package:haku/funcionalidades/lugares/dominio/modelos/modelo_lugar.dart';
import 'package:haku/funcionalidades/lugares/dominio/modelos/modelo_territorio.dart';
import 'package:haku/funcionalidades/lugares/dominio/resolver_provincia_lugar.dart';

void main() {
  group('LogicaUbicacionLugar', () {
    test('acepta coords de Cusco (mapa / GPS típico)', () {
      expect(
        LogicaUbicacionLugar.esUbicacionValida(-13.5167, -71.9788),
        isTrue,
      );
      expect(
        LogicaUbicacionLugar.mensajeErrorUbicacion(-13.5167, -71.9788),
        isNull,
      );
    });

    test('rechaza null o fuera de rango', () {
      expect(LogicaUbicacionLugar.esUbicacionValida(null, -71), isFalse);
      expect(LogicaUbicacionLugar.esUbicacionValida(-13, null), isFalse);
      expect(LogicaUbicacionLugar.esUbicacionValida(91, -71), isFalse);
      expect(LogicaUbicacionLugar.esUbicacionValida(-13, 181), isFalse);
      expect(
        LogicaUbicacionLugar.mensajeErrorUbicacion(null, null),
        isNotNull,
      );
    });

    test('rechaza punto sospechoso 0,0', () {
      expect(LogicaUbicacionLugar.esPuntoSospechoso(0, 0), isTrue);
      expect(
        LogicaUbicacionLugar.mensajeErrorUbicacion(0, 0),
        contains('válida'),
      );
    });

    test('acepta pin típico de Urubamba', () {
      const lat = -13.3042;
      const lon = -72.1167;
      expect(LogicaUbicacionLugar.esUbicacionValida(lat, lon), isTrue);
      expect(LogicaUbicacionLugar.esPuntoSospechoso(lat, lon), isFalse);
    });
  });

  group('ResolverProvinciaLugar', () {
    final remotas = [
      const ModeloProvinciaDb(
        id: 1,
        nombre: 'Urubamba',
        codigo: 'urubamba',
        departamentoId: 1,
      ),
      const ModeloProvinciaDb(
        id: 2,
        nombre: 'La Convención',
        codigo: 'la_convencion',
        departamentoId: 1,
      ),
    ];

    test('resuelve por nombre de isla', () {
      final p = ResolverProvinciaLugar.desdeInicial(
        remotas: remotas,
        inicial: 'Urubamba',
      );
      expect(p?.codigo, 'urubamba');
    });

    test('resuelve por código', () {
      final p = ResolverProvinciaLugar.desdeInicial(
        remotas: remotas,
        inicial: 'la_convencion',
      );
      expect(p?.nombre, 'La Convención');
    });

    test('resuelve Convención con tilde / alias', () {
      final p = ResolverProvinciaLugar.desdeInicial(
        remotas: remotas,
        inicial: 'La Convención',
      );
      expect(p?.codigo, 'la_convencion');
    });

    test('null si no hay match', () {
      expect(
        ResolverProvinciaLugar.desdeInicial(
          remotas: remotas,
          inicial: 'Lima',
        ),
        isNull,
      );
    });
  });

  group('ModeloLugar.desdeFilaRemota', () {
    test('mapea ficha sin dificultad ni tiempo', () {
      final lugar = ModeloLugar.desdeFilaRemota({
        'id': 42,
        'nombre': 'Mirador test',
        'descripcion': 'Vista',
        'foto_portada': null,
        'latitud': -13.3,
        'longitud': -72.1,
        'acceso': 'Caminando',
        'altitud': 2800,
        'distrito_id': 7,
        'fecha_creacion': '2026-09-12T12:00:00Z',
        'distrito': {
          'id': 7,
          'nombre': 'Urubamba',
          'codigo': 'urubamba_dist',
          'provincia_id': 1,
          'provincia': {
            'id': 1,
            'nombre': 'Urubamba',
            'codigo': 'urubamba',
          },
        },
        'lugar_categoria': [],
      });

      expect(lugar.id, '42');
      expect(lugar.nombre, 'Mirador test');
      expect(lugar.distritoId, 7);
      expect(lugar.distrito, 'Urubamba');
      expect(lugar.provinciaCodigo, 'urubamba');
      expect(lugar.provinciaId, 1);
      expect(lugar.acceso, 'Caminando');
      expect(lugar.latitud, -13.3);
      expect(lugar.longitud, -72.1);
      expect(lugar.dificultad, isEmpty);
      expect(lugar.tiempoEstimado, isEmpty);
      expect(lugar.remoto, isTrue);
      expect(lugar.altitud, contains('2800'));
      expect(lugar.etiquetas, isEmpty);
    });

    test('mapea temática y actividad desde lugar_categoria', () {
      final lugar = ModeloLugar.desdeFilaRemota({
        'id': 7,
        'nombre': 'Salineras',
        'descripcion': '',
        'foto_portada': null,
        'latitud': -13.3,
        'longitud': -72.1,
        'acceso': '',
        'distrito_id': 1,
        'distrito': {
          'id': 1,
          'nombre': 'Maras',
          'provincia': {'id': 1, 'nombre': 'Urubamba', 'codigo': 'urubamba'},
        },
        'lugar_categoria': [
          {
            'categoria': {
              'id': 1,
              'nombre': 'Naturaleza',
              'tipo': 'tematica',
            },
          },
          {
            'categoria': {
              'id': 2,
              'nombre': 'Fotografía',
              'tipo': 'actividad',
            },
          },
        ],
      });

      expect(lugar.tematicas.map((e) => e.nombre), ['Naturaleza']);
      expect(lugar.actividades.map((e) => e.nombre), ['Fotografía']);
      expect(lugar.tieneEtiquetaNombre('Naturaleza'), isTrue);
      expect(lugar.subtituloClasificacion, 'Naturaleza · Fotografía');
    });
  });

  group('facetaCategoriaDesdeTipo', () {
    test('normaliza acentos y alias', () {
      expect(
        facetaCategoriaDesdeTipo('Temática'),
        FacetaCategoriaLugar.tematica,
      );
      expect(
        facetaCategoriaDesdeTipo('actividad'),
        FacetaCategoriaLugar.actividad,
      );
      expect(
        facetaCategoriaDesdeTipo('Interés'),
        FacetaCategoriaLugar.tematica,
      );
    });
  });

  group('ContornoDepartamentoCusco', () {
    test('parsea FeatureCollection Polygon lon/lat', () {
      const raw = '''
{"type":"FeatureCollection","features":[{
  "type":"Feature",
  "properties":{"nombre":"Cusco"},
  "geometry":{"type":"Polygon","coordinates":[[
    [-72.0,-13.0],[-71.0,-13.0],[-71.0,-14.0],[-72.0,-14.0],[-72.0,-13.0]
  ]]}
}]}''';
      final pts = ContornoDepartamentoCusco.parsear(raw);
      expect(pts.length, 5);
      expect(pts.first.latitude, -13.0);
      expect(pts.first.longitude, -72.0);
    });
  });
}
