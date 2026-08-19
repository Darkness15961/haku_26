import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../rutas/widgets/estilos_rutas.dart';

/// Tres acciones principales de HAKU en tarjetas visuales.
class BannerAccionesRapidas extends StatelessWidget {
  const BannerAccionesRapidas({
    super.key,
    required this.onExplorar,
    required this.onCultura,
    required this.onAportar,
  });

  final VoidCallback onExplorar;
  final VoidCallback onCultura;
  final VoidCallback onAportar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _Accion(
              titulo: 'Explorar',
              subtitulo: 'Huecos',
              icono: Icons.map_outlined,
              color: PaletaRutas.azulLago,
              onTap: onExplorar,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Accion(
              titulo: 'Cultura',
              subtitulo: 'Hilos vivos',
              asset: 'assets/iconos/ceramica.svg',
              color: PaletaRutas.terracota,
              onTap: onCultura,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Accion(
              titulo: 'Aportar',
              subtitulo: 'Tu relato',
              icono: Icons.add_a_photo_outlined,
              color: PaletaRutas.marronOscuro,
              onTap: onAportar,
            ),
          ),
        ],
      ),
    );
  }
}

class _Accion extends StatelessWidget {
  const _Accion({
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.onTap,
    this.icono,
    this.asset,
  });

  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback onTap;
  final IconData? icono;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withValues(alpha: 0.82),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                  Icon(icono, color: Colors.white, size: 22),
                const Spacer(),
                Text(
                  titulo,
                  style: TipografiaHaku.interfaz(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitulo,
                  style: TipografiaHaku.interfaz(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
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
