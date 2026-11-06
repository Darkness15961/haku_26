import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haku/funcionalidades/carga_inicial/pantallas/pantalla_carga_inicial.dart';
import 'package:haku/nucleo/widgets/cargador_haku.dart';

void main() {
  testWidgets('inicia el backend después de presentar el primer frame', (
    tester,
  ) async {
    var backendIniciado = false;
    SchedulerPhase? faseInicio;
    final preparacion = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: PantallaCargaInicial(
          preparar: () {
            backendIniciado = true;
            faseInicio = SchedulerBinding.instance.schedulerPhase;
            return preparacion.future;
          },
          siguientePantalla: const Scaffold(body: Text('Aplicación lista')),
        ),
      ),
    );

    expect(find.text('HAKU'), findsOneWidget);
    expect(backendIniciado, isTrue);
    expect(faseInicio, SchedulerPhase.postFrameCallbacks);
    expect(find.byKey(const ValueKey('cargador-visible')), findsOneWidget);
    expect(
      tester.widget<CargadorHaku>(find.byType(CargadorHaku)).retraso,
      Duration.zero,
    );
    // Ningún efecto de entrada deja transparente el contenido del splash.
    final fades = tester.widgetList<FadeTransition>(
      find.ancestor(
        of: find.text('HAKU'),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fades.every((fade) => fade.opacity.value > 0), isTrue);

    preparacion.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4999));
    expect(find.text('Aplicación lista'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Aplicación lista'), findsOneWidget);
  });

  testWidgets('mantiene una interfaz visible mientras prepara el backend', (
    tester,
  ) async {
    final preparacion = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: PantallaCargaInicial(
          preparacion: preparacion.future,
          siguientePantalla: const Scaffold(body: Text('Aplicación lista')),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 12));

    expect(find.text('HAKU'), findsOneWidget);
    expect(find.text('Aplicación lista'), findsNothing);

    preparacion.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Aplicación lista'), findsOneWidget);
  });

  testWidgets('muestra un estado controlado si falla la preparación', (
    tester,
  ) async {
    final preparacion = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: PantallaCargaInicial(
          preparacion: preparacion.future,
          pantallaError: const Scaffold(body: Text('Sin conexión')),
          siguientePantalla: const Scaffold(body: Text('Aplicación lista')),
        ),
      ),
    );

    preparacion.completeError(StateError('backend no disponible'));
    await tester.pump();

    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.text('Aplicación lista'), findsNothing);
  });

  testWidgets('captura errores sincronos y permite reintentar una sola vez', (
    tester,
  ) async {
    var intentos = 0;
    final segundoIntento = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaCargaInicial(
          preparar: () {
            intentos++;
            if (intentos == 1) throw StateError('fallo inmediato');
            return segundoIntento.future;
          },
          siguientePantalla: const Scaffold(
            body: Text('Lista tras reintentar'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Reintentar'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(intentos, 2);
    expect(find.text('Reintentar'), findsNothing);
    expect(find.text('Lista tras reintentar'), findsNothing);
    segundoIntento.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Lista tras reintentar'), findsOneWidget);
    expect(intentos, 2);
  });

  testWidgets('ignora la finalizacion cuando la pantalla ya fue desmontada', (
    tester,
  ) async {
    final preparacion = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaCargaInicial(
          preparacion: preparacion.future,
          siguientePantalla: const Scaffold(body: Text('No debe navegar')),
        ),
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: Text('Otra pantalla')));
    preparacion.completeError(StateError('finalizacion tardia'));
    await tester.pump();
    expect(find.text('Otra pantalla'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
