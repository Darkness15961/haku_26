import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../chat/indice.dart';
import '../../rutas/widgets/estilos_rutas.dart';

/// Compat: asegura sala de comunidad y muestra [PantallaChatSala].
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
  String? _salaId;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _abrir());
  }

  Future<void> _abrir() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    try {
      final salaId = await ref
          .read(chatDataSourceProvider)
          .asegurarSalaComunidad(widget.comunidadId);
      if (!mounted) return;
      setState(() => _salaId = salaId);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      mostrarSnackHaku(context, e.message);
    } catch (_) {
      if (!mounted) return;
      const msg =
          'No se pudo abrir el chat. Si sos miembro, pedile al admin que lo active.';
      setState(() => _error = msg);
      mostrarSnackHaku(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = (widget.titulo?.trim().isNotEmpty ?? false)
        ? widget.titulo!.trim()
        : 'Chat';

    if (_salaId != null) {
      return PantallaChatSala(
        salaId: _salaId!,
        titulo: titulo,
        comunidadId: widget.comunidadId,
      );
    }

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        elevation: 0,
        title: Text(
          titulo,
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
      ),
      body: Center(
        child: _error == null
            ? const CircularProgressIndicator(color: PaletaRutas.oro)
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
                ),
              ),
      ),
    );
  }
}
