import 'package:flutter/material.dart';

import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';

/// Tres atajos visuales — una palabra, imagen dominante.
class BannerAccionesRapidas extends StatelessWidget {
  const BannerAccionesRapidas({
    super.key,
    required this.onExplorar,
    required this.onCultura,
    required this.onCompartir,
  });

  final VoidCallback onExplorar;
  final VoidCallback onCultura;
  final VoidCallback onCompartir;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: _AccionCard(
              titulo: 'Mapa',
              fondo: CatalogoImagenesHaku.ausangate,
              onTap: onExplorar,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AccionCard(
              titulo: 'Rutas',
              fondo: CatalogoImagenesHaku.moray,
              onTap: onCultura,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AccionCard(
              titulo: '+',
              fondo: CatalogoImagenesHaku.machuPicchu,
              onTap: onCompartir,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccionCard extends StatelessWidget {
  const _AccionCard({
    required this.titulo,
    required this.fondo,
    required this.onTap,
  });

  final String titulo;
  final String fondo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 110,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImagenHaku(url: fondo, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        color: Color(0xFFF0EDE8),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        shadows: [
                          Shadow(
                            color: Color(0x99000000),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
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
