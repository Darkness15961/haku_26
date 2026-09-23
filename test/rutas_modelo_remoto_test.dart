import 'package:flutter_test/flutter_test.dart';
import 'package:haku/funcionalidades/rutas/dominio/modelos/modelo_ruta.dart';

void main() {
  test('mapea ficha, paradas ordenadas y trazado GeoJSON', () {
    final ruta = ModeloRuta.desdeFilaRemota({
      'id': 42,
      'slug': 'valle-sagrado',
      'nombre': 'Valle Sagrado',
      'resumen': 'Circuito cultural',
      'descripcion': 'Recorrido oficial',
      'foto_portada': 'https://img.test/ruta.jpg',
      'tipo': 'cultural',
      'dificultad': 'facil',
      'distancia_m': 12500,
      'duracion_minutos': 150,
      'dias': 1,
      'altitud_max_m': 3400,
      'meses_recomendados': [5, 6, 7],
      'zona': 'Urubamba',
      'requisitos': ['Agua'],
      'advertencias': ['Aclimatarse'],
      'cantidad_paradas': 2,
      'valoracion_promedio': 4.5,
      'cantidad_valoraciones': 8,
      'usuario_creador_nombre': 'anaq',
      'usuario_creador_foto': 'https://img.test/ana.jpg',
      'publicada_en': '2026-09-22T10:00:00Z',
      'updated_at': '2026-09-23T11:30:00Z',
      'paradas': [
        {
          'id': 1,
          'nombre': 'Inicio',
          'tipo': 'inicio',
          'latitud': -13.5,
          'longitud': -71.9,
          'lugar_id': 99,
          'altitud_m': 3400,
        },
        {
          'id': 2,
          'nombre': 'Destino',
          'tipo': 'destino',
          'latitud': -13.4,
          'longitud': -72.0,
        },
      ],
      'trazado_geojson': {
        'type': 'LineString',
        'coordinates': [
          [-71.9, -13.5],
          [-72.0, -13.4],
        ],
      },
    });

    expect(ruta.id, '42');
    expect(ruta.slug, 'valle-sagrado');
    expect(ruta.categoria, CategoriaRuta.cultura);
    expect(ruta.distancia, '12.5 km');
    expect(ruta.tiempoCaminata, '2 h 30 min');
    expect(ruta.puntos.map((p) => p.nombre), ['Inicio', 'Destino']);
    expect(ruta.puntos.first.lugarId, '99');
    expect(ruta.puntos.first.altitudM, 3400);
    expect(ruta.trazado, hasLength(2));
    expect(ruta.trazado.first.lng, -71.9);
    expect(ruta.tips, ['Agua', 'Aclimatarse']);
    expect(ruta.calificacion, 4.5);
    expect(ruta.cantidadResenas, 8);
    expect(ruta.usuarioCreadorNombre, 'anaq');
    expect(ruta.usuarioCreadorFoto, 'https://img.test/ana.jpg');
    expect(ruta.publicadaEn?.toUtc().year, 2026);
    expect(ruta.updatedAt?.toUtc().day, 23);
  });

  test('no inventa trazado cuando backend no publica LineString', () {
    final ruta = ModeloRuta.desdeFilaRemota({
      'id': 7,
      'slug': 'sin-trazado',
      'nombre': 'Ruta sin trazado',
      'tipo': 'senderismo',
      'dificultad': 'moderado',
      'paradas': const [],
    });

    expect(ruta.trazado, isEmpty);
    expect(ruta.puntos, isEmpty);
  });

  test('descarta coordenadas inválidas en paradas y trazado', () {
    final ruta = ModeloRuta.desdeFilaRemota({
      'id': 8,
      'nombre': 'Ruta defensiva',
      'paradas': [
        {'id': 1, 'nombre': 'Sin coordenadas'},
        {'id': 2, 'nombre': 'Latitud inválida', 'latitud': 95, 'longitud': -72},
        {'id': 3, 'nombre': 'Válida', 'latitud': -13.5, 'longitud': -72},
      ],
      'trazado_geojson': {
        'coordinates': [
          [-72, 100],
          [-72, -13.5],
        ],
      },
    });

    expect(ruta.puntos.map((p) => p.nombre), ['Válida']);
    expect(ruta.trazado, hasLength(1));
    expect(ruta.trazado.single.lat, -13.5);
  });

  test('conserva trazado válido aunque no existan paradas', () {
    final ruta = ModeloRuta.desdeFilaRemota({
      'id': 9,
      'nombre': 'Solo trazado',
      'paradas': const [],
      'trazado_geojson': {
        'coordinates': [
          [-72.0, -13.5],
          [-72.1, -13.6],
        ],
      },
    });

    expect(ruta.puntos, isEmpty);
    expect(ruta.trazado, hasLength(2));
  });
}
