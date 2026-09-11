import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../nucleo/supabase/cliente_supabase.dart';
import '../inicio/proveedores/proveedor_almacen_feed.dart';
import 'dominio/servicios/servicio_auth_supabase.dart';
import 'proveedores/proveedor_sesion.dart';

/// Flujo Google compartido (login / registro).
/// Sin pantalla extra: el trigger rellena nick/PE/foto; editar después en Configuración.
/// Google nativo vía [ServicioAuthSupabase.iniciarConGoogle] (SDK). Ver docs Etapa 3.
Future<bool> completarLoginConGoogle(
  BuildContext context,
  WidgetRef ref, {
  required void Function(String) avisar,
}) async {
  if (!supabaseListo) {
    avisar(
      'No hay conexión con Auth. Revisa la configuración / reinicia la app.',
    );
    return false;
  }

  try {
    final resultado = await ServicioAuthSupabase().iniciarConGoogle();
    await ref
        .read(sesionProvider.notifier)
        .sincronizarDesdeAuth(resultado.usuario);
    await ref.read(almacenFeedProvider.notifier).cargar();
    return true;
  } on AuthException catch (e) {
    // Cancelar el sheet de Google ≠ error.
    if (e.message == ServicioAuthSupabase.mensajeGoogleCancelado) {
      return false;
    }
    avisar(e.message);
    return false;
  } catch (e) {
    avisar('No se pudo entrar con Google. Intenta de nuevo.');
    debugPrint('Google nativo: $e');
    return false;
  }
}
