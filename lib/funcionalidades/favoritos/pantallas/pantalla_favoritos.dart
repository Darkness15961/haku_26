import 'package:flutter/material.dart';

import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';

/// Guardados / Favoritos.
class PantallaFavoritos extends StatelessWidget {
  const PantallaFavoritos({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 110;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guardados',
                    style: TipografiaHaku.titulo(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.marronOscuro,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tus rincones favoritos',
                    style: TipografiaHaku.interfaz(
                      fontSize: 14,
                      color: PaletaRutas.marronCuero,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const LineaEncabezadoInca(altura: 2),
                ],
              ),
            ),
            Expanded(
              child: FondoSuaveSeccion(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: FondosDetalleHaku.tarjeta(indice: 0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.bookmark_rounded,
                            size: 36,
                            color: Colors.black87,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aun no hay favoritos',
                            style: TipografiaHaku.titulo(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Guarda rutas y destinos para verlos aqui.',
                            textAlign: TextAlign.center,
                            style: TipografiaHaku.interfaz(
                              fontSize: 13,
                              color: PaletaRutas.marronCuero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    BotonPrimarioRuta(
                      texto: 'Explorar rutas',
                      icono: Icons.map_outlined,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Ve a la pestaña Rutas para descubrir',
                              style: TipografiaHaku.interfaz(
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: Colors.black,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
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
