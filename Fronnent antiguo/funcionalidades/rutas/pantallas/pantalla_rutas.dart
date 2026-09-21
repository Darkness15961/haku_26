import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inicio/proveedores/proveedor_navegacion_inicio.dart';
import '../widgets/estilos_rutas.dart';
import '../widgets/lista_rutas_explora.dart';

/// Abre la lista de rutas en una pantalla propia (Explora ya no tiene segmentos).
class PantallaRutas extends ConsumerWidget {
  const PantallaRutas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        title: Text(
          'Rutas',
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: PaletaRutas.piedra,
          ),
        ),
      ),
      body: ListaRutasExplora(bottomPadding: bottom),
    );
  }
}

/// Lleva al tab Explora (islas).
void irAExploraShell(WidgetRef ref) {
  ref.read(pestaniaShellInicioProvider.notifier).state = 1;
}
