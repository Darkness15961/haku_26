import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../inicio/datos/provincias_datasource_local.dart';
import '../../inicio/dominio/modelos/provincia.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelo_comunidad.dart';
import '../util/provincia_comunidad.dart';
import '../widgets/chip_categoria_comunidad.dart';

/// Mapa de Cusco con puntos de agrupación comunitaria por provincia.
class MapaComunidadesCusco extends StatefulWidget {
  const MapaComunidadesCusco({
    super.key,
    required this.comunidades,
    required this.unidas,
    required this.provinciaSeleccionadaId,
    required this.onProvincia,
  });

  final List<ComunidadHaku> comunidades;
  final Set<String> unidas;
  final String? provinciaSeleccionadaId;
  final ValueChanged<String?> onProvincia;

  static const _ancho = 1000.0;
  static const _alto = 1150.0;

  @override
  State<MapaComunidadesCusco> createState() => _EstadoMapaComunidadesCusco();
}

class _EstadoMapaComunidadesCusco extends State<MapaComunidadesCusco> {
  final _transform = TransformationController();

  Map<String, List<ComunidadHaku>> get _porProvincia {
    final map = <String, List<ComunidadHaku>>{};
    for (final c in widget.comunidades) {
      final id = provinciaIdDeNombre(c.provincia);
      map.putIfAbsent(id, () => []).add(c);
    }
    return map;
  }

  Set<String> get _provinciasConGrupos => _porProvincia.keys.toSet();

  void _toqueMapa(Offset local, List<Provincia> provincias) {
    final nx = (local.dx / MapaComunidadesCusco._ancho).clamp(0.0, 1.0);
    final ny = (local.dy / MapaComunidadesCusco._alto).clamp(0.0, 1.0);

    Provincia? mejor;
    var distMin = double.infinity;
    for (final p in provincias) {
      if (!_provinciasConGrupos.contains(p.id)) continue;
      final d = math.sqrt(
        math.pow(p.posicionCentro.dx - nx, 2) +
            math.pow(p.posicionCentro.dy - ny, 2),
      );
      if (d < distMin) {
        distMin = d;
        mejor = p;
      }
    }
    if (mejor != null && distMin < 0.22) {
      widget.onProvincia(
        widget.provinciaSeleccionadaId == mejor.id ? null : mejor.id,
      );
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provincias = ProvinciasDataSourceLocal.obtenerProvincias();
    final porProv = _porProvincia;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        color: PaletaRutas.pergamino.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PaletaRutas.terracota.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: PaletaRutas.marronOscuro.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                _LeyendaItem(
                  color: PaletaRutas.terracota,
                  texto: 'Agrupación',
                ),
                const SizedBox(width: 12),
                _LeyendaItem(
                  color: PaletaRutas.marronOscuro,
                  texto: 'Unida',
                  anillo: true,
                ),
                const Spacer(),
                Text(
                  '${widget.comunidades.length} en el mapa',
                  style: TipografiaHaku.interfaz(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.marronCuero,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.85,
              maxScale: 3.5,
              boundaryMargin: const EdgeInsets.all(40),
              child: AspectRatio(
                aspectRatio: MapaComunidadesCusco._ancho / MapaComunidadesCusco._alto,
                child: GestureDetector(
                  onTapUp: (d) => _toqueMapa(d.localPosition, provincias),
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: PaletaRutas.crema.withValues(alpha: 0.6),
                      ),
                      ...provincias.map((p) {
                        final tiene = _provinciasConGrupos.contains(p.id);
                        final sel =
                            widget.provinciaSeleccionadaId == p.id;
                        return _PiezaProvinciaComunidad(
                          provincia: p,
                          activa: tiene,
                          seleccionada: sel,
                        );
                      }),
                      ...porProv.entries.expand((e) {
                        final prov = provinciaPorId(e.key);
                        if (prov == null) return <Widget>[];
                        final lista = e.value;
                        final cx = prov.posicionCentro.dx *
                            MapaComunidadesCusco._ancho;
                        final cy = prov.posicionCentro.dy *
                            MapaComunidadesCusco._alto;
                        if (lista.length == 1) {
                          final c = lista.first;
                          final unida = widget.unidas.contains(c.id);
                          return [
                            _MarcadorAgrupacion(
                              left: cx - 18,
                              top: cy - 18,
                              cantidad: 1,
                              unida: unida,
                              seleccionado:
                                  widget.provinciaSeleccionadaId == e.key,
                            ),
                          ];
                        }
                        return [
                          _MarcadorAgrupacion(
                            left: cx - 22,
                            top: cy - 22,
                            cantidad: lista.length,
                            unida: lista.any((c) => widget.unidas.contains(c.id)),
                            seleccionado:
                                widget.provinciaSeleccionadaId == e.key,
                          ),
                        ];
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PiezaProvinciaComunidad extends StatelessWidget {
  const _PiezaProvinciaComunidad({
    required this.provincia,
    required this.activa,
    required this.seleccionada,
  });

  final Provincia provincia;
  final bool activa;
  final bool seleccionada;

  @override
  Widget build(BuildContext context) {
    Color color;
    if (seleccionada) {
      color = PaletaRutas.terracota.withValues(alpha: 0.85);
    } else if (activa) {
      color = PaletaRutas.terracota.withValues(alpha: 0.38);
    } else {
      color = PaletaRutas.marronCuero.withValues(alpha: 0.22);
    }

    return SvgPicture.asset(
      provincia.rutaSvg,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class _MarcadorAgrupacion extends StatelessWidget {
  const _MarcadorAgrupacion({
    required this.left,
    required this.top,
    required this.cantidad,
    required this.unida,
    required this.seleccionado,
  });

  final double left;
  final double top;
  final int cantidad;
  final bool unida;
  final bool seleccionado;

  @override
  Widget build(BuildContext context) {
    final size = cantidad > 1 ? 44.0 : 36.0;
    return Positioned(
      left: left - (size - 36) / 2,
      top: top - (size - 36) / 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: unida ? PaletaRutas.marronOscuro : PaletaRutas.terracota,
          border: Border.all(
            color: seleccionado ? Colors.white : Colors.white.withValues(alpha: 0.85),
            width: seleccionado ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: PaletaRutas.terracota.withValues(alpha: 0.45),
              blurRadius: seleccionado ? 12 : 6,
              spreadRadius: seleccionado ? 1 : 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: cantidad > 1
            ? Text(
                '$cantidad',
                style: TipografiaHaku.interfaz(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.groups_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  const _LeyendaItem({
    required this.color,
    required this.texto,
    this.anillo = false,
  });

  final Color color;
  final String texto;
  final bool anillo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: anillo ? Colors.transparent : color,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          texto,
          style: TipografiaHaku.interfaz(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.marronCuero,
          ),
        ),
      ],
    );
  }
}

/// Fila compacta de agrupación (sin foto).
class FilaAgrupacionComunidad extends StatelessWidget {
  const FilaAgrupacionComunidad({
    super.key,
    required this.comunidad,
    required this.unida,
    required this.onTap,
  });

  final ComunidadHaku comunidad;
  final bool unida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cat = comunidad.categorias.isNotEmpty
        ? comunidad.categorias.first
        : CategoriaLugar.cultura;

    return Material(
      color: PaletaRutas.crema.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(
              color: unida
                  ? PaletaRutas.terracota.withValues(alpha: 0.55)
                  : PaletaRutas.marronCuero.withValues(alpha: 0.18),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: PaletaRutas.terracota.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconoCategoriaComunidad(cat),
                  color: PaletaRutas.terracota,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comunidad.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TipografiaHaku.interfaz(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: PaletaRutas.marronOscuro,
                      ),
                    ),
                    Text(
                      '${comunidad.miembros} personas · ${comunidad.provincia}',
                      style: TipografiaHaku.interfaz(
                        fontSize: 11,
                        color: PaletaRutas.marronCuero,
                      ),
                    ),
                  ],
                ),
              ),
              if (unida)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: PaletaRutas.marronOscuro,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Unida',
                    style: TipografiaHaku.interfaz(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: PaletaRutas.marronCuero.withValues(alpha: 0.7),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
