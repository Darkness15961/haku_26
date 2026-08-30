import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../lugares/widgets/lista_experiencias_lugar.dart';
import '../dominio/modelos/modelo_ruta.dart';
import '../widgets/decoracion_detalle_fondo.dart';
import '../widgets/estilos_rutas.dart';
import '../widgets/imagen_parallax_ruta.dart';
import '../widgets/linea_encabezado_inca.dart';
import '../widgets/boton_icono_accion.dart';
import '../widgets/menu_acciones_ruta.dart';

/// Detalle de una ruta: hero + ficha + aporte a la comunidad.
class PantallaDetalleRuta extends ConsumerStatefulWidget {
  final ModeloRuta ruta;

  const PantallaDetalleRuta({super.key, required this.ruta});

  @override
  ConsumerState<PantallaDetalleRuta> createState() =>
      _EstadoPantallaDetalleRuta();
}

class _EstadoPantallaDetalleRuta extends ConsumerState<PantallaDetalleRuta> {
  static const _alturaHero = 300.0;
  static const _adorno = 'public/image/adorno_detalle_ruta.jpg';

  final ScrollController _scroll = ScrollController();
  bool _menuAbierto = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double get _offset => _scroll.hasClients ? _scroll.offset : 0.0;

  Future<void> _toggleFavorito() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await ref
        .read(almacenFeedProvider.notifier)
        .toggleFavoritoRuta(widget.ruta.id);
  }

  void _avisar(String mensaje) {
    mostrarSnackHaku(context, mensaje, destacado: true);
  }

  @override
  Widget build(BuildContext context) {
    final ruta = widget.ruta;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final favorito =
        ref.watch(almacenFeedProvider).favoritosRutaIds.contains(ruta.id);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: PaletaRutas.ink,
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: _alturaHero,
                    child: RepaintBoundary(
                      child: ListenableBuilder(
                        listenable: _scroll,
                        builder: (context, _) {
                          return ImagenParallaxRuta(
                            imagenUrl: ruta.imagenUrl,
                            altura: _alturaHero,
                            scrollOffset: _offset,
                            factorParallax: 1.0,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -28),
                    child: ColoredBox(
                      color: PaletaRutas.ink,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.16,
                              child: Image.asset(
                                _adorno,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              22,
                              36,
                              22,
                              100 + bottomInset,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  ruta.titulo,
                                  textAlign: TextAlign.center,
                                  style: TipografiaHaku.titulo(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: PaletaRutas.piedra,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const LineaEncabezadoInca(altura: 2),
                                if (ruta.subtitulo.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    ruta.subtitulo,
                                    textAlign: TextAlign.center,
                                    style: TipografiaHaku.interfaz(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: PaletaRutas.plomoClaro,
                                    ),
                                  ),
                                ],
                                if (ruta.calificacion > 0) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 18,
                                        color: PaletaRutas.oro,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        ruta.calificacion.toStringAsFixed(1),
                                        style: TipografiaHaku.interfaz(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: PaletaRutas.piedra,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '(${ruta.cantidadResenas})',
                                        style: TipografiaHaku.interfaz(
                                          fontSize: 12,
                                          color: PaletaRutas.plomoClaro,
                                        ),
                                      ),
                                      if (ruta.tipoSitio != null) ...[
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: PaletaRutas.carbon,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: PaletaRutas.plomoOscuro
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                          child: Text(
                                            ruta.tipoSitio!,
                                            style: TipografiaHaku.interfaz(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: PaletaRutas.oro,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                                if (ruta.etiquetas.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 18,
                                    runSpacing: 10,
                                    children: ruta.etiquetas.map((tag) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _iconoEtiqueta(tag),
                                            size: 22,
                                            color: PaletaRutas.oro,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            tag,
                                            style: TipografiaHaku.interfaz(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: PaletaRutas.plomoClaro,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                if (ruta.comoLlegar.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: PaletaRutas.carbon,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: PaletaRutas.plomo.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Acceso',
                                          style: TipografiaHaku.titulo(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: PaletaRutas.piedra,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          ruta.comoLlegar,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TipografiaHaku.interfaz(
                                            fontSize: 13,
                                            color: PaletaRutas.plomoClaro,
                                          ),
                                        ),
                                        if (ruta.puntos.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            '${ruta.puntos.length} paradas',
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
                                  const SizedBox(height: 16),
                                ],
                                // Descripción en pergamino (más legible, mismo estilo).
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: PaletaRutas.carbon,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: PaletaRutas.plomoOscuro
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Descripción',
                                        style: TipografiaHaku.titulo(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: PaletaRutas.piedra,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        ruta.descripcion,
                                        style: TipografiaHaku.interfaz(
                                          fontSize: 14,
                                          height: 1.45,
                                          color: PaletaRutas.plomoClaro,
                                        ),
                                      ),
                                      if (ruta.distancia.isNotEmpty) ...[
                                        const SizedBox(height: 14),
                                        Text(
                                          ruta.distancia,
                                          style: TipografiaHaku.interfaz(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: PaletaRutas.oro,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 22),
                                _GrillaInfo(ruta: ruta),
                                const SizedBox(height: 24),
                                Text(
                                  'Experiencias',
                                  style: TipografiaHaku.titulo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: PaletaRutas.piedra,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lo que compartieron exploradores solos o en grupo',
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 12,
                                    color: PaletaRutas.plomoClaro,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ListaExperienciasLugar(rutaId: ruta.id),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Positioned.fill(
              child: VeloAccionesFlotante(
                visible: _menuAbierto,
                onTap: () => setState(() => _menuAbierto = false),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 16 + bottomInset,
              child: MenuAccionesRuta(
                ruta: ruta,
                abierto: _menuAbierto,
                onToggle: () => setState(() => _menuAbierto = !_menuAbierto),
                onCerrar: () => setState(() => _menuAbierto = false),
              ),
            ),

            Positioned(
              top: topInset + 8,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BotonCircular(
                    tooltip: 'Volver',
                    icono: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  Row(
                    children: [
                      _BotonCircular(
                        tooltip: favorito
                            ? 'Quitar de guardados'
                            : 'Guardar ruta',
                        icono: favorito
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        colorIcono: favorito
                            ? PaletaRutas.oro
                            : PaletaRutas.piedra,
                        onTap: _toggleFavorito,
                      ),
                      const SizedBox(width: 8),
                      _BotonCircular(
                        tooltip: 'Compartir',
                        icono: Icons.ios_share_rounded,
                        onTap: () => _avisar('Compartido'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconoEtiqueta(String tag) {
    final t = tag.toLowerCase();
    if (t.contains('natur')) return Icons.park_outlined;
    if (t.contains('avent')) return Icons.hiking;
    if (t.contains('foto')) return Icons.photo_camera_outlined;
    if (t.contains('hist') || t.contains('arque')) {
      return Icons.account_balance_outlined;
    }
    if (t.contains('trek') || t.contains('mont')) return Icons.terrain;
    if (t.contains('cult')) return Icons.museum_outlined;
    return Icons.explore_outlined;
  }
}

class _GrillaInfo extends StatelessWidget {
  final ModeloRuta ruta;

  const _GrillaInfo({required this.ruta});

  @override
  Widget build(BuildContext context) {
    final items = <_InfoItem>[
      if (ruta.altitud.isNotEmpty)
        _InfoItem(Icons.landscape_outlined, 'Altitud', ruta.altitud),
      if (ruta.tiempoCaminata.isNotEmpty)
        _InfoItem(
          Icons.timer_outlined,
          'Tiempo',
          ruta.tiempoCaminata,
        ),
      _InfoItem(Icons.trending_up_rounded, 'Dificultad', ruta.dificultadTexto),
      if (ruta.mejorEpoca.isNotEmpty)
        _InfoItem(
          Icons.calendar_month_outlined,
          'Época',
          ruta.mejorEpoca,
        ),
    ];

    return Column(
      children: [
        for (var i = 0; i < items.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < items.length ? 12 : 0),
            child: Row(
              children: [
                Expanded(
                  child: _InfoItemCard(item: items[i], indice: i),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < items.length
                      ? _InfoItemCard(item: items[i + 1], indice: i + 1)
                      : const SizedBox(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoItem {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _InfoItem(this.icono, this.etiqueta, this.valor);
}

class _InfoItemCard extends StatelessWidget {
  final _InfoItem item;
  final int indice;

  const _InfoItemCard({required this.item, required this.indice});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              FondosDetalleHaku.porIndice(indice),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: PaletaRutas.carbon),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: PaletaRutas.ink.withValues(alpha: 0.68),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: PaletaRutas.plomo.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icono, size: 20, color: PaletaRutas.oro),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.etiqueta,
                        style: TipografiaHaku.interfaz(
                          fontSize: 11,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.valor,
                        style: TipografiaHaku.interfaz(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ],
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

class _BotonCircular extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;
  final Color colorIcono;
  final String tooltip;

  const _BotonCircular({
    required this.icono,
    required this.onTap,
    required this.tooltip,
    this.colorIcono = PaletaRutas.piedra,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: PaletaRutas.ink.withValues(alpha: 0.35),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: AssetImage(FondosDetalleHaku.fondoA),
                fit: BoxFit.cover,
              ),
              border: Border.all(
                color: PaletaRutas.plomo.withValues(alpha: 0.45),
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PaletaRutas.ink.withValues(alpha: 0.55),
              ),
              child: Icon(
                icono,
                size: 18,
                color: colorIcono == PaletaRutas.oro
                    ? PaletaRutas.oro
                    : PaletaRutas.piedra,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
