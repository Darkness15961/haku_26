import 'package:flutter/material.dart';

import '../../../nucleo/widgets/badge_contador.dart';
import 'estilos_rutas.dart';

/// Duración y curvas compartidas del menú flotante HAKU.
const duracionMenuFlotante = Duration(milliseconds: 320);
const curvaAperturaMenu = Curves.easeOutCubic;
const curvaCierreMenu = Curves.easeInCubic;

/// Velo semitransparente con fade suave al abrir/cerrar el menú.
class VeloAccionesFlotante extends StatefulWidget {
  const VeloAccionesFlotante({
    super.key,
    required this.visible,
    required this.onTap,
  });

  final bool visible;
  final VoidCallback onTap;

  @override
  State<VeloAccionesFlotante> createState() => _VeloAccionesFlotanteState();
}

class _VeloAccionesFlotanteState extends State<VeloAccionesFlotante>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: duracionMenuFlotante,
  );

  @override
  void initState() {
    super.initState();
    if (widget.visible) _controller.value = 1;
  }

  @override
  void didUpdateWidget(VeloAccionesFlotante oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.value == 0) return const SizedBox.shrink();
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _controller,
            curve: curvaAperturaMenu,
            reverseCurve: curvaCierreMenu,
          ),
          child: GestureDetector(
            onTap: widget.onTap,
            child: ColoredBox(
              color: PaletaRutas.ink.withValues(alpha: 0.35),
            ),
          ),
        );
      },
    );
  }
}

/// Botón + sin contorno (detalle lugar/ruta) — distinto al + dorado del shell.
class MenuAccionesFlotante extends StatefulWidget {
  const MenuAccionesFlotante({
    super.key,
    required this.abierto,
    required this.onToggle,
    required this.opciones,
    this.contador = 0,
  });

  final bool abierto;
  final VoidCallback onToggle;
  final List<Widget> opciones;
  /// Badge numérico sobre el + (salidas, paradas…).
  final int contador;

  @override
  State<MenuAccionesFlotante> createState() => _MenuAccionesFlotanteState();
}

class _MenuAccionesFlotanteState extends State<MenuAccionesFlotante>
    with SingleTickerProviderStateMixin {
  late final AnimationController _menu = AnimationController(
    vsync: this,
    duration: duracionMenuFlotante,
  );

  @override
  void initState() {
    super.initState();
    if (widget.abierto) _menu.value = 1;
  }

  @override
  void didUpdateWidget(MenuAccionesFlotante oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.abierto != oldWidget.abierto) {
      if (widget.abierto) {
        _menu.forward();
      } else {
        _menu.reverse();
      }
    }
  }

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  Animation<double> _intervaloOpcion(int index, int total) {
    final paso = 1 / (total + 1);
    final inicio = index * paso * 0.55;
    final fin = (inicio + 0.45).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _menu,
      curve: Interval(inicio, fin, curve: curvaAperturaMenu),
      reverseCurve: curvaCierreMenu,
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.opciones.length;
    final mostrarBadge = widget.contador > 0 && !widget.abierto;

    return AnimatedBuilder(
      animation: _menu,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_menu.value);
        final esCerrar = t > 0.5;

        final icono = Transform.rotate(
          angle: t * 0.125 * 2 * 3.1415926535,
          child: Icon(
            esCerrar ? Icons.close_rounded : Icons.add_rounded,
            color: esCerrar ? PaletaRutas.piedra : Colors.white,
            size: 34,
            shadows: const [
              Shadow(
                color: Color(0xAA141210),
                blurRadius: 10,
                offset: Offset(0, 1),
              ),
            ],
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: _menu.value.clamp(0.001, 1.0),
                child: IgnorePointer(
                  ignoring: _menu.value < 0.05,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < n; i++) ...[
                        _OpcionAnimada(
                          animation: _intervaloOpcion(i, n),
                          child: widget.opciones[i],
                        ),
                        if (i < n - 1) const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
            Tooltip(
              message: widget.abierto ? 'Cerrar' : 'Acciones',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onToggle,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: mostrarBadge
                          ? BadgeContadorOverlay(
                              cantidad: widget.contador,
                              compacto: true,
                              child: icono,
                            )
                          : icono,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OpcionAnimada extends StatelessWidget {
  const _OpcionAnimada({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.28),
          end: Offset.zero,
        ).animate(animation),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1).animate(animation),
          alignment: Alignment.bottomRight,
          child: child,
        ),
      ),
    );
  }
}
