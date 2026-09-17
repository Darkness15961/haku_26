import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../../nucleo/metricas/metricas_descubrimiento.dart';
import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../lugares/navegacion_lugar.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/salidas_datasource_local.dart';
import '../widgets/mapa_punto_encuentro.dart';
import 'pantalla_check_in.dart';

/// Detalle de salida **demo local** (legacy). Tab remoto usa PantallaDetalleSalidaRemota.

class PantallaDetalleSalida extends ConsumerStatefulWidget {
  const PantallaDetalleSalida({super.key, required this.salidaId});
  final String salidaId;

  @override
  ConsumerState<PantallaDetalleSalida> createState() =>
      _EstadoPantallaDetalleSalida();
}

class _EstadoPantallaDetalleSalida
    extends ConsumerState<PantallaDetalleSalida> {
  @override
  Widget build(BuildContext context) {
    ref.watch(almacenFeedProvider);
    final s = SalidasDataSourceLocal.instancia.porId(widget.salidaId);
    if (s == null) {
      return const Scaffold(body: Center(child: Text('Salida no encontrada')));
    }
    final uid = AlmacenFeedNotifier.idUsuarioLocal;
    final yaUnido = s.unido(uid);

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        title: Text(
          s.lugarNombre,
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 168,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'public/image/adorno_detalle_ruta.jpg',
                    fit: BoxFit.cover,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          PaletaRutas.ink.withValues(alpha: 0.72),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: PaletaRutas.oro,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            s.dificultad.toUpperCase(),
                            style: TipografiaHaku.interfaz(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: PaletaRutas.ink,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${s.fecha.day}/${s.fecha.month}/${s.fecha.year} · ${s.hora}',
                          style: TipografiaHaku.interfaz(
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Invitación a conocer esta ruta',
            style: TipografiaHaku.titulo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: PaletaRutas.piedra,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'El grupo parte en la fecha indicada. Cupo limitado.',
            style: TipografiaHaku.interfaz(
              fontSize: 13,
              color: PaletaRutas.plomoClaro,
            ),
          ),
          const SizedBox(height: 18),
          _BloqueDetalle(
            titulo: s.esDeGrupo ? 'Organiza (grupo)' : 'Organiza (persona)',
            valor: s.esDeGrupo
                ? '${s.organizador} · ${s.grupo}'
                : s.organizador,
            icono: s.esDeGrupo ? Icons.groups_outlined : Icons.person_outline,
          ),
          _BloqueDetalle(
            titulo: 'Lugar',
            valor: s.lugarNombre,
            icono: Icons.landscape_outlined,
          ),
          _BloqueDetalle(
            titulo: 'Fecha de salida',
            valor:
                '${s.fecha.day}/${s.fecha.month}/${s.fecha.year} · ${s.hora}',
            icono: Icons.event_outlined,
          ),
          _BloqueDetalle(
            titulo: 'Punto de encuentro',
            valor: s.puntoEncuentro,
            icono: Icons.place_outlined,
          ),
          const SizedBox(height: 8),
          Text(
            'Mapa del encuentro',
            style: TipografiaHaku.interfaz(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: PaletaRutas.plomoClaro,
            ),
          ),
          const SizedBox(height: 8),
          MapaPuntoEncuentro(salida: s, altura: 220),
          const SizedBox(height: 16),
          _BloqueDetalle(
            titulo: 'Cupos abiertos (enrolados)',
            valor: '${s.cupos} personas pueden unirse desde la comunidad',
            icono: Icons.person_add_alt_1_outlined,
          ),
          if (s.esDeGrupo)
            _BloqueDetalle(
              titulo: 'Cupos del grupo',
              valor: '${s.cuposGrupo} reservados para miembros de ${s.grupo}',
              icono: Icons.groups_outlined,
            ),
          _BloqueDetalle(
            titulo: 'Inscritos ahora',
            valor:
                '${s.inscritos} / ${s.cuposTotales} (mín. ${s.minimo} para salir)',
            icono: Icons.how_to_reg_outlined,
          ),
          const SizedBox(height: 10),
          if (!supabaseListo || int.tryParse(s.lugarId.trim()) != null)
            TextButton(
              onPressed: () => abrirDetalleLugar(context, s.lugarId),
              child: Text(
                'Ver ficha del lugar',
                style: TipografiaHaku.interfaz(
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.oro,
                ),
              ),
            )
          else
            Text(
              'Abre el lugar desde Explora para ver la información actualizada.',
              style: TipografiaHaku.interfaz(
                fontSize: 12,
                color: PaletaRutas.plomoClaro,
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PantallaCheckIn(salidaId: s.id),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: PaletaRutas.piedra,
              side: BorderSide(color: PaletaRutas.plomo.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.how_to_reg_outlined),
            label: Text(
              'Confirmar asistencia',
              style: TipografiaHaku.interfaz(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: s.llena && !yaUnido
                ? null
                : () async {
                    if (yaUnido) {
                      mostrarSnackHaku(context, 'Ya estás en este grupo');
                      return;
                    }
                    final ok = await asegurarSesion(context, ref);
                    if (!ok || !context.mounted) return;
                    final done = SalidasDataSourceLocal.instancia.enrolar(
                      s.id,
                      usuarioId: uid,
                    );
                    if (done) {
                      await ref
                          .read(metricasDescubrimientoProvider.notifier)
                          .registrarEnrolamiento(s.id);
                      bumpMetricas(ref);
                      await ref
                          .read(almacenFeedProvider.notifier)
                          .persistirSatelites();
                    }
                    if (!context.mounted) return;
                    setState(() {});
                    mostrarSnackHaku(
                      context,
                      done ? 'Te uniste a la salida' : 'No se pudo unir',
                      destacado: done,
                    );
                  },
            style: FilledButton.styleFrom(
              backgroundColor: yaUnido
                  ? PaletaRutas.plomoOscuro
                  : PaletaRutas.oro,
              foregroundColor: PaletaRutas.ink,
              disabledBackgroundColor: PaletaRutas.plomoOscuro,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              yaUnido
                  ? 'Ya estás unido'
                  : s.llena
                  ? 'Cupos llenos'
                  : 'Unirse al grupo',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: yaUnido || s.llena
                    ? PaletaRutas.piedra
                    : PaletaRutas.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BloqueDetalle extends StatelessWidget {
  const _BloqueDetalle({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  final String titulo;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: PaletaRutas.oro),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TipografiaHaku.interfaz(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: TipografiaHaku.interfaz(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PaletaRutas.piedra,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
