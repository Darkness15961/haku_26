import 'package:flutter_test/flutter_test.dart';
import 'package:hakuprueba/main.dart';

void main() {
  test('Smoke test HakuPruebaApp instance', () {
    // Verifica que la app pueda instanciarse correctamente sin crash de compilación
    const app = HakuPruebaApp();
    expect(app, isA<HakuPruebaApp>());
  });
}

