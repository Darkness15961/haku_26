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
      url.isNotEmpty && !url.startsWith('http') && !CatalogoImagenesHaku.esLocal(url);

  Widget _asset(String path) {
    return Image.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => Image.asset(
        _respaldo,
        fit: fit,
        width: width,
        height: height,
      ),
    );
  }

  Widget _contenido() {
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
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
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
    final child = _contenido();
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }
}
