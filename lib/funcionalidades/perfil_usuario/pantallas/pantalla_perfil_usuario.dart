import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../favoritos/indice.dart';
import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../widgets/insignia_perfil.dart';
import '../widgets/tarjeta_destino_sugerido.dart';
import '../widgets/tarjeta_estadistica_perfil.dart';

enum _SeccionPerfil { perfil, contenido }

/// Perfil / Mi Viaje según la guía visual (datos de prueba).
class PantallaPerfilUsuario extends StatefulWidget {
  const PantallaPerfilUsuario({super.key});

  @override
  State<PantallaPerfilUsuario> createState() => _EstadoPantallaPerfilUsuario();
}

class _EstadoPantallaPerfilUsuario extends State<PantallaPerfilUsuario> {
  static const _avatarUrl =
      'https://images.unsplash.com/photo-1551632811-561732d1e306?w=200&q=80';
  static const _destinoUrl =
      'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400&q=80';

  static const _publicacionesDemo = [
    'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=400&q=80',
    'https://images.unsplash.com/photo-1587595431973-160d0d94add1?w=400&q=80',
    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400&q=80',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&q=80',
    'https://images.unsplash.com/photo-1548013146-72479768bada?w=400&q=80',
    'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?w=400&q=80',
  ];

  _SeccionPerfil _seccion = _SeccionPerfil.perfil;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 110;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Guardados',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const PantallaFavoritos(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.bookmark_border_rounded,
                            color: PaletaRutas.marronOscuro,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Ajustes',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          onPressed: () {},
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: PaletaRutas.marronOscuro,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Mi Viaje',
                            textAlign: TextAlign.center,
                            style: TipografiaHaku.titulo(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.marronOscuro,
                            ),
                          ),
                        ),
                        // Equilibra el espacio de los dos iconos de la izquierda.
                        const SizedBox(width: 80),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: LineaEncabezadoInca(altura: 2),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FondoSuaveSeccion(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CardExplorador(avatarUrl: _avatarUrl),
                      const SizedBox(height: 18),
                      _SelectorSeccionPerfil(
                        seccion: _seccion,
                        onCambiar: (s) => setState(() => _seccion = s),
                      ),
                      const SizedBox(height: 22),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _seccion == _SeccionPerfil.perfil
                            ? const _ContenidoPerfil(
                                key: ValueKey('perfil'),
                                destinoUrl: _destinoUrl,
                              )
                            : const _ContenidoPublicaciones(
                                key: ValueKey('contenido'),
                                urls: _publicacionesDemo,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardExplorador extends StatelessWidget {
  final String avatarUrl;

  const _CardExplorador({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: avatarUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              placeholder: (_, __) => const ColoredBox(
                color: Color(0xFF333333),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Icon(
                    Icons.person,
                    color: Colors.white70,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => const ColoredBox(
                color: Color(0xFF333333),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Icon(
                    Icons.person,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explorador',
                  style: TipografiaHaku.titulo(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Nivel 12',
                  style: TipografiaHaku.interfaz(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 3500 / 5000,
                          minHeight: 10,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.25),
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '3500 / 5000 XP',
                      style: TipografiaHaku.interfaz(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorSeccionPerfil extends StatelessWidget {
  final _SeccionPerfil seccion;
  final ValueChanged<_SeccionPerfil> onCambiar;

  const _SelectorSeccionPerfil({
    required this.seccion,
    required this.onCambiar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _IconoSeccion(
            icono: Icons.person_outline_rounded,
            seleccionado: seccion == _SeccionPerfil.perfil,
            tooltip: 'Perfil',
            onTap: () => onCambiar(_SeccionPerfil.perfil),
          ),
        ),
        Expanded(
          child: _IconoSeccion(
            icono: Icons.grid_on_rounded,
            seleccionado: seccion == _SeccionPerfil.contenido,
            tooltip: 'Contenido',
            onTap: () => onCambiar(_SeccionPerfil.contenido),
          ),
        ),
      ],
    );
  }
}

class _IconoSeccion extends StatelessWidget {
  final IconData icono;
  final bool seleccionado;
  final String tooltip;
  final VoidCallback onTap;

  const _IconoSeccion({
    required this.icono,
    required this.seleccionado,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = seleccionado
        ? PaletaRutas.marronOscuro
        : PaletaRutas.marronOscuro.withValues(alpha: 0.38);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Icon(icono, size: 26, color: color),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2.5,
              width: double.infinity,
              decoration: BoxDecoration(
                color: seleccionado
                    ? PaletaRutas.marronOscuro
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContenidoPerfil extends StatelessWidget {
  final String destinoUrl;

  const _ContenidoPerfil({super.key, required this.destinoUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Estadísticas',
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.marronOscuro,
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TarjetaEstadisticaPerfil(
              icono: Icons.account_balance_outlined,
              valor: '24',
              etiqueta: 'Lugares visitados',
              indice: 0,
            ),
            SizedBox(width: 8),
            TarjetaEstadisticaPerfil(
              icono: Icons.explore_outlined,
              valor: '8',
              etiqueta: 'Rutas completadas',
              indice: 1,
            ),
            SizedBox(width: 8),
            TarjetaEstadisticaPerfil(
              icono: Icons.menu_book_outlined,
              valor: '12',
              etiqueta: 'Experiencias vividas',
              indice: 2,
            ),
            SizedBox(width: 8),
            TarjetaEstadisticaPerfil(
              icono: Icons.military_tech_outlined,
              valor: '3',
              etiqueta: 'Insignias obtenidas',
              indice: 3,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                'Insignias',
                style: TipografiaHaku.titulo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.marronOscuro,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: PaletaRutas.verdeBosque,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Ver todas',
                style: TipografiaHaku.interfaz(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.verdeBosque,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 14,
          ),
          decoration: FondosDetalleHaku.tarjeta(indice: 1),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InsigniaPerfil(
                icono: Icons.terrain_rounded,
                nombre: 'Explorador Inca',
                colorFondo: Color(0xFF1A1A1A),
              ),
              SizedBox(width: 8),
              InsigniaPerfil(
                icono: Icons.filter_hdr_rounded,
                nombre: 'Montañista',
                colorFondo: Color(0xFF2D6A4F),
              ),
              SizedBox(width: 8),
              InsigniaPerfil(
                icono: Icons.hiking_rounded,
                nombre: 'Aventurero',
                colorFondo: Color(0xFF9C3B2E),
              ),
              SizedBox(width: 8),
              InsigniaPerfil(
                icono: Icons.photo_camera_outlined,
                nombre: 'Fotógrafo',
                colorFondo: Color(0xFF1E4D6B),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Próximo destino sugerido',
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.marronOscuro,
          ),
        ),
        const SizedBox(height: 12),
        TarjetaDestinoSugerido(
          titulo: 'Parque Nacional Ausangate',
          rating: 4.9,
          resenas: 856,
          imagenUrl: destinoUrl,
          indice: 0,
        ),
      ],
    );
  }
}

class _ContenidoPublicaciones extends StatelessWidget {
  final List<String> urls;

  const _ContenidoPublicaciones({super.key, required this.urls});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 42,
              color: PaletaRutas.marronOscuro.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Text(
              'Aún no tienes publicaciones',
              style: TipografiaHaku.interfaz(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: PaletaRutas.marronOscuro.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Mis publicaciones',
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.marronOscuro,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: urls.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: urls[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => ColoredBox(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: Colors.black.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white70,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
