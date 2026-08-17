import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/metricas/metricas_descubrimiento.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../favoritos/indice.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../widgets/insignia_perfil.dart';
import '../widgets/tarjeta_destino_sugerido.dart';
import '../widgets/tarjeta_estadistica_perfil.dart';
import 'pantalla_configuracion.dart';

enum _SeccionPerfil { perfil, contenido }

/// Perfil — identidad por contribuciones.
class PantallaPerfilUsuario extends ConsumerStatefulWidget {
  const PantallaPerfilUsuario({super.key});

  @override
  ConsumerState<PantallaPerfilUsuario> createState() =>
      _EstadoPantallaPerfilUsuario();
}

class _EstadoPantallaPerfilUsuario extends ConsumerState<PantallaPerfilUsuario> {
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
    final sesion = ref.watch(sesionProvider);
    final store = ref.watch(almacenFeedProvider);
    final nombre = sesion.usuario?.nombreUsuario ?? 'Camila Quispe';
    final avatarUrl = sesion.usuario?.avatarUrl ?? _avatarUrl;
    final bio = sesion.usuario?.bio ?? 'Tu aporte al mapa vivo';
    final misPosts = store.publicaciones
        .where((p) => p.autorId == AlmacenFeedNotifier.idUsuarioLocal)
        .toList();
    final urlsContenido = misPosts.isNotEmpty
        ? [
            for (final p in misPosts)
              if ((p.imagenUrl ?? '').isNotEmpty) p.imagenUrl!,
          ]
        : _publicacionesDemo;

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
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const PantallaConfiguracion(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: PaletaRutas.marronOscuro,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Perfil',
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
                      _CardExplorador(
                        avatarUrl: avatarUrl,
                        nombre: nombre,
                        bio: bio,
                      ),
                      const SizedBox(height: 12),
                      _BannerMetricas(),
                      const SizedBox(height: 18),
                      _SelectorSeccionPerfil(
                        seccion: _seccion,
                        onCambiar: (s) => setState(() => _seccion = s),
                      ),
                      const SizedBox(height: 22),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _seccion == _SeccionPerfil.perfil
                            ? _ContenidoPerfil(
                                key: const ValueKey('perfil'),
                                destinoUrl: _destinoUrl,
                              )
                            : _ContenidoPublicaciones(
                                key: const ValueKey('contenido'),
                                urls: urlsContenido,
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

class _BannerMetricas extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(metricasTickProvider);
    final m = ref.watch(metricasDescubrimientoProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PaletaRutas.crema,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PaletaRutas.beigeEnvejecido),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _kpi('${m.documentados}', 'Descubrimientos'),
          _kpi('${m.experienciasPublicadas}', 'Experiencias'),
          _kpi('${m.salidasEnroladas}', 'Salidas'),
        ],
      ),
    );
  }

  Widget _kpi(String v, String e) {
    return Column(
      children: [
        Text(
          v,
          style: TipografiaHaku.titulo(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        Text(
          e,
          style: TipografiaHaku.interfaz(
            fontSize: 11,
            color: PaletaRutas.marronCuero,
          ),
        ),
      ],
    );
  }
}

class _CardExplorador extends StatelessWidget {
  final String avatarUrl;
  final String nombre;
  final String bio;

  const _CardExplorador({
    required this.avatarUrl,
    required this.nombre,
    required this.bio,
  });

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
                  nombre,
                  style: TipografiaHaku.titulo(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TipografiaHaku.interfaz(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lugares · Experiencias · Salidas',
                  style: TipografiaHaku.interfaz(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
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

class _ContenidoPerfil extends ConsumerWidget {
  final String destinoUrl;

  const _ContenidoPerfil({super.key, required this.destinoUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(almacenFeedProvider);
    final m = ref.watch(metricasDescubrimientoProvider);
    final nPosts = store.publicaciones
        .where((p) => p.autorId == AlmacenFeedNotifier.idUsuarioLocal)
        .length;
    final nRutas = store.favoritosRutaIds.length;
    final nLugares = m.documentados;
    final nSalidas = m.salidasEnroladas;
    final insignias = _insigniasDesde(
      posts: nPosts,
      rutas: nRutas,
      lugares: nLugares,
      salidas: nSalidas,
      siguiendo: store.siguiendoIds.length,
    );

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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TarjetaEstadisticaPerfil(
              icono: Icons.place_outlined,
              valor: '$nLugares',
              etiqueta: 'Lugares',
              indice: 0,
            ),
            const SizedBox(width: 8),
            TarjetaEstadisticaPerfil(
              icono: Icons.route_outlined,
              valor: '$nRutas',
              etiqueta: 'Rutas',
              indice: 1,
            ),
            const SizedBox(width: 8),
            TarjetaEstadisticaPerfil(
              icono: Icons.photo_camera_outlined,
              valor: '$nPosts',
              etiqueta: 'Experiencias',
              indice: 2,
            ),
            const SizedBox(width: 8),
            TarjetaEstadisticaPerfil(
              icono: Icons.hiking,
              valor: '$nSalidas',
              etiqueta: 'Salidas',
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
              onPressed: () => _mostrarTodasInsignias(context, insignias),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < insignias.length && i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                InsigniaPerfil(
                  icono: insignias[i].icono,
                  nombre: insignias[i].nombre,
                  colorFondo: insignias[i].desbloqueada
                      ? insignias[i].color
                      : const Color(0xFFB0B0B0),
                ),
              ],
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

class _InsigniaInfo {
  final IconData icono;
  final String nombre;
  final String descripcion;
  final Color color;
  final bool desbloqueada;

  const _InsigniaInfo({
    required this.icono,
    required this.nombre,
    required this.descripcion,
    required this.color,
    required this.desbloqueada,
  });
}

List<_InsigniaInfo> _insigniasDesde({
  required int posts,
  required int rutas,
  required int lugares,
  required int salidas,
  required int siguiendo,
}) {
  return [
    _InsigniaInfo(
      icono: Icons.terrain_rounded,
      nombre: 'Explorador Inca',
      descripcion: 'Abre el mapa y explora una provincia',
      color: const Color(0xFF1A1A1A),
      desbloqueada: true,
    ),
    _InsigniaInfo(
      icono: Icons.filter_hdr_rounded,
      nombre: 'Montañista',
      descripcion: 'Guarda al menos 1 ruta',
      color: const Color(0xFF2D6A4F),
      desbloqueada: rutas >= 1,
    ),
    _InsigniaInfo(
      icono: Icons.hiking_rounded,
      nombre: 'Aventurero',
      descripcion: 'Enrólate en una salida',
      color: const Color(0xFF9C3B2E),
      desbloqueada: salidas >= 1,
    ),
    _InsigniaInfo(
      icono: Icons.photo_camera_outlined,
      nombre: 'Fotógrafo',
      descripcion: 'Publica 1 experiencia',
      color: const Color(0xFF1E4D6B),
      desbloqueada: posts >= 1,
    ),
    _InsigniaInfo(
      icono: Icons.place_outlined,
      nombre: 'Documentalista',
      descripcion: 'Documenta 3 lugares',
      color: const Color(0xFF6B4F1E),
      desbloqueada: lugares >= 3,
    ),
    _InsigniaInfo(
      icono: Icons.people_outline,
      nombre: 'Conector',
      descripcion: 'Sigue a 3 exploradores',
      color: const Color(0xFF4A3B6B),
      desbloqueada: siguiendo >= 3,
    ),
  ];
}

void _mostrarTodasInsignias(
  BuildContext context,
  List<_InsigniaInfo> insignias,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Todas las insignias',
                style: TipografiaHaku.titulo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              for (final i in insignias)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: i.desbloqueada
                            ? i.color
                            : Colors.grey.shade300,
                        child: Icon(
                          i.icono,
                          color: i.desbloqueada
                              ? Colors.white
                              : Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i.nombre,
                              style: TipografiaHaku.interfaz(
                                fontWeight: FontWeight.w700,
                                color: i.desbloqueada
                                    ? PaletaRutas.marronOscuro
                                    : Colors.grey,
                              ),
                            ),
                            Text(
                              i.descripcion,
                              style: TipografiaHaku.interfaz(
                                fontSize: 12,
                                color: PaletaRutas.marronCuero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        i.desbloqueada
                            ? Icons.check_circle
                            : Icons.lock_outline,
                        size: 18,
                        color: i.desbloqueada
                            ? PaletaRutas.verdeBosque
                            : Colors.grey,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
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
