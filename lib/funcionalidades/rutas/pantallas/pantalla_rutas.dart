import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lugares/proveedores/proveedor_explora_ui.dart';
import '../widgets/estilos_rutas.dart';

/// Puente legacy: abre Explora → Rutas y cierra si venía de un push.
class PantallaRutas extends ConsumerStatefulWidget {
  const PantallaRutas({super.key});

  @override
  ConsumerState<PantallaRutas> createState() => _EstadoPantallaRutasRedirect();
}

class _EstadoPantallaRutasRedirect extends ConsumerState<PantallaRutas> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      irAExplora(ref, modo: ModoExplora.rutas);
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SizedBox.shrink(),
    );
  }
}
