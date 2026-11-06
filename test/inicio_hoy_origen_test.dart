import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haku/funcionalidades/inicio/proveedores/proveedor_datos_inicio_hoy.dart';
import 'package:haku/funcionalidades/inicio/pantallas/pantalla_feed_inicio.dart';
import 'package:haku/funcionalidades/inicio/widgets/portada_inicio_cultura.dart';
import 'package:haku/nucleo/widgets/cargador_haku.dart';
import 'package:haku/funcionalidades/lugares/dominio/modelos/modelo_lugar.dart';
import 'package:haku/funcionalidades/lugares/proveedores/proveedor_lugares.dart';
import 'package:haku/funcionalidades/rutas/dominio/modelos/modelo_ruta.dart';
import 'package:haku/funcionalidades/rutas/proveedores/proveedor_rutas.dart';
import 'package:haku/nucleo/configuracion/modo_ejecucion.dart';
import 'package:haku/nucleo/recursos/copy_haku.dart';

void main() {
  const rutaRemota = ModeloRuta(
    id: '101',
    titulo: 'Ruta remota',
    descripcion: 'Desde Supabase',
    imagenUrl: 'https://example.com/ruta.jpg',
    categoria: CategoriaRuta.naturaleza,
  );
  const lugarRemoto = ModeloLugar(
    id: '202',
    nombre: 'Lugar remoto',
    descripcion: 'Desde Supabase',
    imagenUrl: 'https://example.com/lugar.jpg',
    categoria: CategoriaLugar.naturaleza,
    provincia: 'Cusco',
    remoto: true,
  );

  test('produccion publica rutas y lugares remotos como una unidad', () async {
    final container = ProviderContainer(
      overrides: [
        modoEjecucionInicioProvider.overrideWithValue(
          ModoEjecucionHaku.produccion,
        ),
        rutasPublicadasProvider.overrideWith((ref) async => [rutaRemota]),
        lugaresRemotosProvider.overrideWith((ref) async => [lugarRemoto]),
      ],
    );
    addTearDown(container.dispose);

    final datos = await container.read(datosInicioHoyProvider.future);

    expect(datos.esDemo, isFalse);
    expect(datos.rutas, [rutaRemota]);
    expect(datos.lugares, [lugarRemoto]);
  });

  test(
    'demo usa ambos catalogos locales sin consultar providers remotos',
    () async {
      final container = ProviderContainer(
        overrides: [
          modoEjecucionInicioProvider.overrideWithValue(ModoEjecucionHaku.demo),
          rutasPublicadasProvider.overrideWith(
            (ref) => throw StateError('No debe consultar rutas remotas'),
          ),
          lugaresRemotosProvider.overrideWith(
            (ref) => throw StateError('No debe consultar lugares remotos'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final datos = await container.read(datosInicioHoyProvider.future);

      expect(datos.esDemo, isTrue);
      expect(datos.rutas, isNotEmpty);
      expect(datos.lugares, isNotEmpty);
    },
  );

  test(
    'un fallo de lugares no queda oculto mientras rutas sigue cargando',
    () async {
      final rutas = Completer<List<ModeloRuta>>();
      final lugares = Completer<List<ModeloLugar>>();
      final container = ProviderContainer(
        overrides: [
          modoEjecucionInicioProvider.overrideWithValue(
            ModoEjecucionHaku.produccion,
          ),
          rutasPublicadasProvider.overrideWith((ref) => rutas.future),
          lugaresRemotosProvider.overrideWith((ref) => lugares.future),
        ],
      );
      addTearDown(container.dispose);
      final resultado = container.read(datosInicioHoyProvider.future);
      final comprobacion = expectLater(resultado, throwsA(isA<StateError>()));
      lugares.completeError(StateError('lugares no disponible'));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(datosInicioHoyProvider).hasError, isTrue);
      // También se observa un error tardío de la otra consulta.
      rutas.completeError(StateError('rutas no disponible'));
      await comprobacion;
    },
  );

  testWidgets('produccion no muestra la portada fallback antigua', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PortadaInicioCultura(rutas: [], mostrarFallback: false),
        ),
      ),
    );

    expect(find.text(CopyHaku.portadaTituloFallback), findsNothing);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('Hoy muestra el cargador HAKU durante la carga remota', (
    tester,
  ) async {
    final cargaPendiente = Completer<DatosInicioHoy>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          datosInicioHoyProvider.overrideWith((ref) => cargaPendiente.future),
        ],
        child: const MaterialApp(home: PantallaFeedInicio()),
      ),
    );

    expect(find.byKey(const ValueKey('inicio-hoy-cargando')), findsOneWidget);
    expect(find.byType(CargadorHaku), findsOneWidget);
    expect(find.text(CopyHaku.portadaTituloFallback), findsNothing);
  });
}
