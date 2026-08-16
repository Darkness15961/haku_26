import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../datos/mapa_aventura_datasource_local.dart';

/// Joystick virtual negro: solo cambia el destino seleccionado.
class JoystickNavegacionMapa extends StatefulWidget {
  final ValueChanged<DireccionJoystick> onDireccion;

  const JoystickNavegacionMapa({
    super.key,
    required this.onDireccion,
  });

  @override
  State<JoystickNavegacionMapa> createState() => _EstadoJoystickNavegacionMapa();
}

class _EstadoJoystickNavegacionMapa extends State<JoystickNavegacionMapa> {
  static const _lado = 112.0;
  static const _radioBase = 48.0;
  static const _radioStick = 22.0;
  static const _umbral = 16.0;

  Offset _stick = Offset.zero;
  DireccionJoystick? _ultima;

  void _actualizar(Offset local) {
    final centro = const Offset(_lado / 2, _lado / 2);
    var delta = local - centro;
    const max = _radioBase - _radioStick;
    if (delta.distance > max) {
      delta = Offset.fromDirection(delta.direction, max);
    }

    setState(() => _stick = delta);

    if (delta.distance < _umbral) {
      _ultima = null;
      return;
    }

    final angulo = delta.direction;
    final DireccionJoystick dir;
    if (angulo >= -math.pi / 4 && angulo < math.pi / 4) {
      dir = DireccionJoystick.derecha;
    } else if (angulo >= math.pi / 4 && angulo < 3 * math.pi / 4) {
      dir = DireccionJoystick.abajo;
    } else if (angulo >= -3 * math.pi / 4 && angulo < -math.pi / 4) {
      dir = DireccionJoystick.arriba;
    } else {
      dir = DireccionJoystick.izquierda;
    }

    if (_ultima != dir) {
      _ultima = dir;
      widget.onDireccion(dir);
    }
  }

  void _soltar() {
    setState(() => _stick = Offset.zero);
    _ultima = null;
  }

  @override
  Widget build(BuildContext context) {
    final centro = const Offset(_lado / 2, _lado / 2);

    return Material(
      elevation: 10,
      shadowColor: Colors.black54,
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: Container(
        width: _lado,
        height: _lado,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          border: Border.all(color: const Color(0xFF2A2A2A), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => _actualizar(d.localPosition),
          onPanUpdate: (d) => _actualizar(d.localPosition),
          onPanEnd: (_) => _soltar(),
          onPanCancel: _soltar,
          child: CustomPaint(
            size: const Size(_lado, _lado),
            painter: _PintorStick(
              centro: centro,
              stick: centro + _stick,
              radioStick: _radioStick,
            ),
          ),
        ),
      ),
    );
  }
}

class _PintorStick extends CustomPainter {
  final Offset centro;
  final Offset stick;
  final double radioStick;

  _PintorStick({
    required this.centro,
    required this.stick,
    required this.radioStick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final guia = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(centro.dx - 28, centro.dy),
      Offset(centro.dx + 28, centro.dy),
      guia,
    );
    canvas.drawLine(
      Offset(centro.dx, centro.dy - 28),
      Offset(centro.dx, centro.dy + 28),
      guia,
    );

    final sombra = Paint()
      ..color = Colors.black54
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(stick.translate(0, 3), radioStick, sombra);

    final knob = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF3A3A3A),
          Color(0xFF111111),
        ],
      ).createShader(Rect.fromCircle(center: stick, radius: radioStick));
    canvas.drawCircle(stick, radioStick, knob);

    canvas.drawCircle(
      stick,
      radioStick,
      Paint()
        ..color = const Color(0xFF555555)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawCircle(
      stick.translate(-6, -6),
      5,
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );
  }

  @override
  bool shouldRepaint(covariant _PintorStick oldDelegate) {
    return oldDelegate.stick != stick;
  }
}
