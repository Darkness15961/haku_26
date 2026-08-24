import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_svg/flutter_svg.dart';

import '../../../nucleo/metricas/metricas_descubrimiento.dart';
import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../favoritos/indice.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../../nucleo/widgets/avatar_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/datos/rutas_datasource_local.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/pantallas/pantalla_detalle_ruta.dart';
import '../../rutas/pantallas/pantalla_rutas.dart';
import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../widgets/insignia_perfil.dart';
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
  static const _avatarUrl = CatalogoImagenesHaku.avatar;

  static final _publicacionesDemo = CatalogoImagenesHaku.destinos;

  _SeccionPerfil _seccion = _SeccionPerfil.perfil;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 110;
    final sesion = ref.watch(sesionProvider);
    final store = ref.watch(almacenFeedProvider);
    final nombre = sesion.usuario?.nombreUsuario ?? 'Lucía';
    final avatarUrl = sesion.usuario?.avatarUrl ?? _avatarUrl;
    final bio = sesion.usuario?.bio ?? 'Cusco';
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
      backgroundColor: PaletaRutas.ink,
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
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: PaletaRutas.marronOscuro,
                            ),
                          ),
                        ),
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
                color: PaletaRutas.ink,
                opacidadImagen: 0,
                opacidadVelo: 0,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PortadaPerfil(
                        avatarUrl: avatarUrl,
                        nombre: nombre,
                        bio: bio,
                        posts: misPosts.length,
                      ),
                      const SizedBox(height: 16),
                      _SelectorSeccionPerfil(
                        seccion: _seccion,
                        onCambiar: (s) => setState(() => _seccion = s),
                      ),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _seccion == _SeccionPerfil.perfil
                            ? const _ContenidoPerfil(
                                key: ValueKey('perfil'),
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

class _PortadaPerfil extends StatelessWidget {
  const _PortadaPerfil({
    required this.avatarUrl,
    required this.nombre,
    required this.bio,
    required this.posts,
  });

  final String avatarUrl;
  final String nombre;
  final String bio;
  final int posts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: Image.asset(
                      'public/image/fondoHaku.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'public/image/FONDO_HAKU2.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 14,
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/iconos/chacana.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Explorador HAKU',
                          style: TipografiaHaku.interfaz(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: -42,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AvatarHaku(
                  url: avatarUrl,
                  size: 84,
                  borderWidth: 3,
                  borderColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 52),
        Text(
          nombre,
          style: TipografiaHaku.titulo(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          bio,
          style: TipografiaHaku.interfaz(
            fontSize: 13,
            color: PaletaRutas.marronCuero,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: PaletaRutas.terracota.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: PaletaRutas.terracota.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            '$posts publicaciones · Cusco',
            style: TipografiaHaku.interfaz(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: PaletaRutas.terracota,
            ),
          ),
        ),
      ],
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
  const _ContenidoPerfil({super.key});

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
    final hilos = RutasDataSourceLocal.obtenerCultura();
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
              etiqueta: 'Publicaciones',
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
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'Insignias',
                style: TipografiaHaku.titulo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.marronOscuro,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _mostrarTodasInsignias(context, insignias),
              style: TextButton.styleFrom(
                foregroundColor: PaletaRutas.terracota,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Todas',
                style: TipografiaHaku.interfaz(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.terracota,
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
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Cultura',
                style: TipografiaHaku.titulo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.marronOscuro,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PantallaRutas(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: PaletaRutas.terracota,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Todas',
                style: TipografiaHaku.interfaz(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.terracota,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: hilos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final r = hilos[i];
              return _PedacitoCultura(
                ruta: r,
                indice: i,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PantallaDetalleRuta(ruta: r),
                    ),
                  );
                },
              );
            },
          ),
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
      descripcion: 'Explora el mapa',
      color: const Color(0xFF1A1A1A),
      desbloqueada: true,
    ),
    _InsigniaInfo(
      icono: Icons.grid_on_outlined,
      nombre: 'Tejedora',
      descripcion: '1 publicación',
      color: const Color(0xFF9C3B2E),
      desbloqueada: posts >= 1,
    ),
    _InsigniaInfo(
      icono: Icons.restaurant_outlined,
      nombre: 'Comida',
      descripcion: '1 lugar',
      color: const Color(0xFF6B4F1E),
      desbloqueada: lugares >= 1,
    ),
    _InsigniaInfo(
      icono: Icons.coffee_outlined,
      nombre: 'Alfarera',
      descripcion: 'Cerámica',
      color: const Color(0xFF1E4D6B),
      desbloqueada: rutas >= 1,
    ),
    _InsigniaInfo(
      icono: Icons.filter_hdr_rounded,
      nombre: 'Montañista',
      descripcion: '1 ruta guardada',
      color: const Color(0xFF2D6A4F),
      desbloqueada: rutas >= 1,
    ),
    _InsigniaInfo(
      icono: Icons.hiking_rounded,
      nombre: 'Aventurero',
      descripcion: '1 salida',
      color: const Color(0xFF9C3B2E),
      desbloqueada: salidas >= 1,
    ),
    _InsigniaInfo(
      icono: Icons.photo_camera_outlined,
      nombre: 'Fotógrafo',
      descripcion: '1 publicación',
      color: const Color(0xFF1E4D6B),
      desbloqueada: posts >= 1,
    ),
    _InsigniaInfo(
      icono: Icons.place_outlined,
      nombre: 'Cartógrafo',
      descripcion: '3 lugares',
      color: const Color(0xFF6B4F1E),
      desbloqueada: lugares >= 3,
    ),
    _InsigniaInfo(
      icono: Icons.people_outline,
      nombre: 'Conector',
      descripcion: '3 seguidos',
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
                'Insignias',
                style: TipografiaHaku.titulo(
                  fontSize: 17,
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
                            ? PaletaRutas.terracota
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
              'Todavía no hay nada',
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: urls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final grande = index == 0 && urls.length > 1;
        return ClipRRect(
          borderRadius: BorderRadius.circular(grande ? 14 : 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ImagenHaku(
              url: urls[index],
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}

class _PedacitoCultura extends StatelessWidget {
  const _PedacitoCultura({
    required this.ruta,
    required this.indice,
    required this.onTap,
  });

  final ModeloRuta ruta;
  final int indice;
  final VoidCallback onTap;

  static const _sombra = [
    Shadow(color: Color(0xB3000000), blurRadius: 5, offset: Offset(0, 1)),
  ];

  IconData get _icono {
    switch (ruta.hilo) {
      case HiloCultura.tejido:
        return Icons.grid_on_outlined;
      case HiloCultura.ceramica:
        return Icons.coffee_outlined;
      case HiloCultura.comida:
        return Icons.restaurant_outlined;
      case HiloCultura.teatro:
        return Icons.theater_comedy_outlined;
      case HiloCultura.pintura:
        return Icons.palette_outlined;
      case HiloCultura.camino:
        return Icons.route_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  FondosDetalleHaku.porIndice(indice),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Colors.black87),
                ),
                const ColoredBox(color: Color(0x7A000000)),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ImagenHaku(
                          url: ruta.imagenUrl,
                          height: 64,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(_icono, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ruta.hilo.etiqueta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TipografiaHaku.interfaz(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ).copyWith(shadows: _sombra),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        ruta.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.titulo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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
