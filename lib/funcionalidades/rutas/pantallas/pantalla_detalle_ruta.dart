import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dominio/modelos/modelo_ruta.dart';
import '../widgets/boton_primario_ruta.dart';
import '../widgets/decoracion_detalle_fondo.dart';
import '../widgets/estilos_rutas.dart';
import '../widgets/imagen_parallax_ruta.dart';
import '../widgets/linea_encabezado_inca.dart';

/// Detalle de una ruta: hero circular + ficha blanca + adorno inferior.
class PantallaDetalleRuta extends StatefulWidget {
  final ModeloRuta ruta;

  const PantallaDetalleRuta({super.key, required this.ruta});

  @override
  State<PantallaDetalleRuta> createState() => _EstadoPantallaDetalleRuta();
}

class _EstadoPantallaDetalleRuta extends State<PantallaDetalleRuta> {
  static const _alturaHero = 300.0;
  static const _adorno = 'public/image/adorno_detalle_ruta.jpg';

  final ScrollController _scroll = ScrollController();
  bool _favorito = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double get _offset => _scroll.hasClients ? _scroll.offset : 0.0;

  @override
  Widget build(BuildContext context) {
    final ruta = widget.ruta;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
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
                      color: Colors.white,
                      child: Stack(
                        children: [
                          // Fondo decorativo con transparencia.
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
                              48 + bottomInset,
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
                                      color: PaletaRutas.marronCuero,
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
                                        color: PaletaRutas.terracota,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        ruta.calificacion.toStringAsFixed(1),
                                        style: TipografiaHaku.interfaz(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '(${ruta.cantidadResenas} reseñas)',
                                        style: TipografiaHaku.interfaz(
                                          fontSize: 12,
                                          color: PaletaRutas.marronCuero,
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
                                            color: PaletaRutas.pergamino,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color:
                                                  PaletaRutas.beigeEnvejecido,
                                            ),
                                          ),
                                          child: Text(
                                            ruta.tipoSitio!,
                                            style: TipografiaHaku.interfaz(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: PaletaRutas.verdeBosque,
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
                                            color: PaletaRutas.verdeOliva,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            tag,
                                            style: TipografiaHaku.interfaz(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: PaletaRutas.marronCuero,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.78),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Descripcion',
                                        style: TipografiaHaku.titulo(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        ruta.descripcion,
                                        style: TipografiaHaku.interfaz(
                                          fontSize: 14,
                                          height: 1.45,
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                      if (ruta.distancia.isNotEmpty) ...[
                                        const SizedBox(height: 14),
                                        Text(
                                          'Distancia: ${ruta.distancia}',
                                          style: TipografiaHaku.interfaz(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  'Informacion util',
                                  style: TipografiaHaku.titulo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _GrillaInfo(ruta: ruta),
                                const SizedBox(height: 28),
                                BotonPrimarioRuta(
                                  texto: ruta.textoBoton,
                                  icono: Icons.map_outlined,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${ruta.textoBoton}: ${ruta.titulo}',
                                          style: TipografiaHaku.interfaz(
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: Colors.black,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
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

            Positioned(
              top: topInset + 8,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BotonCircular(
                    icono: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  Row(
                    children: [
                      _BotonCircular(
                        icono: _favorito
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        colorIcono: _favorito
                            ? PaletaRutas.terracota
                            : PaletaRutas.marronOscuro,
                        onTap: () => setState(() => _favorito = !_favorito),
                      ),
                      const SizedBox(width: 8),
                      _BotonCircular(
                        icono: Icons.ios_share_rounded,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Compartir ${ruta.titulo}',
                                style: TipografiaHaku.interfaz(
                                  color: PaletaRutas.crema,
                                ),
                              ),
                              backgroundColor: PaletaRutas.verdeBosque,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
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
          'Tiempo de caminata',
          ruta.tiempoCaminata,
        ),
      _InfoItem(Icons.trending_up_rounded, 'Dificultad', ruta.dificultadTexto),
      if (ruta.mejorEpoca.isNotEmpty)
        _InfoItem(
          Icons.calendar_month_outlined,
          'Mejor época',
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
              errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.62),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icono, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.etiqueta,
                        style: TipografiaHaku.interfaz(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.valor,
                        style: TipografiaHaku.interfaz(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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

  const _BotonCircular({
    required this.icono,
    required this.onTap,
    this.colorIcono = PaletaRutas.marronOscuro,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.35),
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
            border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.55),
            ),
            child: Icon(
              icono,
              size: 18,
              color: colorIcono == PaletaRutas.terracota
                  ? PaletaRutas.terracota
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
