import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lugares/datos/lugares_datasource_local.dart';
import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../datos/salidas_datasource_local.dart';

class PantallaCrearSalida extends ConsumerStatefulWidget {
  const PantallaCrearSalida({super.key, this.lugarId});
  final String? lugarId;

  @override
  ConsumerState<PantallaCrearSalida> createState() => _EstadoPantallaCrearSalida();
}

class _EstadoPantallaCrearSalida extends ConsumerState<PantallaCrearSalida> {
  late String _lugarId;
  final _hora = TextEditingController(text: '6:00 AM');
  final _punto = TextEditingController(text: 'Plaza de Armas');
  final _desc = TextEditingController();
  int _minimo = 4;
  int _maximo = 10;

  @override
  void initState() {
    super.initState();
    final lugares = LugaresDataSourceLocal.instancia.todos();
    _lugarId = widget.lugarId ?? lugares.first.id;
  }

  @override
  void dispose() {
    _hora.dispose();
    _punto.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lugares = LugaresDataSourceLocal.instancia.todos();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: PaletaRutas.marronOscuro,
        title: Text(
          'Crear salida',
          style: TipografiaHaku.titulo(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: FondoSuaveSeccion(
        child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Lugar', style: TipografiaHaku.interfaz(fontWeight: FontWeight.w700)),
          DropdownButton<String>(
            value: _lugarId,
            isExpanded: true,
            items: lugares
                .map(
                  (l) => DropdownMenuItem(
                    value: l.id,
                    child: Text(l.nombre),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _lugarId = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hora,
            decoration: const InputDecoration(labelText: 'Hora'),
          ),
          TextField(
            controller: _punto,
            decoration: const InputDecoration(labelText: 'Punto de encuentro'),
          ),
          TextField(
            controller: _desc,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          const SizedBox(height: 12),
          Text('Mínimo: $_minimo'),
          Slider(
            value: _minimo.toDouble(),
            min: 2,
            max: 8,
            divisions: 6,
            activeColor: PaletaRutas.verdeBosque,
            onChanged: (v) => setState(() => _minimo = v.round()),
          ),
          Text('Máximo: $_maximo'),
          Slider(
            value: _maximo.toDouble(),
            min: 4,
            max: 20,
            divisions: 16,
            activeColor: PaletaRutas.verdeBosque,
            onChanged: (v) => setState(() => _maximo = v.round()),
          ),
          const SizedBox(height: 20),
          BotonPrimarioRuta(
            texto: 'Crear salida',
            onPressed: () {
              final lugar =
                  LugaresDataSourceLocal.instancia.porId(_lugarId)!;
              SalidasDataSourceLocal.instancia.crear(
                ModeloSalida(
                  id: 's_${DateTime.now().millisecondsSinceEpoch}',
                  lugarId: lugar.id,
                  lugarNombre: lugar.nombre,
                  organizador: 'Tú',
                  fecha: DateTime.now().add(const Duration(days: 7)),
                  hora: _hora.text.trim(),
                  puntoEncuentro: _punto.text.trim(),
                  cupos: _maximo,
                  inscritos: 1,
                  minimo: _minimo,
                ),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
      ),
    );
  }
}
