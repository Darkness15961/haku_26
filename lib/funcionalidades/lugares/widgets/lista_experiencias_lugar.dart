import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/recursos/copy_haku.dart';
import '../../../nucleo/widgets/avatar_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../comunidad/datos/salidas_datasource_local.dart';
import '../../inicio/datos/feed_inicio_datasource_local.dart';
import '../../inicio/pantallas/pantalla_comentarios_publicacion.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import 'metricas_comunidad.dart';

/// Publicaciones de experiencia en un lugar o ruta.
class ListaExperienciasLugar extends ConsumerWidget {
  const ListaExperienciasLugar({
    super.key,
    this.lugarId,
    this.rutaId,
  }) : assert(
          lugarId != null || rutaId != null,
          'Indica lugarId o rutaId',
        );

  final String? lugarId;
  final String? rutaId;

  String _etiquetaGrupo(PublicacionFeed p) {
    final g = p.grupoNombre?.trim();
    if (g != null && g.isNotEmpty) return g;
    final sid = p.salidaId;
    if (sid == null || sid.isEmpty) return '';
    return SalidasDataSourceLocal.instancia.porId(sid)?.grupo ?? '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experiencias = MetricasComunidad.experienciasDe(
      ref.watch(almacenFeedProvider).publicaciones,
      lugarId: lugarId,
      rutaId: rutaId,
    );

    if (experiencias.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          CopyHaku.experienciasVacias,
          style: TipografiaHaku.interfaz(
            fontSize: 13,
            height: 1.4,
            color: PaletaRutas.plomoClaro,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in experiencias)
          _TarjetaExperienciaLugar(
            publicacion: p,
            grupo: _etiquetaGrupo(p),
            onTap: () async {
              final ok = await asegurarSesion(context, ref);
              if (!ok || !context.mounted) return;
              await abrirComentariosPublicacion(context, p);
            },
          ),
      ],
    );
  }
}

class _TarjetaExperienciaLugar extends StatelessWidget {
  const _TarjetaExperienciaLugar({
    required this.publicacion,
    required this.grupo,
    required this.onTap,
  });

  final PublicacionFeed publicacion;
  final String grupo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esGrupo = grupo.isNotEmpty || publicacion.esVisitaGrupal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (publicacion.imagenUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ImagenHaku(
                      url: publicacion.imagenUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (publicacion.imagenUrl != null) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AvatarHaku(
                            url: publicacion.avatarUrl,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              publicacion.autor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TipografiaHaku.interfaz(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: PaletaRutas.piedra,
                              ),
                            ),
                          ),
                          if (publicacion.calificacion != null &&
                              publicacion.calificacion! > 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: PaletaRutas.oro,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              publicacion.calificacion!.toStringAsFixed(1),
                              style: TipografiaHaku.interfaz(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: PaletaRutas.oroSuave,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Tooltip(
                            message: esGrupo
                                ? (grupo.isNotEmpty
                                    ? 'Visita en grupo · $grupo'
                                    : 'Visita en grupo')
                                : 'Visita solo/a',
                            child: Icon(
                              esGrupo
                                  ? Icons.groups_rounded
                                  : Icons.person_outline_rounded,
                              size: 16,
                              color: esGrupo
                                  ? PaletaRutas.oro
                                  : PaletaRutas.plomoClaro,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              publicacion.texto,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TipografiaHaku.interfaz(
                                fontSize: 13,
                                height: 1.35,
                                color: PaletaRutas.plomoClaro,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 12,
                            color: PaletaRutas.plomo,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            publicacion.hace,
                            style: TipografiaHaku.interfaz(
                              fontSize: 11,
                              color: PaletaRutas.plomo,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.favorite_border_rounded,
                            size: 13,
                            color: PaletaRutas.plomo,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${publicacion.likes}',
                            style: TipografiaHaku.interfaz(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.plomoClaro,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 13,
                            color: PaletaRutas.plomo,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${publicacion.comentarios}',
                            style: TipografiaHaku.interfaz(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.plomoClaro,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
