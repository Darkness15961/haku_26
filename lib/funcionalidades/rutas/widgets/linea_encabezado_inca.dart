import 'package:flutter/material.dart';

/// Franja fina bajo encabezados.
class LineaEncabezadoInca extends StatelessWidget {
  final double altura;
  final Color color;

  const LineaEncabezadoInca({
    super.key,
    this.altura = 2,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: altura,
      child: ColoredBox(color: color),
    );
  }
}
