import 'package:flutter_test/flutter_test.dart';
import 'package:haku/funcionalidades/lugares/dominio/modelos/modelo_lugar_propio.dart';

void main() {
  test('mapea un Lugar propio publicado con su territorio', () {
    final propio = ModeloLugarPropio.desdeJson({
      'id': 42,
      'nombre': 'Mirador editable',
      'descripcion': 'Ficha del propietario',
      'estado': true,
      'estado_editorial': 'publicado',
      'usuario_id': '10000000-0000-0000-0000-000000000001',
      'distrito_id': 7,
      'latitud': -13.3,
      'longitud': -72.1,
      'updated_at': '2026-10-30T12:00:00Z',
      'distrito': {
        'id': 7,
        'nombre': 'Maras',
        'provincia_id': 1,
        'provincia': {'id': 1, 'nombre': 'Urubamba', 'codigo': 'urubamba'},
      },
      'lugar_categoria': [
        {
          'categoria': {'id': 3, 'nombre': 'Naturaleza', 'tipo': 'tematica'},
        },
      ],
    });

    expect(propio.id, '42');
    expect(propio.estado, EstadoEditorialLugar.publicado);
    expect(propio.publicado, isTrue);
    expect(propio.lugar.distrito, 'Maras');
    expect(propio.lugar.provincia, 'Urubamba');
    expect(propio.lugar.etiquetas.single.id, 3);
    expect(propio.actualizadoEn, DateTime.utc(2026, 10, 30, 12));
  });

  test('presenta archivado como desactivado', () {
    final propio = ModeloLugarPropio.desdeJson({
      'id': 90,
      'nombre': 'Lugar pausado',
      'estado_editorial': 'archivado',
      'distrito': {
        'id': 1,
        'nombre': 'Cusco',
        'provincia': {'id': 1, 'nombre': 'Cusco', 'codigo': 'cusco'},
      },
      'lugar_categoria': const [],
    });

    expect(propio.archivado, isTrue);
    expect(propio.borrador, isFalse);
    expect(EstadoEditorialLugar.archivado.etiquetaPlural, 'Desactivados');
    expect(EstadoEditorialLugar.archivado.etiqueta, 'Desactivado');
  });

  test('un estado remoto desconocido se trata como borrador seguro', () {
    expect(
      EstadoEditorialLugar.desdeValor('estado_nuevo'),
      EstadoEditorialLugar.borrador,
    );
  });
}
