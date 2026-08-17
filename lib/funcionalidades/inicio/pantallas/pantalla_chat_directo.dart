import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/feed_inicio_datasource_local.dart';

/// Chat 1:1 con un explorador.
class PantallaChatDirecto extends StatefulWidget {
  final SugerenciaSeguimiento persona;

  const PantallaChatDirecto({super.key, required this.persona});

  @override
  State<PantallaChatDirecto> createState() => _EstadoPantallaChatDirecto();
}

class _EstadoPantallaChatDirecto extends State<PantallaChatDirecto> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  late final List<_Mensaje> _mensajes;

  @override
  void initState() {
    super.initState();
    _mensajes = [
      _Mensaje(
        mio: false,
        texto: 'Hola, vi tu perfil en HAKU. ¿Sale alguna ruta esta semana?',
      ),
    ];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _enviar() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _mensajes.add(_Mensaje(mio: true, texto: t));
      _ctrl.clear();
    });
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: FondoSuaveSeccion(
        child: SafeArea(
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
                      color: PaletaRutas.marronOscuro,
                    ),
                  ),
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: p.avatarUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
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
                          ),
                        ),
                        Text(
                          p.usuario,
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            color: PaletaRutas.marronCuero,
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
                itemCount: _mensajes.length,
                itemBuilder: (context, i) {
                  final m = _mensajes[i];
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
                            ? PaletaRutas.marronOscuro
                            : Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        m.texto,
                        style: TipografiaHaku.interfaz(
                          fontSize: 14,
                          color: m.mio ? Colors.white : PaletaRutas.marronOscuro,
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
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje…',
                        hintStyle: TipografiaHaku.interfaz(
                          color: PaletaRutas.marronCuero,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _enviar,
                    style: IconButton.styleFrom(
                      backgroundColor: PaletaRutas.marronOscuro,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
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
