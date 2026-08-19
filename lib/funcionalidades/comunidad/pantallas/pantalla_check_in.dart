import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../datos/salidas_datasource_local.dart';

/// Check-in mínimo antes de la salida.
class PantallaCheckIn extends ConsumerStatefulWidget {
  const PantallaCheckIn({super.key, required this.salidaId});
  final String salidaId;

  @override
  ConsumerState<PantallaCheckIn> createState() => _EstadoPantallaCheckIn();
}

class _EstadoPantallaCheckIn extends ConsumerState<PantallaCheckIn> {
  static const _yo = AlmacenFeedNotifier.idUsuarioLocal;

  String _nombre(String id) {
    if (id == _yo) return 'Tú';
    final p = ref.read(almacenFeedProvider).perfilPorId(id);
    return p?.nombre ?? id;
  }

  Future<void> _marcar() async {
    final ok = SalidasDataSourceLocal.instancia.checkIn(widget.salidaId);
    if (ok) {
      await ref.read(almacenFeedProvider.notifier).persistirSatelites();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Check-in' : 'Error',
          style: TipografiaHaku.interfaz(color: Colors.white),
        ),
        backgroundColor: PaletaRutas.terracota,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(almacenFeedProvider);
    final s = SalidasDataSourceLocal.instancia.porId(widget.salidaId);
    final ids = {
      ...?s?.inscritoIds,
      ...?s?.checkinIds,
    }.toList();
    if (ids.isEmpty) ids.add(_yo);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: PaletaRutas.marronOscuro,
        title: Text(
          'Check-in',
          style: TipografiaHaku.titulo(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: FondoSuaveSeccion(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reunión',
                style: TipografiaHaku.titulo(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                s?.lugarNombre ?? 'Salida',
                style: TipografiaHaku.interfaz(color: PaletaRutas.marronCuero),
              ),
              const SizedBox(height: 8),
              Text(
                '${s?.checkinIds.length ?? 0} / ${ids.length}',
                style: TipografiaHaku.interfaz(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: ids.map((id) {
                    final ok = s?.presente(id) ?? false;
                    return ListTile(
                      title: Text(_nombre(id), style: TipografiaHaku.interfaz()),
                      trailing: Icon(
                        ok ? Icons.check_circle : Icons.schedule,
                        color: ok
                            ? PaletaRutas.terracota
                            : PaletaRutas.marronCuero,
                      ),
                    );
                  }).toList(),
                ),
              ),
              BotonPrimarioRuta(
                texto: s?.presente(_yo) == true ? 'Listo' : 'Check-in',
                icono: Icons.how_to_reg,
                habilitado: s?.presente(_yo) != true,
                onPressed: s?.presente(_yo) == true ? null : _marcar,
              ),
              if ((s?.checkinIds.length ?? 0) >= (s?.minimo ?? 4)) ...[
                const SizedBox(height: 10),
                Text(
                  'Mínimo listo',
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(
                    fontWeight: FontWeight.w800,
                    color: PaletaRutas.terracota,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
