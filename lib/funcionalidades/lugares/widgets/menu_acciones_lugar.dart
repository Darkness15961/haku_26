import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../comunidad/datos/salidas_datasource_local.dart';
import '../../comunidad/pantallas/pantalla_salidas.dart';
import '../../publicaciones/pantallas/pantalla_publicaciones.dart';
import '../../rutas/widgets/boton_icono_accion.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelos/modelo_lugar.dart';

/// Menú flotante inferior derecho — solo iconos, etiquetas en tooltip.
class MenuAccionesLugar extends ConsumerWidget {
  const MenuAccionesLugar({
    super.key,
    required this.lugar,
    required this.abierto,
    required this.onToggle,
    required this.onCerrar,
  });

  final ModeloLugar lugar;
  final bool abierto;
  final VoidCallback onToggle;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nSalidas =
        SalidasDataSourceLocal.instancia.todas(lugarId: lugar.id).length;

    Future<void> publicar() async {
      onCerrar();
      final ok = await asegurarSesion(context, ref);
      if (!ok || !context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PantallaPublicaciones(
            rutaId: lugar.id,
            rutaTitulo: lugar.nombre,
          ),
        ),
      );
    }

    void salidas() {
      onCerrar();
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PantallaSalidas(lugarId: lugar.id),
        ),
      );
    }

    Future<void> compartir() async {
      onCerrar();
      final texto =
          'Descubre ${lugar.nombre} en HAKU — ${lugar.categoria.etiqueta}, ${lugar.provincia}';
      await Clipboard.setData(ClipboardData(text: texto));
      if (!context.mounted) return;
      mostrarSnackHaku(context, 'Enlace del lugar copiado', destacado: true);
    }

    return MenuAccionesFlotante(
      abierto: abierto,
      onToggle: onToggle,
      opciones: [
        BotonIconoAccion(
          tooltip: 'Compartir lugar',
          icono: Icons.ios_share_rounded,
          onTap: compartir,
        ),
        BotonIconoAccion(
          tooltip: nSalidas == 0
              ? 'Ver salidas'
              : 'Ver salidas ($nSalidas)',
          icono: Icons.groups_rounded,
          destacado: nSalidas > 0,
          badge: nSalidas > 0 ? '$nSalidas' : null,
          onTap: salidas,
        ),
        BotonIconoAccion(
          tooltip: 'Publicar experiencia',
          icono: Icons.add_a_photo_outlined,
          onTap: publicar,
        ),
      ],
    );
  }
}
