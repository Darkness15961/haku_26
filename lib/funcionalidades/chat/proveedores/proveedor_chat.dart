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

/// Pedido de reload de un mensaje dentro del stream de [salaId] (reacciones).
final chatRecargaMensajeProvider =
    StateProvider.family<String?, String>((ref, salaId) => null);

void forzarRecargaMensajeChat(WidgetRef ref, String salaId, String mensajeId) {
  final id = mensajeId.trim();
  if (salaId.trim().isEmpty || id.isEmpty) return;
  // Nuevo valor aunque sea el mismo id (StateProvider no notifica equals).
  ref.read(chatRecargaMensajeProvider(salaId).notifier).state = null;
  ref.read(chatRecargaMensajeProvider(salaId).notifier).state = id;
}

/// Historial + Realtime INSERT/UPDATE + reacciones de una sala.
final mensajesSalaProvider =
    StreamProvider.autoDispose.family<List<ModeloMensajeChat>, String>(
        (ref, salaId) async* {
  if (!supabaseListo || salaId.trim().isEmpty) {
    yield const [];
    return;
  }

  final ds = ref.watch(chatDataSourceProvider);
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

  // ignore: unawaited_futures
  ds.marcarLeido(salaId);

  yield* controller.stream;
});

/// Bandeja Mensajes: comunidades + salidas (lectura; sin crear sala).
final previewsChatBandejaProvider =
    FutureProvider<List<PreviewChatSala>>((ref) async {
  ref.watch(comunidadesVersionProvider);
  ref.watch(salidasVersionProvider);
  ref.watch(chatVersionProvider);
  final uid = ref.watch(sesionProvider.select((s) => s.usuario?.id ?? ''));
  if (!supabaseListo || uid.isEmpty) return const [];

  final ds = ref.read(chatDataSourceProvider);
  final out = <PreviewChatSala>[];

  // Comunidades mías (en paralelo por ítem: evita cascada N×3 secuencial).
  try {
    final todas = await ref.watch(comunidadesRemotasProvider.future);
    final mias = todas
        .where((c) => c.esMiembro(uid) || c.creadorId == uid)
        .toList();
    final previews = await Future.wait(
      mias.map((c) async {
        final puedeCrear = c.esAdminDe(uid);
        String? salaId;
        ModeloMensajeChat? ultimo;
        var noLeidos = 0;
        try {
          salaId = await ds.idSalaComunidadSiExiste(c.id);
          if (salaId != null && salaId.isNotEmpty) {
            final meta = await Future.wait([
              ds.ultimoMensajeSala(salaId, comunidadId: c.id),
              ds.contarNoLeidos(salaId),
            ]);
            ultimo = meta[0] as ModeloMensajeChat?;
            noLeidos = meta[1] as int;
          }
        } catch (_) {}
        // Sin sala y sin permiso de crear: no listar (evita taps rotos).
        if ((salaId == null || salaId.isEmpty) && !puedeCrear) {
          return null;
        }
        return PreviewChatSala(
          salaId: salaId ?? '',
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
        String? salaId;
        ModeloMensajeChat? ultimo;
        var noLeidos = 0;
        try {
          salaId = await ds.idSalaSalidaSiExiste(s.id);
          if (salaId != null && salaId.isNotEmpty) {
            final meta = await Future.wait([
              ds.ultimoMensajeSala(salaId),
              ds.contarNoLeidos(salaId),
            ]);
            ultimo = meta[0] as ModeloMensajeChat?;
            noLeidos = meta[1] as int;
          }
        } catch (_) {}
        if ((salaId == null || salaId.isEmpty) && !puedeCrear) {
          return null;
        }
        return PreviewChatSala(
          salaId: salaId ?? '',
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
  } catch (_) {}

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
