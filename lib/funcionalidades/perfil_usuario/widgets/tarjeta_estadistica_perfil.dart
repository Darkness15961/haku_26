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

  static const _sombraBlanca = [
    Shadow(
      color: Color(0xCC000000),
      blurRadius: 6,
      offset: Offset(0, 1),
    ),
    Shadow(
      color: Color(0x99000000),
      blurRadius: 3,
      offset: Offset(0, 0),
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
                    const ColoredBox(color: Colors.black87),
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.42),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icono,
                    size: 22,
                    color: Colors.white,
                    shadows: _sombraBlanca,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    valor,
                    style: TipografiaHaku.titulo(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ).copyWith(shadows: _sombraBlanca),
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
                      color: Colors.white,
                      height: 1.2,
                    ).copyWith(shadows: _sombraBlanca),
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
