import 'package:flutter/material.dart';

import '../../../nucleo/widgets/badge_contador.dart';
import 'estilos_rutas.dart';

/// Acción expandida del menú: texto visible para no depender del tooltip.
class BotonIconoAccion extends StatelessWidget {
  const BotonIconoAccion({
    super.key,
    required this.tooltip,
    required this.icono,
    required this.onTap,
    this.destacado = false,
    this.badge,
    this.tamano = 46,
  });

  final String tooltip;
  final IconData icono;
  final VoidCallback onTap;
  final bool destacado;
  final String? badge;
  final double tamano;

  int get _contador => int.tryParse(badge ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(tamano / 2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Ink(
                height: tamano,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: PaletaRutas.carbon,
                  borderRadius: BorderRadius.circular(tamano / 2),
                  border: Border.all(
                    color: destacado
                        ? PaletaRutas.oro.withValues(alpha: 0.55)
                        : PaletaRutas.plomo.withValues(alpha: 0.45),
                    width: destacado ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: PaletaRutas.ink.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tooltip,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(icono, size: tamano * 0.46, color: PaletaRutas.oro),
                  ],
                ),
              ),
              if (destacado && _contador > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: BadgeContador(cantidad: _contador, compacto: true),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
