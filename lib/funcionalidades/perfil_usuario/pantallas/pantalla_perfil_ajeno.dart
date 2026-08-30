import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/recursos/copy_haku.dart';
import '../../../nucleo/widgets/avatar_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../inicio/datos/feed_inicio_datasource_local.dart';
import '../../inicio/pantallas/pantalla_chat_directo.dart';
import '../../rutas/widgets/boton_fondo_textil.dart';
import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../dominio/modelos/perfil_publico.dart';
import '../widgets/insignia_perfil.dart';
import '../widgets/tarjeta_destino_sugerido.dart';
import '../widgets/tarjeta_estadistica_perfil.dart';

enum _SeccionPerfilAjeno { perfil, contenido }

/// Perfil de otra persona: mismo layout que Mi Viaje + Seguir / Chatear.
class PantallaPerfilAjeno extends ConsumerStatefulWidget {
  final PerfilPublico perfil;

  const PantallaPerfilAjeno({
    super.key,
    required this.perfil,
  });

  @override
  ConsumerState<PantallaPerfilAjeno> createState() =>
      _EstadoPantallaPerfilAjeno();
}

class _EstadoPantallaPerfilAjeno extends ConsumerState<PantallaPerfilAjeno> {
  _SeccionPerfilAjeno _seccion = _SeccionPerfilAjeno.perfil;
  bool _siguiendo = false;

  PerfilPublico get p => widget.perfil;

  Future<void> _seguir() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    setState(() => _siguiendo = !_siguiendo);
  }

  Future<void> _chatear() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaChatDirecto(
          persona: SugerenciaSeguimiento(
            id: p.id,
            nombre: p.nombre,
            usuario: p.usuario,
            avatarUrl: p.avatarUrl,
            bioCorta: p.bioCorta,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 24;

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
                          tooltip: 'Volver',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            p.nombre,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaHaku.titulo(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
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
                  padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CardExploradorAjeno(
                        avatarUrl: p.avatarUrl,
                        nombre: p.nombre,
                        usuario: p.usuario,
                        nivel: p.nivel,
                        xpActual: p.xpActual,
                        xpMeta: p.xpMeta,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: BotonFondoTextil(
                              texto: _siguiendo ? 'Siguiendo' : 'Seguir',
                              icono: _siguiendo
                                  ? Icons.check_rounded
                                  : Icons.person_add_alt_1_rounded,
                              onPressed: _seguir,
                              altura: 44,
                              radius: 12,
                              indiceFondo: 0,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _BotonAccionPerfil(
                              etiqueta: 'Chatear',
                              icono: Icons.chat_bubble_outline_rounded,
                              relleno: false,
                              onTap: _chatear,
                            ),
                          ),
                        ],
                      ),
                      if (p.bioCorta.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          p.bioCorta,
                          textAlign: TextAlign.center,
                          style: TipografiaHaku.interfaz(
                            fontSize: 13,
                            color: PaletaRutas.plomoClaro,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _SelectorSeccionAjeno(
                        seccion: _seccion,
                        onCambiar: (s) => setState(() => _seccion = s),
                      ),
                      const SizedBox(height: 22),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _seccion == _SeccionPerfilAjeno.perfil
                            ? _ContenidoPerfilAjeno(
                                key: const ValueKey('perfil'),
                                lugares: p.lugaresVisitados,
                                rutas: p.rutasCompletadas,
                                experiencias: p.experiencias,
                                insignias: p.insignias,
                                destinoTitulo: p.destinoSugeridoTitulo,
                                destinoUrl: p.destinoSugeridoUrl,
                              )
                            : _ContenidoPublicacionesAjeno(
                                key: const ValueKey('contenido'),
                                urls: p.publicacionesUrls,
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

class _CardExploradorAjeno extends StatelessWidget {
  final String avatarUrl;
  final String nombre;
  final String usuario;
  final int nivel;
  final int xpActual;
  final int xpMeta;

  const _CardExploradorAjeno({
    required this.avatarUrl,
    required this.nombre,
    required this.usuario,
    required this.nivel,
    required this.xpActual,
    required this.xpMeta,
  });

  @override
  Widget build(BuildContext context) {
    final progreso = xpMeta == 0 ? 0.0 : (xpActual / xpMeta).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          AvatarHaku(url: avatarUrl, size: 72),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TipografiaHaku.titulo(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.piedra,
                  ),
                ),
                Text(
                  '$usuario · Nivel $nivel',
                  style: TipografiaHaku.interfaz(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progreso,
                          minHeight: 10,
                          backgroundColor: PaletaRutas.plomoOscuro.withValues(
                            alpha: 0.5,
                          ),
                          color: PaletaRutas.oro,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$xpActual / $xpMeta XP',
                      style: TipografiaHaku.interfaz(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
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

class _BotonAccionPerfil extends StatelessWidget {
  final String etiqueta;
  final IconData icono;
  final bool relleno;
  final VoidCallback onTap;

  const _BotonAccionPerfil({
    required this.etiqueta,
    required this.icono,
    required this.relleno,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 44,
          decoration: BoxDecoration(
            color: relleno
                ? PaletaRutas.oro
                : PaletaRutas.carbon,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: relleno
                  ? PaletaRutas.oro
                  : PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
              width: 1.1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icono,
                size: 18,
                color: relleno ? PaletaRutas.ink : PaletaRutas.piedra,
              ),
              const SizedBox(width: 6),
              Text(
                etiqueta,
                style: TipografiaHaku.interfaz(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: relleno ? PaletaRutas.ink : PaletaRutas.piedra,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorSeccionAjeno extends StatelessWidget {
  final _SeccionPerfilAjeno seccion;
  final ValueChanged<_SeccionPerfilAjeno> onCambiar;

  const _SelectorSeccionAjeno({
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
            seleccionado: seccion == _SeccionPerfilAjeno.perfil,
            tooltip: 'Perfil',
            onTap: () => onCambiar(_SeccionPerfilAjeno.perfil),
          ),
        ),
        Expanded(
          child: _IconoSeccion(
            icono: Icons.grid_on_rounded,
            seleccionado: seccion == _SeccionPerfilAjeno.contenido,
            tooltip: 'Contenido',
            onTap: () => onCambiar(_SeccionPerfilAjeno.contenido),
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
        : PaletaRutas.plomo;

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

class _ContenidoPerfilAjeno extends StatelessWidget {
  final String lugares;
  final String rutas;
  final String experiencias;
  final String insignias;
  final String destinoTitulo;
  final String destinoUrl;

  const _ContenidoPerfilAjeno({
    super.key,
    required this.lugares,
    required this.rutas,
    required this.experiencias,
    required this.insignias,
    required this.destinoTitulo,
    required this.destinoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TarjetaEstadisticaPerfil(
              icono: Icons.account_balance_outlined,
              valor: lugares,
              etiqueta: 'Lugares',
              indice: 0,
            ),
            const SizedBox(width: 8),
            TarjetaEstadisticaPerfil(
              icono: Icons.explore_outlined,
              valor: rutas,
              etiqueta: 'Rutas',
              indice: 1,
            ),
            const SizedBox(width: 8),
            TarjetaEstadisticaPerfil(
              icono: Icons.menu_book_outlined,
              valor: experiencias,
              etiqueta: 'Publicaciones',
              indice: 2,
            ),
            const SizedBox(width: 8),
            TarjetaEstadisticaPerfil(
              icono: Icons.military_tech_outlined,
              valor: insignias,
              etiqueta: 'Insignias',
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
                  color: PaletaRutas.piedra,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: PaletaRutas.carbon,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  builder: (ctx) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Insignias',
                          style: TipografiaHaku.titulo(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            InsigniaPerfil(
                              icono: Icons.terrain_rounded,
                              nombre: CopyHaku.insigniaVecinoMapa,
                              colorFondo: Color(0xFF1A1A1A),
                            ),
                            InsigniaPerfil(
                              icono: Icons.filter_hdr_rounded,
                              nombre: 'Montañista',
                              colorFondo: Color(0xFF2D6A4F),
                            ),
                            InsigniaPerfil(
                              icono: Icons.hiking_rounded,
                              nombre: 'Aventurero',
                              colorFondo: Color(0xFF9C3B2E),
                            ),
                            InsigniaPerfil(
                              icono: Icons.photo_camera_outlined,
                              nombre: 'Fotógrafo',
                              colorFondo: Color(0xFF1E4D6B),
                            ),
                            InsigniaPerfil(
                              icono: Icons.restaurant_outlined,
                              nombre: 'Gourmet Andino',
                              colorFondo: Color(0xFF6B4226),
                            ),
                            InsigniaPerfil(
                              icono: Icons.nightlight_round,
                              nombre: 'Nocturno',
                              colorFondo: Color(0xFF2C2C54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: PaletaRutas.oro,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Todas',
                style: TipografiaHaku.interfaz(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.oro,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: FondosDetalleHaku.tarjeta(indice: 1),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InsigniaPerfil(
                icono: Icons.terrain_rounded,
                nombre: CopyHaku.insigniaVecinoMapa,
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
        const SizedBox(height: 20),
        TarjetaDestinoSugerido(
          titulo: destinoTitulo,
          rating: 4.9,
          resenas: 856,
          imagenUrl: destinoUrl,
          indice: 0,
        ),
      ],
    );
  }
}

class _ContenidoPublicacionesAjeno extends StatelessWidget {
  final List<String> urls;

  const _ContenidoPublicacionesAjeno({super.key, required this.urls});

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
              color: PaletaRutas.plomo,
            ),
            const SizedBox(height: 12),
            Text(
              'Sin publicaciones',
              style: TipografiaHaku.interfaz(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: PaletaRutas.plomoClaro,
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
              color: PaletaRutas.carbon.withValues(alpha: 0.35),
            ),
            errorWidget: (_, __, ___) => ColoredBox(
              color: PaletaRutas.carbon.withValues(alpha: 0.5),
              child: const Icon(
                Icons.broken_image_outlined,
                color: PaletaRutas.plomo,
              ),
            ),
          ),
        );
      },
    );
  }
}
