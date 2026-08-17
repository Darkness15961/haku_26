import 'package:flutter/material.dart';

import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../datos/salidas_datasource_local.dart';

/// Check-in mínimo antes de la salida.
class PantallaCheckIn extends StatefulWidget {
  const PantallaCheckIn({super.key, required this.salidaId});
  final String salidaId;

  @override
  State<PantallaCheckIn> createState() => _EstadoPantallaCheckIn();
}

class _EstadoPantallaCheckIn extends State<PantallaCheckIn> {
  final _presentes = <String>{'Ana', 'Carlos'};
  static const _lista = ['Ana', 'Carlos', 'Eduardo', 'Luis', 'Mario', 'Sofía'];

  @override
  Widget build(BuildContext context) {
    final s = SalidasDataSourceLocal.instancia.porId(widget.salidaId);

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
              'Nos estamos reuniendo',
              style: TipografiaHaku.titulo(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            Text(
              s?.lugarNombre ?? 'Salida',
              style: TipografiaHaku.interfaz(color: PaletaRutas.marronCuero),
            ),
            const SizedBox(height: 8),
            Text(
              '${_presentes.length} / ${_lista.length} presentes',
              style: TipografiaHaku.interfaz(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: _lista.map((n) {
                  final ok = _presentes.contains(n);
                  return ListTile(
                    title: Text(n, style: TipografiaHaku.interfaz()),
                    trailing: Icon(
                      ok ? Icons.check_circle : Icons.schedule,
                      color: ok ? PaletaRutas.verdeBosque : PaletaRutas.marronCuero,
                    ),
                  );
                }).toList(),
              ),
            ),
            BotonPrimarioRuta(
              texto: 'Hacer check-in',
              icono: Icons.how_to_reg,
              onPressed: () {
                setState(() => _presentes.add('Eduardo'));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Check-in registrado',
                      style: TipografiaHaku.interfaz(color: Colors.white),
                    ),
                    backgroundColor: PaletaRutas.verdeBosque,
                  ),
                );
              },
            ),
            if (_presentes.length >= (s?.minimo ?? 4)) ...[
              const SizedBox(height: 10),
              Text(
                'Mínimo alcanzado. ¡Salida activa!',
                textAlign: TextAlign.center,
                style: TipografiaHaku.interfaz(
                  fontWeight: FontWeight.w800,
                  color: PaletaRutas.verdeBosque,
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
