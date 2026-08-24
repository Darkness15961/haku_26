import 'dart:async';

import 'package:flutter/material.dart';

import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import 'boton_favorito_card.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';

/// Carrusel místico — lo que se siente al llegar a Cusco.
class PortadaInicioCultura extends StatefulWidget {
  const PortadaInicioCultura({
    super.key,
    required this.rutas,
    this.onExplorar,
    this.onTapRuta,
  });

  final List<ModeloRuta> rutas;
  final VoidCallback? onExplorar;
  final ValueChanged<ModeloRuta>? onTapRuta;

  @override
  State<PortadaInicioCultura> createState() => _EstadoPortadaInicioCultura();
}

class _EstadoPortadaInicioCultura extends State<PortadaInicioCultura> {
  late final PageController _page;
  Timer? _auto;
  int _pagina = 0;

  List<ModeloRuta> get _slides {
    if (widget.rutas.isNotEmpty) return widget.rutas;
    return const [
      ModeloRuta(
        id: 'fallback_mistico',
        titulo: 'Cusco de noche',
        subtitulo: 'Calles y piedras que guardan silencio',
        descripcion: '',
        imagenUrl: CatalogoImagenesHaku.u46,
        categoria: CategoriaRuta.cultura,
        provincia: 'Cusco',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _page = PageController();
    _auto = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_page.hasClients) return;
      final slides = _slides;
      if (slides.isEmpty) return;
      final next = (_pagina + 1) % slides.length;
      _page.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    final actual = slides[_pagina.clamp(0, slides.length - 1)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cusco mágico',
            style: TipografiaHaku.titulo(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: PaletaRutas.piedra,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Noches, leyendas y lugares que guardan misterio',
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              color: PaletaRutas.plomoClaro,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 240,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _page,
                    itemCount: slides.length,
                    onPageChanged: (i) => setState(() => _pagina = i),
                    itemBuilder: (_, i) {
                      final s = slides[i];
                      return GestureDetector(
                        onTap: () {
                          if (widget.onTapRuta != null) {
                            widget.onTapRuta!(s);
                          } else {
                            widget.onExplorar?.call();
                          }
                        },
                        child: ImagenHaku(url: s.imagenUrl, fit: BoxFit.cover),
                      );
                    },
                  ),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            PaletaRutas.ink.withValues(alpha: 0.15),
                            Colors.transparent,
                            PaletaRutas.ink.withValues(alpha: 0.78),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: BotonFavoritoCard(rutaId: actual.id),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          actual.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TipografiaHaku.titulo(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          actual.subtitulo.isNotEmpty
                              ? actual.subtitulo
                              : actual.provincia,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            color: PaletaRutas.piedra.withValues(alpha: 0.88),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ...List.generate(slides.length, (i) {
                              final activo = i == _pagina;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                margin: const EdgeInsets.only(right: 5),
                                width: activo ? 18 : 6,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: activo
                                      ? PaletaRutas.oro
                                      : PaletaRutas.piedra
                                          .withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                            const Spacer(),
                            if (widget.onExplorar != null)
                              Material(
                                color: PaletaRutas.oro.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  onTap: widget.onExplorar,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      'Descubrir',
                                      style: TipografiaHaku.interfaz(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: PaletaRutas.ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
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
