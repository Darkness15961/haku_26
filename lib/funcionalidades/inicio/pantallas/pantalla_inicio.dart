import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../comunidad/indice.dart';
import '../../lugares/pantallas/pantalla_explora_lugares.dart';
import '../../perfil_usuario/indice.dart';
import '../../publicaciones/indice.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../../nucleo/demo/senales_atencion.dart';
import '../../../nucleo/navegacion/abrir_pantalla_haku.dart';
import '../../../nucleo/navegacion/control_retroceso.dart';
import '../../../nucleo/recursos/copy_haku.dart';
import '../../../nucleo/responsive/espacio_haku.dart';
import '../proveedores/proveedor_almacen_feed.dart';
import '../proveedores/proveedor_navegacion_inicio.dart';
import '../widgets/barra_navegacion_curva.dart';
import '../widgets/riel_navegacion_haku.dart';
import 'pantalla_feed_inicio.dart';

/// Shell Fase 1: Inicio | Explora | + | Comunidad | Perfil
/// Portrait → barra inferior · Landscape → riel lateral (libera altura).
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
      etiqueta: CopyHaku.tabInicio,
    ),
    ItemBarraNavegacion(
      iconoNormal: Icons.explore_outlined,
      iconoActivo: Icons.explore_rounded,
      etiqueta: CopyHaku.tabExplora,
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
      etiqueta: CopyHaku.tabComunidad,
    ),
    ItemBarraNavegacion(
      iconoNormal: Icons.person_outline_rounded,
      iconoActivo: Icons.person_rounded,
      etiqueta: CopyHaku.tabPerfil,
    ),
  ];

  int _indiceVisualDesdeStack(int stack) => stack < 2 ? stack : stack + 1;

  int? _indiceStackDesdeVisual(int visual) {
    if (visual == 2) return null;
    return visual < 2 ? visual : visual - 1;
  }

  void _irATab(int stack) {
    ref.read(pestaniaShellInicioProvider.notifier).state = stack;
    setState(() => _indiceSeleccionado = stack);
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
    _irATab(stack);
  }

  Future<void> _abrirPublicar() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    final done = await abrirPantallaHaku<bool>(
      context,
      const PantallaPublicaciones(),
    );
    // Cierra el hilo: feed remoto se refresca aunque Comunidad no estuviera visible.
    if (done == true && mounted) {
      notificarPublicacionesCambiaron(ref);
    }
  }

  void _onRetrocesoSistema(bool didPop, Object? result) {
    if (didPop) return;
    ControlRetrocesoShell.alIntentarSalirDelShell(
      context: context,
      indiceTab: _indiceSeleccionado,
      irATab: _irATab,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(almacenFeedProvider);
    ref.listen<int>(pestaniaShellInicioProvider, (prev, next) {
      if (next != _indiceSeleccionado && mounted) {
        setState(() => _indiceSeleccionado = next);
      }
    });

    final pendientes = SenalesAtencion.totalPendientesComunidad();
    final contadorNav = [0, 0, 0, pendientes, 0];
    final puedePopRuta = Navigator.of(context).canPop();
    final riel = EspacioHaku.usarRielLateral(context);

    // Mismo árbol de contenido al rotar: solo aparece/desaparece el riel.
    // Evita remount del IndexedStack (crash intermitente al voltear).
    return PopScope(
      canPop: puedePopRuta,
      onPopInvokedWithResult: _onRetrocesoSistema,
      child: Scaffold(
        backgroundColor: PaletaRutas.ink,
        extendBody: !riel,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (riel) ...[
              RielNavegacionHaku(
                indiceActual: _indiceVisualDesdeStack(_indiceSeleccionado),
                items: _itemsNavegacion,
                contadorPorIndice: contadorNav,
                onCambiar: _seleccionarPestaniaVisual,
              ),
              Container(
                width: 0.6,
                color: PaletaRutas.plomoOscuro.withValues(alpha: 0.55),
              ),
            ],
            Expanded(
              child: IndexedStack(
                index: _indiceSeleccionado,
                sizing: StackFit.expand,
                children: _pantallas,
              ),
            ),
          ],
        ),
        bottomNavigationBar: riel
            ? null
            : BarraNavegacionCurva(
                indiceActual: _indiceVisualDesdeStack(_indiceSeleccionado),
                items: _itemsNavegacion,
                contadorPorIndice: contadorNav,
                onCambiar: _seleccionarPestaniaVisual,
                compacta: EspacioHaku.esAlturaCorta(context),
              ),
      ),
    );
  }
}
