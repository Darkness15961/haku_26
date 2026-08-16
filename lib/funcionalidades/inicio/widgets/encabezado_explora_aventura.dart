import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';

/// Encabezado Explora: bloque negro, tipografia en mayusculas.
class EncabezadoExploraAventura extends StatelessWidget {
  final double topSafe;

  const EncabezadoExploraAventura({
    super.key,
    required this.topSafe,
  });

  static const _altoContenido = 56.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: topSafe + _altoContenido,
      width: double.infinity,
      color: Colors.black,
      padding: EdgeInsets.only(top: topSafe, left: 16, right: 16, bottom: 10),
      alignment: Alignment.bottomCenter,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'RINCONES ',
                style: TipografiaHaku.logo(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: 'CON ',
                style: TipografiaHaku.titulo(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFB8D4A8),
                  letterSpacing: 1.2,
                ),
              ),
              TextSpan(
                text: 'HISTORIA',
                style: TipografiaHaku.logo(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
