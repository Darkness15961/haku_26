import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/recursos/copy_haku.dart';
import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../../nucleo/widgets/avatar_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../comunidad/pantallas/pantalla_comentarios_publicacion_remota.dart';
import '../../comunidad/proveedores/proveedor_publicaciones.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../comunidad/dominio/modelo_publicacion.dart';

/// Publicaciones de experiencia en un lugar o ruta (solo remoto).
class ListaExperienciasLugar extends ConsumerWidget {
  const ListaExperienciasLugar({super.key, this.lugarId, this.rutaId})
    : assert(lugarId != null || rutaId != null, 'Indica lugarId o rutaId');

  final String? lugarId;
  final String? rutaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!supabaseListo) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Conecta el servicio para ver experiencias.',
          style: TipografiaHaku.interfaz(
            fontSize: 13,
            height: 1.4,
            color: PaletaRutas.plomoClaro,
          ),
        ),
      );
    }

    final rid = rutaId?.trim() ?? '';
    final lid = lugarId?.trim() ?? '';
    final async = rid.isNotEmpty
        ? ref.watch(publicacionesPorRutaProvider(rid))
        : ref.watch(publicacionesPorLugarProvider(lid));
    if (async.isLoading && !async.hasValue) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: PaletaRutas.oro,
          ),
        ),
      );
    }
    if (async.hasError && !async.hasValue) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No se pudieron cargar las experiencias.',
          style: TipografiaHaku.interfaz(
            fontSize: 13,
            color: PaletaRutas.oroSuave,
          ),
        ),
      );
    }
    final remotas = async.valueOrNull ?? const [];
    if (remotas.isEmpty) {
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
        for (final p in remotas)
          TarjetaExperienciaLugarRemota(
            publicacion: p,
            onTap: () async {
              final ok = await asegurarSesion(context, ref);
              if (!ok || !context.mounted) return;
              await abrirComentariosPublicacionRemota(
                context,
                publicacion: p,
              );
            },
          ),
      ],
    );
  }
}

class TarjetaExperienciaLugarRemota extends StatelessWidget {
  const TarjetaExperienciaLugarRemota({
    super.key,
    required this.publicacion,
    required this.onTap,
  });

  final ModeloPublicacionRemota publicacion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Determine if it's group
    final esGrupo = publicacion.salidaId != null && publicacion.salidaId!.isNotEmpty;
    final grupo = publicacion.salidaNombre?.trim() ?? '';
    final imagen = publicacion.imagenUrl?.trim();
    
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
                if (imagen != null && imagen.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ImagenHaku(
                      url: imagen,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (imagen != null && imagen.isNotEmpty) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AvatarHaku(url: publicacion.autorFotoPerfil, size: 28),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              publicacion.etiquetaAutor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TipografiaHaku.interfaz(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: PaletaRutas.piedra,
                              ),
                            ),
                          ),
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
                              publicacion.contenido.isEmpty ? 'Publicación visual' : publicacion.contenido,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TipografiaHaku.interfaz(
                                fontSize: 13,
                                height: 1.35,
                                color: publicacion.contenido.isEmpty ? PaletaRutas.plomo : PaletaRutas.plomoClaro,
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
                            '${publicacion.cantidadMeGusta}',
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
