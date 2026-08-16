import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';

/// Ítem visual de la barra de navegación inferior curva.
class ItemBarraNavegacion {
  final IconData iconoNormal;
  final IconData iconoActivo;
  final String etiqueta;
  /// Botón central (+) que no es una pestaña.
  final bool esCentral;

  const ItemBarraNavegacion({
    required this.iconoNormal,
    required this.iconoActivo,
    required this.etiqueta,
    this.esCentral = false,
  });
}

/// Barra inferior con forma de montaña que se desliza al índice activo.
///
/// La curva no se recrea: un único [CustomPainter] interpola la posición
/// del pico entre pestañas. Respeta el SafeArea.
class BarraNavegacionCurva extends StatefulWidget {
  final int indiceActual;
  final List<ItemBarraNavegacion> items;
  final ValueChanged<int> onCambiar;

  const BarraNavegacionCurva({
    super.key,
    required this.indiceActual,
    required this.items,
    required this.onCambiar,
  });

  @override
  State<BarraNavegacionCurva> createState() => _EstadoBarraNavegacionCurva();
}

class _EstadoBarraNavegacionCurva extends State<BarraNavegacionCurva>
    with SingleTickerProviderStateMixin {
  static const _duracion = Duration(milliseconds: 420);
  static const _alturaBarra = 62.0;
  /// Pico más bajo y ancho → silueta de colina suave.
  static const _alturaMontana = 18.0;

  late AnimationController _controlador;
  late Animation<double> _animacionIndice;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(vsync: this, duration: _duracion);
    _animacionIndice = AlwaysStoppedAnimation(
      widget.indiceActual.toDouble(),
    );
  }

  @override
  void didUpdateWidget(covariant BarraNavegacionCurva oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.indiceActual != widget.indiceActual) {
      _animacionIndice = Tween<double>(
        begin: _animacionIndice.value,
        end: widget.indiceActual.toDouble(),
      ).animate(
        CurvedAnimation(parent: _controlador, curve: Curves.easeInOutCubic),
      );
      _controlador
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final totalItems = widget.items.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controlador,
          builder: (context, _) {
            final indiceSuave = _animacionIndice.value;

            return SizedBox(
              height: _alturaBarra + _alturaMontana + bottomInset,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PintorMontanaNavegacion(
                        indiceSuave: indiceSuave,
                        totalItems: totalItems,
                        alturaMontana: _alturaMontana,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _alturaMontana * 0.35,
                    bottom: bottomInset,
                    child: Row(
                      children: List.generate(totalItems, (index) {
                        final item = widget.items[index];
                        final distancia =
                            (indiceSuave - index).abs().clamp(0.0, 1.0);
                        final elevacion = (1.0 - distancia) * 6.0;
                        final esActivo = widget.indiceActual == index;

                        if (item.esCentral) {
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => widget.onCambiar(index),
                              behavior: HitTestBehavior.opaque,
                              child: const _BotonCentralPublicar(),
                            ),
                          );
                        }

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => widget.onCambiar(index),
                            behavior: HitTestBehavior.opaque,
                            child: Transform.translate(
                              offset: Offset(0, -elevacion),
                              child: _ItemNavegacion(
                                item: item,
                                esActivo: esActivo,
                                intensidad: 1.0 - distancia,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BotonCentralPublicar extends StatelessWidget {
  const _BotonCentralPublicar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.black,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _ItemNavegacion extends StatelessWidget {
  final ItemBarraNavegacion item;
  final bool esActivo;
  final double intensidad;

  const _ItemNavegacion({
    required this.item,
    required this.esActivo,
    required this.intensidad,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(
      Colors.white54,
      Colors.white,
      intensidad.clamp(0.0, 1.0),
    )!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (intensidad > 0.55)
          Opacity(
            opacity: ((intensidad - 0.55) / 0.45).clamp(0.0, 1.0),
            child: Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.35),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          )
        else
          const SizedBox(height: 6),
        Icon(
          esActivo ? item.iconoActivo : item.iconoNormal,
          color: color,
          size: 20 + (intensidad * 1.5),
        ),
        const SizedBox(height: 2),
        Text(
          item.etiqueta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TipografiaHaku.interfaz(
            fontSize: 10,
            fontWeight: esActivo ? FontWeight.w800 : FontWeight.w500,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

/// Dibuja la barra con un pico tipo colina suave centrado en [indiceSuave].
class _PintorMontanaNavegacion extends CustomPainter {
  final double indiceSuave;
  final int totalItems;
  final double alturaMontana;

  _PintorMontanaNavegacion({
    required this.indiceSuave,
    required this.totalItems,
    required this.alturaMontana,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final anchoItem = size.width / totalItems;
    final picoX = (indiceSuave + 0.5) * anchoItem;
    // Base ancha: la pendiente arranca lejos del centro → menos “pico afilado”.
    final mitadMontana = anchoItem * 1.05;
    final yBase = alturaMontana;
    // Cresta redondeada (no llega a y = 0).
    final yPico = alturaMontana * 0.18;

    Path construirSilueta() {
      final inicioMontana = (picoX - mitadMontana).clamp(0.0, size.width);
      final finMontana = (picoX + mitadMontana).clamp(0.0, size.width);

      final path = Path()
        ..moveTo(0, yBase)
        ..lineTo(inicioMontana, yBase);

      // Subida gradual (controles lejos del vértice).
      path.cubicTo(
        picoX - mitadMontana * 0.78,
        yBase,
        picoX - mitadMontana * 0.52,
        yBase * 0.55,
        picoX - mitadMontana * 0.22,
        yPico + (yBase - yPico) * 0.28,
      );
      path.cubicTo(
        picoX - mitadMontana * 0.08,
        yPico,
        picoX + mitadMontana * 0.08,
        yPico,
        picoX + mitadMontana * 0.22,
        yPico + (yBase - yPico) * 0.28,
      );
      // Bajada simétrica.
      path.cubicTo(
        picoX + mitadMontana * 0.52,
        yBase * 0.55,
        picoX + mitadMontana * 0.78,
        yBase,
        finMontana,
        yBase,
      );

      return path;
    }

    final pathBorde = construirSilueta()..lineTo(size.width, yBase);

    final path = construirSilueta()
      ..lineTo(size.width, yBase)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final rect = Offset.zero & size;

    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: 0.45),
      14,
      true,
    );

    final relleno = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1A1A1A),
          Color(0xFF0D0D0D),
          Colors.black,
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(rect);

    canvas.drawPath(path, relleno);

    final borde = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;

    canvas.drawPath(pathBorde, borde);

    final brillo = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(picoX, yPico + 2),
          radius: mitadMontana * 0.55,
        ),
      );
    canvas.drawCircle(
      Offset(picoX, yPico + 2),
      mitadMontana * 0.4,
      brillo,
    );
  }

  @override
  bool shouldRepaint(covariant _PintorMontanaNavegacion oldDelegate) {
    return oldDelegate.indiceSuave != indiceSuave ||
        oldDelegate.totalItems != totalItems ||
        oldDelegate.alturaMontana != alturaMontana;
  }
}
