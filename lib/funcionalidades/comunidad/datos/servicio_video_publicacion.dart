import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';

class ErrorVideoPublicacion implements Exception {
  const ErrorVideoPublicacion(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

class TicketVideoPublicacion {
  const TicketVideoPublicacion({
    required this.libraryId,
    required this.guid,
    required this.signature,
    required this.expiration,
  });

  final String libraryId;
  final String guid;
  final String signature;
  final int expiration;

  factory TicketVideoPublicacion.desdeJson(Map<String, dynamic> json) {
    final libraryId = '${json['library_id'] ?? ''}'.trim();
    final guid = '${json['guid'] ?? ''}'.trim();
    final signature = '${json['signature'] ?? ''}'.trim();
    final expiration = json['expiration'] is int
        ? json['expiration'] as int
        : int.tryParse('${json['expiration']}');
    if (libraryId.isEmpty ||
        guid.isEmpty ||
        signature.isEmpty ||
        expiration == null) {
      throw const ErrorVideoPublicacion(
        'El servidor devolvió un ticket de video incompleto.',
      );
    }
    return TicketVideoPublicacion(
      libraryId: libraryId,
      guid: guid,
      signature: signature,
      expiration: expiration,
    );
  }
}

class EstadoVideoPublicacion {
  const EstadoVideoPublicacion({
    required this.estado,
    this.urlVideo,
    this.miniaturaUrl,
  });

  final String estado;
  final String? urlVideo;
  final String? miniaturaUrl;

  bool get listo => estado == 'ready';

  factory EstadoVideoPublicacion.desdeJson(Map<String, dynamic> json) {
    String? textoOpcional(String llave) {
      final value = '${json[llave] ?? ''}'.trim();
      return value.isEmpty ? null : value;
    }

    return EstadoVideoPublicacion(
      estado: '${json['estado'] ?? 'processing'}'.trim(),
      urlVideo: textoOpcional('url_video'),
      miniaturaUrl: textoOpcional('miniatura_url'),
    );
  }
}

/// Orquesta el ticket privado y la subida TUS directa a Bunny Stream.
///
/// La API key de Bunny nunca sale de la Edge Function. El cliente recibe una
/// firma temporal limitada al GUID que el servidor creó para su publicación.
class ServicioVideoPublicacion {
  static const int maxBytes = 500 * 1024 * 1024;
  static const int _chunkBytes = 2 * 1024 * 1024;
  static const String _funcion = 'bunny-ticket';

  Future<int> validarArchivo(XFile archivo) async {
    final length = await archivo.length();
    if (length <= 0) {
      throw const ErrorVideoPublicacion('El video seleccionado está vacío.');
    }
    if (length > maxBytes) {
      throw const ErrorVideoPublicacion('El video supera el límite de 500 MB.');
    }
    return length;
  }

  Future<TicketVideoPublicacion> preparar(int publicacionId) async {
    final data = await _invocar({
      'accion': 'crear',
      'publicacion_id': publicacionId,
    });
    return TicketVideoPublicacion.desdeJson(data);
  }

  Future<void> subir({
    required XFile archivo,
    required TicketVideoPublicacion ticket,
    void Function(double progreso)? alProgresar,
  }) async {
    final fileLength = await validarArchivo(archivo);
    final authHeaders = <String, String>{
      'AuthorizationSignature': ticket.signature,
      'AuthorizationExpire': '${ticket.expiration}',
      'VideoId': ticket.guid,
      'LibraryId': ticket.libraryId,
    };

    final createResponse = await http.post(
      Uri.parse('https://video.bunnycdn.com/tusupload'),
      headers: {
        ...authHeaders,
        'Tus-Resumable': '1.0.0',
        'Upload-Length': '$fileLength',
        'Content-Type': 'application/offset+octet-stream',
      },
    );
    if (createResponse.statusCode != 201) {
      throw const ErrorVideoPublicacion(
        'Bunny Stream no pudo iniciar la subida.',
      );
    }

    final location = createResponse.headers['location']?.trim() ?? '';
    if (location.isEmpty) {
      throw const ErrorVideoPublicacion(
        'Bunny Stream no devolvió una dirección de subida.',
      );
    }
    final uploadUri = location.startsWith('http')
        ? Uri.parse(location)
        : Uri.parse('https://video.bunnycdn.com').resolve(location);

    final client = http.Client();
    try {
      var offset = 0;
      while (offset < fileLength) {
        final proposedEnd = offset + _chunkBytes;
        final end = proposedEnd < fileLength ? proposedEnd : fileLength;
        final builder = BytesBuilder(copy: false);
        await for (final bytes in archivo.openRead(offset, end)) {
          builder.add(bytes);
        }
        final chunk = builder.takeBytes();
        if (chunk.isEmpty) {
          throw const ErrorVideoPublicacion(
            'No se pudo leer una parte del video.',
          );
        }

        int? siguiente;
        Object? ultimoError;
        for (var intento = 0; intento < 4 && siguiente == null; intento++) {
          if (intento > 0) {
            await Future<void>.delayed(Duration(seconds: intento * 2));
            final remoto = await _consultarOffset(
              client,
              uploadUri,
              authHeaders,
            );
            if (remoto != null && remoto > offset) {
              siguiente = remoto;
              break;
            }
          }
          try {
            siguiente = await _enviarChunk(
              client: client,
              uploadUri: uploadUri,
              authHeaders: authHeaders,
              offset: offset,
              chunk: chunk,
            );
          } catch (error) {
            ultimoError = error;
          }
        }
        if (siguiente == null) {
          if (ultimoError is ErrorVideoPublicacion) throw ultimoError;
          throw const ErrorVideoPublicacion(
            'La conexión se interrumpió durante la subida.',
          );
        }
        if (siguiente <= offset || siguiente > fileLength) {
          throw const ErrorVideoPublicacion(
            'Bunny Stream devolvió un progreso inválido.',
          );
        }
        offset = siguiente;
        alProgresar?.call(offset / fileLength);
      }
    } finally {
      client.close();
    }
  }

  Future<int> _enviarChunk({
    required http.Client client,
    required Uri uploadUri,
    required Map<String, String> authHeaders,
    required int offset,
    required Uint8List chunk,
  }) async {
    final request = http.Request('PATCH', uploadUri)
      ..headers.addAll({
        ...authHeaders,
        'Tus-Resumable': '1.0.0',
        'Upload-Offset': '$offset',
        'Content-Type': 'application/offset+octet-stream',
      })
      ..bodyBytes = chunk;
    final response = await client.send(request);
    await response.stream.drain<void>();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ErrorVideoPublicacion(
        'La subida se interrumpió (HTTP ${response.statusCode}).',
      );
    }
    return int.tryParse(response.headers['upload-offset'] ?? '') ??
        offset + chunk.length;
  }

  Future<int?> _consultarOffset(
    http.Client client,
    Uri uploadUri,
    Map<String, String> authHeaders,
  ) async {
    try {
      final request = http.Request('HEAD', uploadUri)
        ..headers.addAll({...authHeaders, 'Tus-Resumable': '1.0.0'});
      final response = await client.send(request);
      await response.stream.drain<void>();
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      return int.tryParse(response.headers['upload-offset'] ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<EstadoVideoPublicacion> consultarEstado(int publicacionId) async {
    final data = await _invocar({
      'accion': 'estado',
      'publicacion_id': publicacionId,
    });
    return EstadoVideoPublicacion.desdeJson(data);
  }

  Future<void> cancelar(int publicacionId) async {
    await _invocar({'accion': 'cancelar', 'publicacion_id': publicacionId});
  }

  Future<Map<String, dynamic>> _invocar(Map<String, dynamic> body) async {
    if (!supabaseListo || clienteSupabase.auth.currentUser == null) {
      throw const ErrorVideoPublicacion(
        'Debes iniciar sesión para subir videos.',
      );
    }
    try {
      final response = await clienteSupabase.functions.invoke(
        _funcion,
        body: body,
      );
      final raw = response.data;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
      throw const ErrorVideoPublicacion(
        'La respuesta del servidor de video no es válida.',
      );
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map) {
        final message = '${details['error'] ?? ''}'.trim();
        if (message.isNotEmpty) throw ErrorVideoPublicacion(message);
      }
      throw const ErrorVideoPublicacion(
        'No se pudo conectar con el servicio de video.',
      );
    } on ErrorVideoPublicacion {
      rethrow;
    } catch (_) {
      throw const ErrorVideoPublicacion(
        'No se pudo conectar con el servicio de video.',
      );
    }
  }
}
