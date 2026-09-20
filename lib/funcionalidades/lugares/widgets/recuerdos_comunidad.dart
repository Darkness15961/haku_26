import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../comunidad/dominio/modelo_publicacion.dart';
import '../../comunidad/proveedores/proveedor_publicaciones.dart';
import '../../inicio/datos/feed_inicio_datasource_local.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import 'metricas_comunidad.dart';

/// Carrusel de fotos extraídas de publicaciones (lugar o ruta).
class RecuerdosComunidad extends ConsumerWidget {
  const RecuerdosComunidad({super.key, this.lugarId, this.rutaId})
    : assert(lugarId != null || rutaId != null, 'Indica lugarId o rutaId');

  final String? lugarId;
  final String? rutaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> fotos;
    int totalFotos = 0;
    
    if (supabaseListo) {
      final rid = rutaId?.trim() ?? '';
      final lid = lugarId?.trim() ?? '';
      List<ModeloPublicacionRemota> remotas =
          (rid.isNotEmpty
                  ? ref.watch(publicacionesPorRutaProvider(rid))
                  : ref.watch(publicacionesPorLugarProvider(lid)))
              .valueOrNull ??
          const [];
      
      // Ordenar por popularidad (Me Gustas)
      remotas = List.of(remotas)..sort((a, b) => b.cantidadMeGusta.compareTo(a.cantidadMeGusta));
      
      final todas = MetricasComunidad.calcularRemotas(
        remotas,
        lugarId: lugarId,
        rutaId: rutaId,
      ).fotosUrls;
      
      totalFotos = todas.length;
      fotos = todas.take(3).toList();
    } else {
      List<PublicacionFeed> feed = ref.watch(almacenFeedProvider).publicaciones;
      // Ordenar por popularidad (Me Gustas)
      feed = List.of(feed)..sort((a, b) => b.likes.compareTo(a.likes));
      
      final todas = MetricasComunidad.calcular(
        feed,
        lugarId: lugarId,
        rutaId: rutaId,
      ).fotosUrls;
      
      totalFotos = todas.length;
      fotos = todas.take(3).toList();
    }
    
    if (fotos.isEmpty) return const SizedBox.shrink();

    final extras = totalFotos - 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          'Galería',
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(3, (i) {
            if (i >= fotos.length) {
              return Expanded(child: const SizedBox.shrink());
            }
            final esUltimo = i == 2 && extras > 0;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: i < 2 ? 8.0 : 0.0,
                ),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ImagenHaku(
                          url: fotos[i],
                          fit: BoxFit.cover,
                        ),
                        if (esUltimo)
                          Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            alignment: Alignment.center,
                            child: Text(
                              '+$extras',
                              style: TipografiaHaku.titulo(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
