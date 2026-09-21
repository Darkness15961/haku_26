import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/widgets/avatar_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelo_salida.dart';
import '../proveedores/proveedor_salidas.dart';

class PantallaConfiguracionSalida extends ConsumerStatefulWidget {
  final ModeloSalidaRemota salida;

  const PantallaConfiguracionSalida({super.key, required this.salida});

  @override
  ConsumerState<PantallaConfiguracionSalida> createState() =>
      _EstadoPantallaConfiguracionSalida();
}

class _EstadoPantallaConfiguracionSalida
    extends ConsumerState<PantallaConfiguracionSalida> {
  bool _cambiandoInscripcion = false;

  Future<void> _toggleInscripcion(bool actual) async {
    if (_cambiandoInscripcion) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;

    final nuevoEstado = !actual;
    if (!nuevoEstado) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: PaletaRutas.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: PaletaRutas.oro.withValues(alpha: 0.3)),
          ),
          title: Text(
            'Cerrar inscripciones',
            style: TipografiaHaku.titulo(
              color: PaletaRutas.piedra,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Nadie más podrá unirse a la salida.',
            style: TipografiaHaku.interfaz(
              color: PaletaRutas.plomoClaro,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancelar',
                style: TipografiaHaku.interfaz(
                  color: PaletaRutas.plomo,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PaletaRutas.oro,
                foregroundColor: PaletaRutas.ink,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Sí, cerrar',
                style: TipografiaHaku.interfaz(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;
    }

    setState(() => _cambiandoInscripcion = true);
    try {
      await ref
          .read(salidaRemotoDataSourceProvider)
          .cambiarEstadoInscripcionSalida(widget.salida.id, nuevoEstado);
      notificarSalidasCambiaron(ref);
      if (mounted) {
        mostrarSnackHaku(
          context,
          nuevoEstado ? 'Inscripciones abiertas' : 'Inscripciones cerradas',
          destacado: true,
        );
      }
    } catch (_) {
      if (mounted) {
        mostrarSnackHaku(context, 'No se pudo actualizar la inscripción');
      }
    } finally {
      if (mounted) setState(() => _cambiandoInscripcion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remotaAsync = ref.watch(salidaDetalleProvider(widget.salida.id));
    final s = remotaAsync.valueOrNull ?? widget.salida;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        elevation: 0,
        title: Text(
          'Configuraciones de Salida',
          style: TipografiaHaku.titulo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Información',
                style: TipografiaHaku.titulo(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: PaletaRutas.piedra,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PaletaRutas.carbon,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: PaletaRutas.plomo.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado de Inscripciones',
                        style: TipografiaHaku.interfaz(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.inscripcionAbierta
                            ? 'Los usuarios pueden unirse libremente.'
                            : 'Las inscripciones están cerradas.',
                        style: TipografiaHaku.interfaz(
                          fontSize: 13,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_cambiandoInscripcion)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: PaletaRutas.oro,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else
                  Switch(
                    value: s.inscripcionAbierta,
                    activeColor: PaletaRutas.oro,
                    onChanged: (val) => _toggleInscripcion(s.inscripcionAbierta),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Inscritos Confirmados',
            style: TipografiaHaku.titulo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: PaletaRutas.piedra,
            ),
          ),
          const SizedBox(height: 16),
          if (s.participanteIds.isEmpty)
            Text(
              'Aún no hay inscritos.',
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            )
          else
            ...s.participanteIds.map((uid) {
              return ListTile(
                leading: const Icon(Icons.person, color: PaletaRutas.oro),
                title: Text(
                  uid == s.organizadorId ? 'Tú (Organizador)' : uid,
                  style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                ),
              );
            }),
        ],
      ),
    );
  }
}
