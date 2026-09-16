import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../comunidad/proveedores/proveedor_comunidad.dart';
import '../../comunidad/proveedores/proveedor_salidas.dart';
import '../datos/chat_datasource_supabase.dart';
import '../dominio/modelo_mensaje_chat.dart';

final chatDataSourceProvider = Provider<ChatDataSourceSupabase>((ref) {
  return ChatDataSourceSupabase();
});

final chatVersionProvider = StateProvider<int>((ref) => 0);

/// Mantiene la bandeja viva ante mensajes recibidos/editados/eliminados.
///
/// RLS limita los eventos a salas del usuario. Se activa únicamente mientras
/// la pantalla de Mensajes observa este provider.
final chatBandejaRealtimeProvider = Provider.autoDispose<void>((ref) {
  if (!supabaseListo) return;
  final uid = ref.watch(sesionProvider.select((s) => s.usuario?.id ?? ''));
  if (uid.isEmpty) return;
  Timer? debounce;

  final channel = clienteSupabase
      .channel('bandeja_chat_$uid')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'mensaje',
        callback: (_) {
          debounce?.cancel();
          debounce = Timer(const Duration(milliseconds: 300), () {
            ref.invalidate(previewsChatBandejaProvider);
          });
        },
      )
      .subscribe();

  ref.onDispose(() {
    debounce?.cancel();
    try {
      clienteSupabase.removeChannel(channel);
    } catch (_) {}
  });
});

/// Pedido de reload de un mensaje dentro del stream de [salaId] (reacciones).
final chatRecargaMensajeProvider = StateProvider.family<String?, String>(
  (ref, salaId) => null,
);

void forzarRecargaMensajeChat(WidgetRef ref, String salaId, String mensajeId) {
  final id = mensajeId.trim();
  if (salaId.trim().isEmpty || id.isEmpty) return;
  // Nuevo valor aunque sea el mismo id (StateProvider no notifica equals).
  ref.read(chatRecargaMensajeProvider(salaId).notifier).state = null;
  ref.read(chatRecargaMensajeProvider(salaId).notifier).state = id;
}

/// Historial + Realtime INSERT/UPDATE + reacciones de una sala.
final mensajesSalaProvider = StreamProvider.autoDispose
    .family<List<ModeloMensajeChat>, String>((ref, salaId) async* {
      if (!supabaseListo || salaId.trim().isEmpty) {
        yield const [];
        return;
      }

      final ds = ref.watch(chatDataSourceProvider);
      final uid = clienteSupabase.auth.currentUser?.id ?? '';
      List<ModeloMensajeChat> seed;
      try {
        seed = await ds.listarMensajes(salaId);
      } catch (e, st) {
        // No fingir chat vacío: el UI muestra error real.
        yield* Stream<List<ModeloMensajeChat>>.error(e, st);
        return;
      }

      final controller = StreamController<List<ModeloMensajeChat>>();
      var buffer = List<ModeloMensajeChat>.from(seed);
      controller.add(List.unmodifiable(buffer));

      void emitir() {
        if (!controller.isClosed) {
          controller.add(List.unmodifiable(buffer));
        }
      }

      void upsert(ModeloMensajeChat m, {required bool traeReacciones}) {
        final i = buffer.indexWhere((x) => x.id == m.id);
        if (i >= 0) {
          buffer[i] = ModeloMensajeChat.fusionarConPrevio(
            buffer[i],
            m,
            entranteTraeReacciones: traeReacciones,
          );
        } else {
          buffer = [...buffer, m];
        }
        emitir();
        if (m.usuarioId.isNotEmpty && m.usuarioId != uid) {
          unawaited(
            ds.marcarLeido(salaId).then((_) {
              try {
                ref.invalidate(previewsChatBandejaProvider);
              } catch (_) {}
            }),
          );
        }
      }

      Future<void> refrescarMensaje(String mensajeId) async {
        if (mensajeId.isEmpty || controller.isClosed) return;
        // Solo si el mensaje está en el buffer de esta sala (filtro cliente).
        if (!buffer.any((m) => m.id == mensajeId)) return;
        try {
          final fresco = await ds.recargarMensaje(mensajeId);
          if (fresco == null || controller.isClosed) return;
          if (fresco.salaId.isNotEmpty && fresco.salaId != salaId) return;
          final i = buffer.indexWhere((x) => x.id == fresco.id);
          if (i >= 0) {
            buffer[i] = fresco;
          } else {
            buffer = [...buffer, fresco];
          }
          emitir();
        } catch (_) {}
      }

      RealtimeChannel? channel;
      try {
        channel = ds.suscribirSala(
          salaId: salaId,
          onInsert: (m, {required traeReacciones}) {
            upsert(m, traeReacciones: traeReacciones);
            // INSERT realtime casi nunca trae embed de reacciones.
            if (!traeReacciones) {
              // ignore: unawaited_futures
              refrescarMensaje(m.id);
            }
          },
          onUpdate: (m, {required traeReacciones}) {
            upsert(m, traeReacciones: traeReacciones);
            if (!traeReacciones) {
              // ignore: unawaited_futures
              refrescarMensaje(m.id);
            }
          },
          onReaccionCambio: (mensajeId) {
            // ignore: unawaited_futures
            refrescarMensaje(mensajeId);
          },
          onEstado: (status, error) {
            if (status != RealtimeSubscribeStatus.channelError &&
                status != RealtimeSubscribeStatus.timedOut) {
              return;
            }
            if (!controller.isClosed) {
              controller.addError(
                const AuthException(
                  'Conexión en tiempo real interrumpida. Reabrí el chat.',
                ),
              );
            }
          },
        );
      } catch (_) {}

      // Reload puntual desde UI (p. ej. tras toggle de reacción propia).
      ref.listen<String?>(chatRecargaMensajeProvider(salaId), (_, id) {
        if (id == null || id.isEmpty) return;
        // ignore: unawaited_futures
        refrescarMensaje(id);
      });

      ref.onDispose(() {
        final c = channel;
        channel = null;
        if (c != null && supabaseListo) {
          try {
            clienteSupabase.removeChannel(c);
          } catch (_) {}
        }
        if (!controller.isClosed) controller.close();
      });

      unawaited(
        ds.marcarLeido(salaId).then((_) {
          try {
            ref.invalidate(previewsChatBandejaProvider);
          } catch (_) {}
        }),
      );

      yield* controller.stream;
    });

/// Bandeja Mensajes: comunidades + salidas (lectura; sin crear sala).
final previewsChatBandejaProvider = FutureProvider<List<PreviewChatSala>>((
  ref,
) async {
  ref.watch(comunidadesVersionProvider);
  ref.watch(salidasVersionProvider);
  ref.watch(chatVersionProvider);
  final uid = ref.watch(sesionProvider.select((s) => s.usuario?.id ?? ''));
  if (!supabaseListo || uid.isEmpty) return const [];

  final ds = ref.read(chatDataSourceProvider);
  final out = <PreviewChatSala>[];
  var fuentesOk = 0;

  // Conversaciones privadas reales del usuario.
  try {
    out.addAll(await ds.listarChatsPrivados());
    fuentesOk++;
  } catch (_) {}

  // Comunidades mías (en paralelo por ítem: evita cascada N×3 secuencial).
  try {
    final todas = await ref.watch(comunidadesRemotasProvider.future);
    final mias = todas
        .where((c) => c.esMiembro(uid) || c.creadorId == uid)
        .toList();
    final previews = await Future.wait(
      mias.map((c) async {
        final puedeCrear = c.esAdminDe(uid);
        String? salaIdExistente;
        var enRoster = false;
        ModeloMensajeChat? ultimo;
        var noLeidos = 0;
        try {
          salaIdExistente = await ds.idSalaComunidadSiExiste(c.id);
          if (salaIdExistente != null && salaIdExistente.isNotEmpty) {
            enRoster = await ds.soyParticipanteSala(salaIdExistente);
            if (enRoster) {
              final meta = await Future.wait([
                ds.ultimoMensajeSala(salaIdExistente, comunidadId: c.id),
                ds.contarNoLeidos(salaIdExistente),
              ]);
              ultimo = meta[0] as ModeloMensajeChat?;
              noLeidos = meta[1] as int;
            }
          }
        } catch (_) {}
        // Solo roster o admin (crear / reentrar). Fuera del chat → no listar.
        if (!enRoster && !puedeCrear) return null;
        return PreviewChatSala(
          salaId: enRoster ? (salaIdExistente ?? '') : '',
          titulo: c.nombre,
          fotoPortada: c.imagenUrl.trim().isEmpty ? null : c.imagenUrl,
          comunidadId: c.id,
          tipo: 'comunidad',
          ultimo: ultimo,
          noLeidos: noLeidos,
          puedeCrearSala: puedeCrear,
        );
      }),
    );
    for (final p in previews) {
      if (p != null) out.add(p);
    }
    fuentesOk++;
  } catch (_) {}

  // Salidas: organizador o confirmado.
  try {
    final salidas = await ref.watch(salidasRemotasProvider.future);
    final mias = salidas
        .where((s) => s.organizadorId == uid || s.inscrito(uid))
        .toList();
    final previews = await Future.wait(
      mias.map((s) async {
        final puedeCrear = s.organizadorId == uid;
        String? salaIdExistente;
        var enRoster = false;
        ModeloMensajeChat? ultimo;
        var noLeidos = 0;
        try {
          salaIdExistente = await ds.idSalaSalidaSiExiste(s.id);
          if (salaIdExistente != null && salaIdExistente.isNotEmpty) {
            enRoster = await ds.soyParticipanteSala(salaIdExistente);
            if (enRoster) {
              final meta = await Future.wait([
                ds.ultimoMensajeSala(salaIdExistente),
                ds.contarNoLeidos(salaIdExistente),
              ]);
              ultimo = meta[0] as ModeloMensajeChat?;
              noLeidos = meta[1] as int;
            }
          }
        } catch (_) {}
        if (!enRoster && !puedeCrear) return null;
        return PreviewChatSala(
          salaId: enRoster ? (salaIdExistente ?? '') : '',
          titulo: s.etiquetaPrincipal,
          fotoPortada: (s.lugarFotoPortada?.trim().isNotEmpty ?? false)
              ? s.lugarFotoPortada
              : null,
          salidaId: s.id,
          tipo: 'salida',
          ultimo: ultimo,
          noLeidos: noLeidos,
          puedeCrearSala: puedeCrear,
        );
      }),
    );
    for (final p in previews) {
      if (p != null) out.add(p);
    }
    fuentesOk++;
  } catch (_) {}

  if (fuentesOk == 0) {
    throw const AuthException('No se pudo cargar la bandeja de mensajes');
  }

  out.sort((a, b) {
    final fa = a.ultimo?.fechaEnvio;
    final fb = b.ultimo?.fechaEnvio;
    if (fa == null && fb == null) return a.titulo.compareTo(b.titulo);
    if (fa == null) return 1;
    if (fb == null) return -1;
    return fb.compareTo(fa);
  });
  return out;
});

/// Compat: mismo provider unificado.
final previewsChatComunidadProvider = previewsChatBandejaProvider;

void notificarChatCambio(WidgetRef ref) {
  ref.read(chatVersionProvider.notifier).state++;
}
