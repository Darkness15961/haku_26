import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haku/funcionalidades/chat/proveedores/proveedor_chat.dart';
import 'package:haku/funcionalidades/inicio/pantallas/pantalla_feed_inicio.dart';
import 'package:haku/funcionalidades/inicio/proveedores/proveedor_almacen_feed.dart';
import 'package:haku/funcionalidades/inicio/proveedores/proveedor_datos_inicio_hoy.dart';
import 'package:haku/funcionalidades/inicio/widgets/card_escapada_comunidad.dart';
import 'package:haku/funcionalidades/inicio/widgets/carrusel_rutas_recomendadas.dart';
import 'package:haku/funcionalidades/inicio/widgets/portada_inicio_cultura.dart';
import 'package:haku/funcionalidades/lugares/dominio/modelos/modelo_lugar.dart';
import 'package:haku/funcionalidades/rutas/dominio/modelos/modelo_ruta.dart';
import 'package:haku/nucleo/configuracion/modo_ejecucion.dart';
import 'package:haku/nucleo/recursos/catalogo_imagenes_haku.dart';
import 'package:haku/nucleo/widgets/imagen_haku.dart';

// Aísla favoritos: estas pruebas no leen ni escriben el almacén local.
class _AlmacenVacio extends AlmacenFeedNotifier {
  @override
  Future<void> cargar() async {
    state = const EstadoAlmacenFeed(listo: true);
  }
}

void main() {
  for (final conFoto in [true, false]) {
    testWidgets(
      conFoto
          ? 'Hoy conserva las fotos remotas en todas sus secciones'
          : 'Hoy usa el respaldo habitual cuando los registros no tienen foto',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final categorias = [
          CategoriaLugar.magico,
          CategoriaLugar.naturaleza,
          CategoriaLugar.gastronomia,
          CategoriaLugar.fotografia,
          CategoriaLugar.aventura,
        ];
        final lugares = [
          for (var i = 0; i < categorias.length; i++)
            ModeloLugar.desdeFilaRemota({
              'id': i + 1,
              'nombre': 'Lugar ${i + 1}',
              'foto_portada': conFoto
                  ? 'https://example.com/lugar-$i.jpg'
                  : null,
            }).copyWith(
              categoria: categorias[i],
              nivelExploracion: i == 1
                  ? NivelExploracion.nuevoEnHaku
                  : NivelExploracion.enCrecimiento,
            ),
        ];
        final ruta = ModeloRuta(
          id: '101',
          titulo: 'Ruta de comida',
          descripcion: '',
          imagenUrl: conFoto ? 'https://example.com/ruta.jpg' : '',
          categoria: CategoriaRuta.cultura,
          hilo: HiloCultura.comida,
        );
        final esperadas = {
          for (final lugar in lugares) 'lugar_${lugar.id}': lugar.imagenUrl,
          ruta.id: ruta.imagenUrl,
        };

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              datosInicioHoyProvider.overrideWith(
                (ref) async => DatosInicioHoy(
                  modo: ModoEjecucionHaku.produccion,
                  rutas: [ruta],
                  lugares: lugares,
                ),
              ),
              totalNoLeidosChatProvider.overrideWithValue(0),
              almacenFeedProvider.overrideWith((ref) => _AlmacenVacio()),
            ],
            child: const MaterialApp(home: PantallaFeedInicio()),
          ),
        );
        await tester.pump();

        final tarjetas = [
          ...tester
              .widget<PortadaInicioCultura>(find.byType(PortadaInicioCultura))
              .rutas,
          ...tester
              .widget<CardEscapadaComunidad>(find.byType(CardEscapadaComunidad))
              .lugares,
          for (final carrusel in tester.widgetList<CarruselRutasRecomendadas>(
            find.byType(CarruselRutasRecomendadas),
          ))
            ...carrusel.rutas,
        ];
        expect({for (final r in tarjetas) r.id: r.imagenUrl}, esperadas);
        expect(
          tester.widgetList<ImagenHaku>(find.byType(ImagenHaku)),
          isNotEmpty,
        );
        for (final imagen in tester.widgetList<ImagenHaku>(
          find.byType(ImagenHaku),
        )) {
          expect(esperadas.values, contains(imagen.url));
        }
        if (!conFoto) {
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Image &&
                  widget.image is AssetImage &&
                  (widget.image as AssetImage).assetName ==
                      CatalogoImagenesHaku.respaldo,
            ),
            findsWidgets,
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
