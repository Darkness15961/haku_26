import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/configuracion/modo_ejecucion.dart';
import '../../lugares/datos/lugares_datasource_local.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../lugares/proveedores/proveedor_lugares.dart';
import '../../rutas/datos/rutas_datasource_local.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/proveedores/proveedor_rutas.dart';

/// Datos necesarios para dibujar Hoy sin mezclar origenes.
class DatosInicioHoy {
  const DatosInicioHoy({
    required this.modo,
    required this.rutas,
    required this.lugares,
  });

  final ModoEjecucionHaku modo;
  final List<ModeloRuta> rutas;
  final List<ModeloLugar> lugares;

  bool get esDemo => modo == ModoEjecucionHaku.demo;
}

/// Punto de inyeccion para probar ambos modos sin depender de dart-define.
final modoEjecucionInicioProvider = Provider<ModoEjecucionHaku>((ref) {
  return ConfigEntornoHaku.modo;
});

/// Publica rutas y lugares como una sola unidad coherente.
///
/// En produccion ambas consultas comienzan en paralelo y la UI permanece en
/// carga hasta tener las dos respuestas. En demo ambas fuentes son locales.
final datosInicioHoyProvider = FutureProvider<DatosInicioHoy>((ref) async {
  final modo = ref.watch(modoEjecucionInicioProvider);

  if (modo == ModoEjecucionHaku.demo) {
    return DatosInicioHoy(
      modo: modo,
      rutas: RutasDataSourceLocal.obtenerTodas(),
      lugares: LugaresDataSourceLocal.instancia.todos(),
    );
  }

  final rutasFuture = ref.watch(rutasPublicadasProvider.future);
  final lugaresFuture = ref.watch(lugaresRemotosProvider.future);
  final rutas = await rutasFuture;
  final lugares = await lugaresFuture;

  return DatosInicioHoy(
    modo: modo,
    rutas: List.unmodifiable(rutas),
    lugares: List.unmodifiable(lugares),
  );
});
