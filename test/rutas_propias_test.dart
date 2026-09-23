import 'package:flutter_test/flutter_test.dart';
import 'package:haku/funcionalidades/rutas/dominio/modelos/modelo_ruta_propia.dart';
import 'package:haku/funcionalidades/rutas/dominio/modelos/solicitud_crear_ruta.dart';

void main() {
  test('mapea estado editorial y version de una ruta propia', () {
    final propia = ModeloRutaPropia.desdeJson({
      'id': 77,
      'nombre': 'Ruta editable',
      'descripcion': 'Ficha de prueba',
      'tipo': 'cultural',
      'dificultad': 'exigente',
      'estado_editorial': 'publicado',
      'version': 3,
      'cantidad_paradas': 2,
      'updated_at': '2026-09-23T02:00:00Z',
      'paradas': [
        {
          'id': 1,
          'nombre': 'Inicio',
          'tipo': 'inicio',
          'latitud': -13.5,
          'longitud': -71.9,
          'lugar_id': 10,
        },
        {
          'id': 2,
          'nombre': 'Destino',
          'tipo': 'destino',
          'latitud': -13.6,
          'longitud': -72.0,
          'lugar_id': 11,
        },
      ],
    });

    expect(propia.estado, EstadoEditorialRuta.publicado);
    expect(propia.publicada, isTrue);
    expect(propia.version, 3);
    expect(propia.ruta.puntos.map((p) => p.lugarId), ['10', '11']);
  });

  test('presenta rutas archivadas como desactivadas para el usuario', () {
    final propia = ModeloRutaPropia.desdeJson({
      'id': 90,
      'nombre': 'Ruta pausada',
      'estado_editorial': 'archivado',
      'version': 2,
      'paradas': const [],
    });

    expect(propia.estado, EstadoEditorialRuta.archivado);
    expect(propia.archivada, isTrue);
    expect(propia.borrador, isFalse);
    expect(EstadoEditorialRuta.archivado.etiquetaPlural, 'Desactivadas');
    expect(EstadoEditorialRuta.archivado.etiqueta, 'Desactivada');
  });

  test('crea solicitud de edicion desde ruta propia', () {
    final propia = ModeloRutaPropia.desdeJson({
      'id': 88,
      'nombre': 'Camino editable',
      'resumen': 'Resumen',
      'descripcion': 'Descripcion',
      'foto_portada': 'https://img.test/ruta.jpg',
      'tipo': 'cultural',
      'dificultad': 'facil',
      'hilo_cultural': 'camino',
      'zona': 'Cusco',
      'acceso': 'A pie',
      'transporte': 'Bus',
      'requisitos': ['Agua'],
      'advertencias': ['Sol fuerte'],
      'etiquetas': ['cultura'],
      'estado_editorial': 'borrador',
      'paradas': [
        {
          'id': 1,
          'nombre': 'Inicio',
          'tipo': 'inicio',
          'latitud': -13.5,
          'longitud': -71.9,
          'lugar_id': 10,
          'instrucciones': 'Primera parada',
        },
        {
          'id': 2,
          'nombre': 'Destino',
          'tipo': 'destino',
          'latitud': -13.6,
          'longitud': -72.0,
          'lugar_id': 11,
        },
      ],
    });

    final solicitud = SolicitudCrearRuta.desdeRutaPropia(propia);

    expect(solicitud.nombre, 'Camino editable');
    expect(solicitud.tipo, TipoRutaEscritura.cultural);
    expect(solicitud.dificultad, DificultadRutaEscritura.facil);
    expect(solicitud.fotoPortadaUrl, 'https://img.test/ruta.jpg');
    expect(solicitud.paradas.map((p) => p.lugarId), ['10', '11']);
    expect(solicitud.paradas.first.instrucciones, 'Primera parada');
    expect(solicitud.validar(), isNull);
  });
}
