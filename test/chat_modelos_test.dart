import 'package:flutter_test/flutter_test.dart';
import 'package:haku/funcionalidades/chat/dominio/modelo_mensaje_chat.dart';

void main() {
  group('PerfilChatBasico', () {
    test('normaliza nombre completo y arroba', () {
      final perfil = PerfilChatBasico.desdeFila({
        'otro_usuario_id': 'u-2',
        'nombres': 'Ana',
        'apellidos': 'Quispe',
        'nombre_nick': 'anaq',
        'foto_perfil': 'https://example.com/a.jpg',
      });

      expect(perfil.id, 'u-2');
      expect(perfil.nombreCompleto, 'Ana Quispe');
      expect(perfil.etiquetaNick, '@anaq');
    });

    test('no duplica arroba y usa nick si no hay nombre', () {
      final perfil = PerfilChatBasico.desdeFila({
        'id': 'u-3',
        'nombre_nick': '@explorador',
      });

      expect(perfil.nombreCompleto, '@explorador');
      expect(perfil.etiquetaNick, '@explorador');
    });
  });

  group('PreviewChatSala', () {
    test('privado existente siempre puede abrirse', () {
      const preview = PreviewChatSala(
        salaId: '42',
        titulo: 'Ana Quispe',
        usuarioId: 'u-2',
        tipo: 'privado',
      );

      expect(preview.esPrivado, isTrue);
      expect(preview.puedeAbrir, isTrue);
      expect(preview.etiquetaTipo, 'Privado');
      expect(preview.previewVacioEtiqueta, 'Sin mensajes aún');
    });
  });

  group('ModeloMensajeChat', () {
    test('fusion realtime conserva reacciones si payload no las trae', () {
      final fecha = DateTime.utc(2026, 9, 15);
      final previo = ModeloMensajeChat(
        id: '1',
        salaId: '42',
        usuarioId: 'u-2',
        autorNick: 'ana',
        contenido: 'Hola',
        fechaEnvio: fecha,
        reacciones: const [
          ReaccionMensajeAgregada(emoji: '❤️', cantidad: 2, mia: true),
        ],
      );
      final realtime = ModeloMensajeChat(
        id: '1',
        salaId: '42',
        usuarioId: 'u-2',
        contenido: 'Hola editado',
        fechaEnvio: fecha,
        editadoEn: fecha.add(const Duration(minutes: 1)),
      );

      final fusionado = ModeloMensajeChat.fusionarConPrevio(
        previo,
        realtime,
        entranteTraeReacciones: false,
      );

      expect(fusionado.autorNick, 'ana');
      expect(fusionado.contenido, 'Hola editado');
      expect(fusionado.reacciones.single.cantidad, 2);
    });

    test('contenido visible distingue adjuntos y eliminados', () {
      final fecha = DateTime.utc(2026, 9, 15);
      final imagen = ModeloMensajeChat(
        id: '1',
        salaId: '42',
        usuarioId: 'u-1',
        contenido: 'https://example.com/foto.jpg',
        tipoMensaje: 'imagen',
        fechaEnvio: fecha,
      );
      final eliminado = ModeloMensajeChat(
        id: '2',
        salaId: '42',
        usuarioId: 'u-1',
        contenido: '[eliminado]',
        fechaEnvio: fecha,
        eliminadoEn: fecha,
      );

      expect(imagen.contenidoVisible, '📷 Imagen');
      expect(eliminado.contenidoVisible, 'Mensaje eliminado');
    });

    test('imagen firmada espera al live resuelto antes de soltar overlay', () {
      final fecha = DateTime.utc(2026, 9, 15);
      final local = ModeloMensajeChat(
        id: '8',
        salaId: '42',
        usuarioId: 'u-1',
        contenido: 'https://signed.example/foto.jpg?token=1',
        tipoMensaje: 'imagen',
        fechaEnvio: fecha,
      );
      final rutaCruda = ModeloMensajeChat(
        id: '8',
        salaId: '42',
        usuarioId: 'u-1',
        contenido: 'chat://u-1/42/foto.jpg',
        tipoMensaje: 'imagen',
        fechaEnvio: fecha,
      );
      final firmadaRemota = rutaCruda.copyWith(
        contenido: 'https://signed.example/foto.jpg?token=2',
      );

      expect(local.cubiertoPor(rutaCruda), isFalse);
      expect(local.cubiertoPor(firmadaRemota), isTrue);
    });
  });
}
