import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';

/// Insignia circular con etiqueta (guía Mi Viaje).
class InsigniaPerfil extends StatelessWidget {
  final IconData icono;
  final String nombre;
  final Color colorFondo;

  const InsigniaPerfil({
    super.key,
    required this.icono,
    required this.nombre,
    required this.colorFondo,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorFondo,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorFondo.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icono, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            nombre,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TipografiaHaku.interfaz(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: PaletaRutas.marronOscuro,
              height: 1.15,
            ).copyWith(
              shadows: const [
                Shadow(
                  color: Color(0xE6FFFFFF),
                  blurRadius: 5,
                  offset: Offset(0, 0),
                ),
                Shadow(
                  color: Color(0x66000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
