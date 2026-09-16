import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/indice.dart';
import '../../rutas/widgets/estilos_rutas.dart';

/// Compat: delega en [abrirChatComunidad] (mismo flujo de crear/abrir).
class PantallaChatComunidad extends ConsumerStatefulWidget {
  const PantallaChatComunidad({
    super.key,
    required this.comunidadId,
    this.titulo,
  });

  final String comunidadId;
  final String? titulo;

  @override
  ConsumerState<PantallaChatComunidad> createState() =>
      _EstadoPantallaChatComunidad();
}

class _EstadoPantallaChatComunidad extends ConsumerState<PantallaChatComunidad> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _abrir());
  }

  Future<void> _abrir() async {
    await abrirChatComunidad(
      context,
      ref,
      comunidadId: widget.comunidadId,
      titulo: widget.titulo,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: const Center(
        child: CircularProgressIndicator(color: PaletaRutas.oro),
      ),
    );
  }
}
