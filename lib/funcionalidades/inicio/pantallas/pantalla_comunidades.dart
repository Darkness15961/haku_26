import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/mensajes_datasource_local.dart';

/// Listado de comunidades con opción de solicitar unirte.
class PantallaComunidades extends StatefulWidget {
  const PantallaComunidades({super.key});

  @override
  State<PantallaComunidades> createState() => _EstadoPantallaComunidades();
}

class _EstadoPantallaComunidades extends State<PantallaComunidades> {
  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 24;
    final comunidades = MensajeriaEstado.instancia.comunidades;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
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
                          'Comunidades',
                          style: TipografiaHaku.titulo(
                            fontSize: 22,
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
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                  itemCount: comunidades.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final c = comunidades[index];
                    final solicitada =
                        MensajeriaEstado.instancia.solicitudEnviada(c.id);
                    return _CardComunidad(
                      comunidad: c,
                      indice: index,
                      solicitada: solicitada,
                      onSolicitar: () {
                        setState(() {
                          MensajeriaEstado.instancia.solicitarUnirse(c.id);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Solicitud enviada a "${c.nombre}"',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.9),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardComunidad extends StatelessWidget {
  final ComunidadHaku comunidad;
  final int indice;
  final bool solicitada;
  final VoidCallback onSolicitar;

  const _CardComunidad({
    required this.comunidad,
    required this.indice,
    required this.solicitada,
    required this.onSolicitar,
  });

  @override
  Widget build(BuildContext context) {
    final veloNegro = indice.isEven;
    final texto = veloNegro ? Colors.white : PaletaRutas.marronOscuro;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.14)),
        image: DecorationImage(
          image: AssetImage(FondosDetalleHaku.porIndice(indice)),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: veloNegro
              ? Colors.black.withValues(alpha: 0.62)
              : Colors.white.withValues(alpha: 0.78),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: comunidad.imagenUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const ColoredBox(
                          color: Color(0xFFBBBBBB),
                          child: SizedBox(width: 64, height: 64),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comunidad.nombre,
                            style: TipografiaHaku.interfaz(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: texto,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            comunidad.descripcion,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: texto.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${comunidad.miembros} miembros',
                            style: TipografiaHaku.interfaz(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: texto.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: TextButton(
                    onPressed: solicitada ? null : onSolicitar,
                    style: TextButton.styleFrom(
                      backgroundColor: solicitada
                          ? Colors.transparent
                          : (veloNegro
                              ? Colors.white.withValues(alpha: 0.92)
                              : Colors.black.withValues(alpha: 0.88)),
                      foregroundColor: solicitada
                          ? texto.withValues(alpha: 0.7)
                          : (veloNegro
                              ? PaletaRutas.marronOscuro
                              : Colors.white),
                      disabledForegroundColor: texto.withValues(alpha: 0.7),
                      side: solicitada
                          ? BorderSide(color: texto.withValues(alpha: 0.45))
                          : BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      solicitada ? 'Solicitud enviada' : 'Solicitar unirte',
                      style: TipografiaHaku.interfaz(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
