import 'package:flutter/material.dart';

import '../datos/destinos_datasource_local.dart';
import '../widgets/tarjeta_experiencia_inmersiva.dart';

/// Pantalla de Destinos (segunda pestaña "Explora") con feed vertical inmersivo
/// basado en el diseño de referencia con paleta cálida de pergamino.
class PantallaDestinos extends StatefulWidget {
  const PantallaDestinos({super.key});

  @override
  State<PantallaDestinos> createState() => _EstadoPantallaDestinos();
}

class _EstadoPantallaDestinos extends State<PantallaDestinos> {
  final PageController _controladorPagina = PageController();
  int _paginaActual = 0;

  final destinos = DestinosDataSourceLocal.obtenerDestinosExperiencia;

  @override
  void dispose() {
    _controladorPagina.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Feed Inmersivo Vertical (PageView)
          PageView.builder(
            controller: _controladorPagina,
            scrollDirection: Axis.vertical,
            onPageChanged: (indice) {
              setState(() => _paginaActual = indice);
            },
            itemCount: destinos.length,
            itemBuilder: (context, index) {
              final destino = destinos[index];
              return TarjetaExperienciaInmersiva(
                destino: destino,
                onComenzarAventura: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Iniciando aventura en ${destino.tituloPrincipal}...'),
                      backgroundColor: const Color(0xFF8B5E3C),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),

          // Indicador de Paginación Vertical Lateral Derecha
          Positioned(
            right: 12,
            top: 0,
            bottom: 100,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(destinos.length, (index) {
                  final esActivo = _paginaActual == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    width: 6,
                    height: esActivo ? 20 : 6,
                    decoration: BoxDecoration(
                      color: esActivo
                          ? const Color(0xFFC9A84C)
                          : const Color(0xFF8B5E3C).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
