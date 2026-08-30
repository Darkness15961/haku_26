import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../publicaciones/pantallas/pantalla_publicaciones.dart';
import '../dominio/modelos/modelo_ruta.dart';
import '../pantallas/pantalla_mapa_ruta.dart';
import 'boton_icono_accion.dart';
import 'estilos_rutas.dart';

/// Menú + inferior derecho en detalle de ruta (Publicar, Mapa, Compartir).
class MenuAccionesRuta extends ConsumerWidget {
  const MenuAccionesRuta({
    super.key,
    required this.ruta,
    required this.abierto,
    required this.onToggle,
    required this.onCerrar,
  });

  final ModeloRuta ruta;
  final bool abierto;
  final VoidCallback onToggle;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tieneMapa = ruta.puntos.isNotEmpty;

    Future<void> publicar() async {
      onCerrar();
      final ok = await asegurarSesion(context, ref);
      if (!ok || !context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PantallaPublicaciones(
            rutaId: ruta.id,
            rutaTitulo: ruta.titulo,
          ),
        ),
      );
    }

    void mapa() {
      onCerrar();
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PantallaMapaRuta(ruta: ruta),
        ),
      );
    }

    Future<void> compartir() async {
      onCerrar();
      final texto =
          '${ruta.titulo} en HAKU — ${ruta.distancia.isNotEmpty ? ruta.distancia : ruta.dias} día${ruta.dias == 1 ? '' : 's'}';
      await Clipboard.setData(ClipboardData(text: texto));
      if (!context.mounted) return;
      mostrarSnackHaku(context, 'Ruta copiada', destacado: true);
    }

    return MenuAccionesFlotante(
      abierto: abierto,
      onToggle: onToggle,
      opciones: [
        BotonIconoAccion(
          tooltip: 'Compartir ruta',
          icono: Icons.ios_share_rounded,
          onTap: compartir,
        ),
        if (tieneMapa)
          BotonIconoAccion(
            tooltip: 'Ver mapa · ${ruta.puntos.length} paradas',
            icono: Icons.map_outlined,
            destacado: true,
            badge: '${ruta.puntos.length}',
            onTap: mapa,
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
