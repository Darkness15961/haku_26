import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/widgets/avatar_haku.dart';
import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../datos/mensajes_datasource_local.dart';
import '../proveedores/proveedor_almacen_feed.dart';
import 'pantalla_chat_directo.dart';
import 'pantalla_comunidades.dart';
import 'pantalla_crear_grupo_comunidad.dart';
import 'pantalla_detalle_grupo.dart';

/// Lista de chats / mensajería en cards estilo Haku.
class PantallaMensajesInicio extends ConsumerStatefulWidget {
  const PantallaMensajesInicio({super.key});

  @override
  ConsumerState<PantallaMensajesInicio> createState() =>
      _EstadoPantallaMensajesInicio();
}

class _EstadoPantallaMensajesInicio
    extends ConsumerState<PantallaMensajesInicio> {
  Future<void> _abrirCrearGrupo() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PantallaCrearGrupo()),
    );
    if (ok == true && mounted) setState(() {});
  }

  Future<void> _abrirCrearComunidad() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PantallaCrearComunidad()),
    );
    if (ok == true && mounted) setState(() {});
  }

  Future<void> _abrirGrupo(GrupoRuta grupo) async {
    final eliminado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PantallaDetalleGrupo(grupo: grupo),
      ),
    );
    if (eliminado == true && mounted) setState(() {});
  }

  ChatConversacion _conUltimo(ChatConversacion c, EstadoAlmacenFeed store) {
    final conv = store.mensajesDirectos
        .where((m) => m.conversacionId == c.id)
        .toList()
      ..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
    if (conv.isEmpty) return c;
    final last = conv.last;
    final mio = last.autorId == AlmacenFeedNotifier.idUsuarioLocal;
    return c.copyWith(
      ultimoMensaje: last.texto,
      hace: _hace(last.creadoEn),
      noLeidos: mio ? 0 : c.noLeidos,
    );
  }

  static String _hace(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(almacenFeedProvider);
    final bottomPad = MediaQuery.paddingOf(context).bottom + 24;
    final chats = [
      for (final c in MensajesDataSourceLocal.chats) _conUltimo(c, store),
    ];
    final grupos = MensajesDataSourceLocal.grupos;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PaletaRutas.marronOscuro,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Mensajes',
                      style: TipografiaHaku.titulo(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.marronOscuro,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LineaEncabezadoInca(altura: 2),
            ),
            Expanded(
              child: FondoSuaveSeccion(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _AccionMensajes(
                            icono: Icons.group_add_outlined,
                            etiqueta: 'Crear grupo',
                            onTap: _abrirCrearGrupo,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _AccionMensajes(
                            icono: Icons.diversity_3_outlined,
                            etiqueta: 'Crear comunidad',
                            onTap: _abrirCrearComunidad,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _AccionMensajes(
                            icono: Icons.groups_outlined,
                            etiqueta: 'Comunidades',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const PantallaComunidades(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    if (grupos.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Grupos',
                        style: TipografiaHaku.titulo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.marronOscuro,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < grupos.length; i++) ...[
                        _CardGrupo(
                          grupo: grupos[i],
                          indice: i,
                          onTap: () => _abrirGrupo(grupos[i]),
                        ),
                        if (i < grupos.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                    const SizedBox(height: 18),
                    Text(
                      'Chats',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.marronOscuro,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < chats.length; i++) ...[
                      _CardChat(chat: chats[i], indice: i),
                      if (i < chats.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccionMensajes extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;

  const _AccionMensajes({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black),
          ),
          child: Column(
            children: [
              Icon(icono, color: Colors.white, size: 22),
              const SizedBox(height: 6),
              Text(
                etiqueta,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TipografiaHaku.interfaz(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardGrupo extends StatelessWidget {
  final GrupoRuta grupo;
  final int indice;
  final VoidCallback onTap;

  const _CardGrupo({
    required this.grupo,
    required this.indice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final veloNegro = indice.isEven;
    final texto = veloNegro ? Colors.white : PaletaRutas.marronOscuro;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.14)),
            image: DecorationImage(
              image: AssetImage(FondosDetalleHaku.porIndice(indice + 2)),
              fit: BoxFit.cover,
              opacity: 0.48,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: veloNegro
                  ? Colors.black.withValues(alpha: 0.64)
                  : Colors.white.withValues(alpha: 0.78),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: veloNegro
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.hiking_rounded,
                        color: texto,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  grupo.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: texto,
                                  ),
                                ),
                              ),
                              if (grupo.esCreador)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: veloNegro
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : Colors.black.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Creador',
                                    style: TipografiaHaku.interfaz(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: texto,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            grupo.rutaTitulo,
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: texto.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            grupo.ultimoMensaje,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaHaku.interfaz(
                              fontSize: 13,
                              color: texto.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardChat extends StatelessWidget {
  final ChatConversacion chat;
  final int indice;

  const _CardChat({required this.chat, required this.indice});

  @override
  Widget build(BuildContext context) {
    final veloNegro = indice % 3 != 1;
    final texto = veloNegro ? Colors.white : PaletaRutas.marronOscuro;
    final secundario = texto.withValues(alpha: 0.7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final persona = SugerenciaSeguimiento(
            id: chat.id,
            nombre: chat.nombre,
            usuario: chat.usuario,
            avatarUrl: chat.avatarUrl,
            bioCorta: '',
          );
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PantallaChatDirecto(persona: persona),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.14)),
            image: DecorationImage(
              image: AssetImage(FondosDetalleHaku.porIndice(indice)),
              fit: BoxFit.cover,
              opacity: 0.48,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: veloNegro
                  ? Colors.black.withValues(alpha: 0.64)
                  : Colors.white.withValues(alpha: 0.78),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        AvatarHaku(url: chat.avatarUrl, size: 52),
                        if (chat.noLeidos > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: PaletaRutas.verdeOliva,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: texto,
                                  ),
                                ),
                              ),
                              Text(
                                chat.hace,
                                style: TipografiaHaku.interfaz(
                                  fontSize: 11,
                                  color: secundario,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            chat.usuario,
                            style: TipografiaHaku.interfaz(
                              fontSize: 11,
                              color: secundario,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            chat.ultimoMensaje,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaHaku.interfaz(
                              fontSize: 13,
                              fontWeight: chat.noLeidos > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: texto.withValues(
                                alpha: chat.noLeidos > 0 ? 0.95 : 0.78,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (chat.noLeidos > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        constraints: const BoxConstraints(minWidth: 22),
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: veloNegro
                              ? Colors.white
                              : Colors.black.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          '${chat.noLeidos}',
                          style: TipografiaHaku.interfaz(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: veloNegro
                                ? PaletaRutas.marronOscuro
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
