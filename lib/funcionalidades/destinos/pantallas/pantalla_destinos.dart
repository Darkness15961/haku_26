import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../rutas/indice.dart';
import '../datos/destinos_datasource_local.dart';
import '../widgets/hero_entrada_inicio.dart';
import '../widgets/indicador_recorrido_pergamin.dart';
import '../widgets/tarjeta_experiencia_inmersiva.dart';

/// Feed vertical inmersivo (tab Inicio).
class PantallaDestinos extends StatefulWidget {
  const PantallaDestinos({super.key});

  @override
  State<PantallaDestinos> createState() => _EstadoPantallaDestinos();
}

class _EstadoPantallaDestinos extends State<PantallaDestinos> {
  final PageController _controladorPagina = PageController();
  int _paginaActual = 0;
  bool _mostrarHero = true;
  bool _ambienteActivo = false; // mute por defecto (sin paquete de audio)

  final destinos = DestinosDataSourceLocal.obtenerDestinosExperiencia;

  static const _mapaDestinoARuta = {
    'machupicchu': 'machu_picchu',
    'humantay': 'laguna_humantay',
    'vinicunca': 'vinicunca',
    'cusco_imperial': 'cusco_historico',
    'llama_machu': 'cusco_historico',
  };

  @override
  void dispose() {
    _controladorPagina.dispose();
    super.dispose();
  }

  void _abrirDetalleDesdeExplora(String destinoId, String titulo) {
    final rutaId = _mapaDestinoARuta[destinoId];
    final ruta =
        rutaId != null ? RutasDataSourceLocal.obtenerPorId(rutaId) : null;

    if (ruta != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PantallaDetalleRuta(ruta: ruta),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Proximamente: $titulo'),
        backgroundColor: PaletaRutas.verdeBosque,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onPageChanged(int indice) {
    setState(() => _paginaActual = indice);
    if (_ambienteActivo) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final haySiguiente = _paginaActual < destinos.length - 1;
    final siguiente =
        haySiguiente ? destinos[_paginaActual + 1] : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controladorPagina,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: destinos.length,
            itemBuilder: (context, index) {
              final destino = destinos[index];
              return TarjetaExperienciaInmersiva(
                destino: destino,
                onComenzarAventura: () {
                  _abrirDetalleDesdeExplora(
                    destino.id,
                    destino.tituloPrincipal,
                  );
                },
              );
            },
          ),

          // Indicador de recorrido pergamino.
          if (!_mostrarHero)
            Positioned(
              right: 12,
              top: 0,
              bottom: 120 + bottomPad,
              child: Center(
                child: IndicadorRecorridoPergamino(
                  actual: _paginaActual + 1,
                  total: destinos.length,
                ),
              ),
            ),

          // Peek del siguiente destino (encima de la barra).
          if (!_mostrarHero && siguiente != null)
            Positioned(
              left: 24,
              right: 72,
              bottom: 96 + bottomPad,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Siguiente: ${siguiente.tituloPrincipal}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Mute / ambiente (sin audio real; haptic si activo).
          if (!_mostrarHero)
            Positioned(
              top: 8,
              right: 12,
              child: SafeArea(
                child: IconButton(
                  tooltip: _ambienteActivo
                      ? 'Ambiente activo'
                      : 'Ambiente silenciado',
                  onPressed: () {
                    setState(() => _ambienteActivo = !_ambienteActivo);
                    if (_ambienteActivo) {
                      HapticFeedback.selectionClick();
                    }
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.35),
                  ),
                  icon: Icon(
                    _ambienteActivo
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Hero de entrada (solo primera vez en la sesión del tab).
          if (_mostrarHero)
            Positioned.fill(
              child: HeroEntradaInicio(
                onComenzar: () {
                  setState(() => _mostrarHero = false);
                },
              ),
            ),
        ],
      ),
    );
  }
}
