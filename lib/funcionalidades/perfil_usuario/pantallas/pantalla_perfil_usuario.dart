import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/recursos/copy_haku.dart';
import '../../../nucleo/responsive/espacio_haku.dart';
import '../../../nucleo/widgets/avatar_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../comunidad/dominio/modelo_publicacion.dart';
import '../../comunidad/pantallas/pantalla_detalle_salida_remota.dart';
import '../../favoritos/indice.dart';
import '../../lugares/navegacion_lugar.dart';
import '../../lugares/proveedores/proveedor_explora_ui.dart';
import '../../rutas/datos/rutas_datasource_local.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/pantallas/pantalla_detalle_ruta.dart';
import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../proveedores/proveedor_aportaciones_perfil.dart';
import '../widgets/insignia_perfil.dart';
import '../widgets/sheet_lista_perfil.dart';
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

  _SeccionPerfil _seccion = _SeccionPerfil.perfil;

  @override
  Widget build(BuildContext context) {
    final bottomPad = EspacioHaku.bottomNavClearance(context);
    final padH = EspacioHaku.horizontal(context);
    final sesion = ref.watch(sesionProvider);
    final aportacionesAsync = ref.watch(aportacionesPerfilProvider);
    final aportaciones =
        aportacionesAsync.valueOrNull ?? const AportacionesPerfil();
    final nombre = sesion.usuario?.nombreUsuario ?? 'Explorador';
    final avatarUrl = sesion.usuario?.avatarUrl ?? _avatarUrl;
    final bio = sesion.usuario?.bio ?? 'Cusco';
    final misPosts = aportaciones.publicaciones;

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
                            color: PaletaRutas.piedra,
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
                            color: PaletaRutas.piedra,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Perfil',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaHaku.titulo(
                              fontSize: EspacioHaku.sp(context, 20),
                              fontWeight: FontWeight.w800,
                              color: PaletaRutas.piedra,
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
                  padding: EdgeInsets.fromLTRB(padH, 12, padH, bottomPad),
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
                            ? _ContenidoPerfil(
                                key: const ValueKey('perfil'),
                                aportaciones: aportaciones,
                                cargando: aportacionesAsync.isLoading &&
                                    !aportacionesAsync.hasValue,
                              )
                            : _ContenidoPublicaciones(
                                key: const ValueKey('contenido'),
                                publicaciones: misPosts,
                                cargando: aportacionesAsync.isLoading &&
                                    !aportacionesAsync.hasValue,
                              ),
                      ),
                      if (sesion.autenticado) ...[
                        const SizedBox(height: 28),
                        Material(
                          color: PaletaRutas.carbon,
                          borderRadius: BorderRadius.circular(14),
                          child: ListTile(
                            onTap: () async {
                              await ref
                                  .read(sesionProvider.notifier)
                                  .cerrarSesion();
                            },
                            leading: const Icon(
                              Icons.logout_rounded,
                              color: PaletaRutas.piedra,
                            ),
                            title: Text(
                              'Cerrar sesión',
                              style: TipografiaHaku.interfaz(
                                fontWeight: FontWeight.w700,
                                color: PaletaRutas.piedra,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: PaletaRutas.plomo,
                            ),
                          ),
                        ),
                      ],
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
    final horizontal = EspacioHaku.esHorizontal(context);
    final altoPortada = horizontal ? 88.0 : 140.0;
    final avatarSize = horizontal ? 56.0 : 84.0;

    final portada = ClipRRect(
      borderRadius: BorderRadius.circular(horizontal ? 16 : 20),
      child: SizedBox(
        height: altoPortada,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'public/image/fondoHaku.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'public/image/FONDO_HAKU2.png',
                fit: BoxFit.cover,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PaletaRutas.ink.withValues(alpha: 0.05),
                    PaletaRutas.ink.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: PaletaRutas.piedra, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: PaletaRutas.ink.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AvatarHaku(
        url: avatarUrl,
        size: avatarSize,
        borderWidth: 0,
        borderColor: Colors.transparent,
      ),
    );

    final info = Column(
      crossAxisAlignment:
          horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TipografiaHaku.titulo(
            fontSize: EspacioHaku.sp(context, horizontal ? 18 : 24),
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          bio,
          maxLines: horizontal ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: TipografiaHaku.interfaz(
            fontSize: 13,
            color: PaletaRutas.plomoClaro,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: PaletaRutas.oro.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: PaletaRutas.oro.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            '$posts publicaciones · Cusco',
            style: TipografiaHaku.interfaz(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: PaletaRutas.oro,
            ),
          ),
        ),
      ],
    );

    // Landscape: avatar + info centrados (no pegados a un borde).
    if (horizontal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          portada,
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  avatar,
                  const SizedBox(width: 14),
                  Expanded(child: info),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            portada,
            Positioned(bottom: -avatarSize / 2, child: avatar),
          ],
        ),
        SizedBox(height: avatarSize / 2 + 12),
        info,
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
        ? PaletaRutas.oro
        : PaletaRutas.plomoClaro;

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
                    ? PaletaRutas.oro
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
  const _ContenidoPerfil({
    super.key,
    required this.aportaciones,
    this.cargando = false,
  });

  final AportacionesPerfil aportaciones;
  final bool cargando;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nPosts = aportaciones.nPublicaciones;
    final nRutas = aportaciones.nRutas;
    final nLugares = aportaciones.nLugares;
    final nSalidas = aportaciones.nSalidas;
    final hilos = RutasDataSourceLocal.obtenerCultura();
    final insignias = _insigniasDesde(
      posts: nPosts,
      rutas: nRutas,
      lugares: nLugares,
      salidas: nSalidas,
      siguiendo: 0,
    );

    void sheetLugares() {
      mostrarSheetListaPerfil(
        context,
        titulo: 'Mis lugares ($nLugares)',
        vacio: 'Todavía no registraste lugares. Empezá en Explora.',
        iconoVacio: Icons.place_outlined,
        items: [
          for (final l in aportaciones.lugares)
            ItemListaPerfil(
              titulo: l.nombre,
              subtitulo: l.subtituloClasificacion,
              onTap: () => abrirDetalleLugar(context, l.id),
            ),
        ],
      );
    }

    void sheetRutas() {
      mostrarSheetListaPerfil(
        context,
        titulo: 'Mis rutas',
        vacio:
            'Todavía no hay rutas propias en Haku. Pronto vas a poder crearlas acá.',
        iconoVacio: Icons.route_outlined,
        items: const [],
      );
    }

    void sheetPosts() {
      mostrarSheetListaPerfil(
        context,
        titulo: 'Mis publicaciones ($nPosts)',
        vacio: 'Sin publicaciones todavía. Comenzá tu aventura.',
        iconoVacio: Icons.photo_camera_outlined,
        items: [
          for (final p in aportaciones.publicaciones)
            ItemListaPerfil(
              titulo: p.contenido.trim().isEmpty
                  ? 'Publicación'
                  : (p.contenido.length > 80
                      ? '${p.contenido.substring(0, 80)}…'
                      : p.contenido),
              subtitulo: p.hace,
            ),
        ],
      );
    }

    void sheetSalidas() {
      mostrarSheetListaPerfil(
        context,
        titulo: 'Mis salidas ($nSalidas)',
        vacio: 'Todavía no organizaste salidas. Creá una desde Comunidad.',
        iconoVacio: Icons.hiking,
        items: [
          for (final s in aportaciones.salidas)
            ItemListaPerfil(
              titulo: s.etiquetaPrincipal,
              subtitulo: s.fechaHoraEtiqueta,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PantallaDetalleSalidaRemota(salidaId: s.id),
                  ),
                );
              },
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cargando)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(
              minHeight: 2,
              color: PaletaRutas.oro,
              backgroundColor: PaletaRutas.carbon,
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TarjetaEstadisticaPerfil(
              icono: Icons.place_outlined,
              valor: '$nLugares',
              etiqueta: 'Lugares',
              indice: 0,
              onTap: sheetLugares,
            ),
            const SizedBox(width: 8),
            TarjetaEstadisticaPerfil(
              icono: Icons.route_outlined,
              valor: '$nRutas',
              etiqueta: 'Rutas',
              indice: 1,
              onTap: sheetRutas,
            ),
            const SizedBox(width: 8),
            TarjetaEstadisticaPerfil(
              icono: Icons.photo_camera_outlined,
              valor: '$nPosts',
              etiqueta: 'Publicaciones',
              indice: 2,
              onTap: sheetPosts,
            ),
            const SizedBox(width: 8),
            TarjetaEstadisticaPerfil(
              icono: Icons.hiking,
              valor: '$nSalidas',
              etiqueta: 'Salidas',
              indice: 3,
              onTap: sheetSalidas,
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
                  color: PaletaRutas.piedra,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _mostrarTodasInsignias(context, insignias),
              style: TextButton.styleFrom(
                foregroundColor: PaletaRutas.oro,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Todas',
                style: TipografiaHaku.interfaz(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.oro,
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
          decoration: BoxDecoration(
            color: PaletaRutas.carbon,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: PaletaRutas.plomo.withValues(alpha: 0.28),
            ),
          ),
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
                      : PaletaRutas.plomoOscuro,
                  bloqueada: !insignias[i].desbloqueada,
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
                  color: PaletaRutas.piedra,
                ),
              ),
            ),
            TextButton(
              onPressed: () => irAExplora(ref, modo: ModoExplora.rutas),
              style: TextButton.styleFrom(
                foregroundColor: PaletaRutas.oro,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Todas',
                style: TipografiaHaku.interfaz(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.oro,
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
      nombre: CopyHaku.insigniaVecinoMapa,
      descripcion: CopyHaku.insigniaVecinoMapaDesc,
      color: const Color(0xFF3D2B1F),
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
      descripcion: 'CerÃ¡mica',
      color: const Color(0xFF1E4D6B),
      desbloqueada: rutas >= 1,
    ),
    _InsigniaInfo(
      icono: Icons.filter_hdr_rounded,
      nombre: 'MontaÃ±ista',
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
      nombre: 'FotÃ³grafo',
      descripcion: '1 publicación',
      color: const Color(0xFF1E4D6B),
      desbloqueada: posts >= 1,
    ),
    _InsigniaInfo(
      icono: Icons.place_outlined,
      nombre: 'CartÃ³grafo',
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
    backgroundColor: PaletaRutas.carbon,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      final maxH = MediaQuery.sizeOf(ctx).height * 0.62;
      return SafeArea(
        child: SizedBox(
          height: maxH,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: PaletaRutas.plomoOscuro,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Insignias',
                  style: TipografiaHaku.titulo(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.piedra,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Se van desbloqueando con lo que aportás en Haku.',
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: insignias.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final i = insignias[index];
                      return Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: i.desbloqueada
                                ? i.color
                                : PaletaRutas.plomoOscuro,
                            child: Icon(
                              i.icono,
                              color: i.desbloqueada
                                  ? PaletaRutas.piedra
                                  : PaletaRutas.plomo,
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
                                        ? PaletaRutas.piedra
                                        : PaletaRutas.plomo,
                                  ),
                                ),
                                Text(
                                  i.descripcion,
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 12,
                                    color: PaletaRutas.plomoClaro,
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
                                ? PaletaRutas.oro
                                : PaletaRutas.plomo,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ContenidoPublicaciones extends StatelessWidget {
  final List<ModeloPublicacionRemota> publicaciones;
  final bool cargando;

  const _ContenidoPublicaciones({
    super.key,
    required this.publicaciones,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    if (cargando && publicaciones.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: PaletaRutas.oro),
        ),
      );
    }

    if (publicaciones.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: PaletaRutas.carbon,
                shape: BoxShape.circle,
                border: Border.all(
                  color: PaletaRutas.oro.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                Icons.photo_camera_outlined,
                size: 32,
                color: PaletaRutas.oro.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              CopyHaku.perfilSinPublicaciones,
              textAlign: TextAlign.center,
              style: TipografiaHaku.titulo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CopyHaku.perfilSinPublicacionesSub,
              textAlign: TextAlign.center,
              style: TipografiaHaku.interfaz(
                fontSize: 13,
                height: 1.35,
                color: PaletaRutas.plomoClaro,
              ),
            ),
          ],
        ),
      );
    }

    // Mosaico estable (evita overflow del card completo en GridView).
    final cols = EspacioHaku.esHorizontal(context) ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: publicaciones.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) {
        return _CeldaPublicacionPerfil(publicacion: publicaciones[i]);
      },
    );
  }
}

/// Celda tipo álbum: imagen o texto corto. Sin overflow.
class _CeldaPublicacionPerfil extends StatelessWidget {
  const _CeldaPublicacionPerfil({required this.publicacion});

  final ModeloPublicacionRemota publicacion;

  void _abrirDetalle(BuildContext context) {
    final p = publicacion;
    final imagen = p.imagenUrl?.trim() ?? '';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PaletaRutas.carbon,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.72;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: PaletaRutas.plomoOscuro,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (imagen.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ImagenHaku(url: imagen, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    p.hace,
                    style: TipografiaHaku.interfaz(
                      fontSize: 11,
                      color: PaletaRutas.plomoClaro,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.contenido.trim().isEmpty ? 'Publicación' : p.contenido,
                    style: TipografiaHaku.interfaz(
                      fontSize: 14,
                      height: 1.4,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  if (p.lugarNombre != null &&
                      p.lugarNombre!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      p.lugarNombre!,
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.oro,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagen = publicacion.imagenUrl?.trim() ?? '';
    return Material(
      color: PaletaRutas.carbon,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirDetalle(context),
        child: imagen.isNotEmpty
            ? ImagenHaku(url: imagen, fit: BoxFit.cover)
            : Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 18,
                      color: PaletaRutas.oro.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        publicacion.contenido.trim().isEmpty
                            ? 'Sin texto'
                            : publicacion.contenido,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          height: 1.3,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
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

  static final _sombra = [
    Shadow(
      color: PaletaRutas.ink.withValues(alpha: 0.75),
      blurRadius: 5,
      offset: const Offset(0, 1),
    ),
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
    return SizedBox(
      width: 148,
      height: 168,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  FondosDetalleHaku.porIndice(indice),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: PaletaRutas.carbon),
                ),
                ColoredBox(
                  color: PaletaRutas.ink.withValues(alpha: 0.48),
                ),
                // Contorno suave, mismo lenguaje que las stats.
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: PaletaRutas.plomo.withValues(alpha: 0.35),
                    ),
                  ),
                ),
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
                          Icon(_icono, size: 14, color: PaletaRutas.oro),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ruta.hilo.etiqueta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TipografiaHaku.interfaz(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: PaletaRutas.plomoClaro,
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
                          color: PaletaRutas.piedra,
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
