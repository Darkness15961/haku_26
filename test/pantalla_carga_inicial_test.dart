import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haku/funcionalidades/carga_inicial/pantallas/pantalla_carga_inicial.dart';

void main() {
  testWidgets('inicia el backend después de presentar el primer frame', (
    tester,
  ) async {
    var backendIniciado = false;
    final preparacion = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: PantallaCargaInicial(
          preparar: () {
            backendIniciado = true;
            return preparacion.future;
          },
          siguientePantalla: const Scaffold(body: Text('Aplicación lista')),
        ),
      ),
    );

    expect(find.text('HAKU'), findsOneWidget);
    expect(backendIniciado, isFalse);

    await tester.pump(const Duration(milliseconds: 199));
    expect(backendIniciado, isFalse);

    await tester.pump(const Duration(milliseconds: 1));
    expect(backendIniciado, isTrue);

    preparacion.complete();
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
    await tester.pump(const Duration(seconds: 1));

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
}
