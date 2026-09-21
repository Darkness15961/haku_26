import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/widgets/avatar_haku.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/mensajes_datasource_local.dart';
import '../proveedores/proveedor_almacen_feed.dart';

/// Detalle de grupo de ruta. Solo el creador puede finalizar (elimina el grupo).
class PantallaDetalleGrupo extends ConsumerWidget {
  final GrupoRuta grupo;

  const PantallaDetalleGrupo({super.key, required this.grupo});

  Future<void> _finalizar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PaletaRutas.carbon,
        title: Text(
          'Finalizar ruta',
          style: TipografiaHaku.titulo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
        content: Text(
          'Se elimina el equipo.',
          style: TipografiaHaku.interfaz(
            fontSize: 14,
            color: PaletaRutas.plomoClaro,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: PaletaRutas.plomoClaro,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: PaletaRutas.oro,
            ),
            child: Text(
              'Eliminar',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: PaletaRutas.ink,
              ),
            ),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    MensajeriaEstado.instancia.eliminarGrupo(grupo.id);
    await ref.read(almacenFeedProvider.notifier).persistirSatelites();
    if (!context.mounted) return;
    Navigator.of(context).pop(true);
    mostrarSnackHaku(context, 'Equipo eliminado', destacado: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 24;
    final miembros = grupo.miembros;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          grupo.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TipografiaHaku.titulo(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: LineaEncabezadoInca(altura: 2),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: PaletaRutas.carbon,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ruta del equipo',
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: PaletaRutas.plomoClaro,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            grupo.rutaTitulo,
                            style: TipografiaHaku.titulo(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${grupo.miembroIds.length} · ${grupo.esCreador ? 'Creador' : 'Miembro'}',
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: PaletaRutas.plomo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Integrantes',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < miembros.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: PaletaRutas.carbon,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: PaletaRutas.plomoOscuro
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          child: Row(
                            children: [
                              AvatarHaku(url: miembros[i].avatarUrl, size: 40),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  miembros[i].nombre,
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: PaletaRutas.piedra,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (grupo.esCreador) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Se elimina al terminar.',
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _finalizar(context, ref),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PaletaRutas.oro,
                            backgroundColor: PaletaRutas.carbon,
                            side: BorderSide(
                              color: PaletaRutas.oro.withValues(alpha: 0.6),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.flag_outlined),
                          label: Text(
                            'Finalizar',
                            style: TipografiaHaku.interfaz(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.oro,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ),
          ],
        ),
      ),
    );
  }
}
