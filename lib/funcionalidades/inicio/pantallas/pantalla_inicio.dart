import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../comunidad/indice.dart';
import '../../perfil_usuario/indice.dart';
import '../../publicaciones/indice.dart';
import '../widgets/barra_navegacion_curva.dart';
import '../widgets/contenido_inicio.dart';
import 'pantalla_feed_inicio.dart';

/// Shell: Inicio | Explora | + | Comunidad | Perfil
class PantallaInicio extends ConsumerStatefulWidget {
  const PantallaInicio({super.key});

  @override
  ConsumerState<PantallaInicio> createState() => _EstadoPantallaInicio();
}

class _EstadoPantallaInicio extends ConsumerState<PantallaInicio> {
  /// 0 Inicio, 1 Explora, 2 Comunidad, 3 Perfil
  int _indiceSeleccionado = 0;

  static const List<Widget> _pantallas = [
    PantallaFeedInicio(),
    ContenidoInicio(),
    PantallaComunidad(),
    PantallaPerfilUsuario(),
  ];

  static const List<ItemBarraNavegacion> _itemsNavegacion = [
    ItemBarraNavegacion(
      iconoNormal: Icons.home_outlined,
      iconoActivo: Icons.home_rounded,
      etiqueta: 'Inicio',
    ),
    ItemBarraNavegacion(
      iconoNormal: Icons.compass_calibration_outlined,
      iconoActivo: Icons.compass_calibration_rounded,
      etiqueta: 'Explora',
    ),
    ItemBarraNavegacion(
      iconoNormal: Icons.add_rounded,
      iconoActivo: Icons.add_rounded,
      etiqueta: '',
      esCentral: true,
    ),
    ItemBarraNavegacion(
      iconoNormal: Icons.groups_outlined,
      iconoActivo: Icons.groups_rounded,
      etiqueta: 'Comunidad',
    ),
    ItemBarraNavegacion(
      iconoNormal: Icons.person_outline_rounded,
      iconoActivo: Icons.person_rounded,
      etiqueta: 'Perfil',
    ),
  ];

  int _indiceVisualDesdeStack(int stack) => stack < 2 ? stack : stack + 1;

  int? _indiceStackDesdeVisual(int visual) {
    if (visual == 2) return null;
    return visual < 2 ? visual : visual - 1;
  }

  Future<void> _seleccionarPestaniaVisual(int visual) async {
    final stack = _indiceStackDesdeVisual(visual);
    if (stack == null) {
      await _abrirPublicar();
      return;
    }

    if (stack == 3) {
      final ok = await asegurarSesion(context, ref);
      if (!ok || !mounted) return;
    }

    if (stack == _indiceSeleccionado) return;
    setState(() => _indiceSeleccionado = stack);
  }

  Future<void> _abrirPublicar() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PantallaPublicaciones(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: IndexedStack(
        index: _indiceSeleccionado,
        children: _pantallas,
      ),
      bottomNavigationBar: BarraNavegacionCurva(
        indiceActual: _indiceVisualDesdeStack(_indiceSeleccionado),
        items: _itemsNavegacion,
        onCambiar: _seleccionarPestaniaVisual,
      ),
    );
  }
}
