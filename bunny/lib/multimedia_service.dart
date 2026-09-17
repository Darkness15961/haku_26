import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class MultimediaService {
  final supabase = Supabase.instance.client;
  final String nombreBucket = 'haku-storage-produccion-2026';

  Future<String?> subirFotoDePrueba(int idDePublicacion) async {
    try {
      // 1. Interfaz de Hardware: Abrir galería
      final ImagePicker picker = ImagePicker();
      final XFile? imagenSeleccionada = await picker.pickImage(source: ImageSource.gallery);
      
      if (imagenSeleccionada == null) {
        print('Abortado: El usuario no seleccionó ninguna imagen.');
        return null; 
      }

      final File archivoFisico = File(imagenSeleccionada.path);
      final String extension = imagenSeleccionada.path.split('.').last.toLowerCase();
      
      // 2. FAIL FAST (Formato): Firewall del cliente
      if (extension != 'jpg' && extension != 'jpeg' && extension != 'png' && extension != 'webp') {
         print('Error Arquitectónico: El formato .$extension será rechazado por el Bucket S3.');
         return null;
      }

      // 3. FAIL FAST (Peso): Verificar límite de 10MB (10 * 1024 * 1024 bytes) antes de gastar red
      final int tamanoBytes = await archivoFisico.length();
      if (tamanoBytes > 10485760) {
         print('Error: La imagen pesa ${tamanoBytes / 1024 / 1024}MB. El límite estricto es 10MB.');
         return null;
      }

      // 4. Sanitización: Generar nombre único para S3
      final String nombreUnico = 'prueba_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final String rutaEnBucket = 'sandbox/$nombreUnico'; 

      // 5. INFRAESTRUCTURA: Disparar archivo por el túnel hacia VPS -> AWS S3
      print('Iniciando transferencia binaria hacia AWS S3...');
      await supabase.storage
          .from(nombreBucket)
          .upload(rutaEnBucket, archivoFisico);

      // 6. RESOLUCIÓN: Extraer el enlace público
      final String urlPublica = supabase.storage
          .from(nombreBucket)
          .getPublicUrl(rutaEnBucket);
      
      print('Recibo generado por S3: $urlPublica');

      // 7. CONEXIÓN A (PostgreSQL): Registro en el inventario relacional
      print('Insertando metadatos en PostgreSQL...');
      await supabase.from('multimedia').insert({
        'publicacion_id': idDePublicacion,
        'url_archivo': urlPublica,
        'tipo': 'imagen',
        // NOTA SENIOR: 'fecha_registro' ha sido omitido. 
        // Confiamos en el DEFAULT now() del servidor para evitar hackeos de tiempo.
      });

      print('¡ÉXITO TOTAL! Túnel A-B-C verificado correctamente.');
      return urlPublica;

    } on StorageException catch (e) {
      print('FALLA S3/VPS: ${e.message}');
      return null;
    } on PostgrestException catch (e) {
      print('FALLA POSTGRESQL: ${e.message} (Verifica que el ID de publicación exista y tus RLS).');
      return null;
    } catch (e) {
      print('FALLA CRÍTICA INESPERADA: $e');
      return null;
    }
  }

  /// Método auxiliar para extraer la ruta interna del bucket a partir de la URL pública
  String obtenerRutaDesdeUrl(String url) {
    final String separator = '$nombreBucket/';
    final int index = url.indexOf(separator);
    if (index != -1) {
      return url.substring(index + separator.length);
    }
    throw Exception('URL de archivo no válido para este bucket');
  }

  /// Elimina un archivo de S3 y su registro correspondiente en la tabla multimedia de PostgreSQL
  Future<bool> eliminarFoto(String urlPublica) async {
    try {
      final String rutaEnBucket = obtenerRutaDesdeUrl(urlPublica);
      
      print('Eliminando archivo de AWS S3...');
      await supabase.storage.from(nombreBucket).remove([rutaEnBucket]);
      
      print('Eliminando metadatos de PostgreSQL...');
      await supabase.from('multimedia').delete().eq('url_archivo', urlPublica);
      
      print('¡Eliminación exitosa en S3 y base de datos!');
      return true;
    } on StorageException catch (e) {
      print('FALLA S3 al eliminar: ${e.message}');
      return false;
    } on PostgrestException catch (e) {
      print('FALLA PostgreSQL al eliminar: ${e.message}');
      return false;
    } catch (e) {
      print('FALLA inesperada al eliminar: $e');
      return false;
    }
  }

  /// Reemplaza una imagen existente en S3 y actualiza el registro en la base de datos
  Future<String?> actualizarFoto(String urlPublicaVieja, int idDePublicacion) async {
    try {
      // 1. Seleccionar la nueva imagen
      final ImagePicker picker = ImagePicker();
      final XFile? imagenSeleccionada = await picker.pickImage(source: ImageSource.gallery);
      
      if (imagenSeleccionada == null) {
        print('Abortado: No se seleccionó la nueva imagen.');
        return null;
      }

      final File archivoFisico = File(imagenSeleccionada.path);
      final String extension = imagenSeleccionada.path.split('.').last.toLowerCase();
      
      // 2. Validar formato y tamaño
      if (extension != 'jpg' && extension != 'jpeg' && extension != 'png' && extension != 'webp') {
         print('Error: Formato .$extension no soportado.');
         return null;
      }
      final int tamanoBytes = await archivoFisico.length();
      if (tamanoBytes > 10485760) {
         print('Error: El peso excede 10MB.');
         return null;
      }

      // 3. Subir la nueva imagen a S3
      final String nombreUnico = 'prueba_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final String rutaEnBucketNueva = 'sandbox/$nombreUnico';
      
      print('Subiendo nueva imagen a S3...');
      await supabase.storage.from(nombreBucket).upload(rutaEnBucketNueva, archivoFisico);
      final String urlPublicaNueva = supabase.storage.from(nombreBucket).getPublicUrl(rutaEnBucketNueva);

      // 4. Actualizar base de datos
      print('Actualizando metadatos en PostgreSQL...');
      await supabase.from('multimedia').update({
        'url_archivo': urlPublicaNueva,
      }).eq('url_archivo', urlPublicaVieja);

      // 5. Eliminar la imagen vieja de S3
      try {
        final String rutaViejaEnBucket = obtenerRutaDesdeUrl(urlPublicaVieja);
        print('Eliminando archivo anterior de S3...');
        await supabase.storage.from(nombreBucket).remove([rutaViejaEnBucket]);
      } catch (e) {
        print('Advertencia: No se pudo eliminar la imagen vieja de S3, pero la nueva fue registrada: $e');
      }

      print('¡Actualización completada con éxito!');
      return urlPublicaNueva;

    } on StorageException catch (e) {
      print('FALLA S3 al actualizar: ${e.message}');
      return null;
    } on PostgrestException catch (e) {
      print('FALLA PostgreSQL al actualizar: ${e.message}');
      return null;
    } catch (e) {
      print('FALLA inesperada al actualizar: $e');
      return null;
    }
  }
}