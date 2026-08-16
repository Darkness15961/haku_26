import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/mapa_aventura_datasource_local.dart';

/// Tarjeta inferior con info de la caminata seleccionada.
class TarjetaInfoCaminata extends StatelessWidget {
  final NodoMapaAventura nodo;
  final VoidCallback? onExplorar;

  const TarjetaInfoCaminata({
    super.key,
    required this.nodo,
    this.onExplorar,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: PaletaRutas.beigeEnvejecido.withValues(alpha: 0.65),
          ),
          boxShadow: [
            BoxShadow(
              color: PaletaRutas.marronOscuro.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: PaletaRutas.beigeEnvejecido,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              nodo.nombre,
              textAlign: TextAlign.center,
              style: TipografiaHaku.titulo(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: PaletaRutas.marronOscuro,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Meta(
                    icono: Icons.schedule_outlined,
                    etiqueta: 'Duración',
                    valor: nodo.duracion,
                  ),
                ),
                Expanded(
                  child: _Meta(
                    icono: Icons.trending_up_rounded,
                    etiqueta: 'Dificultad',
                    valor: nodo.dificultad,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _Meta(
                    icono: Icons.straighten_rounded,
                    etiqueta: 'Distancia',
                    valor: nodo.distancia,
                  ),
                ),
                Expanded(
                  child: _Meta(
                    icono: Icons.landscape_outlined,
                    etiqueta: 'Elevación',
                    valor: nodo.elevacion,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: onExplorar,
                style: FilledButton.styleFrom(
                  backgroundColor: PaletaRutas.verdeBosque,
                  foregroundColor: PaletaRutas.crema,
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFF2D432B)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Explorar',
                  style: TipografiaHaku.interfaz(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.crema,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _Meta({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Icon(icono, size: 18, color: PaletaRutas.verdeOliva),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: TipografiaHaku.interfaz(
                    fontSize: 11,
                    color: PaletaRutas.marronCuero,
                  ),
                ),
                Text(
                  valor,
                  style: TipografiaHaku.interfaz(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.marronOscuro,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
