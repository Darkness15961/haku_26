import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../rutas/widgets/boton_fondo_textil.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../dominio/modelo_comunidad.dart';
import '../widgets/chip_categoria_comunidad.dart';
import 'pantalla_salidas.dart';

class PantallaDetalleComunidad extends ConsumerWidget {
  final String comunidadId;

  const PantallaDetalleComunidad({super.key, required this.comunidadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(almacenFeedProvider);
    ComunidadHaku? comunidad;
    for (final c in store.comunidades) {
      if (c.id == comunidadId) {
        comunidad = c;
        break;
      }
    }
    if (comunidad == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white),
        body: const Center(child: Text('Comunidad no encontrada')),
      );
    }

    final c = comunidad;
    final unida = store.comunidadIds.contains(c.id);
    final miembros = [
      for (final id in c.miembroIds)
        if (store.perfilPorId(id) != null) store.perfilPorId(id)!,
    ];
    final bottom = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PaletaRutas.marronOscuro,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      c.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TipografiaHaku.titulo(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Salidas',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PantallaSalidas(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.hiking,
                      color: PaletaRutas.marronOscuro,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LineaEncabezadoInca(altura: 2),
            ),
            Expanded(
              child: FondoSuaveSeccion(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: c.imagenUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.descripcion,
                            style: TipografiaHaku.interfaz(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${c.miembros} miembros · ${c.provincia}',
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final cat in c.categorias)
                                ChipCategoriaComunidad(
                                  categoria: cat,
                                  sobreOscuro: true,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    BotonFondoTextil(
                      texto: unida ? 'Salir de la comunidad' : 'Unirme',
                      icono: unida
                          ? Icons.check_rounded
                          : Icons.group_add_outlined,
                      altura: 44,
                      radius: 12,
                      onPressed: () async {
                        final ok = await asegurarSesion(context, ref);
                        if (!ok) return;
                        await ref
                            .read(almacenFeedProvider.notifier)
                            .toggleUnirseComunidad(c.id);
                      },
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Miembros',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (miembros.isEmpty)
                      Text(
                        'Todavía no hay perfiles vinculados.',
                        style: TipografiaHaku.interfaz(
                          color: PaletaRutas.marronCuero,
                        ),
                      )
                    else
                      ...miembros.map((p) {
                        final admin = p.id == c.creadorId;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: p.avatarUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.nombre,
                                      style: TipografiaHaku.interfaz(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      admin
                                          ? '${p.usuario} · admin'
                                          : p.usuario,
                                      style: TipografiaHaku.interfaz(
                                        fontSize: 12,
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
