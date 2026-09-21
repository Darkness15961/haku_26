import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/salidas_datasource_local.dart';

/// Confirmar asistencia antes de la salida.
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
    mostrarSnackHaku(
      context,
      ok ? 'Asistencia confirmada' : 'No se pudo confirmar',
      destacado: ok,
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
    final bottom = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        elevation: 0,
        title: Text(
          'Confirmar asistencia',
          style: TipografiaHaku.titulo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reunión',
              style: TipografiaHaku.titulo(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
              ),
            ),
            Text(
              s?.lugarNombre ?? 'Salida',
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            ),
            const SizedBox(height: 8),
            Text(
              'Presentes: ${s?.checkinIds.length ?? 0} / ${ids.length}',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: ids.map((id) {
                  final ok = s?.presente(id) ?? false;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: PaletaRutas.carbon,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        _nombre(id),
                        style: TipografiaHaku.interfaz(
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      trailing: Icon(
                        ok ? Icons.check_circle : Icons.schedule,
                        color: ok ? PaletaRutas.oro : PaletaRutas.plomo,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            BotonPrimarioRuta(
              texto: s?.presente(_yo) == true
                  ? 'Ya confirmaste'
                  : 'Confirmar asistencia',
              icono: Icons.how_to_reg,
              habilitado: s?.presente(_yo) != true,
              onPressed: s?.presente(_yo) == true ? null : _marcar,
            ),
            if ((s?.checkinIds.length ?? 0) >= (s?.minimo ?? 4)) ...[
              const SizedBox(height: 10),
              Text(
                'Cupo mínimo alcanzado',
                textAlign: TextAlign.center,
                style: TipografiaHaku.interfaz(
                  fontWeight: FontWeight.w800,
                  color: PaletaRutas.oro,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
