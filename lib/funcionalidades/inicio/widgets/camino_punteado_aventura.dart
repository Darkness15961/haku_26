import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Camino de huellas entre dos puntos; animadas si estan resaltadas.
class CaminoPunteadoAventura extends StatefulWidget {
  final Offset desde;
  final Offset hasta;
  final bool resaltado;

  const CaminoPunteadoAventura({
    super.key,
    required this.desde,
    required this.hasta,
    this.resaltado = false,
  });

  @override
  State<CaminoPunteadoAventura> createState() => _EstadoCaminoPunteadoAventura();
}

class _EstadoCaminoPunteadoAventura extends State<CaminoPunteadoAventura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.resaltado) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant CaminoPunteadoAventura oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resaltado && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.resaltado && _ctrl.isAnimating) {
      _ctrl
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _PintorCaminoHuellas(
            desde: widget.desde,
            hasta: widget.hasta,
            resaltado: widget.resaltado,
            fase: widget.resaltado ? _ctrl.value : 0,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _PintorCaminoHuellas extends CustomPainter {
  final Offset desde;
  final Offset hasta;
  final bool resaltado;
  final double fase;

  _PintorCaminoHuellas({
    required this.desde,
    required this.hasta,
    required this.resaltado,
    required this.fase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final distancia = (hasta - desde).distance;
    if (distancia < 1) return;

    final direccion = (hasta - desde) / distancia;
    final angulo = math.atan2(direccion.dy, direccion.dx);
    final perpendicular = Offset(-direccion.dy, direccion.dx);

    const paso = 16.0;
    const separacionLateral = 3.2;
    final colorRgb = Colors.black;
    final alphaBase = resaltado ? 0.85 : 0.55;
    const escalaHuella = 0.55;

    var recorrido = 10.0;
    var pieIzquierdo = true;
    var indice = 0;

    while (recorrido < distancia - 8) {
      final pulse = resaltado
          ? 0.55 +
              0.45 *
                  (0.5 +
                      0.5 *
                          math.sin(
                            (fase * math.pi * 2) + indice * 0.7,
                          ))
          : 1.0;
      final paint = Paint()
        ..color = colorRgb.withValues(alpha: alphaBase * pulse)
        ..style = PaintingStyle.fill;

      final centro = desde +
          direccion * recorrido +
          perpendicular * (pieIzquierdo ? -separacionLateral : separacionLateral);

      canvas.save();
      canvas.translate(centro.dx, centro.dy);
      canvas.rotate(angulo + math.pi / 2);
      if (!pieIzquierdo) {
        canvas.scale(-1, 1);
      }
      _dibujarHuella(canvas, paint, escalaHuella * (resaltado ? 1.1 : 1.0));
      canvas.restore();

      recorrido += paso;
      pieIzquierdo = !pieIzquierdo;
      indice++;
    }
  }

  void _dibujarHuella(Canvas canvas, Paint paint, double escala) {
    final planta = Path()
      ..moveTo(0, -7 * escala)
      ..quadraticBezierTo(4.2 * escala, -6 * escala, 4.5 * escala, -1 * escala)
      ..quadraticBezierTo(4.2 * escala, 3.5 * escala, 2.2 * escala, 5.5 * escala)
      ..quadraticBezierTo(0, 7.2 * escala, -2.2 * escala, 5.5 * escala)
      ..quadraticBezierTo(-4.2 * escala, 3.5 * escala, -4.5 * escala, -1 * escala)
      ..quadraticBezierTo(-4.2 * escala, -6 * escala, 0, -7 * escala)
      ..close();

    canvas.drawPath(planta, paint);

    final dedo = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-2.4 * escala, -9.2 * escala),
        width: 2.4 * escala,
        height: 3.2 * escala,
      ),
      dedo,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-0.6 * escala, -9.8 * escala),
        width: 2.6 * escala,
        height: 3.6 * escala,
      ),
      dedo,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(1.2 * escala, -9.5 * escala),
        width: 2.3 * escala,
        height: 3.2 * escala,
      ),
      dedo,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(2.8 * escala, -8.6 * escala),
        width: 2.0 * escala,
        height: 2.8 * escala,
      ),
      dedo,
    );
  }

  @override
  bool shouldRepaint(covariant _PintorCaminoHuellas oldDelegate) {
    return oldDelegate.desde != desde ||
        oldDelegate.hasta != hasta ||
        oldDelegate.resaltado != resaltado ||
        oldDelegate.fase != fase;
  }
}
