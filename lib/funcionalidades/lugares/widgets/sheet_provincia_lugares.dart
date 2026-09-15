import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/recursos/copy_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../comunidad/proveedores/proveedor_salidas.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/provincias_datasource_local.dart';
import '../dominio/modelos/modelo_lugar.dart';
import '../dominio/modelos/modelo_territorio.dart';

/// Bottom sheet: rincones de una provincia.
/// Un eje de filtro a la vez (Qué es / Qué hacer) + lista respirada.
Future<void> abrirSheetProvinciaLugares(
  BuildContext context, {
  required IslaProvinciaData data,
  required ValueChanged<ModeloLugar> onTapLugar,
  Map<String, int>? fotosPorLugar,
  VoidCallback? onRegistrar,
}) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _SheetProvinciaLugares(
      data: data,
      fotosPorLugar: fotosPorLugar ?? const {},
      onTapLugar: (l) {
        Navigator.of(ctx).pop();
        onTapLugar(l);
      },
      onRegistrar: onRegistrar == null
          ? null
          : () {
              Navigator.of(ctx).pop();
              onRegistrar();
            },
    ),
  );
}

enum _EjeFiltro { tematica, actividad }

class _SheetProvinciaLugares extends ConsumerStatefulWidget {
  const _SheetProvinciaLugares({
    required this.data,
    required this.onTapLugar,
    required this.fotosPorLugar,
    this.onRegistrar,
  });

  final IslaProvinciaData data;
  final ValueChanged<ModeloLugar> onTapLugar;
  final Map<String, int> fotosPorLugar;
  final VoidCallback? onRegistrar;

  @override
  ConsumerState<_SheetProvinciaLugares> createState() =>
      _EstadoSheetProvinciaLugares();
}

class _EstadoSheetProvinciaLugares
    extends ConsumerState<_SheetProvinciaLugares> {
  _EjeFiltro _eje = _EjeFiltro.tematica;
  String? _tematicaFiltro;
  String? _actividadFiltro;
  String? _distritoFiltro;
  bool _mostrarDistrito = false;

  List<ModeloLugar> get _filtrados {
    var lista = [...widget.data.lugares];
    final t = _tematicaFiltro;
    if (t != null && t.isNotEmpty) {
      lista = lista.where((l) => l.tieneEtiquetaNombre(t)).toList();
    }
    final a = _actividadFiltro;
    if (a != null && a.isNotEmpty) {
      lista = lista.where((l) => l.tieneEtiquetaNombre(a)).toList();
    }
    final d = _distritoFiltro;
    if (d != null && d.isNotEmpty) {
      lista = lista.where((l) => l.distrito == d).toList();
    }
    lista.sort(
      (x, y) => x.nombre.toLowerCase().compareTo(y.nombre.toLowerCase()),
    );
    return lista;
  }

  List<String> _nombresFaceta(FacetaCategoriaLugar faceta) {
    final set = <String>{};
    for (final l in widget.data.lugares) {
      for (final e in l.etiquetas) {
        if (e.faceta == faceta && e.nombre.trim().isNotEmpty) {
          set.add(e.nombre.trim());
        }
      }
    }
    final out = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

  List<String> get _distritosDisponibles {
    final set = <String>{};
    for (final l in widget.data.lugares) {
      if (l.distrito.trim().isNotEmpty) set.add(l.distrito.trim());
    }
    final out = set.toList()..sort();
    return out;
  }

  String _etiquetaChip(String raw) {
    // Acorta etiquetas largas en el filtro (p. ej. Trekking / Caminata).
    if (raw.contains('/')) {
      return raw.split('/').first.trim();
    }
    return raw;
  }

  bool get _hayFiltroActivo =>
      _tematicaFiltro != null ||
      _actividadFiltro != null ||
      _distritoFiltro != null;

  void _limpiarFiltros() {
    setState(() {
      _tematicaFiltro = null;
      _actividadFiltro = null;
      _distritoFiltro = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.82;
    final salidasRemotas =
        ref.watch(salidasRemotasProvider).valueOrNull ?? const [];
    final filtrados = _filtrados;
    final tematicas = _nombresFaceta(FacetaCategoriaLugar.tematica);
    final actividades = _nombresFaceta(FacetaCategoriaLugar.actividad);
    final distritos = _distritosDisponibles;

    final ejes = <_EjeFiltro>[
      if (tematicas.isNotEmpty) _EjeFiltro.tematica,
      if (actividades.isNotEmpty) _EjeFiltro.actividad,
    ];
    final eje = ejes.contains(_eje)
        ? _eje
        : (ejes.isNotEmpty ? ejes.first : _EjeFiltro.tematica);
    final chipsActuales =
        eje == _EjeFiltro.tematica ? tematicas : actividades;
    final activoActual =
        eje == _EjeFiltro.tematica ? _tematicaFiltro : _actividadFiltro;

    final meta = [
      CopyHaku.sheetProvinciaContexto,
      CopyHaku.islaLugares(data.lugares.length),
      if (data.cantidadNuevos > 0) CopyHaku.islaNuevos(data.cantidadNuevos),
    ].join(' · ');

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(
          color: PaletaRutas.plomo.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: PaletaRutas.plomo,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 8, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.provincia.nombre,
                        style: TipografiaHaku.titulo(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meta,
                        style: TipografiaHaku.interfaz(
                          fontSize: 13,
                          height: 1.35,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
              ],
            ),
          ),
          if (data.lugares.isNotEmpty && ejes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtrar rincones',
                    style: TipografiaHaku.interfaz(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.plomo,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (ejes.length > 1)
                    _SegmentoEje(
                      ejes: ejes,
                      activo: eje,
                      onChanged: (e) => setState(() => _eje = e),
                    ),
                  if (ejes.length > 1) const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ChipFiltro(
                        texto: 'Todos',
                        activo: activoActual == null,
                        onTap: () => setState(() {
                          if (eje == _EjeFiltro.tematica) {
                            _tematicaFiltro = null;
                          } else {
                            _actividadFiltro = null;
                          }
                        }),
                      ),
                      ...chipsActuales.map(
                        (v) => _ChipFiltro(
                          texto: _etiquetaChip(v),
                          activo: activoActual == v,
                          onTap: () => setState(() {
                            if (eje == _EjeFiltro.tematica) {
                              _tematicaFiltro =
                                  _tematicaFiltro == v ? null : v;
                            } else {
                              _actividadFiltro =
                                  _actividadFiltro == v ? null : v;
                            }
                          }),
                        ),
                      ),
                    ],
                  ),
                  if (distritos.length > 1) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => setState(() {
                        _mostrarDistrito = !_mostrarDistrito;
                        if (!_mostrarDistrito) _distritoFiltro = null;
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              CopyHaku.sheetFiltroDistritoOpcional,
                              style: TipografiaHaku.interfaz(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: PaletaRutas.plomoClaro,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _mostrarDistrito
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 20,
                              color: PaletaRutas.plomo,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_mostrarDistrito) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ChipFiltro(
                            texto: 'Todos',
                            activo: _distritoFiltro == null,
                            onTap: () =>
                                setState(() => _distritoFiltro = null),
                          ),
                          ...distritos.map(
                            (d) => _ChipFiltro(
                              texto: d,
                              activo: _distritoFiltro == d,
                              onTap: () => setState(() {
                                _distritoFiltro =
                                    _distritoFiltro == d ? null : d;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  if (_hayFiltroActivo) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _limpiarFiltros,
                        style: TextButton.styleFrom(
                          foregroundColor: PaletaRutas.oro,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Quitar filtros',
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.oro,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(
              height: 1,
              color: PaletaRutas.plomo.withValues(alpha: 0.25),
            ),
          ],
          if (data.lugares.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(22, 16, 22, 28 + bottom),
              child: Column(
                children: [
                  Icon(
                    Icons.add_location_alt_outlined,
                    size: 40,
                    color: PaletaRutas.plomo.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    CopyHaku.sheetProvinciaVacia,
                    textAlign: TextAlign.center,
                    style: TipografiaHaku.interfaz(
                      fontSize: 14,
                      height: 1.45,
                      color: PaletaRutas.plomoClaro,
                    ),
                  ),
                  if (widget.onRegistrar != null) ...[
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: widget.onRegistrar,
                      style: FilledButton.styleFrom(
                        backgroundColor: PaletaRutas.oro,
                        foregroundColor: PaletaRutas.ink,
                      ),
                      child: Text(
                        CopyHaku.sheetCtaRegistrar,
                        style: TipografiaHaku.interfaz(
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.ink,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else if (filtrados.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(22, 20, 22, 28 + bottom),
              child: Column(
                children: [
                  Text(
                    CopyHaku.sheetFiltroVacio,
                    textAlign: TextAlign.center,
                    style: TipografiaHaku.interfaz(
                      fontSize: 14,
                      color: PaletaRutas.plomoClaro,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _limpiarFiltros,
                    child: Text(
                      'Ver todos',
                      style: TipografiaHaku.interfaz(
                        color: PaletaRutas.oro,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(18, 14, 18, 18 + bottom),
                itemCount:
                    filtrados.length + (widget.onRegistrar != null ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  if (widget.onRegistrar != null && i == filtrados.length) {
                    return OutlinedButton.icon(
                      onPressed: widget.onRegistrar,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PaletaRutas.oro,
                        side: BorderSide(
                          color: PaletaRutas.oro.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        CopyHaku.sheetCtaRegistrar,
                        style: TipografiaHaku.interfaz(
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.oro,
                        ),
                      ),
                    );
                  }
                  final l = filtrados[i];
                  final nSalidas = salidasRemotas
                      .where((s) => s.lugarId == l.id)
                      .length;
                  final fotos = widget.fotosPorLugar[l.id] ?? 0;
                  final lineaTipo = l.subtituloClasificacion;
                  final lineaZona =
                      l.distrito.isNotEmpty ? l.distrito : null;
                  return Material(
                    color: PaletaRutas.ink.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onTapLugar(l);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ImagenHaku(
                                url: l.imagenUrl,
                                width: 68,
                                height: 68,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TipografiaHaku.interfaz(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: PaletaRutas.piedra,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lineaTipo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TipografiaHaku.interfaz(
                                      fontSize: 12,
                                      color: PaletaRutas.plomoClaro,
                                    ),
                                  ),
                                  if (lineaZona != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      lineaZona,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TipografiaHaku.interfaz(
                                        fontSize: 11,
                                        color: PaletaRutas.plomo,
                                      ),
                                    ),
                                  ],
                                  if (l.calificacion > 0 ||
                                      nSalidas > 0 ||
                                      fotos > 0) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (l.calificacion > 0) ...[
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 14,
                                            color: PaletaRutas.oro,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            l.calificacion.toStringAsFixed(1),
                                            style: TipografiaHaku.interfaz(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: PaletaRutas.oroSuave,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        if (nSalidas > 0) ...[
                                          Icon(
                                            Icons.groups_rounded,
                                            size: 14,
                                            color: PaletaRutas.oro
                                                .withValues(alpha: 0.9),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '$nSalidas',
                                            style: TipografiaHaku.interfaz(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: PaletaRutas.plomoClaro,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        if (fotos > 0) ...[
                                          const Icon(
                                            Icons.photo_outlined,
                                            size: 14,
                                            color: PaletaRutas.plomo,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '$fotos',
                                            style: TipografiaHaku.interfaz(
                                              fontSize: 11,
                                              color: PaletaRutas.plomoClaro,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: PaletaRutas.plomo,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentoEje extends StatelessWidget {
  const _SegmentoEje({
    required this.ejes,
    required this.activo,
    required this.onChanged,
  });

  final List<_EjeFiltro> ejes;
  final _EjeFiltro activo;
  final ValueChanged<_EjeFiltro> onChanged;

  String _label(_EjeFiltro e) => switch (e) {
        _EjeFiltro.tematica => 'Qué es',
        _EjeFiltro.actividad => 'Qué hacer',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: PaletaRutas.ink.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final e in ejes)
            Expanded(
              child: Material(
                color: activo == e
                    ? PaletaRutas.oro.withValues(alpha: 0.22)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => onChanged(e),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      _label(e),
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.interfaz(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: activo == e
                            ? PaletaRutas.oro
                            : PaletaRutas.plomoClaro,
                      ),
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

class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({
    required this.texto,
    required this.activo,
    required this.onTap,
  });

  final String texto;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: activo
          ? PaletaRutas.oro.withValues(alpha: 0.20)
          : PaletaRutas.ink.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: activo
                  ? PaletaRutas.oro.withValues(alpha: 0.75)
                  : PaletaRutas.plomo.withValues(alpha: 0.28),
            ),
          ),
          child: Text(
            texto,
            style: TipografiaHaku.interfaz(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: activo ? PaletaRutas.oro : PaletaRutas.plomoClaro,
            ),
          ),
        ),
      ),
    );
  }
}
