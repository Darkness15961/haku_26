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
  Timer? reconciliacion;

  void refrescar() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 300), () {
      ref.invalidate(previewsChatBandejaProvider);
    });
  }

  final channel = clienteSupabase
      .channel('bandeja_chat_$uid')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'mensaje',
        callback: (_) => refrescar(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'sala_participante',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'usuario_id',
          value: uid,
        ),
        callback: (_) => refrescar(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'sala_chat',
        callback: (_) => refrescar(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'comunidad_miembro',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'usuario_id',
          value: uid,
        ),
        callback: (_) => refrescar(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'salida_participante',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'usuario_id',
          value: uid,
        ),
        callback: (_) => refrescar(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'comunidad',
        callback: (_) => refrescar(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'salida',
        callback: (_) => refrescar(),
      )
      .subscribe();

  // Un DELETE de roster puede dejar de ser visible por RLS justo después de
  // quitar el acceso. Esta reconciliación acotada evita una bandeja obsoleta.
  reconciliacion = Timer.periodic(
    const Duration(seconds: 30),
    (_) => ref.invalidate(previewsChatBandejaProvider),
  );

  ref.onDispose(() {
    debounce?.cancel();
    reconciliacion?.cancel();
    try {
      clienteSupabase.removeChannel(channel);
    } catch (_) {}
  });
});

/// Pedido de reload de un mensaje dentro del stream de [salaId] (reacciones).
final chatRecargaMensajeProvider = StateProvider.family<String?, String>(
  (ref, salaId) => null,
);

/// Mensaje recargado que pertenece a una página antigua mantenida por la UI.
final chatMensajePaginadoActualizadoProvider =
    StateProvider.family<ModeloMensajeChat?, String>((ref, salaId) => null);

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
      ref.watch(perfilVersionProvider);
      if (!supabaseListo || salaId.trim().isEmpty) {
        yield const [];
        return;
      }

      final ds = ref.watch(chatDataSourceProvider);
      final controller = StreamController<List<ModeloMensajeChat>>();
      var buffer = <ModeloMensajeChat>[];
      final suscrito = Completer<void>();
      Timer? reconectar;
      RealtimeChannel? channel;
      var seedCargado = false;
      final reaccionesPendientes = <String>{};

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
      }

      Future<void> refrescarMensaje(String mensajeId) async {
        if (mensajeId.isEmpty || controller.isClosed) return;
        final estabaEnBuffer = buffer.any((m) => m.id == mensajeId);
        if (!estabaEnBuffer) {
          // Una reacción puede llegar entre el snapshot de historial y su
          // incorporación al buffer. Se reconcilia al terminar el seed.
          if (!seedCargado) reaccionesPendientes.add(mensajeId);
          if (!seedCargado) return;
        }
        try {
          final fresco = await ds.recargarMensaje(mensajeId);
          if (fresco == null || controller.isClosed) return;
          if (fresco.salaId.isNotEmpty && fresco.salaId != salaId) return;
          final i = buffer.indexWhere((x) => x.id == fresco.id);
          if (i >= 0) {
            buffer[i] = fresco;
          } else {
            final notifier = ref.read(
              chatMensajePaginadoActualizadoProvider(salaId).notifier,
            );
            notifier.state = null;
            notifier.state = fresco;
            return;
          }
          emitir();
        } catch (_) {}
      }

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
            if (status == RealtimeSubscribeStatus.subscribed) {
              if (!suscrito.isCompleted) suscrito.complete();
              return;
            }
            if (status != RealtimeSubscribeStatus.channelError &&
                status != RealtimeSubscribeStatus.timedOut) {
              return;
            }
            final fallo = AuthException(
              'Conexión en tiempo real interrumpida. Reintentando…',
            );
            final yaEstabaSuscrito = suscrito.isCompleted;
            if (!yaEstabaSuscrito) {
              suscrito.completeError(fallo);
            } else if (!controller.isClosed) {
              controller.addError(fallo);
              reconectar ??= Timer(
                const Duration(seconds: 2),
                ref.invalidateSelf,
              );
            }
          },
        );
      } catch (e, st) {
        if (!suscrito.isCompleted) suscrito.completeError(e, st);
      }

      ref.onDispose(() {
        reconectar?.cancel();
        final c = channel;
        channel = null;
        if (c != null && supabaseListo) {
          try {
            clienteSupabase.removeChannel(c);
          } catch (_) {}
        }
        if (!controller.isClosed) controller.close();
      });

      try {
        await suscrito.future.timeout(const Duration(seconds: 12));
        final seed = await ds.listarMensajes(salaId);
        final porId = <String, ModeloMensajeChat>{
          for (final mensaje in seed) mensaje.id: mensaje,
          // Los eventos recibidos durante la carga son más recientes.
          for (final mensaje in buffer) mensaje.id: mensaje,
        };
        buffer = porId.values.toList()
          ..sort((a, b) {
            final fecha = a.fechaEnvio.compareTo(b.fechaEnvio);
            return fecha != 0 ? fecha : a.id.compareTo(b.id);
          });
        seedCargado = true;
        emitir();
        final pendientes = reaccionesPendientes.toList(growable: false);
        reaccionesPendientes.clear();
        for (final id in pendientes) {
          unawaited(refrescarMensaje(id));
        }
      } catch (e, st) {
        if (!controller.isClosed) {
          controller.addError(e, st);
          await controller.close();
        }
        yield* controller.stream;
        return;
      }

      // Reload puntual desde UI (p. ej. tras toggle de reacción propia).
      ref.listen<String?>(chatRecargaMensajeProvider(salaId), (_, id) {
        if (id == null || id.isEmpty) return;
        // ignore: unawaited_futures
        refrescarMensaje(id);
      });

      yield* controller.stream;
    });

/// Bandeja Mensajes en una sola RPC: privados + comunidades + salidas.
final previewsChatBandejaProvider = FutureProvider<List<PreviewChatSala>>((
  ref,
) async {
  ref.watch(comunidadesVersionProvider);
  ref.watch(salidasVersionProvider);
  ref.watch(chatVersionProvider);
  ref.watch(perfilVersionProvider);
  final uid = ref.watch(sesionProvider.select((s) => s.usuario?.id ?? ''));
  if (!supabaseListo || uid.isEmpty) return const [];

  final ds = ref.read(chatDataSourceProvider);
  return ds.listarBandeja();
});

/// Compat: mismo provider unificado.
final previewsChatComunidadProvider = previewsChatBandejaProvider;

final totalNoLeidosChatProvider = Provider<int>((ref) {
  final previews = ref.watch(previewsChatBandejaProvider).valueOrNull;
  if (previews == null) return 0;
  return previews.fold<int>(0, (total, chat) => total + chat.noLeidos);
});

void notificarChatCambio(WidgetRef ref) {
  ref.read(chatVersionProvider.notifier).state++;
}
