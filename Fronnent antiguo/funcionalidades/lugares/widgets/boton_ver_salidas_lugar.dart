import 'package:flutter/material.dart';

import '../../comunidad/datos/salidas_datasource_local.dart';
import '../../comunidad/pantallas/pantalla_salidas.dart';
import '../../rutas/widgets/estilos_rutas.dart';

/// Botón «Ver salidas» — brilla en oro si hay salidas grupales.
class BotonVerSalidasLugar extends StatefulWidget {
  const BotonVerSalidasLugar({
    super.key,
    required this.lugarId,
    this.lugarNombre,
  });

  final String lugarId;
  final String? lugarNombre;

  @override
  State<BotonVerSalidasLugar> createState() => _EstadoBotonVerSalidasLugar();
}

class _EstadoBotonVerSalidasLugar extends State<BotonVerSalidasLugar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _glow;

  int get _nSalidas =>
      SalidasDataSourceLocal.instancia.todas(lugarId: widget.lugarId).length;

  bool get _haySalidas => _nSalidas > 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _glow = Tween<double>(begin: 0.35, end: 1).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (_haySalidas) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BotonVerSalidasLugar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_haySalidas && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_haySalidas && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0.35;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _abrir() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaSalidas(lugarId: widget.lugarId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = _nSalidas;
    final label = n == 0
        ? 'Ver salidas'
        : n == 1
            ? 'Ver salidas grupales (1)'
            : 'Ver salidas grupales ($n)';

    if (!_haySalidas) {
      return OutlinedButton.icon(
        onPressed: _abrir,
        style: OutlinedButton.styleFrom(
          foregroundColor: PaletaRutas.piedra,
          side: BorderSide(color: PaletaRutas.plomo.withValues(alpha: 0.65)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.groups_outlined),
        label: Text(
          label,
          style: TipografiaHaku.interfaz(fontWeight: FontWeight.w700),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        final t = _glow.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: PaletaRutas.oro.withValues(alpha: 0.25 + 0.45 * t),
                blurRadius: 8 + 14 * t,
                spreadRadius: 0.5 + 1.5 * t,
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: _abrir,
            style: FilledButton.styleFrom(
              backgroundColor: Color.lerp(
                PaletaRutas.oroOscuro,
                PaletaRutas.oro,
                t,
              ),
              foregroundColor: PaletaRutas.ink,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.groups_rounded),
            label: Text(
              label,
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w800,
                color: PaletaRutas.ink,
              ),
            ),
          ),
        );
      },
    );
  }
}
