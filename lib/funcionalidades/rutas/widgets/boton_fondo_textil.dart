import 'package:flutter/material.dart';

import 'decoracion_detalle_fondo.dart';
import 'estilos_rutas.dart';

/// Botón con imagen de fondo + velo negro (estilo Inicio).
class BotonFondoTextil extends StatelessWidget {
  final String texto;
  final IconData? icono;
  final VoidCallback? onPressed;
  final double altura;
  final double radius;
  final int indiceFondo;

  const BotonFondoTextil({
    super.key,
    required this.texto,
    this.icono,
    this.onPressed,
    this.altura = 52,
    this.radius = 28,
    this.indiceFondo = 0,
  });

  @override
  Widget build(BuildContext context) {
    final habilitado = onPressed != null;

    return SizedBox(
      width: double.infinity,
      height: altura,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    FondosDetalleHaku.porIndice(indiceFondo),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Colors.black87),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(
                            alpha: habilitado ? 0.52 : 0.7,
                          ),
                          Colors.black.withValues(
                            alpha: habilitado ? 0.7 : 0.82,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icono != null) ...[
                          Icon(icono, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          texto,
                          style: TipografiaHaku.interfaz(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
