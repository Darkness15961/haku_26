import 'package:flutter_test/flutter_test.dart';
import 'package:haku/nucleo/configuracion/modo_ejecucion.dart';

void main() {
  group('interpretarModoEjecucion', () {
    test('acepta los nombres de produccion soportados', () {
      expect(
        interpretarModoEjecucion('production'),
        ModoEjecucionHaku.produccion,
      );
      expect(
        interpretarModoEjecucion(' PRODUCCION '),
        ModoEjecucionHaku.produccion,
      );
      expect(interpretarModoEjecucion('prod'), ModoEjecucionHaku.produccion);
    });

    test('acepta demo sin importar mayusculas', () {
      expect(interpretarModoEjecucion('DeMo'), ModoEjecucionHaku.demo);
    });

    test('rechaza un modo desconocido para evitar fallbacks silenciosos', () {
      expect(
        () => interpretarModoEjecucion('offline'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
