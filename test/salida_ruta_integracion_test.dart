import 'package:flutter_test/flutter_test.dart';
import 'package:haku/funcionalidades/comunidad/dominio/modelo_publicacion.dart';
import 'package:haku/funcionalidades/comunidad/dominio/modelo_salida.dart';

void main() {
  group('Integracion rutas y salidas', () {
    test('salida conserva ruta vinculada y punto de encuentro independiente', () {
      final salida = ModeloSalidaRemota.desdeFilaRemota({
        'id': 91,
        'titulo': 'Salida al valle',
        'organizador_id': 'user-1',
        'ruta_id': 42,
        'fecha_hora_inicio': '2026-10-01T11:30:00Z',
        'punto_encuentro_lat': -13.516,
        'punto_encuentro_lon': -71.978,
        'punto_encuentro_lugar_id': 7,
        'tipo': 'publica',
        'cupos_totales': 12,
        'minimo_para_salir': 3,
        'estado': 'programada',
        'ruta': {
          'id': 42,
          'nombre': 'Valle Sagrado vivo',
          'resumen': 'Itinerario cultural',
        },
        'lugar': {
          'id': 7,
          'nombre': 'Plaza San Francisco',
          'latitud': -13.516,
          'longitud': -71.978,
        },
      });

      expect(salida.rutaId, '42');
      expect(salida.rutaNombre, 'Valle Sagrado vivo');
      expect(salida.rutaResumen, 'Itinerario cultural');
      expect(salida.lugarId, '7');
      expect(salida.puntoEncuentroEtiqueta, 'Plaza San Francisco');
      expect(salida.latitud, -13.516);
      expect(salida.longitud, -71.978);
    });

    test('salida mantiene rutaId aunque la ruta ya no llegue embebida', () {
      final salida = ModeloSalidaRemota.desdeFilaRemota({
        'id': 92,
        'titulo': 'Salida historica',
        'organizador_id': 'user-1',
        'ruta_id': 50,
        'fecha_hora_inicio': '2026-10-02T11:30:00Z',
        'punto_encuentro_lat': -13.5,
        'punto_encuentro_lon': -71.9,
        'tipo': 'publica',
        'cupos_totales': 8,
      });

      expect(salida.rutaId, '50');
      expect(salida.rutaNombre, isNull);
      expect(salida.puntoEncuentroEtiqueta, '-13.50000, -71.90000');
    });

    test('publicacion remota enlaza ruta y salida como experiencias', () {
      final publicacion = ModeloPublicacionRemota.desdeFilaRemota({
        'id': 10,
        'usuario_id': 'user-2',
        'contenido': 'Recorrido recomendado',
        'fecha_creacion': '2026-09-23T12:00:00Z',
        'publicacion_ruta': [
          {
            'ruta_id': 42,
            'ruta': {'id': 42, 'nombre': 'Valle Sagrado vivo'},
          },
        ],
        'publicacion_salida': [
          {
            'salida_id': 91,
            'salida': {'id': 91, 'titulo': 'Salida al valle'},
          },
        ],
      });

      expect(publicacion.rutaId, '42');
      expect(publicacion.rutaNombre, 'Valle Sagrado vivo');
      expect(publicacion.salidaId, '91');
      expect(publicacion.salidaNombre, 'Salida al valle');
    });
  });
}
