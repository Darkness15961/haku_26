import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';

/// Portada editorial de Inicio — carrusel hero.
class PortadaInicioCultura extends StatefulWidget {
  const PortadaInicioCultura({
    super.key,
    required this.rutas,
  });

  final List<ModeloRuta> rutas;

  @override
  State<PortadaInicioCultura> createState() => _EstadoPortadaInicioCultura();
}

class _EstadoPortadaInicioCultura extends State<PortadaInicioCultura> {
  late final PageController _pageController;
  Timer? _autoTimer;
  int _pagina = 0;

  List<ModeloRuta> get _slides => widget.rutas;

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
                              ? 'Cultura en Cusco'
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
                              ? 'Fotos y rutas de Cusco'
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
        ],
      ),
    );
  }
}
