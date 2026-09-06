import 'package:flutter/material.dart';

import 'espacio_haku.dart';

/// Patrón Lego: N columnas en landscape, 1 en portrait.
/// Al rotar, las celdas se reacomodan (quitar una → la siguiente sube).
abstract final class RejillaLegoHaku {
  RejillaLegoHaku._();

  static int columnas(BuildContext context) {
    if (!EspacioHaku.esHorizontal(context)) return 1;
    if (EspacioHaku.esTablet(context)) return 3;
    return 2;
  }

  /// Relación ancho/alto de cada celda (imagen arriba + texto abajo).
  static double aspect(BuildContext context, {double? override}) {
    if (override != null) return override;
    // Un poco más alto: deja espacio al texto sin “campo negro” bajo la foto.
    if (!EspacioHaku.esHorizontal(context)) return 0.78;
    return 0.88;
  }

  static double gap(BuildContext context) =>
      EspacioHaku.esHorizontal(context) ? 10.0 : 12.0;

  static EdgeInsets padding(BuildContext context, {double bottom = 0}) {
    final h = EspacioHaku.horizontal(context);
    return EdgeInsets.fromLTRB(h, 0, h, bottom);
  }

  static SliverGridDelegate delegate(
    BuildContext context, {
    double? childAspectRatio,
  }) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columnas(context),
      mainAxisSpacing: gap(context),
      crossAxisSpacing: gap(context),
      childAspectRatio: aspect(context, override: childAspectRatio),
    );
  }

  /// Grid embebido (TabBarView / Expanded).
  static Widget grid({
    required BuildContext context,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    double bottomPadding = 16,
    double? childAspectRatio,
  }) {
    final cols = columnas(context);
    final pad = padding(context, bottom: bottomPadding);
    if (cols <= 1) {
      return ListView.separated(
        padding: pad.copyWith(top: 12),
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(height: gap(context)),
        itemBuilder: itemBuilder,
      );
    }
    return GridView.builder(
      key: ValueKey('lego-$cols-$itemCount'),
      padding: pad.copyWith(top: 12),
      gridDelegate: delegate(context, childAspectRatio: childAspectRatio),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }

  /// Slivers para CustomScrollView.
  static List<Widget> slivers({
    required BuildContext context,
    required int itemCount,
    required NullableIndexedWidgetBuilder itemBuilder,
    double bottom = 16,
    double? childAspectRatio,
  }) {
    final cols = columnas(context);
    final pad = padding(context, bottom: bottom);
    if (itemCount == 0) return const [];
    if (cols <= 1) {
      return [
        SliverPadding(
          padding: pad,
          sliver: SliverList.separated(
            itemCount: itemCount,
            separatorBuilder: (_, __) => SizedBox(height: gap(context)),
            itemBuilder: itemBuilder,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: pad,
        sliver: SliverGrid(
          key: ValueKey('lego-sliver-$cols-${childAspectRatio ?? 'd'}'),
          gridDelegate:
              delegate(context, childAspectRatio: childAspectRatio),
          delegate: SliverChildBuilderDelegate(
            itemBuilder,
            childCount: itemCount,
          ),
        ),
      ),
    ];
  }
}
