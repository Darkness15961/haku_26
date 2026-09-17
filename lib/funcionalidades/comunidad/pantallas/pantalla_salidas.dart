import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelo_salida.dart';
import '../proveedores/proveedor_salidas.dart';
import '../widgets/tarjeta_salida_remota.dart';
import 'pantalla_crear_salida_remota.dart';

/// Listado remoto de salidas filtrado por lugar, ruta o comunidad.
class PantallaSalidas extends ConsumerWidget {
  const PantallaSalidas({
    super.key,
    this.lugarId,
    this.rutaId,
    this.rutaTitulo,
    this.comunidadId,
    this.comunidadTitulo,
  });

  final String? lugarId;
  final String? rutaId;
  final String? rutaTitulo;
  final String? comunidadId;
  final String? comunidadTitulo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ModeloSalidaRemota>> async;
    if (lugarId != null && lugarId!.trim().isNotEmpty) {
      async = ref.watch(salidasPorLugarProvider(lugarId!));
    } else if (rutaId != null && rutaId!.trim().isNotEmpty) {
      async = ref.watch(salidasPorRutaProvider(rutaId!));
    } else if (comunidadId != null && comunidadId!.trim().isNotEmpty) {
      async = ref.watch(salidasPorComunidadProvider(comunidadId!));
    } else {
      async = ref.watch(salidasRemotasProvider);
    }

    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    final titulo = lugarId != null
        ? 'Salidas del lugar'
        : (rutaId != null
              ? 'Salidas de la ruta'
              : (comunidadId != null ? 'Salidas de la comunidad' : 'Salidas'));

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        elevation: 0,
        title: Text(
          titulo,
          style: TipografiaHaku.titulo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Crear salida',
            onPressed: () async {
              final ok = await asegurarSesion(context, ref);
              if (!ok || !context.mounted) return;
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => PantallaCrearSalidaRemota(
                    lugarId: lugarId,
                    rutaId: rutaId,
                    rutaTitulo: rutaTitulo,
                    comunidadId: comunidadId,
                    comunidadTitulo: comunidadTitulo,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded, color: PaletaRutas.oro),
          ),
        ],
      ),
      body: () {
        if (async.isLoading && !async.hasValue) {
          return const Center(
            child: CircularProgressIndicator(color: PaletaRutas.oro),
          );
        }
        if (async.hasError && !async.hasValue) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 36,
                  color: PaletaRutas.plomo,
                ),
                const SizedBox(height: 10),
                Text(
                  'No pudimos cargar las salidas.',
                  style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(
                    lugarId != null && lugarId!.trim().isNotEmpty
                        ? salidasPorLugarProvider(lugarId!)
                        : rutaId != null && rutaId!.trim().isNotEmpty
                        ? salidasPorRutaProvider(rutaId!)
                        : comunidadId != null && comunidadId!.trim().isNotEmpty
                        ? salidasPorComunidadProvider(comunidadId!)
                        : salidasRemotasProvider,
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final salidas = async.valueOrNull ?? const <ModeloSalidaRemota>[];
        if (salidas.isEmpty) {
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 48, 24, bottom),
            child: Text(
              'No hay salidas en este filtro.',
              textAlign: TextAlign.center,
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
          itemCount: salidas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            return TarjetaSalidaRemota(salida: salidas[i], omitirPadding: true);
          },
        );
      }(),
    );
  }
}
