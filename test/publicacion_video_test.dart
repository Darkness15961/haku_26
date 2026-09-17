import 'package:flutter_test/flutter_test.dart';
import 'package:haku/funcionalidades/comunidad/dominio/modelo_publicacion.dart';

void main() {
  test('mapea imagen y video sin interpretar HLS como fotografía', () {
    final publicacion = ModeloPublicacionRemota.desdeFilaRemota({
      'id': 42,
      'usuario_id': 'usuario-1',
      'contenido': 'Camino a la montaña',
      'estado': 'publico',
      'fecha_creacion': '2026-09-17T05:00:00Z',
      'publicacion_multimedia': [
        {
          'id': 2,
          'url_archivo': 'https://cdn.haku/imagen.webp',
          'tipo': 'imagen',
          'orden': 2,
        },
        {
          'id': 1,
          'url_archivo': 'https://video.haku/guid/playlist.m3u8',
          'miniatura_url': 'https://video.haku/guid/thumbnail.jpg',
          'proveedor_video_id': 'guid',
          'video_estado': 'ready',
          'tipo': 'video',
          'orden': 1,
        },
      ],
    });

    expect(publicacion.imagenUrl, 'https://cdn.haku/imagen.webp');
    expect(publicacion.videoUrl, 'https://video.haku/guid/playlist.m3u8');
    expect(
      publicacion.videoMiniaturaUrl,
      'https://video.haku/guid/thumbnail.jpg',
    );
    expect(publicacion.videoProveedorId, 'guid');
    expect(publicacion.videoEstado, 'ready');
  });

  test('multimedia histórica sin tipo conserva comportamiento de imagen', () {
    final publicacion = ModeloPublicacionRemota.desdeFilaRemota({
      'id': 7,
      'usuario_id': 'usuario-2',
      'contenido': 'Una fotografía',
      'fecha_creacion': '2026-09-17T05:00:00Z',
      'publicacion_multimedia': [
        {'url_archivo': 'https://cdn.haku/historica.jpg', 'orden': 1},
      ],
    });

    expect(publicacion.imagenUrl, 'https://cdn.haku/historica.jpg');
    expect(publicacion.videoUrl, isNull);
  });
}
