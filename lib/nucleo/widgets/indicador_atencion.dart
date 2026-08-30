import 'package:flutter/material.dart';

import '../../funcionalidades/rutas/widgets/estilos_rutas.dart';

enum IndicadorAtencionTamano { normal, pequeno, mini }

/// Badge animado (!, punto o número) para señalar acción pendiente.
class IndicadorAtencion extends StatefulWidget {
  const IndicadorAtencion({
    super.key,
    this.tamano = IndicadorAtencionTamano.normal,
    this.texto,
    this.icono = Icons.priority_high_rounded,
  });

  const IndicadorAtencion.punto({
    super.key,
    this.tamano = IndicadorAtencionTamano.mini,
  })  : texto = null,
        icono = null;

  const IndicadorAtencion.numero({
    super.key,
    required String this.texto,
    this.tamano = IndicadorAtencionTamano.pequeno,
  }) : icono = null;

  final IndicadorAtencionTamano tamano;
  final String? texto;
  final IconData? icono;

  double get _diametro => switch (tamano) {
        IndicadorAtencionTamano.normal => 22,
        IndicadorAtencionTamano.pequeno => 18,
        IndicadorAtencionTamano.mini => 10,
      };

  @override
  State<IndicadorAtencion> createState() => _IndicadorAtencionState();
}

class _IndicadorAtencionState extends State<IndicadorAtencion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget._diametro;
    final esPunto = widget.icono == null && widget.texto == null;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        final halo = 1 + t * 0.55;
        final bounce = 1 + (t < 0.5 ? t : 1 - t) * 0.12;

        return SizedBox(
          width: d * halo + 6,
          height: d * halo + 6,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.scale(
                scale: halo,
                child: Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PaletaRutas.atencion.withValues(alpha: 0.35 * (1 - t)),
                    border: Border.all(
                      color: PaletaRutas.atencionBrillo.withValues(alpha: 0.5 * (1 - t)),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: bounce,
                child: Container(
                  width: d,
                  height: d,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: esPunto ? PaletaRutas.atencion : PaletaRutas.piedra,
                    border: Border.all(
                      color: PaletaRutas.ink,
                      width: esPunto ? 0 : 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: PaletaRutas.atencion.withValues(alpha: 0.55),
                        blurRadius: 6,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  child: esPunto
                      ? null
                      : widget.texto != null
                          ? Text(
                              widget.texto!,
                              style: TipografiaHaku.interfaz(
                                fontSize: d * 0.48,
                                fontWeight: FontWeight.w900,
                                color: PaletaRutas.ink,
                                height: 1,
                              ),
                            )
                          : Icon(
                              widget.icono,
                              size: d * 0.72,
                              color: PaletaRutas.atencion,
                            ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Coloca [IndicadorAtencion] sobre la esquina de un hijo (FAB, icono de tab…).
class IndicadorAtencionOverlay extends StatelessWidget {
  const IndicadorAtencionOverlay({
    super.key,
    required this.mostrar,
    required this.child,
    this.tamano = IndicadorAtencionTamano.normal,
    this.texto,
    this.punto = false,
    this.alineacion = Alignment.topRight,
  });

  final bool mostrar;
  final Widget child;
  final IndicadorAtencionTamano tamano;
  final String? texto;
  final bool punto;
  final Alignment alineacion;

  @override
  Widget build(BuildContext context) {
    if (!mostrar) return child;

    final indicador = punto
        ? IndicadorAtencion.punto(tamano: tamano)
        : texto != null
            ? IndicadorAtencion.numero(texto: texto!, tamano: tamano)
            : IndicadorAtencion(tamano: tamano);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        child,
        Positioned(
          right: alineacion == Alignment.topRight ? -2 : null,
          left: alineacion == Alignment.topLeft ? -2 : null,
          top: -2,
          child: indicador,
        ),
      ],
    );
  }
}
