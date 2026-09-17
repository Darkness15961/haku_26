import 'package:flutter_test/flutter_test.dart';
import 'package:haku/funcionalidades/autenticacion/dominio/servicios/politica_nickname.dart';
import 'package:haku/funcionalidades/autenticacion/widgets/ayuda_nickname.dart';

void main() {
  group('PoliticaNickname', () {
    test('normaliza arroba, espacios y mayúsculas', () {
      expect(PoliticaNickname.normalizar('  @Viajero_2026  '), 'viajero_2026');
    });

    test('acepta el contrato público', () {
      for (final nick in ['haku2', 'viajero_cusco', '7caminos', 'abc']) {
        expect(
          PoliticaNickname.validar(nick),
          isNull,
          reason: '$nick debería ser válido',
        );
      }
    });

    test('rechaza longitud fuera de 3 a 30', () {
      expect(PoliticaNickname.validar('ab'), isNotNull);
      expect(PoliticaNickname.validar(List.filled(31, 'a').join()), isNotNull);
    });

    test('rechaza bordes, espacios, tildes y símbolos', () {
      for (final nick in [
        '_haku',
        'haku_',
        'ha ku',
        'josé',
        'haku-peru',
        r'haku$peru',
      ]) {
        expect(
          PoliticaNickname.validar(nick),
          isNotNull,
          reason: '$nick debería ser inválido',
        );
      }
    });

    test('rechaza nombres operativos reservados sin importar mayúsculas', () {
      expect(PoliticaNickname.validar('ADMIN'), isNotNull);
      expect(PoliticaNickname.validar('@Soporte'), isNotNull);
      expect(PoliticaNickname.validar('haku'), isNotNull);
    });

    test(
      'formatter convierte mayúsculas pero conserva errores para explicar',
      () {
        const formatter = FormateadorNicknameMinusculas();
        final resultado = formatter.formatEditUpdate(
          TextEditingValue.empty,
          const TextEditingValue(text: 'ÁNA Pérez!'),
        );

        expect(resultado.text, 'ána pérez!');
        expect(PoliticaNickname.validar(resultado.text), isNotNull);
      },
    );
  });
}
