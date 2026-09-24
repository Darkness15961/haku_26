import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../comunidad/dominio/modelo_publicacion.dart';
import '../../comunidad/dominio/modelo_salida.dart';
import '../../comunidad/proveedores/proveedor_publicaciones.dart';
import '../../comunidad/proveedores/proveedor_salidas.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../lugares/proveedores/proveedor_lugares.dart';
import '../../rutas/dominio/modelos/modelo_ruta_propia.dart';
import '../../rutas/proveedores/proveedor_rutas.dart';

/// Aportaciones reales del usuario logueado (perfil).
class AportacionesPerfil {
  final List<ModeloLugar> lugares;
  final List<ModeloRutaPropia> rutas;
  final List<ModeloPublicacionRemota> publicaciones;
  final List<ModeloSalidaRemota> salidas;

  const AportacionesPerfil({
    this.lugares = const [],
    this.rutas = const [],
    this.publicaciones = const [],
    this.salidas = const [],
  });

  int get nLugares => lugares.length;
  int get nRutas => rutas.length;
  int get nPublicaciones => publicaciones.length;
  int get nSalidas => salidas.length;
}

final aportacionesPerfilProvider =
    FutureProvider<AportacionesPerfil>((ref) async {
  ref.watch(publicacionesVersionProvider);
  ref.watch(lugaresVersionProvider);
  ref.watch(rutasVersionProvider);
  ref.watch(salidasVersionProvider);
  final uid = ref.watch(sesionProvider.select((s) => s.usuario?.id ?? ''));
  if (!supabaseListo || uid.isEmpty) {
    return const AportacionesPerfil();
  }

  // Cada fuente aislada: un fallo no tumba todo el perfil.
  List<ModeloPublicacionRemota> pubs = const [];
  List<ModeloLugar> lugares = const [];
  List<ModeloRutaPropia> rutas = const [];
  List<ModeloSalidaRemota> salidas = const [];

  try {
    pubs = await ref
        .read(publicacionRemotoDataSourceProvider)
        .listarDeUsuario(uid);
  } catch (_) {}

  try {
    lugares =
        await ref.read(lugarRemotoDataSourceProvider).listarDeUsuario(uid);
  } catch (_) {}

  try {
    rutas = await ref.read(rutasDataSourceProvider).listarPropias();
  } catch (_) {}

  try {
    final salidasAll = await ref.read(salidasRemotasProvider.future);
    salidas = salidasAll.where((s) => s.organizadorId == uid).toList();
  } catch (_) {}

  return AportacionesPerfil(
    lugares: lugares,
    rutas: rutas,
    publicaciones: pubs,
    salidas: salidas,
  );
});
