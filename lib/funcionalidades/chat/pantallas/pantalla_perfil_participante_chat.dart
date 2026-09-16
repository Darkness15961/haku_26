import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/widgets/avatar_haku.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../dominio/modelo_mensaje_chat.dart';
import '../proveedores/proveedor_chat.dart';
import 'pantalla_chat_sala.dart';

/// Perfil mínimo y real de una persona descubierta dentro de un chat grupal.
///
/// No inventa estadísticas ni contenido: muestra únicamente identidad pública
/// disponible en `usuario` y conserva el contexto que habilita el DM.
class PantallaPerfilParticipanteChat extends ConsumerStatefulWidget {
  const PantallaPerfilParticipanteChat({
    super.key,
    required this.usuarioId,
    required this.salaOrigenId,
    required this.contextoCompartido,
  });

  final String usuarioId;
  final String salaOrigenId;
  final String contextoCompartido;

  @override
  ConsumerState<PantallaPerfilParticipanteChat> createState() =>
      _EstadoPerfilParticipanteChat();
}

class _EstadoPerfilParticipanteChat
    extends ConsumerState<PantallaPerfilParticipanteChat> {
  late final Future<PerfilChatBasico?> _perfil;
  bool _abriendoChat = false;

  @override
  void initState() {
    super.initState();
    _perfil = ref.read(chatDataSourceProvider).perfilChat(widget.usuarioId);
  }

  Future<void> _mensaje(PerfilChatBasico perfil) async {
    if (_abriendoChat) return;
    final uid = ref.read(sesionProvider).usuario?.id ?? '';
    if (uid.isEmpty || uid == perfil.id) return;

    setState(() => _abriendoChat = true);
    try {
      final salaId = await ref
          .read(chatDataSourceProvider)
          .asegurarSalaPrivada(
            otroUsuarioId: perfil.id,
            salaOrigenId: widget.salaOrigenId,
          );
      if (!mounted) return;
      notificarChatCambio(ref);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              PantallaChatSala(salaId: salaId, titulo: perfil.nombreCompleto),
        ),
      );
    } on AuthException catch (e) {
      if (mounted) mostrarSnackHaku(context, e.message);
    } catch (_) {
      if (mounted) {
        mostrarSnackHaku(context, 'No se pudo abrir el chat privado');
      }
    } finally {
      if (mounted) setState(() => _abriendoChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        elevation: 0,
        title: Text(
          'Perfil',
          style: TipografiaHaku.titulo(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LineaEncabezadoInca(altura: 2),
          ),
          Expanded(
            child: FutureBuilder<PerfilChatBasico?>(
              future: _perfil,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: PaletaRutas.oro),
                  );
                }
                final perfil = snap.data;
                if (perfil == null) {
                  return Center(
                    child: Text(
                      'Este perfil no está disponible.',
                      style: TipografiaHaku.interfaz(
                        color: PaletaRutas.plomoClaro,
                      ),
                    ),
                  );
                }
                final esYo = ref.watch(sesionProvider).usuario?.id == perfil.id;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                  child: Column(
                    children: [
                      AvatarHaku(url: perfil.fotoPerfil ?? '', size: 96),
                      const SizedBox(height: 16),
                      Text(
                        perfil.nombreCompleto,
                        textAlign: TextAlign.center,
                        style: TipografiaHaku.titulo(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      if (perfil.etiquetaNick.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          perfil.etiquetaNick,
                          style: TipografiaHaku.interfaz(
                            fontSize: 14,
                            color: PaletaRutas.plomoClaro,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: PaletaRutas.carbon,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: PaletaRutas.plomoOscuro.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.groups_2_outlined,
                              color: PaletaRutas.oro,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Coinciden en ${widget.contextoCompartido}.',
                                style: TipografiaHaku.interfaz(
                                  fontSize: 13,
                                  color: PaletaRutas.plomoClaro,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!esYo) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _abriendoChat
                                ? null
                                : () => _mensaje(perfil),
                            style: FilledButton.styleFrom(
                              backgroundColor: PaletaRutas.oro,
                              foregroundColor: PaletaRutas.ink,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: _abriendoChat
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: PaletaRutas.ink,
                                    ),
                                  )
                                : const Icon(Icons.chat_bubble_outline_rounded),
                            label: Text(
                              'Mensaje privado',
                              style: TipografiaHaku.interfaz(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
