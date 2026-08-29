import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../comunidad/indice.dart';
import '../../lugares/pantallas/pantalla_explora_lugares.dart';
import '../../perfil_usuario/indice.dart';
import '../../publicaciones/indice.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../proveedores/proveedor_navegacion_inicio.dart';
import '../widgets/barra_navegacion_curva.dart';
import 'pantalla_feed_inicio.dart';

/// Shell Fase 1: Inicio (aportes) | Explora (lugares) | + (publicar) | Comunidad | Perfil
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
    PantallaExploraLugares(),
    PantallaComunidad(),
    PantallaPerfilUsuario(),
  ];

  static const List<ItemBarraNavegacion> _itemsNavegacion = [
    ItemBarraNavegacion(
      iconoNormal: Icons.auto_awesome_outlined,
      iconoActivo: Icons.auto_awesome,
      etiqueta: 'Descubre',
    ),
    ItemBarraNavegacion(
      iconoNormal: Icons.explore_outlined,
      iconoActivo: Icons.explore_rounded,
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
    ref.read(pestaniaShellInicioProvider.notifier).state = stack;
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
    ref.listen<int>(pestaniaShellInicioProvider, (prev, next) {
      if (next != _indiceSeleccionado && mounted) {
        setState(() => _indiceSeleccionado = next);
      }
    });

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
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
