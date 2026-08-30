import 'package:flutter/material.dart';

import 'estilos_rutas.dart';

const _duracionMenu = Duration(milliseconds: 320);
const _curvaApertura = Curves.easeOutCubic;
const _curvaCierre = Curves.easeInCubic;

/// Botón circular solo icono (menús flotantes HAKU).
class BotonIconoAccion extends StatelessWidget {
  const BotonIconoAccion({
    super.key,
    required this.tooltip,
    required this.icono,
    required this.onTap,
    this.destacado = false,
    this.badge,
    this.tamano = 46,
  });

  final String tooltip;
  final IconData icono;
  final VoidCallback onTap;
  final bool destacado;
  final String? badge;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Ink(
                width: tamano,
                height: tamano,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: destacado
                      ? PaletaRutas.oro.withValues(alpha: 0.92)
                      : PaletaRutas.carbon,
                  border: Border.all(
                    color: destacado
                        ? PaletaRutas.oroOscuro.withValues(alpha: 0.35)
                        : PaletaRutas.plomo.withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: PaletaRutas.ink.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icono,
                  size: tamano * 0.48,
                  color: destacado ? PaletaRutas.ink : PaletaRutas.oro,
                ),
              ),
              if (badge != null)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: PaletaRutas.oro,
                      shape: BoxShape.circle,
                      border: Border.all(color: PaletaRutas.ink, width: 1.2),
                    ),
                    child: Text(
                      badge!,
                      style: TipografiaHaku.interfaz(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: PaletaRutas.ink,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    duration: _duracionMenu,
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
            curve: _curvaApertura,
            reverseCurve: _curvaCierre,
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

/// Botón principal + desplegable (solo iconos), con transición suave.
class MenuAccionesFlotante extends StatefulWidget {
  const MenuAccionesFlotante({
    super.key,
    required this.abierto,
    required this.onToggle,
    required this.opciones,
  });

  final bool abierto;
  final VoidCallback onToggle;
  final List<Widget> opciones;

  @override
  State<MenuAccionesFlotante> createState() => _MenuAccionesFlotanteState();
}

class _MenuAccionesFlotanteState extends State<MenuAccionesFlotante>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duracionMenu,
  );

  @override
  void initState() {
    super.initState();
    if (widget.abierto) _controller.value = 1;
  }

  @override
  void didUpdateWidget(MenuAccionesFlotante oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.abierto != oldWidget.abierto) {
      if (widget.abierto) {
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

  Animation<double> _intervaloOpcion(int index, int total) {
    final paso = 1 / (total + 1);
    final inicio = index * paso * 0.55;
    final fin = (inicio + 0.45).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(inicio, fin, curve: _curvaApertura),
      reverseCurve: _curvaCierre,
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.opciones.length;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: _controller.value.clamp(0.001, 1.0),
                child: IgnorePointer(
                  ignoring: _controller.value < 0.05,
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
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(PaletaRutas.oro, PaletaRutas.carbon, t),
                      border: Border.all(
                        color: Color.lerp(
                          PaletaRutas.oroOscuro.withValues(alpha: 0.4),
                          PaletaRutas.plomo.withValues(alpha: 0.5),
                          t,
                        )!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: PaletaRutas.ink
                              .withValues(alpha: 0.25 + 0.2 * t),
                          blurRadius: 8 + 4 * t,
                          offset: Offset(0, 2 + 2 * t),
                        ),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: _controller.value * 0.125 * 2 * 3.1415926535,
                      child: Icon(
                        _controller.value > 0.5
                            ? Icons.close_rounded
                            : Icons.add_rounded,
                        color: Color.lerp(PaletaRutas.ink, PaletaRutas.piedra, t),
                        size: 26,
                      ),
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
