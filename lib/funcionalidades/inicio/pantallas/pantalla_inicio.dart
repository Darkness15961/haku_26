import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../perfil_usuario/indice.dart';
import '../../publicaciones/indice.dart';
import '../../rutas/indice.dart';
import '../proveedores/proveedor_mapa_cusco.dart';
import '../widgets/barra_navegacion_curva.dart';
import '../widgets/contenido_inicio.dart';
import 'pantalla_feed_inicio.dart';

/// Pantalla principal: 4 tabs + acción central (+).
class PantallaInicio extends ConsumerStatefulWidget {
  const PantallaInicio({super.key});

  @override
  ConsumerState<PantallaInicio> createState() => _EstadoPantallaInicio();
}

class _EstadoPantallaInicio extends ConsumerState<PantallaInicio> {
  /// 0 Inicio, 1 Explora, 2 Rutas, 3 Perfil
  int _indiceSeleccionado = 0;

  static const List<Widget> _pantallas = [
    PantallaFeedInicio(),
    ContenidoInicio(),
    PantallaRutas(),
    PantallaPerfilUsuario(),
  ];

  /// Visual: Inicio | Explora | + | Rutas | Perfil
  static const List<ItemBarraNavegacion> _itemsNavegacion = [
    ItemBarraNavegacion(
      iconoNormal: Icons.grid_view_outlined,
      iconoActivo: Icons.grid_view_rounded,
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
      iconoNormal: Icons.map_outlined,
      iconoActivo: Icons.map_rounded,
      etiqueta: 'Rutas',
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

    // Perfil requiere sesión.
    if (stack == 3) {
      final ok = await asegurarSesion(context, ref);
      if (!ok || !mounted) return;
    }

    if (stack == _indiceSeleccionado) return;
    ref.read(mapasCuscoProvider.notifier).deseleccionarProvincia();
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
