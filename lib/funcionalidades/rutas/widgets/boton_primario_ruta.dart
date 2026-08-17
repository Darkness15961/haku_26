import 'package:flutter/material.dart';

import 'estilos_rutas.dart';

/// Botón primario negro (mismo estilo que Explorar en Inicio).
class BotonPrimarioRuta extends StatelessWidget {
  final String texto;
  final IconData? icono;
  final VoidCallback? onPressed;
  final bool habilitado;

  const BotonPrimarioRuta({
    super.key,
    required this.texto,
    this.icono,
    this.onPressed,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    final activo = habilitado && onPressed != null;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: activo ? onPressed : null,
          borderRadius: BorderRadius.circular(28),
          child: Opacity(
            opacity: activo ? 1 : 0.55,
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
      ),
    );
  }
}

/// Botón secundario outline (estilo Haku / pergamino).
class BotonSecundarioRuta extends StatelessWidget {
  final String texto;
  final IconData? icono;
  final VoidCallback? onPressed;

  const BotonSecundarioRuta({
    super.key,
    required this.texto,
    this.icono,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icono ?? Icons.add_a_photo_outlined, size: 18),
        label: Text(
          texto,
          style: TipografiaHaku.interfaz(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: PaletaRutas.marronOscuro,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: PaletaRutas.marronOscuro,
          side: const BorderSide(color: PaletaRutas.marronCuero, width: 1.4),
          backgroundColor: PaletaRutas.crema.withValues(alpha: 0.92),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}
