import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../comunidad/dominio/modelo_publicacion.dart';
import '../../comunidad/dominio/modelo_salida.dart';
import '../../comunidad/proveedores/proveedor_publicaciones.dart';
import '../../comunidad/proveedores/proveedor_salidas.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../lugares/proveedores/proveedor_lugares.dart';

/// Aportaciones reales del usuario logueado (perfil).
class AportacionesPerfil {
  final List<ModeloLugar> lugares;
  final List<ModeloPublicacionRemota> publicaciones;
  final List<ModeloSalidaRemota> salidas;

  const AportacionesPerfil({
    this.lugares = const [],
    this.publicaciones = const [],
    this.salidas = const [],
  });

  int get nLugares => lugares.length;
  int get nPublicaciones => publicaciones.length;
  int get nSalidas => salidas.length;

  /// Rutas propias aún no están en remoto: conteo honesto en 0.
  int get nRutas => 0;
}

final aportacionesPerfilProvider =
    FutureProvider<AportacionesPerfil>((ref) async {
  ref.watch(publicacionesVersionProvider);
  ref.watch(lugaresVersionProvider);
  ref.watch(salidasVersionProvider);
  final uid = ref.watch(sesionProvider.select((s) => s.usuario?.id ?? ''));
  if (!supabaseListo || uid.isEmpty) {
    return const AportacionesPerfil();
  }

  // Cada fuente aislada: un fallo no tumba todo el perfil.
  List<ModeloPublicacionRemota> pubs = const [];
  List<ModeloLugar> lugares = const [];
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
    final salidasAll = await ref.read(salidasRemotasProvider.future);
    salidas = salidasAll.where((s) => s.organizadorId == uid).toList();
  } catch (_) {}

  return AportacionesPerfil(
    lugares: lugares,
    publicaciones: pubs,
    salidas: salidas,
  );
});
