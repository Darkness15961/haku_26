import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comunidad/datos/publicacion_datasource_supabase.dart';
import '../../comunidad/dominio/modelo_publicacion.dart';
import '../../lugares/datos/lugar_datasource_supabase.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../rutas/datos/rutas_datasource_supabase.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';

import '../../autenticacion/proveedores/proveedor_sesion.dart';

final rutasGuardadasRemotasProvider = FutureProvider.autoDispose<List<ModeloRuta>>((ref) async {
  final uid = ref.watch(sesionProvider.select((s) => s.usuario?.id));
  final lista = await RutasDataSourceSupabase().listarRutasGuardadas();
  if (uid == null) return lista;
  return lista.where((r) => r.usuarioCreadorId != uid).toList();
});

final lugaresGuardadosRemotosProvider = FutureProvider.autoDispose<List<ModeloLugar>>((ref) async {
  final uid = ref.watch(sesionProvider.select((s) => s.usuario?.id));
  final lista = await LugarDataSourceSupabase().listarLugaresGuardados();
  if (uid == null) return lista;
  return lista.where((l) => l.usuarioCreadorId != uid).toList();
});

final publicacionesGuardadasRemotasProvider = FutureProvider.autoDispose<List<ModeloPublicacionRemota>>((ref) async {
  final uid = ref.watch(sesionProvider.select((s) => s.usuario?.id));
  final lista = await PublicacionDataSourceSupabase().listarPublicacionesGuardadas();
  if (uid == null) return lista;
  return lista.where((p) => p.usuarioId != uid).toList();
});
