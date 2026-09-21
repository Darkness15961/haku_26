import 'package:flutter/material.dart';

import '../../../nucleo/widgets/badge_contador.dart';
import 'estilos_rutas.dart';

/// Botón circular solo icono (menús flotantes HAKU).
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
          customBorder: const CircleBorder(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Ink(
                width: tamano,
                height: tamano,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PaletaRutas.carbon,
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
                child: Icon(
                  icono,
                  size: tamano * 0.48,
                  color: destacado ? PaletaRutas.oro : PaletaRutas.oro,
                ),
              ),
              if (destacado && _contador > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: BadgeContador(
                    cantidad: _contador,
                    compacto: true,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
