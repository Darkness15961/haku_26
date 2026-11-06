import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Indicador de espera compartido para cargas de página y de contenido.
///
/// Mantiene una sola implementación de la animación, respeta la preferencia
/// de movimiento reducido del sistema y conserva un indicador nativo como
/// respaldo si el recurso no pudiera decodificarse.
class CargadorHaku extends StatefulWidget {
  const CargadorHaku({
    super.key,
    this.mensaje = 'Preparando tu experiencia…',
    this.tamano = 120,
    this.centrado = true,
    this.retraso = const Duration(milliseconds: 250),
  });

  const CargadorHaku.pagina({
    super.key,
    this.mensaje = 'Preparando tu experiencia…',
  }) : tamano = 136,
       centrado = true,
       retraso = const Duration(milliseconds: 250);

  const CargadorHaku.contenido({super.key, this.mensaje})
    : tamano = 92,
      centrado = true,
      retraso = const Duration(milliseconds: 250);

  static const rutaAnimacion = 'assets/animaciones/travel.json';

  final String? mensaje;
  final double tamano;
  final bool centrado;
  final Duration retraso;

  @override
  State<CargadorHaku> createState() => _EstadoCargadorHaku();
}

class _EstadoCargadorHaku extends State<CargadorHaku> {
  bool _visible = false;
  Timer? _temporizadorVisibilidad;

  @override
  void initState() {
    super.initState();
    _programarVisibilidad();
  }

  void _programarVisibilidad() {
    if (widget.retraso == Duration.zero) {
      _visible = true;
    } else {
      _temporizadorVisibilidad = Timer(widget.retraso, () {
        if (!mounted) return;
        setState(() => _visible = true);
      });
    }
  }

  @override
  void dispose() {
    _temporizadorVisibilidad?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducirMovimiento = MediaQuery.disableAnimationsOf(context);
    final colorTexto = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.78);

    final contenido = Semantics(
      container: true,
      liveRegion: true,
      label: widget.mensaje ?? 'Cargando',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: widget.tamano,
            child: RepaintBoundary(
              child: Lottie.asset(
                CargadorHaku.rutaAnimacion,
                fit: BoxFit.contain,
                animate: !reducirMovimiento,
                repeat: !reducirMovimiento,
                frameRate: FrameRate.composition,
                renderCache: RenderCache.drawingCommands,
                frameBuilder: (_, child, composition) => Stack(
                  alignment: Alignment.center,
                  children: [
                    child,
                    if (composition == null)
                      const CircularProgressIndicator(strokeWidth: 2.5),
                  ],
                ),
                errorBuilder: (_, __, ___) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
          ),
          if (widget.mensaje != null) ...[
            const SizedBox(height: 12),
            ExcludeSemantics(
              child: Text(
                widget.mensaje!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorTexto,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final cargador = widget.centrado ? Center(child: contenido) : contenido;

    return AnimatedSwitcher(
      duration: reducirMovimiento
          ? Duration.zero
          : const Duration(milliseconds: 160),
      child: _visible
          ? KeyedSubtree(
              key: const ValueKey('cargador-visible'),
              child: cargador,
            )
          : const SizedBox.shrink(key: ValueKey('cargador-oculto')),
    );
  }
}
