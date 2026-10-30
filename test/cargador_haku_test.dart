import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haku/nucleo/widgets/cargador_haku.dart';
import 'package:lottie/lottie.dart';

void main() {
  testWidgets('muestra la animación y comunica el estado de carga', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CargadorHaku.pagina(mensaje: 'Preparando tu viaje…'),
        ),
      ),
    );

    expect(find.byType(Lottie), findsNothing);
    expect(find.text('Preparando tu viaje…'), findsNothing);

    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(Lottie), findsOneWidget);
    expect(find.text('Preparando tu viaje…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 160));

    expect(find.bySemanticsLabel('Preparando tu viaje…'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('respeta la preferencia de movimiento reducido', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: CargadorHaku.contenido()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final lottie = tester.widget<Lottie>(find.byType(Lottie));
    expect(lottie.animate, isFalse);
    expect(lottie.repeat, isFalse);
  });

  testWidgets('no aparece si una carga termina antes del umbral', (
    tester,
  ) async {
    var cargando = true;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: cargando
                  ? const CargadorHaku.pagina()
                  : const Text('Contenido listo'),
              floatingActionButton: FloatingActionButton(
                onPressed: () => setState(() => cargando = false),
              ),
            );
          },
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(Lottie), findsNothing);
    expect(find.text('Contenido listo'), findsOneWidget);
  });
}
