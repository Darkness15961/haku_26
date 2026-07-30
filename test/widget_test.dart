import 'package:flutter_test/flutter_test.dart';
import 'package:haku/main.dart';

void main() {
  testWidgets('muestra la carga inicial de HAKU', (probador) async {
    await probador.pumpWidget(const AplicacionHaku());

    expect(find.text('HAKU'), findsOneWidget);
  });
}
