import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';

/// Portada editorial de Inicio — carrusel hero + hilos + spotlight.
class PortadaInicioCultura extends StatefulWidget {
  const PortadaInicioCultura({
    super.key,
    required this.rutas,
    required this.destacada,
    this.onDestacada,
    this.onHilo,
  });

  final List<ModeloRuta> rutas;
  final ModeloRuta? destacada;
  final VoidCallback? onDestacada;
  final ValueChanged<HiloCultura>? onHilo;

  @override
  State<PortadaInicioCultura> createState() => _EstadoPortadaInicioCultura();
}

class _EstadoPortadaInicioCultura extends State<PortadaInicioCultura> {
  late final PageController _pageController;
  Timer? _autoTimer;
  int _pagina = 0;

  static const _hilos = [
    (HiloCultura.tejido, Icons.grid_on_outlined, 'Tejido'),
    (HiloCultura.ceramica, Icons.coffee_outlined, 'Cerámica'),
    (HiloCultura.comida, Icons.restaurant_outlined, 'Fogón'),
    (HiloCultura.teatro, Icons.theater_comedy_outlined, 'Teatro'),
    (HiloCultura.pintura, Icons.palette_outlined, 'Pintura'),
  ];

  List<ModeloRuta> get _slides {
    if (widget.rutas.isNotEmpty) return widget.rutas;
    if (widget.destacada != null) return [widget.destacada!];
    return const [];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _iniciarAuto();
  }

  void _iniciarAuto() {
    _autoTimer?.cancel();
    if (_slides.length < 2) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_pagina + 1) % _slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    final fallback = CatalogoImagenesHaku.respaldo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (slides.isEmpty)
                    ImagenHaku(url: fallback, fit: BoxFit.cover)
                  else
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _pagina = i),
                      itemCount: slides.length,
                      itemBuilder: (_, i) {
                        return ImagenHaku(
                          url: slides[i].imagenUrl,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.78),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/iconos/chacana.svg',
                              width: 22,
                              height: 22,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'CUSCO VIVO',
                              style: TipografiaHaku.interfaz(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withValues(alpha: 0.92),
                                letterSpacing: 1.4,
                              ),
                            ),
                            const Spacer(),
                            if (slides.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: PaletaRutas.terracota
                                      .withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  slides[_pagina.clamp(0, slides.length - 1)]
                                      .hilo
                                      .etiqueta
                                      .toUpperCase(),
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          slides.isEmpty
                              ? 'Documenta la cultura\ncon la comunidad'
                              : slides[_pagina.clamp(0, slides.length - 1)]
                                  .titulo,
                          style: TipografiaHaku.titulo(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          slides.isEmpty
                              ? 'Tejido · Cerámica · Fogón · Teatro · Pintura'
                              : slides[_pagina.clamp(0, slides.length - 1)]
                                  .subtitulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                        if (slides.length > 1) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(slides.length, (i) {
                              final activo = i == _pagina;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: activo ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: activo
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _hilos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final h = _hilos[i];
                return Material(
                  color: PaletaRutas.marronOscuro,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    onTap: () => widget.onHilo?.call(h.$1),
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(h.$2, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            h.$3,
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.destacada != null) ...[
            const SizedBox(height: 14),
            _SpotlightCultura(
              ruta: widget.destacada!,
              onTap: widget.onDestacada,
            ),
          ],
        ],
      ),
    );
  }
}

class _SpotlightCultura extends StatelessWidget {
  const _SpotlightCultura({required this.ruta, this.onTap});
  final ModeloRuta ruta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: PaletaRutas.terracota.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: PaletaRutas.marronOscuro.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 140,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ImagenHaku(
                        url: ruta.imagenUrl,
                        fit: BoxFit.cover,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        bottom: 12,
                        right: 14,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: PaletaRutas.terracota,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                ruta.hilo.etiqueta.toUpperCase(),
                                style: TipografiaHaku.interfaz(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: PaletaRutas.crema.withValues(alpha: 0.96),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Destacado',
                        style: TipografiaHaku.interfaz(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.terracota,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ruta.titulo,
                        style: TipografiaHaku.titulo(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.marronOscuro,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ruta.subtitulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.interfaz(
                          fontSize: 13,
                          color: PaletaRutas.marronCuero,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const LineaEncabezadoInca(altura: 2),
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
