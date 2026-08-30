import 'package:flutter_test/flutter_test.dart';
import 'package:haku/funcionalidades/inicio/datos/feed_inicio_datasource_local.dart';
import 'package:haku/funcionalidades/lugares/widgets/metricas_comunidad.dart';
import 'package:haku/funcionalidades/rutas/datos/rutas_datasource_local.dart';

void main() {
  group('MetricasComunidad rutas', () {
    test('indiceRutas agrupa valoraciones por rutaId', () {
      final publicaciones = [
        PublicacionFeed(
          id: 'p1',
          autorId: 'a',
          autor: 'A',
          usuario: '@a',
          avatarUrl: '',
          hace: '1h',
          texto: 'Incredible',
          imagenUrl: 'https://example.com/1.jpg',
          likes: 0,
          comentarios: 0,
          estiloFondo: EstiloFondoPublicacion.veloNegro,
          rutaId: 'ruta_inca_clasica',
          calificacion: 5,
        ),
        PublicacionFeed(
          id: 'p2',
          autorId: 'b',
          autor: 'B',
          usuario: '@b',
          avatarUrl: '',
          hace: '2h',
          texto: 'Great trek',
          imagenUrl: 'https://example.com/2.jpg',
          likes: 0,
          comentarios: 0,
          estiloFondo: EstiloFondoPublicacion.veloNegro,
          rutaId: 'ruta_inca_clasica',
          calificacion: 4,
        ),
      ];

      final indice = MetricasComunidad.indiceRutas(publicaciones);

      expect(indice.calificaciones['ruta_inca_clasica'], 4.5);
      expect(indice.valoraciones['ruta_inca_clasica'], 2);
      expect(indice.fotos['ruta_inca_clasica'], 2);
      expect(indice.exploradores['ruta_inca_clasica'], 2);
    });

    test('enriquecerRuta sustituye catálogo cuando hay comunidad', () {
      final base = RutasDataSourceLocal.obtenerPorId('ruta_inca_clasica')!;
      final indice = MetricasComunidad.indiceRutas([
        PublicacionFeed(
          id: 'p1',
          autorId: 'yo',
          autor: 'Yo',
          usuario: '@yo',
          avatarUrl: '',
          hace: 'ahora',
          texto: 'Test',
          imagenUrl: 'https://example.com/x.jpg',
          likes: 0,
          comentarios: 0,
          estiloFondo: EstiloFondoPublicacion.veloNegro,
          rutaId: 'ruta_inca_clasica',
          calificacion: 5,
        ),
      ]);

      final enriquecida = MetricasComunidad.enriquecerRuta(base, indice);

      expect(enriquecida.calificacion, 5);
      expect(enriquecida.cantidadResenas, 1);
      expect(base.cantidadResenas, greaterThan(100));
    });

    test('experienciasDe filtra invitaciones de salida', () {
      final lista = [
        PublicacionFeed(
          id: 'exp',
          autorId: 'yo',
          autor: 'Yo',
          usuario: '@yo',
          avatarUrl: '',
          hace: 'ahora',
          texto: 'Experiencia',
          imagenUrl: null,
          likes: 0,
          comentarios: 0,
          estiloFondo: EstiloFondoPublicacion.veloNegro,
          rutaId: 'ruta_inca_clasica',
        ),
        PublicacionFeed(
          id: 'inv',
          autorId: 'yo',
          autor: 'Yo',
          usuario: '@yo',
          avatarUrl: '',
          hace: 'ahora',
          texto: 'Salida',
          imagenUrl: null,
          likes: 0,
          comentarios: 0,
          estiloFondo: EstiloFondoPublicacion.veloNegro,
          rutaId: 'ruta_inca_clasica',
          tipo: 'invitacion_salida',
          salidaId: 's1',
        ),
      ];

      final exp = MetricasComunidad.experienciasDe(lista, rutaId: 'ruta_inca_clasica');

      expect(exp.length, 1);
      expect(exp.first.id, 'exp');
    });
  });
}
