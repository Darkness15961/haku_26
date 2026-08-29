import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/widgets/avatar_haku.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../proveedores/proveedor_almacen_feed.dart';

/// Chat 1:1 con un explorador.
class PantallaChatDirecto extends ConsumerStatefulWidget {
  final SugerenciaSeguimiento persona;

  const PantallaChatDirecto({super.key, required this.persona});

  @override
  ConsumerState<PantallaChatDirecto> createState() =>
      _EstadoPantallaChatDirecto();
}

class _EstadoPantallaChatDirecto extends ConsumerState<PantallaChatDirecto> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    _ctrl.clear();
    await ref.read(almacenFeedProvider.notifier).agregarMensajeDirecto(
          conversacionId: widget.persona.id,
          texto: t,
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.persona;
    final persistidos = ref
        .watch(almacenFeedProvider)
        .mensajesDirectos
        .where((m) => m.conversacionId == p.id)
        .toList()
      ..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
    final mensajes = persistidos.isEmpty
        ? const [_Mensaje(mio: false, texto: 'Hola.')]
        : [
            for (final m in persistidos)
              _Mensaje(
                mio: m.autorId == AlmacenFeedNotifier.idUsuarioLocal,
                texto: m.texto,
              ),
          ];
    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  AvatarHaku(url: p.avatarUrl, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nombre,
                          style: TipografiaHaku.titulo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                        Text(
                          p.usuario,
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            color: PaletaRutas.plomoClaro,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: LineaEncabezadoInca(altura: 2),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                itemCount: mensajes.length,
                itemBuilder: (context, i) {
                  final m = mensajes[i];
                  return Align(
                    alignment:
                        m.mio ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: m.mio
                            ? PaletaRutas.oro
                            : PaletaRutas.carbon,
                        borderRadius: BorderRadius.circular(16),
                        border: m.mio
                            ? null
                            : Border.all(
                                color: PaletaRutas.plomoOscuro
                                    .withValues(alpha: 0.7),
                              ),
                      ),
                      child: Text(
                        m.texto,
                        style: TipografiaHaku.interfaz(
                          fontSize: 14,
                          color: m.mio
                              ? PaletaRutas.ink
                              : PaletaRutas.piedra,
                          height: 1.35,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviar(),
                      style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                      cursorColor: PaletaRutas.oro,
                      decoration: InputDecoration(
                        hintText: 'Mensaje',
                        hintStyle: TipografiaHaku.interfaz(
                          color: PaletaRutas.plomo,
                        ),
                        filled: true,
                        fillColor: PaletaRutas.carbon,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: PaletaRutas.plomoOscuro
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: PaletaRutas.plomoOscuro
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: PaletaRutas.oro),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _enviar,
                    style: IconButton.styleFrom(
                      backgroundColor: PaletaRutas.oro,
                      foregroundColor: PaletaRutas.ink,
                    ),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Mensaje {
  final bool mio;
  final String texto;

  const _Mensaje({required this.mio, required this.texto});
}
