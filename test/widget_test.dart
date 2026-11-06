import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:haku/main.dart';

void main() {
  testWidgets('muestra la carga inicial de HAKU', (probador) async {
    final preparacion = Completer<void>();
    await probador.pumpWidget(AplicacionHaku(preparacion: preparacion.future));

    expect(find.text('HAKU'), findsOneWidget);
  });
}
