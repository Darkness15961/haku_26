import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/mapa_aventura_datasource_local.dart';

/// Nodo ilustrado colorido (estilo mapa de aventura / dibujo).
class NodoDestinoAventura extends StatefulWidget {
  final NodoMapaAventura nodo;
  final bool seleccionado;
  final VoidCallback? onTap;
  /// Escala visual para caber en mapa sin scroll (~0.5–1.0).
  final double escala;

  const NodoDestinoAventura({
    super.key,
    required this.nodo,
    required this.seleccionado,
    this.onTap,
    this.escala = 1,
  });

  @override
  State<NodoDestinoAventura> createState() => _EstadoNodoDestinoAventura();
}

class _EstadoNodoDestinoAventura extends State<NodoDestinoAventura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathing;

  @override
  void initState() {
    super.initState();
    _breathing = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.seleccionado) _breathing.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant NodoDestinoAventura oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seleccionado && !_breathing.isAnimating) {
      _breathing.repeat(reverse: true);
    } else if (!widget.seleccionado && _breathing.isAnimating) {
      _breathing
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breathing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _breathing,
        builder: (context, child) {
          final breath =
              widget.seleccionado ? 1.0 + (_breathing.value * 0.06) : 1.0;
          return AnimatedScale(
            scale: (widget.seleccionado ? 1.12 : 1.0) * breath,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.nodo.rutaIlustracion != null
                ? _IlustracionPngTalCual(
                    ruta: widget.nodo.rutaIlustracion!,
                    seleccionado: widget.seleccionado,
                    ancho: 140 * widget.escala,
                  )
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 140 * widget.escala,
                    height: 84 * widget.escala,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8EC),
                      borderRadius: BorderRadius.circular(42 * widget.escala),
                      border: Border.all(
                        color: widget.seleccionado
                            ? PaletaRutas.verdeOliva
                            : const Color(0xFFC8B18A),
                        width: widget.seleccionado ? 3 : 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8 * widget.escala),
                      child: CustomPaint(
                        painter: _PintorIlustracionColorida(
                          tipo: widget.nodo.tipo,
                          resaltado: widget.seleccionado,
                        ),
                      ),
                    ),
                  ),
            SizedBox(height: 4 * widget.escala),
            Text(
              widget.nodo.nombre,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TipografiaHaku.interfaz(
                fontSize: (12 * widget.escala).clamp(8.5, 11.0),
                fontWeight:
                    widget.seleccionado ? FontWeight.w800 : FontWeight.w600,
                color: widget.seleccionado
                    ? PaletaRutas.verdeBosque
                    : PaletaRutas.marronOscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// PNG tal cual; selección = sombreado negro + verde suave.
class _IlustracionPngTalCual extends StatelessWidget {
  final String ruta;
  final bool seleccionado;
  final double ancho;

  const _IlustracionPngTalCual({
    required this.ruta,
    required this.seleccionado,
    required this.ancho,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: seleccionado
            ? [
                // Núcleo negro suave.
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
                // Halo verde oliva.
                BoxShadow(
                  color: PaletaRutas.verdeOliva.withValues(alpha: 0.55),
                  blurRadius: 22,
                  spreadRadius: 3,
                ),
                // Extensión verde bosque más difusa.
                BoxShadow(
                  color: PaletaRutas.verdeBosque.withValues(alpha: 0.28),
                  blurRadius: 32,
                  spreadRadius: 5,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          ruta,
          width: ancho,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => SizedBox(
            width: ancho,
            height: ancho * 0.6,
            child: const ColoredBox(
              color: Color(0xFFEADCC2),
              child: Icon(Icons.landscape, color: Color(0xFF8A5A3C)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ilustraciones más detalladas y coloridas (inspiración mapa explorador).
class _PintorIlustracionColorida extends CustomPainter {
  final TipoIlustracionNodo tipo;
  final bool resaltado;

  _PintorIlustracionColorida({
    required this.tipo,
    required this.resaltado,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final s = size.shortestSide;

    switch (tipo) {
      case TipoIlustracionNodo.pueblo:
        _pueblo(canvas, c, s);
      case TipoIlustracionNodo.ruinas:
        _ruinas(canvas, c, s);
      case TipoIlustracionNodo.terrazas:
        _terrazas(canvas, c, s);
      case TipoIlustracionNodo.montana:
      case TipoIlustracionNodo.nevado:
        _montana(canvas, c, s, conNieve: tipo == TipoIlustracionNodo.nevado);
      case TipoIlustracionNodo.laguna:
        _laguna(canvas, c, s);
      case TipoIlustracionNodo.bosque:
        _bosque(canvas, c, s);
      case TipoIlustracionNodo.catarata:
        _catarata(canvas, c, s);
    }

    if (resaltado) {
      canvas.drawCircle(
        c,
        s * 0.48,
        Paint()
          ..color = PaletaRutas.verdeOliva.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _pueblo(Canvas canvas, Offset c, double s) {
    // Cielo / base
    canvas.drawCircle(
      c.translate(0, s * 0.12),
      s * 0.22,
      Paint()..color = const Color(0xFF7EC8E3).withValues(alpha: 0.35),
    );
    // Cuerpo iglesia
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c.translate(0, s * 0.08), width: s * 0.55, height: s * 0.42),
      const Radius.circular(4),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFF2E6C9));
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFF8A5A3C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // Torre
    final torre = Rect.fromCenter(
      center: c.translate(0, -s * 0.12),
      width: s * 0.22,
      height: s * 0.38,
    );
    canvas.drawRect(torre, Paint()..color = const Color(0xFFE8D4A8));
    canvas.drawRect(
      torre,
      Paint()
        ..color = const Color(0xFF8A5A3C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    // Cúpula
    canvas.drawArc(
      Rect.fromCenter(center: c.translate(0, -s * 0.28), width: s * 0.28, height: s * 0.22),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFF3D7184),
    );
    canvas.drawCircle(
      c.translate(0, -s * 0.38),
      2.5,
      Paint()..color = const Color(0xFFC9A84C),
    );
  }

  void _ruinas(Canvas canvas, Offset c, double s) {
    final piedra = Paint()..color = const Color(0xFFB8A48A);
    final borde = Paint()
      ..color = const Color(0xFF5C4030)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final verde = Paint()..color = const Color(0xFF6E8B4A).withValues(alpha: 0.55);

    canvas.drawOval(
      Rect.fromCenter(center: c.translate(0, s * 0.28), width: s * 0.7, height: s * 0.18),
      verde,
    );

    for (var i = 0; i < 3; i++) {
      final x = c.dx - s * 0.28 + i * s * 0.28;
      final h = s * (0.35 + (i == 1 ? 0.2 : 0));
      final rect = Rect.fromLTWH(x - s * 0.1, c.dy + s * 0.15 - h, s * 0.2, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        piedra,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        borde,
      );
    }
  }

  void _terrazas(Canvas canvas, Offset c, double s) {
    final colores = [
      const Color(0xFF2D6A4F),
      const Color(0xFF40916C),
      const Color(0xFF52B788),
      const Color(0xFF95D5B2),
    ];
    for (var i = 0; i < colores.length; i++) {
      final t = i / (colores.length - 1);
      final w = s * (0.75 - t * 0.35);
      final h = s * 0.12;
      final y = c.dy - s * 0.28 + i * s * 0.16;
      final oval = Rect.fromCenter(center: Offset(c.dx, y), width: w, height: h);
      canvas.drawOval(oval, Paint()..color = colores[i]);
      canvas.drawOval(
        oval,
        Paint()
          ..color = const Color(0xFF1B4332)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }
  }

  void _montana(Canvas canvas, Offset c, double s, {required bool conNieve}) {
    final path = Path()
      ..moveTo(c.dx - s * 0.42, c.dy + s * 0.3)
      ..lineTo(c.dx - s * 0.08, c.dy - s * 0.35)
      ..lineTo(c.dx + s * 0.05, c.dy - s * 0.05)
      ..lineTo(c.dx + s * 0.18, c.dy - s * 0.28)
      ..lineTo(c.dx + s * 0.42, c.dy + s * 0.3)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF5B8C5A));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF2D5016)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    if (conNieve) {
      final nieve = Path()
        ..moveTo(c.dx - s * 0.08, c.dy - s * 0.35)
        ..lineTo(c.dx - s * 0.02, c.dy - s * 0.12)
        ..lineTo(c.dx + s * 0.04, c.dy - s * 0.22)
        ..close();
      canvas.drawPath(nieve, Paint()..color = Colors.white);
    }
    // Árboles pequeños
    canvas.drawCircle(
      c.translate(-s * 0.22, s * 0.18),
      s * 0.07,
      Paint()..color = const Color(0xFF2D6A4F),
    );
    canvas.drawCircle(
      c.translate(s * 0.24, s * 0.2),
      s * 0.06,
      Paint()..color = const Color(0xFF40916C),
    );
  }

  void _laguna(Canvas canvas, Offset c, double s) {
    canvas.drawOval(
      Rect.fromCenter(center: c, width: s * 0.7, height: s * 0.45),
      Paint()..color = const Color(0xFF48CAE4),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(0, -2), width: s * 0.45, height: s * 0.22),
      Paint()..color = const Color(0xFF90E0EF),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c, width: s * 0.7, height: s * 0.45),
      Paint()
        ..color = const Color(0xFF0077B6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  void _bosque(Canvas canvas, Offset c, double s) {
    void arbol(Offset p, double escala) {
      canvas.drawLine(
        p,
        p.translate(0, s * 0.18 * escala),
        Paint()
          ..color = const Color(0xFF8B5E3C)
          ..strokeWidth = 2.2 * escala,
      );
      canvas.drawCircle(
        p.translate(0, -s * 0.02 * escala),
        s * 0.12 * escala,
        Paint()..color = const Color(0xFF2D6A4F),
      );
      canvas.drawCircle(
        p.translate(0, -s * 0.1 * escala),
        s * 0.09 * escala,
        Paint()..color = const Color(0xFF40916C),
      );
    }

    arbol(c.translate(-s * 0.18, s * 0.05), 1);
    arbol(c.translate(s * 0.02, -s * 0.05), 1.15);
    arbol(c.translate(s * 0.2, s * 0.08), 0.9);
  }

  void _catarata(Canvas canvas, Offset c, double s) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(0, -s * 0.05), width: s * 0.35, height: s * 0.55),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF90E0EF),
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(c.dx - s * 0.08 + i * s * 0.08, c.dy - s * 0.25),
        Offset(c.dx - s * 0.08 + i * s * 0.08, c.dy + s * 0.22),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 1.5,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(0, s * 0.28), width: s * 0.5, height: s * 0.14),
      Paint()..color = const Color(0xFF48CAE4),
    );
  }

  @override
  bool shouldRepaint(covariant _PintorIlustracionColorida oldDelegate) {
    return oldDelegate.tipo != tipo || oldDelegate.resaltado != resaltado;
  }
}
