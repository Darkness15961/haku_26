import 'package:flutter/material.dart';

import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import 'boton_favorito_card.dart';

/// Card cuadrado — lugares descubiertos / votados por la comunidad.
class CardEscapadaComunidad extends StatefulWidget {
  const CardEscapadaComunidad({
    super.key,
    required this.lugares,
    this.onConocerMas,
  });

  final List<ModeloRuta> lugares;
  final ValueChanged<ModeloRuta>? onConocerMas;

  static const _badges = [
    'Descubierto por la comunidad',
    'Recién compartido',
    'Poco explorado',
  ];

  @override
  State<CardEscapadaComunidad> createState() => _EstadoCardEscapadaComunidad();
}

class _EstadoCardEscapadaComunidad extends State<CardEscapadaComunidad> {
  late final PageController _page;
  int _pagina = 0;

  List<ModeloRuta> get _destacadas {
    final lista = [...widget.lugares];
    lista.sort((a, b) {
      final sa = a.cantidadResenas * a.calificacion;
      final sb = b.cantidadResenas * b.calificacion;
      final c = sb.compareTo(sa);
      if (c != 0) return c;
      return b.calificacion.compareTo(a.calificacion);
    });
    return lista.take(5).toList();
  }

  @override
  void initState() {
    super.initState();
    _page = PageController();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  String _badge(int index) =>
      CardEscapadaComunidad._badges[index % CardEscapadaComunidad._badges.length];

  @override
  Widget build(BuildContext context) {
    final items = _destacadas;
    if (items.isEmpty) return const SizedBox.shrink();

    final ancho = MediaQuery.sizeOf(context).width - 32;
    final actual = items[_pagina.clamp(0, items.length - 1)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descubiertos por la comunidad',
            style: TipografiaHaku.titulo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: PaletaRutas.piedra,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: ancho,
              height: ancho,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _page,
                    itemCount: items.length,
                    onPageChanged: (i) => setState(() => _pagina = i),
                    itemBuilder: (_, i) {
                      final r = items[i];
                      return ImagenHaku(
                        key: ValueKey('${r.id}_${r.imagenUrl}'),
                        url: r.imagenUrl,
                        fit: BoxFit.cover,
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
                            Colors.transparent,
                            PaletaRutas.ink.withValues(alpha: 0.08),
                            PaletaRutas.ink.withValues(alpha: 0.82),
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: BotonFavoritoCard(rutaId: actual.id),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Material(
                                color: PaletaRutas.piedra,
                                elevation: 2,
                                shadowColor:
                                    PaletaRutas.ink.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(24),
                                child: InkWell(
                                  onTap: () =>
                                      widget.onConocerMas?.call(actual),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 9,
                                    ),
                                    child: Text(
                                      'Conocer más',
                                      style: TipografiaHaku.interfaz(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: PaletaRutas.ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                actual.titulo,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TipografiaHaku.titulo(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: PaletaRutas.piedra,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.place_outlined,
                                    size: 14,
                                    color: PaletaRutas.piedra
                                        .withValues(alpha: 0.85),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      actual.provincia,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TipografiaHaku.interfaz(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: PaletaRutas.piedra
                                            .withValues(alpha: 0.88),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (items.length > 1) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: List.generate(items.length, (i) {
                                    final activo = i == _pagina;
                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      margin: const EdgeInsets.only(right: 5),
                                      width: activo ? 16 : 6,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: activo
                                            ? PaletaRutas.oro
                                            : PaletaRutas.piedra
                                                .withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: PaletaRutas.oro.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _badge(_pagina),
                                textAlign: TextAlign.right,
                                style: TipografiaHaku.interfaz(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: PaletaRutas.ink,
                                  letterSpacing: 0.1,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            if (actual.calificacion > 0) ...[
                              const SizedBox(height: 8),
                              _NotaComunidad(calificacion: actual.calificacion),
                            ],
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

/// Nota que la comunidad le dio al lugar (estrella + valor + votos).
class _NotaComunidad extends StatelessWidget {
  const _NotaComunidad({required this.calificacion});

  final double calificacion;

  @override
  Widget build(BuildContext context) {
    final nota = calificacion.toStringAsFixed(1).replaceAll('.', ',');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: PaletaRutas.ink.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: PaletaRutas.oro.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 15,
            color: PaletaRutas.oro,
          ),
          const SizedBox(width: 4),
          Text(
            nota,
            style: TipografiaHaku.interfaz(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: PaletaRutas.piedra,
            ),
          ),
        ],
      ),
    );
  }
}
