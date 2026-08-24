import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../../nucleo/metricas/metricas_descubrimiento.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
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
    ref.watch(almacenFeedProvider);
    final salidas = SalidasDataSourceLocal.instancia.todas(
      lugarId: widget.lugarId,
    );
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    final inscritos = salidas.fold<int>(0, (s, x) => s + x.inscritos);

    return Scaffold(
      backgroundColor: Colors.white,
      body: FondoSuaveSeccion(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: PaletaRutas.marronOscuro,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Salidas',
                          textAlign: TextAlign.center,
                          style: TipografiaHaku.titulo(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Crear salida',
                        onPressed: () async {
                          final ok = await asegurarSesion(context, ref);
                          if (!ok || !mounted) return;
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  PantallaCrearSalida(lugarId: widget.lugarId),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.add_rounded,
                          color: PaletaRutas.marronOscuro,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: LineaEncabezadoInca(altura: 2),
                ),
              ),
              SliverToBoxAdapter(
                child: _HeroSalidas(
                  total: salidas.length,
                  inscritos: inscritos,
                ),
              ),
              if (salidas.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.hiking,
                          size: 48,
                          color: PaletaRutas.marronCuero.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sin salidas programadas',
                          style: TipografiaHaku.titulo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () async {
                            final ok = await asegurarSesion(context, ref);
                            if (!ok || !mounted) return;
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PantallaCrearSalida(
                                  lugarId: widget.lugarId,
                                ),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: PaletaRutas.terracota,
                          ),
                          child: const Text('Crear salida'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
                  sliver: SliverList.separated(
                    itemCount: salidas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final s = salidas[i];
                      return _CardSalidaVisual(
                        salida: s,
                        indice: i,
                        onDetalle: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  PantallaDetalleSalida(salidaId: s.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSalidas extends StatelessWidget {
  const _HeroSalidas({required this.total, required this.inscritos});

  final int total;
  final int inscritos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Image.asset(
                'public/image/encabezado_rutas.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PaletaRutas.marronOscuro.withValues(alpha: 0.55),
                      PaletaRutas.terracota.withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próximas salidas',
                    style: TipografiaHaku.titulo(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$total salidas · $inscritos inscritos',
                    style: TipografiaHaku.interfaz(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardSalidaVisual extends StatelessWidget {
  const _CardSalidaVisual({
    required this.salida,
    required this.indice,
    required this.onDetalle,
  });

  final ModeloSalida salida;
  final int indice;
  final VoidCallback onDetalle;

  @override
  Widget build(BuildContext context) {
    final fecha =
        '${salida.fecha.day}/${salida.fecha.month} · ${salida.hora}';
    final lleno = salida.inscritos >= salida.cupos;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onDetalle,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        indice.isEven
                            ? 'public/image/adorno_rutas.jpg'
                            : 'public/image/detalle_ruta_b.jpg',
                        fit: BoxFit.cover,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.65),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: lleno
                                    ? PaletaRutas.marronOscuro
                                    : PaletaRutas.terracota,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                lleno ? 'LLENO' : salida.dificultad.toUpperCase(),
                                style: TipografiaHaku.interfaz(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              fecha,
                              style: TipografiaHaku.interfaz(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: PaletaRutas.crema,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salida.lugarNombre,
                        style: TipografiaHaku.titulo(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${salida.puntoEncuentro} · ${salida.organizador}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          color: PaletaRutas.marronCuero,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 16,
                            color: PaletaRutas.terracota,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${salida.inscritos}/${salida.cupos} inscritos',
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.terracota,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: PaletaRutas.marronOscuro,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    ref.watch(almacenFeedProvider);
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 160,
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
                            Colors.black.withValues(alpha: 0.6),
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
                              color: PaletaRutas.terracota,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s.dificultad.toUpperCase(),
                              style: TipografiaHaku.interfaz(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${s.fecha.day}/${s.fecha.month} · ${s.hora}',
                            style: TipografiaHaku.interfaz(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const LineaEncabezadoInca(altura: 2),
            const SizedBox(height: 16),
            Text(
              'Punto de encuentro',
              style: TipografiaHaku.titulo(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(s.puntoEncuentro, style: TipografiaHaku.interfaz()),
            const SizedBox(height: 12),
            Text(
              'Organiza',
              style: TipografiaHaku.titulo(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(s.organizador, style: TipografiaHaku.interfaz()),
            const SizedBox(height: 12),
            Text(
              'Cupos',
              style: TipografiaHaku.titulo(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              '${s.inscritos}/${s.cupos} (mín. ${s.minimo})',
              style: TipografiaHaku.interfaz(fontWeight: FontWeight.w600),
            ),
            if (s.grupo.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Grupo',
                style: TipografiaHaku.titulo(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(s.grupo, style: TipografiaHaku.interfaz()),
            ],
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => abrirDetalleLugar(context, s.lugarId),
              child: Text(
                'Ver lugar',
                style: TipografiaHaku.interfaz(
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.terracota,
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
              texto: s.llena ? 'Cupos llenos' : 'Me apunto',
              habilitado: !s.llena,
              onPressed: s.llena
                  ? null
                  : () async {
                      final ok = await asegurarSesion(context, ref);
                      if (!ok || !mounted) return;
                      final done =
                          SalidasDataSourceLocal.instancia.enrolar(s.id);
                      if (done) {
                        await ref
                            .read(metricasDescubrimientoProvider.notifier)
                            .registrarEnrolamiento(s.id);
                        bumpMetricas(ref);
                        await ref
                            .read(almacenFeedProvider.notifier)
                            .persistirSatelites();
                      }
                      if (!mounted) return;
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            done
                                ? 'Te enrolaste en la salida'
                                : 'No se pudo enrolar',
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
    );
  }
}
