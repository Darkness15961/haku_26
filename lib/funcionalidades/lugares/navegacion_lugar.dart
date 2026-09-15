import 'package:flutter/material.dart';

import '../../../nucleo/navegacion/abrir_pantalla_haku.dart';
import '../../../nucleo/supabase/cliente_supabase.dart';
import '../rutas/widgets/estilos_rutas.dart';
import 'pantallas/pantalla_detalle_lugar.dart';

/// Puente Explora: abre ficha remota solo con ID numérico de `public.lugar`.
void abrirDetalleLugar(BuildContext context, String lugarId) {
  final id = lugarId.trim();
  if (id.isEmpty) return;
  if (supabaseListo && int.tryParse(id) == null) {
    mostrarSnackHaku(
      context,
      'Ese lugar es de la demo local; abrilo desde Explora cuando esté en el servidor.',
    );
    return;
  }
  abrirPantallaHaku<void>(
    context,
    PantallaDetalleLugar(lugarId: id),
  );
}
