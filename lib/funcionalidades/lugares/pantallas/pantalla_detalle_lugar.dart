import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/widgets/boton_icono_accion.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelos/modelo_lugar.dart';
import '../proveedores/proveedor_lugares.dart';
import '../widgets/lista_experiencias_lugar.dart';
import '../widgets/menu_acciones_lugar.dart';

/// Ficha de lugar — Conoce más (Descubre / Explora).
class PantallaDetalleLugar extends ConsumerStatefulWidget {
  const PantallaDetalleLugar({super.key, required this.lugarId});

  final String lugarId;

  @override
  ConsumerState<PantallaDetalleLugar> createState() =>
      _EstadoPantallaDetalleLugar();
}

class _EstadoPantallaDetalleLugar extends ConsumerState<PantallaDetalleLugar> {
  bool _menuAbierto = false;

  @override
  Widget build(BuildContext context) {
    final lugar = ref.watch(lugaresDataSourceProvider).porId(widget.lugarId);    if (lugar == null) {
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

    final bottom = MediaQuery.paddingOf(context).bottom;
    final desc = lugar.descripcion.trim().isEmpty
        ? 'Un rincón de ${lugar.provincia} por descubrir con calma.'
        : lugar.descripcion.trim();

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [          SliverAppBar(
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
                            lugar.nivelExploracion.etiqueta.toUpperCase(),
                            style: TipografiaHaku.interfaz(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: PaletaRutas.ink,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          lugar.nombre,
                          style: TipografiaHaku.titulo(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: PaletaRutas.piedra,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${lugar.categoria.etiqueta} · ${lugar.provincia}'
                          '${lugar.distrito.isEmpty ? '' : ' / ${lugar.distrito}'}',
                          style: TipografiaHaku.interfaz(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PaletaRutas.plomoClaro,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 100 + bottom),              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: PaletaRutas.oro,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lugar.calificacion.toStringAsFixed(1),
                        style: TipografiaHaku.interfaz(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        Icons.people_outline,
                        size: 18,
                        color: PaletaRutas.plomoClaro,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${lugar.exploradores} exploradores',
                        style: TipografiaHaku.interfaz(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${lugar.fotos} fotos',
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.oroSuave,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Sobre este lugar',
                    style: TipografiaHaku.titulo(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    style: TipografiaHaku.interfaz(
                      fontSize: 14,
                      height: 1.5,
                      color: PaletaRutas.piedra.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Datos del camino',
                    style: TipografiaHaku.titulo(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ChipDato(Icons.trending_up, lugar.dificultad),
                      if (lugar.tiempoEstimado.isNotEmpty)
                        _ChipDato(
                          Icons.timer_outlined,
                          lugar.tiempoEstimado,
                        ),
                      if (lugar.altitud.isNotEmpty)
                        _ChipDato(
                          Icons.landscape_outlined,
                          lugar.altitud,
                        ),
                      if (lugar.acceso.isNotEmpty)
                        _ChipDato(Icons.directions_walk, lugar.acceso),
                      if (lugar.distanciaKm > 0)
                        _ChipDato(
                          Icons.near_me_outlined,
                          '${lugar.distanciaKm.toStringAsFixed(0)} km',
                        ),
                    ],
                  ),
                  if (lugar.galeria.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Text(
                      'Galería',
                      style: TipografiaHaku.titulo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: lugar.galeria.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ImagenHaku(
                              url: lugar.galeria[i],
                              width: 120,
                              height: 96,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text(
                    'Experiencias',
                    style: TipografiaHaku.titulo(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lo que compartieron exploradores solos o en grupo',
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
            child: MenuAccionesLugar(
              lugar: lugar,
              abierto: _menuAbierto,
              onToggle: () => setState(() => _menuAbierto = !_menuAbierto),
              onCerrar: () => setState(() => _menuAbierto = false),
            ),
          ),
        ],
      ),
    );
  }
}
class _ChipDato extends StatelessWidget {
  const _ChipDato(this.icono, this.texto);
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletaRutas.plomoOscuro),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 15, color: PaletaRutas.oro),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: PaletaRutas.piedra,
            ),
          ),
        ],
      ),
    );
  }
}

void abrirDetalleLugar(BuildContext context, String lugarId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PantallaDetalleLugar(lugarId: lugarId),
    ),
  );
}
