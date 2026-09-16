import 'package:flutter/material.dart';

import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';

/// Tarjeta vertical de estadística (guía Mi Viaje).
class TarjetaEstadisticaPerfil extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final int indice;
  final VoidCallback? onTap;

  const TarjetaEstadisticaPerfil({
    super.key,
    required this.icono,
    required this.valor,
    required this.etiqueta,
    this.indice = 0,
    this.onTap,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
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
                    color: PaletaRutas.ink.withValues(alpha: 0.55),
                  ),
                ),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 96),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: PaletaRutas.plomo.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icono,
                        size: 20,
                        color: PaletaRutas.oro,
                        shadows: _sombraInk,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        valor,
                        style: TipografiaHaku.titulo(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ).copyWith(shadows: _sombraInk),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        etiqueta,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.interfaz(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.plomoClaro,
                          height: 1.15,
                        ).copyWith(shadows: _sombraInk),
                      ),
                    ],
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
