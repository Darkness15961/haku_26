import 'package:flutter/material.dart';

/// Tinte suave según la hora local (amanecer / día / tarde / noche).
class OverlayMomentoDia extends StatelessWidget {
  const OverlayMomentoDia({super.key});

  static Color colorParaHora([DateTime? ahora]) {
    final h = (ahora ?? DateTime.now()).hour;
    if (h >= 5 && h < 8) {
      return const Color(0xFFFFB347).withValues(alpha: 0.18); // amanecer
    }
    if (h >= 8 && h < 17) {
      return const Color(0xFFFFF3D6).withValues(alpha: 0.06); // dia
    }
    if (h >= 17 && h < 20) {
      return const Color(0xFFE07A3D).withValues(alpha: 0.20); // tarde
    }
    return const Color(0xFF1A2744).withValues(alpha: 0.32); // noche
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(color: colorParaHora()),
    );
  }
}
