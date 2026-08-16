import 'package:flutter/material.dart';

import 'estilos_rutas.dart';

/// Botón primario negro (mismo estilo que Explorar en Inicio).
class BotonPrimarioRuta extends StatelessWidget {
  final String texto;
  final IconData? icono;
  final VoidCallback? onPressed;

  const BotonPrimarioRuta({
    super.key,
    required this.texto,
    this.icono,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icono != null) ...[
                  Icon(icono, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  texto,
                  style: TipografiaHaku.interfaz(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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
