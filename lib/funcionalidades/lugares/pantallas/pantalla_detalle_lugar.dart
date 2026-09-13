import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/navegacion/abrir_pantalla_haku.dart';
import '../../../nucleo/recursos/copy_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/menu_acciones_detalle.dart';
import '../../rutas/widgets/menu_acciones_flotante.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../dominio/modelos/modelo_lugar.dart';
import '../proveedores/proveedor_lugares.dart';
import '../widgets/fila_metricas_comunidad.dart';
import '../widgets/lista_experiencias_lugar.dart';
import '../widgets/metricas_comunidad.dart';
import '../widgets/recuerdos_comunidad.dart';

/// Ficha de lugar — ordenada para el turista (Explora / isla / mapa).
class PantallaDetalleLugar extends ConsumerStatefulWidget {
  const PantallaDetalleLugar({super.key, required this.lugarId});

  final String lugarId;

  @override
  ConsumerState<PantallaDetalleLugar> createState() =>
      _EstadoPantallaDetalleLugar();
}

class _EstadoPantallaDetalleLugar extends ConsumerState<PantallaDetalleLugar> {
  bool _menuAbierto = false;

  void _toggleMenu() => setState(() => _menuAbierto = !_menuAbierto);

  @override
  Widget build(BuildContext context) {
    final asyncLugar = ref.watch(lugarDetalleProvider(widget.lugarId));

    return asyncLugar.when(
      loading: () => Scaffold(
        backgroundColor: PaletaRutas.ink,
        appBar: AppBar(
          backgroundColor: PaletaRutas.ink,
          foregroundColor: PaletaRutas.piedra,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: PaletaRutas.oro),
        ),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: PaletaRutas.ink,
        appBar: AppBar(
          backgroundColor: PaletaRutas.ink,
          foregroundColor: PaletaRutas.piedra,
        ),
        body: Center(
          child: Text(
            'No se pudo cargar el lugar.',
            style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
          ),
        ),
      ),
      data: (lugar) {
        if (lugar == null) {
          return Scaffold(
            backgroundColor: PaletaRutas.ink,
            appBar: AppBar(
              backgroundColor: PaletaRutas.ink,
              foregroundColor: PaletaRutas.piedra,
            ),
            body: Center(
              child: Text(
                'Lugar no encontrado',
                style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
              ),
            ),
          );
        }
        return _construirDetalle(context, lugar);
      },
    );
  }

  Widget _construirDetalle(BuildContext context, ModeloLugar lugar) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final publicaciones = ref.watch(almacenFeedProvider).publicaciones;
    final metricas = MetricasComunidad.calcular(
      publicaciones,
      lugarId: lugar.id,
    );
    final desc = lugar.descripcion.trim().isEmpty
        ? CopyHaku.lugarSinDescripcion(lugar.provincia)
        : lugar.descripcion.trim();

    final ubicacionLinea = [
      if (lugar.provincia.isNotEmpty) lugar.provincia,
      if (lugar.distrito.isNotEmpty) lugar.distrito,
    ].join(' · ');

    final tematicas = lugar.tematicas.map((e) => e.nombre).toList();
    final actividades = lugar.actividades.map((e) => e.nombre).toList();
    final sinEtiquetas = tematicas.isEmpty && actividades.isEmpty;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: PaletaRutas.ink,
                foregroundColor: PaletaRutas.piedra,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      ImagenHaku(url: lugar.imagenUrl, fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x66141210),
                              Color(0x00141210),
                              Color(0xF2141210),
                            ],
                            stops: [0, 0.4, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lugar.nombre,
                              style: TipografiaHaku.titulo(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: PaletaRutas.piedra,
                                height: 1.05,
                              ),
                            ),
                            if (ubicacionLinea.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                ubicacionLinea,
                                style: TipografiaHaku.interfaz(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: PaletaRutas.plomoClaro,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 100 + bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!sinEtiquetas) ...[
                        if (tematicas.isNotEmpty) ...[
                          _TituloBloque('Qué es'),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final t in tematicas) _ChipClasificacion(t),
                            ],
                          ),
                          const SizedBox(height: 18),
                        ],
                        if (actividades.isNotEmpty) ...[
                          _TituloBloque('Qué hacer'),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final a in actividades)
                                _ChipClasificacion(a, suave: true),
                            ],
                          ),
                          const SizedBox(height: 18),
                        ],
                      ] else ...[
                        Text(
                          lugar.categoria.etiqueta,
                          style: TipografiaHaku.interfaz(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.oroSuave,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      FilaMetricasComunidad(
                        metricas: metricas,
                        calificacionCatalogo: lugar.calificacion,
                      ),
                      const SizedBox(height: 22),
                      _TituloBloque('Sobre este lugar'),
                      const SizedBox(height: 10),
                      Text(
                        desc,
                        style: TipografiaHaku.interfaz(
                          fontSize: 15,
                          height: 1.55,
                          color: PaletaRutas.piedra.withValues(alpha: 0.94),
                        ),
                      ),
                      if (lugar.acceso.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _TituloBloque('Cómo llegar'),
                        const SizedBox(height: 10),
                        _TarjetaInfo(
                          icono: Icons.directions_walk_rounded,
                          titulo: 'Acceso',
                          cuerpo: lugar.acceso,
                        ),
                      ],
                      if (lugar.distrito.isNotEmpty ||
                          lugar.provincia.isNotEmpty ||
                          lugar.altitud.isNotEmpty ||
                          lugar.distanciaKm > 0) ...[
                        const SizedBox(height: 24),
                        _TituloBloque('Dónde está'),
                        const SizedBox(height: 10),
                        if (lugar.provincia.isNotEmpty)
                          _FilaDato(
                            Icons.map_outlined,
                            'Provincia',
                            lugar.provincia,
                          ),
                        if (lugar.distrito.isNotEmpty)
                          _FilaDato(
                            Icons.place_outlined,
                            'Distrito',
                            lugar.distrito,
                          ),
                        if (lugar.altitud.isNotEmpty)
                          _FilaDato(
                            Icons.landscape_outlined,
                            'Altitud',
                            lugar.altitud,
                          ),
                        if (lugar.distanciaKm > 0)
                          _FilaDato(
                            Icons.near_me_outlined,
                            'Distancia',
                            '${lugar.distanciaKm.toStringAsFixed(0)} km',
                          ),
                      ],
                      RecuerdosComunidad(lugarId: lugar.id),
                      const SizedBox(height: 24),
                      _TituloBloque('Experiencias'),
                      const SizedBox(height: 6),
                      Text(
                        CopyHaku.seccionExperienciasSub,
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListaExperienciasLugar(lugarId: lugar.id),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: VeloAccionesFlotante(
              visible: _menuAbierto,
              onTap: () => setState(() => _menuAbierto = false),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 16 + bottom,
            child: MenuAccionesDetalle.lugar(
              lugar: lugar,
              abierto: _menuAbierto,
              onToggle: _toggleMenu,
              onCerrar: () => setState(() => _menuAbierto = false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TituloBloque extends StatelessWidget {
  const _TituloBloque(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TipografiaHaku.titulo(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: PaletaRutas.piedra,
      ),
    );
  }
}

class _ChipClasificacion extends StatelessWidget {
  const _ChipClasificacion(this.texto, {this.suave = false});

  final String texto;
  final bool suave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: suave
            ? PaletaRutas.ink.withValues(alpha: 0.55)
            : PaletaRutas.oro.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: suave
              ? PaletaRutas.plomo.withValues(alpha: 0.35)
              : PaletaRutas.oro.withValues(alpha: 0.55),
        ),
      ),
      child: Text(
        texto,
        style: TipografiaHaku.interfaz(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: suave ? PaletaRutas.plomoClaro : PaletaRutas.oro,
        ),
      ),
    );
  }
}

class _TarjetaInfo extends StatelessWidget {
  const _TarjetaInfo({
    required this.icono,
    required this.titulo,
    required this.cuerpo,
  });

  final IconData icono;
  final String titulo;
  final String cuerpo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: PaletaRutas.plomo.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: PaletaRutas.oro),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TipografiaHaku.interfaz(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.plomo,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cuerpo,
                  style: TipografiaHaku.interfaz(
                    fontSize: 14,
                    height: 1.4,
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

class _FilaDato extends StatelessWidget {
  const _FilaDato(this.icono, this.etiqueta, this.valor);

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icono, size: 18, color: PaletaRutas.oro),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              etiqueta,
              style: TipografiaHaku.interfaz(
                fontSize: 13,
                color: PaletaRutas.plomoClaro,
              ),
            ),
          ),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: TipografiaHaku.interfaz(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void abrirDetalleLugar(BuildContext context, String lugarId) {
  abrirPantallaHaku<void>(
    context,
    PantallaDetalleLugar(lugarId: lugarId),
  );
}
