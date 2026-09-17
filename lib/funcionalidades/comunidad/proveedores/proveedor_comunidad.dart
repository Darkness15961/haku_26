import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../datos/comunidad_datasource_supabase.dart';
import '../dominio/modelo_comunidad.dart';

final comunidadRemotoDataSourceProvider = Provider<ComunidadDataSourceSupabase>(
  (ref) {
    return ComunidadDataSourceSupabase();
  },
);

/// Tick para refresh tras mutaciones (Bloque B+).
final comunidadesVersionProvider = StateProvider<int>((ref) => 0);

/// Fuente de verdad tab Comunidades: solo Supabase (vacío honesto).
final comunidadesRemotasProvider = FutureProvider<List<ComunidadHaku>>((
  ref,
) async {
  ref.watch(comunidadesVersionProvider);
  ref.watch(perfilVersionProvider);
  // Solo uid: evita re-fetch en cada tokenRefreshed (EstadoSesion sin ==).
  ref.watch(sesionProvider.select((s) => s.usuario?.id ?? ''));
  if (!supabaseListo) return const [];
  return ref.read(comunidadRemotoDataSourceProvider).listarVisibles();
});

final comunidadesListaProvider = Provider<List<ComunidadHaku>>((ref) {
  final async = ref.watch(comunidadesRemotasProvider);
  // valueOrNull conserva datos previos en reload (maybeWhen data → [] y “rompe” UI).
  return async.valueOrNull ?? const [];
});

final comunidadesCargandoProvider = Provider<bool>((ref) {
  final async = ref.watch(comunidadesRemotasProvider);
  return async.isLoading && !async.hasValue;
});

final comunidadesErrorProvider = Provider<Object?>((ref) {
  final async = ref.watch(comunidadesRemotasProvider);
  if (async.hasValue) return null;
  return async.whenOrNull(error: (e, _) => e);
});

final comunidadDetalleProvider = FutureProvider.family<ComunidadHaku?, String>((
  ref,
  id,
) async {
  ref.watch(comunidadesVersionProvider);
  ref.watch(perfilVersionProvider);
  final lista = ref.watch(comunidadesListaProvider);
  for (final c in lista) {
    if (c.id == id) return c;
  }
  // Evitar “no encontrada” mientras el listado aún carga la 1.ª vez.
  final listAsync = ref.watch(comunidadesRemotasProvider);
  if (listAsync.isLoading && !listAsync.hasValue) {
    final frescas = await ref.watch(comunidadesRemotasProvider.future);
    for (final c in frescas) {
      if (c.id == id) return c;
    }
  }
  if (!supabaseListo) return null;
  return ref.read(comunidadRemotoDataSourceProvider).porId(id);
});

final miembrosComunidadProvider =
    FutureProvider.family<List<MiembroComunidadRemoto>, String>((
      ref,
      id,
    ) async {
      ref.watch(comunidadesVersionProvider);
      ref.watch(perfilVersionProvider);
      if (!supabaseListo || id.trim().isEmpty) return const [];
      return ref.read(comunidadRemotoDataSourceProvider).listarMiembros(id);
    });

final pendientesComunidadProvider =
    FutureProvider.family<List<MiembroComunidadRemoto>, String>((
      ref,
      id,
    ) async {
      ref.watch(comunidadesVersionProvider);
      ref.watch(perfilVersionProvider);
      if (!supabaseListo || id.trim().isEmpty) return const [];
      return ref.read(comunidadRemotoDataSourceProvider).listarPendientes(id);
    });

/// ¿El usuario de sesión es miembro aprobado de [comunidadId]?
final soyMiembroComunidadProvider = Provider.family<bool, String>((
  ref,
  comunidadId,
) {
  final uid = ref.watch(sesionProvider.select((s) => s.usuario?.id ?? ''));
  if (uid.isEmpty) return false;
  final lista = ref.watch(comunidadesListaProvider);
  for (final c in lista) {
    if (c.id == comunidadId) return c.esMiembro(uid) || c.creadorId == uid;
  }
  return false;
});

void notificarComunidadesCambiaron(WidgetRef ref) {
  // Solo tick: detalle/miembros/pendientes ya watch-ean el version.
  ref.read(comunidadesVersionProvider.notifier).state++;
}
