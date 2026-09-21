import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/widgets/imagen_haku.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import 'metricas_comunidad.dart';

/// Carrusel de fotos extraídas de publicaciones (lugar o ruta).
class RecuerdosComunidad extends ConsumerWidget {
  const RecuerdosComunidad({
    super.key,
    this.lugarId,
    this.rutaId,
  }) : assert(
          lugarId != null || rutaId != null,
          'Indica lugarId o rutaId',
        );

  final String? lugarId;
  final String? rutaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricas = MetricasComunidad.calcular(
      ref.watch(almacenFeedProvider).publicaciones,
      lugarId: lugarId,
      rutaId: rutaId,
    );
    if (metricas.fotosUrls.isEmpty) return const SizedBox.shrink();

    final subtitulo = rutaId != null
        ? 'Fotos que dejó la comunidad en esta ruta'
        : 'Fotos que dejó la comunidad en este lugar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 22),
        Text(
          'Recuerdos',
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitulo,
          style: TipografiaHaku.interfaz(
            fontSize: 12,
            color: PaletaRutas.plomoClaro,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: metricas.fotosUrls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ImagenHaku(
                  url: metricas.fotosUrls[i],
                  width: 120,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
