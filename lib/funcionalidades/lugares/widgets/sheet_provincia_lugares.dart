import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../nucleo/recursos/copy_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../comunidad/datos/salidas_datasource_local.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/provincias_datasource_local.dart';
import '../dominio/modelos/modelo_lugar.dart';
import '../widgets/metricas_comunidad.dart';

/// Bottom sheet con rincones, métricas y CTA si la provincia está vacía.
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

class _SheetProvinciaLugares extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.78;
    final salidasDs = SalidasDataSourceLocal.instancia;
    var totalSalidas = 0;
    var totalFotos = 0;
    for (final l in data.lugares) {
      totalSalidas += salidasDs.todas(lugarId: l.id).length;
      totalFotos += fotosPorLugar[l.id] ?? 0;
    }

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
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
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
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${CopyHaku.sheetProvinciaCapitalPrefijo}: ${data.provincia.capital}',
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _ChipInfo(
                            texto: CopyHaku.islaLugares(data.lugares.length),
                          ),
                          if (data.cantidadNuevos > 0)
                            _ChipInfo(
                              texto: CopyHaku.islaNuevos(data.cantidadNuevos),
                              destacado: true,
                            ),
                          _ChipInfo(texto: CopyHaku.sheetSalidas(totalSalidas)),
                          if (totalFotos > 0)
                            _ChipInfo(
                              texto: MetricasComunidad.etiquetaFotos(totalFotos),
                            ),
                        ],
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
          if (data.lugares.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottom),
              child: Column(
                children: [
                  Icon(
                    Icons.add_location_alt_outlined,
                    size: 40,
                    color: PaletaRutas.plomo.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    CopyHaku.sheetProvinciaVacia,
                    textAlign: TextAlign.center,
                    style: TipografiaHaku.interfaz(
                      fontSize: 14,
                      height: 1.4,
                      color: PaletaRutas.plomoClaro,
                    ),
                  ),
                  if (onRegistrar != null) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onRegistrar,
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
          else
            Flexible(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottom),
                itemCount: data.lugares.length + (onRegistrar != null ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  if (onRegistrar != null && i == data.lugares.length) {
                    return OutlinedButton.icon(
                      onPressed: onRegistrar,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PaletaRutas.oro,
                        side: BorderSide(
                          color: PaletaRutas.oro.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                  final l = data.lugares[i];
                  final nSalidas = salidasDs.todas(lugarId: l.id).length;
                  final fotos = fotosPorLugar[l.id] ?? 0;
                  return Material(
                    color: PaletaRutas.ink.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onTapLugar(l);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: ImagenHaku(
                                url: l.imagenUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TipografiaHaku.interfaz(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: PaletaRutas.piedra,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${l.categoria.etiqueta} · ${l.nivelExploracion.etiqueta}',
                                    style: TipografiaHaku.interfaz(
                                      fontSize: 12,
                                      color: PaletaRutas.plomoClaro,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
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

class _ChipInfo extends StatelessWidget {
  const _ChipInfo({required this.texto, this.destacado = false});

  final String texto;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: destacado
            ? PaletaRutas.oro.withValues(alpha: 0.18)
            : PaletaRutas.ink.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: destacado
              ? PaletaRutas.oro.withValues(alpha: 0.55)
              : PaletaRutas.plomo.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        texto,
        style: TipografiaHaku.interfaz(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: destacado ? PaletaRutas.oro : PaletaRutas.plomoClaro,
        ),
      ),
    );
  }
}
