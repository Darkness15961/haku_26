import 'package:flutter/material.dart';

import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';

/// Tarjeta vertical de estadística (guía Mi Viaje).
class TarjetaEstadisticaPerfil extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final int indice;

  const TarjetaEstadisticaPerfil({
    super.key,
    required this.icono,
    required this.valor,
    required this.etiqueta,
    this.indice = 0,
  });

  static final _sombraInk = [
    Shadow(
      color: PaletaRutas.ink.withValues(alpha: 0.75),
      blurRadius: 6,
      offset: const Offset(0, 1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                FondosDetalleHaku.porIndice(indice),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: PaletaRutas.carbon),
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: PaletaRutas.ink.withValues(alpha: 0.52),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: PaletaRutas.plomo.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icono,
                    size: 22,
                    color: PaletaRutas.oro,
                    shadows: _sombraInk,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    valor,
                    style: TipografiaHaku.titulo(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.piedra,
                    ).copyWith(shadows: _sombraInk),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    etiqueta,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TipografiaHaku.interfaz(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.plomoClaro,
                      height: 1.2,
                    ).copyWith(shadows: _sombraInk),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
