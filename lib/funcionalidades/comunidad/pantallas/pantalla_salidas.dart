import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../../nucleo/metricas/metricas_descubrimiento.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../inicio/proveedores/proveedor_comunidad_ui.dart';
import '../../inicio/proveedores/proveedor_navegacion_inicio.dart';
import '../../lugares/datos/lugares_datasource_local.dart';
import '../../lugares/pantallas/pantalla_detalle_lugar.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/salidas_datasource_local.dart';
import '../widgets/mapa_punto_encuentro.dart';
import 'pantalla_check_in.dart';

class PantallaSalidas extends ConsumerStatefulWidget {
  const PantallaSalidas({super.key, this.lugarId, this.comunidadId});

  final String? lugarId;
  final String? comunidadId;

  @override
  ConsumerState<PantallaSalidas> createState() => _EstadoPantallaSalidas();
}

class _EstadoPantallaSalidas extends ConsumerState<PantallaSalidas> {
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(almacenFeedProvider);
    final salidas = SalidasDataSourceLocal.instancia.todas(
      lugarId: widget.lugarId,
      comunidadId: widget.comunidadId,
    );
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    final inscritos = salidas.fold<int>(0, (s, x) => s + x.inscritos);
    final lugar = widget.lugarId == null
        ? null
        : LugaresDataSourceLocal.instancia.porId(widget.lugarId!);
    String? tituloComunidad;
    if (widget.comunidadId != null) {
      for (final c in store.comunidades) {
        if (c.id == widget.comunidadId) {
          tituloComunidad = c.nombre;
          break;
        }
      }
    }
    final tituloSitio = lugar?.nombre ??
        (salidas.isNotEmpty ? salidas.first.lugarNombre : null);
    final tituloAppBar = tituloComunidad ?? tituloSitio ?? 'Salidas';

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
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
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tituloAppBar,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.titulo(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _HeroSalidas(
                total: salidas.length,
                inscritos: inscritos,
                nombreSitio: tituloSitio,
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
                        color: PaletaRutas.plomo.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.comunidadId != null
                            ? 'Sin salidas en esta comunidad'
                            : 'Sin salidas en este sitio',
                        style: TipografiaHaku.titulo(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea salidas desde Comunidad → Salidas',
                        textAlign: TextAlign.center,
                        style: TipografiaHaku.interfaz(
                          fontSize: 13,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          ref.read(pestaniaShellInicioProvider.notifier).state =
                              2;
                          ref.read(pestaniaComunidadProvider.notifier).state =
                              1;
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: PaletaRutas.oro,
                          foregroundColor: PaletaRutas.ink,
                        ),
                        child: Text(
                          'Ir a Comunidad',
                          style: TipografiaHaku.interfaz(
                            fontWeight: FontWeight.w800,
                            color: PaletaRutas.ink,
                          ),
                        ),
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
    );
  }
}

class _HeroSalidas extends StatelessWidget {
  const _HeroSalidas({
    required this.total,
    required this.inscritos,
    this.nombreSitio,
  });

  final int total;
  final int inscritos;
  final String? nombreSitio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            SizedBox(
              height: 112,
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
                      PaletaRutas.ink.withValues(alpha: 0.72),
                      PaletaRutas.oroOscuro.withValues(alpha: 0.75),
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
                    nombreSitio == null
                        ? 'Próximas salidas'
                        : 'Salidas grupales',
                    style: TipografiaHaku.titulo(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nombreSitio == null
                        ? '$total salidas · $inscritos inscritos'
                        : '$nombreSitio · $total salidas · $inscritos inscritos',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TipografiaHaku.interfaz(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.92),
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
    final cuposMax = salida.cuposTotales;
    final lleno = salida.inscritos >= cuposMax;
    final cuposLibres = cuposMax - salida.inscritos;
    final colorCupos = lleno
        ? const Color(0xFFC45C4A)
        : const Color(0xFF2F7D4A);

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
                color: Colors.black.withValues(alpha: 0.28),
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
                  height: 108,
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
                                color: colorCupos,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                lleno
                                    ? 'SIN CUPOS'
                                    : '$cuposLibres cupos',
                                style: TipografiaHaku.interfaz(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                lleno
                                    ? 'LLENO'
                                    : salida.dificultad.toUpperCase(),
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
                  color: const Color(0xFF1C1A17),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salida.lugarNombre,
                        style: TipografiaHaku.titulo(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${salida.puntoEncuentro} · ${salida.organizador}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          color: PaletaRutas.plomo,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 16,
                            color: colorCupos,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${salida.inscritos}/$cuposMax inscritos',
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colorCupos,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: PaletaRutas.oro,
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
                          Colors.black.withValues(alpha: 0.72),
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
                            color: Colors.white,
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
            valor: '${s.fecha.day}/${s.fecha.month}/${s.fecha.year} · ${s.hora}',
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
          TextButton(
            onPressed: () => abrirDetalleLugar(context, s.lugarId),
            child: Text(
              'Ver ficha del lugar',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: PaletaRutas.oro,
              ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Ya estás en este grupo',
                            style: TipografiaHaku.interfaz(color: Colors.white),
                          ),
                          backgroundColor: PaletaRutas.carbon,
                        ),
                      );
                      return;
                    }
                    final ok = await asegurarSesion(context, ref);
                    if (!ok || !mounted) return;
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
                    if (!mounted) return;
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          done
                              ? 'Te uniste a la salida'
                              : 'No se pudo unir',
                          style: TipografiaHaku.interfaz(color: Colors.white),
                        ),
                        backgroundColor: PaletaRutas.carbon,
                      ),
                    );
                  },
            style: FilledButton.styleFrom(
              backgroundColor:
                  yaUnido ? PaletaRutas.plomoOscuro : PaletaRutas.oro,
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
                color: yaUnido || s.llena ? PaletaRutas.piedra : PaletaRutas.ink,
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
