import 'package:flutter/material.dart';

import '../../../nucleo/recursos/copy_haku.dart';
import '../../../nucleo/responsive/espacio_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import 'boton_favorito_card.dart';

/// Card de “lo que dejó la gente” — tamaño acotado, overlay sin overflow.
class CardEscapadaComunidad extends StatefulWidget {
  const CardEscapadaComunidad({
    super.key,
    required this.lugares,
    this.onConocerMas,
  });

  final List<ModeloRuta> lugares;
  final ValueChanged<ModeloRuta>? onConocerMas;

  static const _badges = [
    CopyHaku.badgeComunidad1,
    CopyHaku.badgeComunidad2,
    CopyHaku.badgeComunidad3,
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

    final lado = EspacioHaku.ladoCardCuadrada(context);
    final actual = items[_pagina.clamp(0, items.length - 1)];
    final compacta = lado < 230;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        EspacioHaku.horizontal(context),
        24,
        EspacioHaku.horizontal(context),
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CopyHaku.comunidadDestacadaTitulo,
            style: TipografiaHaku.titulo(
              fontSize: EspacioHaku.sp(context, 20),
              fontWeight: FontWeight.w700,
              color: PaletaRutas.piedra,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: lado,
                height: lado,
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
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x00000000),
                              Color(0x14141210),
                              Color(0xD9141210),
                            ],
                            stops: [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: compacta ? 8 : 12,
                      right: compacta ? 8 : 12,
                      child: BotonFavoritoCard(rutaId: actual.id),
                    ),
                    Positioned(
                      left: compacta ? 10 : 14,
                      right: compacta ? 10 : 14,
                      bottom: compacta ? 10 : 14,
                      child: _OverlayCard(
                        titulo: actual.titulo,
                        provincia: actual.provincia,
                        badge: _badge(_pagina),
                        calificacion: actual.calificacion,
                        paginas: items.length,
                        pagina: _pagina,
                        compacta: compacta,
                        onCta: () => widget.onConocerMas?.call(actual),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayCard extends StatelessWidget {
  const _OverlayCard({
    required this.titulo,
    required this.provincia,
    required this.badge,
    required this.calificacion,
    required this.paginas,
    required this.pagina,
    required this.compacta,
    required this.onCta,
  });

  final String titulo;
  final String provincia;
  final String badge;
  final double calificacion;
  final int paginas;
  final int pagina;
  final bool compacta;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final tituloSize = compacta ? 15.0 : 18.0;
    final gap = compacta ? 4.0 : 8.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Material(
                color: PaletaRutas.piedra,
                elevation: 2,
                shadowColor: PaletaRutas.ink.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onCta,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compacta ? 12 : 16,
                      vertical: compacta ? 6 : 8,
                    ),
                    child: Text(
                      CopyHaku.cardComunidadCta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TipografiaHaku.interfaz(
                        fontSize: compacta ? 11 : 13,
                        fontWeight: FontWeight.w800,
                        color: PaletaRutas.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: gap),
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compacta ? 8 : 10,
                  vertical: compacta ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: PaletaRutas.oro.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: PaletaRutas.ink,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        Text(
          titulo,
          maxLines: compacta ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: TipografiaHaku.titulo(
            fontSize: tituloSize,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
            height: 1.1,
          ),
        ),
        SizedBox(height: compacta ? 2 : 4),
        Row(
          children: [
            Icon(
              Icons.place_outlined,
              size: 13,
              color: PaletaRutas.piedra.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                provincia,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TipografiaHaku.interfaz(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: PaletaRutas.piedra.withValues(alpha: 0.88),
                ),
              ),
            ),
            if (calificacion > 0) ...[
              const Icon(Icons.star_rounded, size: 14, color: PaletaRutas.oro),
              const SizedBox(width: 2),
              Text(
                calificacion.toStringAsFixed(1).replaceAll('.', ','),
                style: TipografiaHaku.interfaz(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: PaletaRutas.piedra,
                ),
              ),
            ],
          ],
        ),
        if (paginas > 1) ...[
          SizedBox(height: gap),
          Row(
            children: List.generate(paginas, (i) {
              final activo = i == pagina;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 4),
                width: activo ? 14 : 5,
                height: 3,
                decoration: BoxDecoration(
                  color: activo
                      ? PaletaRutas.oro
                      : PaletaRutas.piedra.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
