import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../recursos/catalogo_imagenes_haku.dart';

/// Carga asset local, archivo o red con respaldo local.
class ImagenHaku extends StatelessWidget {
  const ImagenHaku({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.respaldo,
    this.borderRadius,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? respaldo;
  final BorderRadius? borderRadius;

  String get _respaldo => respaldo ?? CatalogoImagenesHaku.respaldo;

  bool get _esArchivo =>
      url.isNotEmpty &&
      !url.startsWith('http') &&
      !CatalogoImagenesHaku.esLocal(url);

  Widget _asset(String path) {
    return Image.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) =>
          Image.asset(_respaldo, fit: fit, width: width, height: height),
    );
  }

  Widget _contenido(BuildContext context) {
    if (url.isEmpty) return _asset(_respaldo);
    if (CatalogoImagenesHaku.esLocal(url)) return _asset(url);
    if (_esArchivo) {
      return Image.file(
        File(url),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _asset(_respaldo),
      );
    }
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = width != null && width!.isFinite && width! > 0
        ? (width! * pixelRatio).round()
        : null;
    final cacheHeight = height != null && height!.isFinite && height! > 0
        ? (height! * pixelRatio).round()
        : null;
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      maxWidthDiskCache: cacheWidth,
      maxHeightDiskCache: cacheHeight,
      placeholder: (_, __) => ColoredBox(
        color: const Color(0xFFE8E0D4),
        child: width != null && height != null
            ? SizedBox(width: width, height: height)
            : null,
      ),
      errorWidget: (_, __, ___) => _asset(_respaldo),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child = _contenido(context);
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    // Solo expandir si el padre da tamaño acotado (Expanded / Positioned.fill).
    // En Stack suelto, expandir rompe el layout.
    if (width != null || height != null) return child;
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth.isFinite &&
            c.maxHeight.isFinite &&
            c.maxWidth > 0 &&
            c.maxHeight > 0) {
          return SizedBox(width: c.maxWidth, height: c.maxHeight, child: child);
        }
        return child;
      },
    );
  }
}
