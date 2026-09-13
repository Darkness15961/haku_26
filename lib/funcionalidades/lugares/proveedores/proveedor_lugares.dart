import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../datos/lugar_datasource_supabase.dart';
import '../datos/lugares_datasource_local.dart';
import '../datos/territorio_datasource_supabase.dart';
import '../dominio/modelos/modelo_lugar.dart';
import '../dominio/modelos/modelo_territorio.dart';

/// Catálogo local (legacy / demos; Explora ya no lo usa para listar).
final lugaresDataSourceProvider = Provider<LugaresDataSourceLocal>((ref) {
  return LugaresDataSourceLocal.instancia;
});

final territorioDataSourceProvider = Provider<TerritorioDataSourceSupabase>((ref) {
  return TerritorioDataSourceSupabase();
});

final lugarRemotoDataSourceProvider = Provider<LugarDataSourceSupabase>((ref) {
  return LugarDataSourceSupabase();
});

/// Tick para forzar refresh tras mutaciones.
final lugaresVersionProvider = StateProvider<int>((ref) => 0);

final interesesUsuarioProvider =
    StateProvider<Set<CategoriaLugar>>((ref) => {});

/// Provincias Cusco remotas (códigos alineados a assets).
final provinciasRemotasProvider =
    FutureProvider<List<ModeloProvinciaDb>>((ref) async {
  if (!supabaseListo) return const [];
  return ref.read(territorioDataSourceProvider).listarProvinciasCusco();
});

final categoriasLugarRemotasProvider =
    FutureProvider<List<ModeloCategoriaDb>>((ref) async {
  if (!supabaseListo) return const [];
  return ref.read(territorioDataSourceProvider).listarCategoriasLugar();
});

final distritosPorProvinciaProvider =
    FutureProvider.family<List<ModeloDistritoDb>, int>((ref, provinciaId) async {
  if (!supabaseListo || provinciaId <= 0) return const [];
  return ref
      .read(territorioDataSourceProvider)
      .listarDistritos(provinciaId: provinciaId);
});

/// Fuente de verdad Explora: solo Supabase (vacío honesto si no hay filas).
final lugaresRemotosProvider = FutureProvider<List<ModeloLugar>>((ref) async {
  ref.watch(lugaresVersionProvider);
  if (!supabaseListo) return const [];
  return ref.read(lugarRemotoDataSourceProvider).listarActivos();
});

final lugaresListaProvider = Provider<List<ModeloLugar>>((ref) {
  final async = ref.watch(lugaresRemotosProvider);
  return async.maybeWhen(data: (d) => d, orElse: () => const []);
});

final lugaresCargandoProvider = Provider<bool>((ref) {
  return ref.watch(lugaresRemotosProvider).isLoading;
});

final lugaresErrorProvider = Provider<Object?>((ref) {
  return ref.watch(lugaresRemotosProvider).whenOrNull(error: (e, _) => e);
});

final lugarDetalleProvider =
    FutureProvider.family<ModeloLugar?, String>((ref, id) async {
  final lista = ref.watch(lugaresListaProvider);
  for (final l in lista) {
    if (l.id == id) return l;
  }
  if (!supabaseListo) return null;
  return ref.read(lugarRemotoDataSourceProvider).porId(id);
});

/// Centro por defecto Cusco (plaza) para mapa / cercanía.
const centroMapaCuscoLat = -13.5167;
const centroMapaCuscoLon = -71.9788;

/// Parámetros de cercanía PostGIS.
class ConsultaCercaLugares {
  const ConsultaCercaLugares({
    this.latitud = centroMapaCuscoLat,
    this.longitud = centroMapaCuscoLon,
    this.radioM = 50000,
  });

  final double latitud;
  final double longitud;
  final double radioM;

  @override
  bool operator ==(Object other) =>
      other is ConsultaCercaLugares &&
      other.latitud == latitud &&
      other.longitud == longitud &&
      other.radioM == radioM;

  @override
  int get hashCode => Object.hash(latitud, longitud, radioM);
}

final lugaresCercaProvider =
    FutureProvider.family<List<ModeloLugar>, ConsultaCercaLugares>(
        (ref, q) async {
  ref.watch(lugaresVersionProvider);
  if (!supabaseListo) return const [];
  return ref.read(lugarRemotoDataSourceProvider).listarCerca(
        latitud: q.latitud,
        longitud: q.longitud,
        radioM: q.radioM,
      );
});

void notificarLugaresCambiaron(WidgetRef ref) {
  ref.read(lugaresVersionProvider.notifier).state++;
  ref.invalidate(lugaresRemotosProvider);
  ref.invalidate(lugaresCercaProvider);
}
