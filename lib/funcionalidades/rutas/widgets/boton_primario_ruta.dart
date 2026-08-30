import 'package:flutter/material.dart';

import 'estilos_rutas.dart';

/// Botón primario (CTA oro sobre fondo oscuro).
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
                color: PaletaRutas.oro,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: PaletaRutas.oroOscuro.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icono != null) ...[
                    Icon(icono, size: 20, color: PaletaRutas.ink),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    texto,
                    style: TipografiaHaku.interfaz(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: PaletaRutas.ink,
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

/// Botón secundario outline (carbon + borde oro).
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
            color: PaletaRutas.piedra,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: PaletaRutas.piedra,
          side: BorderSide(
            color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
            width: 1.4,
          ),
          backgroundColor: PaletaRutas.carbon,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}
