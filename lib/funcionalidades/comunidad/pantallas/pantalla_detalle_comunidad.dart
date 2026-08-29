import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/widgets/avatar_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../rutas/widgets/boton_fondo_textil.dart';
import '../../rutas/widgets/estilos_rutas.dart';
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
        backgroundColor: PaletaRutas.ink,
        appBar: AppBar(
          backgroundColor: PaletaRutas.ink,
          foregroundColor: PaletaRutas.piedra,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'Comunidad no encontrada',
            style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
          ),
        ),
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
      backgroundColor: PaletaRutas.ink,
      body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImagenHaku(
                      url: c.imagenUrl,
                      fit: BoxFit.cover,
                      respaldo: CatalogoImagenesHaku.encabezadoRutas,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.72),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Salidas de la comunidad',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => PantallaSalidas(
                                      comunidadId: c.id,
                                    ),
                                  ),
                                );
                              },
                              icon:
                                  const Icon(Icons.hiking, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        if (unida)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: PaletaRutas.oro,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Unida',
                              style: TipografiaHaku.interfaz(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: PaletaRutas.ink,
                              ),
                            ),
                          ),
                        Text(
                          c.nombre,
                          style: TipografiaHaku.titulo(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${c.miembros} miembros · ${c.provincia}',
                          style: TipografiaHaku.interfaz(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      texto: unida ? 'Salir' : 'Unirme',
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
                    const LineaEncabezadoInca(altura: 2),
                    const SizedBox(height: 14),
                    Text(
                      'Miembros',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (miembros.isEmpty)
                      Text(
                        'Aún no hay miembros visibles',
                        style: TipografiaHaku.interfaz(
                          color: PaletaRutas.plomoClaro,
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
                              AvatarHaku(url: p.avatarUrl, size: 44),
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
                                          ? '${p.usuario} · organizador'
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
    );
  }
}
