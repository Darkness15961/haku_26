import 'package:flutter/material.dart';

import '../recursos/catalogo_imagenes_haku.dart';
import 'imagen_haku.dart';

/// Avatar circular — siempre local (logo HAKU por defecto).
class AvatarHaku extends StatelessWidget {
  const AvatarHaku({
    super.key,
    required this.url,
    this.size = 36,
    this.borderWidth = 0,
    this.borderColor,
  });

  final String? url;
  final double size;
  final double borderWidth;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final img = CatalogoImagenesHaku.resolverAvatar(url);
    Widget avatar = ClipOval(
      child: ImagenHaku(
        url: img,
        width: size,
        height: size,
        fit: BoxFit.cover,
        respaldo: CatalogoImagenesHaku.avatar,
      ),
    );
    if (borderWidth > 0) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? Colors.white,
            width: borderWidth,
          ),
        ),
        child: avatar,
      );
    }
    return SizedBox(width: size, height: size, child: avatar);
  }
}
