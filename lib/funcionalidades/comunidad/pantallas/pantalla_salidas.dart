import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/metricas/metricas_descubrimiento.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../lugares/pantallas/pantalla_detalle_lugar.dart';
import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/salidas_datasource_local.dart';
import 'pantalla_check_in.dart';
import 'pantalla_crear_salida.dart';

class PantallaSalidas extends ConsumerStatefulWidget {
  const PantallaSalidas({super.key, this.lugarId});

  final String? lugarId;

  @override
  ConsumerState<PantallaSalidas> createState() => _EstadoPantallaSalidas();
}

class _EstadoPantallaSalidas extends ConsumerState<PantallaSalidas> {
  @override
  Widget build(BuildContext context) {
    final salidas = SalidasDataSourceLocal.instancia.todas(
      lugarId: widget.lugarId,
    );
    final bottom = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: PaletaRutas.marronOscuro,
        elevation: 0,
        title: Text(
          'Próximas salidas',
          style: TipografiaHaku.titulo(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Crear salida',
            onPressed: () async {
              final ok = await asegurarSesion(context, ref);
              if (!ok || !mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PantallaCrearSalida(lugarId: widget.lugarId),
                ),
              );
              setState(() {});
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: FondoSuaveSeccion(
        child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: LineaEncabezadoInca(altura: 2),
          ),
          Expanded(
            child: salidas.isEmpty
                ? Center(
                    child: Text(
                      'No hay salidas aún. Crea la primera.',
                      style: TipografiaHaku.interfaz(color: PaletaRutas.marronCuero),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
                    itemCount: salidas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final s = salidas[i];
                      return _CardSalida(
                        salida: s,
                        onDetalle: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PantallaDetalleSalida(salidaId: s.id),
                            ),
                          );
                          setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      ),
    );
  }
}

class _CardSalida extends StatelessWidget {
  const _CardSalida({required this.salida, required this.onDetalle});
  final ModeloSalida salida;
  final VoidCallback onDetalle;

  @override
  Widget build(BuildContext context) {
    final fecha =
        '${salida.fecha.day}/${salida.fecha.month} · ${salida.hora}';
    return Material(
      color: PaletaRutas.crema,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onDetalle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                salida.lugarNombre,
                style: TipografiaHaku.titulo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$fecha · ${salida.puntoEncuentro}',
                style: TipografiaHaku.interfaz(
                  fontSize: 13,
                  color: PaletaRutas.marronCuero,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${salida.inscritos} / ${salida.cupos} · mínimo ${salida.minimo}',
                style: TipografiaHaku.interfaz(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PantallaDetalleSalida extends ConsumerStatefulWidget {
  const PantallaDetalleSalida({super.key, required this.salidaId});
  final String salidaId;

  @override
  ConsumerState<PantallaDetalleSalida> createState() =>
      _EstadoPantallaDetalleSalida();
}

class _EstadoPantallaDetalleSalida extends ConsumerState<PantallaDetalleSalida> {
  @override
  Widget build(BuildContext context) {
    final s = SalidasDataSourceLocal.instancia.porId(widget.salidaId);
    if (s == null) {
      return const Scaffold(body: Center(child: Text('Salida no encontrada')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: PaletaRutas.marronOscuro,
        title: Text(
          s.lugarNombre,
          style: TipografiaHaku.titulo(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: FondoSuaveSeccion(
        child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${s.fecha.day}/${s.fecha.month} · ${s.hora}',
              style: TipografiaHaku.interfaz(
                fontSize: 15,
                color: PaletaRutas.marronCuero,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Organizador: ${s.organizador}',
              style: TipografiaHaku.titulo(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (s.grupo.isNotEmpty)
              Text(
                'Grupo: ${s.grupo}',
                style: TipografiaHaku.interfaz(color: PaletaRutas.marronCuero),
              ),
            const SizedBox(height: 12),
            Text(
              'Punto de encuentro: ${s.puntoEncuentro}',
              style: TipografiaHaku.interfaz(),
            ),
            Text(
              'Dificultad: ${s.dificultad}',
              style: TipografiaHaku.interfaz(),
            ),
            Text(
              'Participantes: ${s.inscritos} / ${s.cupos}',
              style: TipografiaHaku.interfaz(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => abrirDetalleLugar(context, s.lugarId),
              child: Text(
                'Ver lugar',
                style: TipografiaHaku.interfaz(
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.verdeBosque,
                ),
              ),
            ),
            BotonSecundarioRuta(
              texto: 'Check-in',
              icono: Icons.how_to_reg_outlined,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PantallaCheckIn(salidaId: s.id),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            BotonPrimarioRuta(
              texto: s.llena ? 'Cupos llenos' : 'Enrolarme',
              habilitado: !s.llena,
              onPressed: s.llena
                  ? null
                  : () async {
                      final ok = await asegurarSesion(context, ref);
                      if (!ok || !mounted) return;
                      final done =
                          SalidasDataSourceLocal.instancia.enrolar(s.id);
                      if (done) {
                        ref
                            .read(metricasDescubrimientoProvider.notifier)
                            .registrarEnrolamiento(s.id);
                        bumpMetricas(ref);
                      }
                      setState(() {});
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            done ? 'Te enrolaste en la salida' : 'No se pudo enrolar',
                            style: TipografiaHaku.interfaz(color: Colors.white),
                          ),
                          backgroundColor: PaletaRutas.marronOscuro,
                        ),
                      );
                    },
            ),
          ],
        ),
      ),
      ),
    );
  }
}
