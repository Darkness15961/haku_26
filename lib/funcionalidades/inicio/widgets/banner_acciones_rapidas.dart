import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/widgets/estilos_rutas.dart';

/// Acciones de Inicio: cards simples con fondo cultural (como perfil).
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _AccionCard(
              titulo: 'Explorar',
              fondo: CatalogoImagenesHaku.ausangate,
              icono: Icons.map_outlined,
              onTap: onExplorar,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _AccionCard(
              titulo: 'Cultura',
              fondo: CatalogoImagenesHaku.moray,
              asset: 'assets/iconos/ceramica.svg',
              onTap: onCultura,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _AccionCard(
              titulo: 'Compartir',
              fondo: CatalogoImagenesHaku.machuPicchu,
              icono: Icons.add_a_photo_outlined,
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
    this.icono,
    this.asset,
  });

  final String titulo;
  final String fondo;
  final VoidCallback onTap;
  final IconData? icono;
  final String? asset;

  static const _sombra = [
    Shadow(color: Color(0xB3000000), blurRadius: 6, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 96,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImagenHaku(url: fondo, fit: BoxFit.cover),
                const ColoredBox(color: Color(0x66000000)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (asset != null)
                        SvgPicture.asset(
                          asset!,
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        )
                      else
                        Icon(
                          icono,
                          color: Colors.white,
                          size: 22,
                          shadows: _sombra,
                        ),
                      const Spacer(),
                      Text(
                        titulo,
                        style: TipografiaHaku.interfaz(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ).copyWith(shadows: _sombra),
                      ),
                    ],
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
