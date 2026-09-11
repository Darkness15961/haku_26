import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelos/modelo_lugar.dart';

/// Foto estilo polaroid / marco oro-piedra para islas Explora.
class FotoEnmarcadaLugar extends StatelessWidget {
  const FotoEnmarcadaLugar({
    super.key,
    required this.lugar,
    required this.onTap,
    this.ancho = 88,
    this.rotacion = -0.04,
    this.mostrarNuevo = true,
  });

  final ModeloLugar lugar;
  final VoidCallback onTap;
  final double ancho;
  final double rotacion;
  final bool mostrarNuevo;

  bool get _esNuevo =>
      lugar.nivelExploracion == NivelExploracion.nuevoEnHaku ||
      lugar.creadoPorUsuario;

  @override
  Widget build(BuildContext context) {
    final alto = ancho * 1.15;

    return Transform.rotate(
      angle: rotacion,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: ancho,
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 18),
            decoration: BoxDecoration(
              color: PaletaRutas.piedra,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: PaletaRutas.oro.withValues(alpha: 0.55),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: PaletaRutas.ink.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: alto - 28,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ImagenHaku(url: lugar.imagenUrl, fit: BoxFit.cover),
                        if (mostrarNuevo && _esNuevo)
                          Positioned(
                            left: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: PaletaRutas.oro,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Nuevo',
                                style: TipografiaHaku.interfaz(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: PaletaRutas.ink,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lugar.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.ink,
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
