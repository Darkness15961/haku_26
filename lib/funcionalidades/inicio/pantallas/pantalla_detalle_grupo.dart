import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/mensajes_datasource_local.dart';

/// Detalle de grupo de ruta. Solo el creador puede finalizar (elimina el grupo).
class PantallaDetalleGrupo extends StatelessWidget {
  final GrupoRuta grupo;

  const PantallaDetalleGrupo({super.key, required this.grupo});

  Future<void> _finalizar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Finalizar ruta',
          style: TipografiaHaku.titulo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Al finalizar la ruta se eliminará el grupo "${grupo.nombre}". '
          'Solo tú, como creador, puedes hacerlo.',
          style: TipografiaHaku.interfaz(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: PaletaRutas.marronOscuro,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.9),
            ),
            child: Text(
              'Finalizar y eliminar',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    MensajeriaEstado.instancia.eliminarGrupo(grupo.id);
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ruta finalizada. Grupo "${grupo.nombre}" eliminado.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withValues(alpha: 0.9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 24;
    final miembros = grupo.miembros;

    return Scaffold(
      backgroundColor: Colors.white,
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
                          color: PaletaRutas.marronOscuro,
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
                            color: PaletaRutas.marronOscuro,
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
              child: FondoSuaveSeccion(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ruta del grupo',
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            grupo.rutaTitulo,
                            style: TipografiaHaku.titulo(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${grupo.miembroIds.length} compañeros · ${grupo.esCreador ? 'Eres el creador' : 'Miembro'}',
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.75),
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
                        color: PaletaRutas.marronOscuro,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < miembros.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.12),
                            ),
                            image: DecorationImage(
                              image: AssetImage(
                                FondosDetalleHaku.porIndice(i),
                              ),
                              fit: BoxFit.cover,
                              opacity: 0.35,
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: miembros[i].avatarUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      const ColoredBox(
                                    color: Color(0xFFBBBBBB),
                                    child: SizedBox(width: 40, height: 40),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  miembros[i].nombre,
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
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
                        'Al finalizar la ruta, el grupo se elimina. Solo el creador puede hacerlo.',
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          color: PaletaRutas.marronOscuro.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _finalizar(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                const Color(0xFF9C3B2E).withValues(alpha: 0.95),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.flag_outlined),
                          label: Text(
                            'Finalizar ruta (eliminar grupo)',
                            style: TipografiaHaku.interfaz(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
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
