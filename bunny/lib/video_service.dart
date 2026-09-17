import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cross_file/cross_file.dart';

class VideoService {
  // TODO: Reemplaza esto con la IP real de tu VPS
  final String _vpsUrl = 'https://supabase.haku.best/functions/v1/bunny-ticket';

  /// Fase 7.1: Solicita un ticket (guid + signature) al VPS para autorizar la subida
  Future<Map<String, dynamic>?> solicitarTicketVideo(int publicacionId) async {
    try {
      print('🚀 Iniciando solicitud de ticket al VPS...');

      // 1. Obtener la sesión actual del turista
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception('Error: El usuario no está logueado.');
      }

      final jwtToken = session.accessToken;

      // 2. Preparar el paquete HTTP
      final response = await http.post(
        Uri.parse(_vpsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken', // El escudo de seguridad
        },
        body: jsonEncode({
          'publicacion_id': publicacionId, // El fail-fast de tu backend
        }),
      );

      // 3. Evaluar la respuesta del servidor
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ ¡Ticket recibido con éxito!');
        print('GUID del Video: ${data['guid']}');
        print('Firma SHA-256: ${data['signature']}');
        
        // 👉 LÍNEA AGREGADA PARA AUDITAR EL JSON COMPLETO (Diagnóstico)
        print('📦 PAQUETE COMPLETO: $data');
        
        return data; // Devolvemos el ticket completo para el Paso 7.2
      } else {
        print('❌ Error del servidor VPS: ${response.statusCode}');
        print('Detalle: ${response.body}');
        return null;
      }
    } catch (e) {
      print('⚠️ Error de conexión o código: $e');
      return null;
    }
  }

  /// Fase 7.2: Sube el video a Bunny Stream usando TUS manual (HTTP crudo).
  /// Implementación directa sin la librería tus_client_dart.
  Future<bool> subirVideoConTus(XFile videoFile, Map<String, dynamic> ticket) async {
    const int chunkSize = 2 * 1024 * 1024; // 2 MB por fragmento

    try {
      print('📦 Configurando motor TUS para el archivo: ${videoFile.name}');

      // Headers de autenticación para Bunny Stream
      final Map<String, String> authHeaders = {
        'AuthorizationSignature': ticket['signature'].toString(),
        'AuthorizationExpire': ticket['expiration'].toString(),
        'VideoId': ticket['guid'].toString(),
        'LibraryId': ticket['library_id'].toString(),
      };

      // Obtener el tamaño real del archivo
      final file = File(videoFile.path);
      final fileLength = await file.length();
      print('📏 Tamaño del archivo: ${(fileLength / 1024 / 1024).toStringAsFixed(2)} MB');

      // ============================================================
      // PASO 1: Crear el upload en Bunny Stream (POST)
      // ============================================================
      print('🚀 Paso 1: Creando upload en Bunny Stream...');

      final createResponse = await http.post(
        Uri.parse('https://video.bunnycdn.com/tusupload'),
        headers: {
          ...authHeaders,
          'Tus-Resumable': '1.0.0',
          'Upload-Length': fileLength.toString(),
          'Content-Type': 'application/offset+octet-stream',
        },
      );

      if (createResponse.statusCode != 201) {
        print('❌ Bunny rechazó la creación: ${createResponse.statusCode}');
        print('❌ Detalle: ${createResponse.body}');
        return false;
      }

      // Extraer la URL de subida del header Location
      final locationHeader = createResponse.headers['location'];
      if (locationHeader == null || locationHeader.isEmpty) {
        print('❌ Bunny no devolvió header Location');
        return false;
      }

      // Construir la URL completa (Location viene como ruta relativa)
      final uploadUrl = locationHeader.startsWith('http')
          ? Uri.parse(locationHeader)
          : Uri.parse('https://video.bunnycdn.com$locationHeader');

      print('✅ Upload creado exitosamente');

      // ============================================================
      // PASO 2: Subir el archivo en fragmentos (PATCH)
      // ============================================================
      print('🚀 Paso 2: Subiendo fragmentos...');

      int offset = 0;
      final raf = await file.open(mode: FileMode.read);
      final client = http.Client();

      try {
        while (offset < fileLength) {
          final currentChunkSize = min(chunkSize, fileLength - offset);

          // Leer el fragmento del archivo
          await raf.setPosition(offset);
          final chunkBytes = await raf.read(currentChunkSize);

          // Construir y enviar el PATCH con los bytes
          final patchRequest = http.Request('PATCH', uploadUrl)
            ..headers.addAll({
              ...authHeaders,
              'Tus-Resumable': '1.0.0',
              'Upload-Offset': offset.toString(),
              'Content-Type': 'application/offset+octet-stream',
            })
            ..bodyBytes = chunkBytes;

          final patchResponse = await client.send(patchRequest);

          // Consumir el body de la respuesta para liberar recursos
          await patchResponse.stream.drain<void>();

          if (patchResponse.statusCode < 200 || patchResponse.statusCode >= 300) {
            print('❌ Error en fragmento offset=$offset: HTTP ${patchResponse.statusCode}');
            return false;
          }

          // Leer el nuevo offset del servidor
          final serverOffset = patchResponse.headers['upload-offset'];
          if (serverOffset != null) {
            offset = int.parse(serverOffset);
          } else {
            offset += currentChunkSize;
          }

          // Mostrar progreso
          final progress = (offset / fileLength * 100).clamp(0.0, 100.0);
          print('📤 ${progress.toStringAsFixed(1)}% completado');
        }
      } finally {
        await raf.close();
        client.close();
      }

      // ============================================================
      // PASO 3: Confirmación
      // ============================================================
      print('✅ ¡Transmisión TUS completada al 100%!');
      print('🎉 El video está procesándose en Bunny Stream');
      return true;

    } catch (e) {
      print('❌ Error en la transmisión TUS: $e');
      return false;
    }
  }

  /// Fase 7.4: Confirma que el video terminó de subirse y actualiza su estado en Supabase.
  /// Solo cambia video_estado a 'ready' porque el GUID ya fue insertado por la Edge Function.
  Future<bool> confirmarVideoListo(String videoGuid) async {
    try {
      print('🔄 Fase 7.4: Sincronizando estado en la tabla multimedia...');

      await Supabase.instance.client
          .from('multimedia')
          .update({
            'video_estado': 'ready',
          })
          .eq('proveedor_video_id', videoGuid);

      print('✅ Handoff exitoso: El video $videoGuid está listo para el Feed');
      return true;

    } on PostgrestException catch (e) {
      print('❌ Error de PostgreSQL (Posible bloqueo RLS): ${e.message}');
      print('Detalles: ${e.details}');
      return false;
    } catch (e) {
      print('⚠️ Error inesperado en el Handoff: $e');
      return false;
    }
  }
}