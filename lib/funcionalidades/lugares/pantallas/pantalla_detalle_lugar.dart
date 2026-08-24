import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../comunidad/pantallas/pantalla_salidas.dart';
import '../../publicaciones/pantallas/pantalla_publicaciones.dart';
import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../dominio/modelos/modelo_lugar.dart';
import '../proveedores/proveedor_lugares.dart';

class PantallaDetalleLugar extends ConsumerWidget {
  const PantallaDetalleLugar({super.key, required this.lugarId});

  final String lugarId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lugar = ref.watch(lugaresDataSourceProvider).porId(lugarId);
    if (lugar == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Lugar no encontrado')),
      );
    }

    final bottom = MediaQuery.paddingOf(context).bottom;
    final img = lugar.imagenUrl.startsWith('assets/')
        ? null
        : lugar.imagenUrl;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FondoSuaveSeccion(
        child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: PaletaRutas.marronOscuro,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: img == null
                  ? Image.asset(lugar.imagenUrl, fit: BoxFit.cover)
                  : CachedNetworkImage(imageUrl: img, fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 32 + bottom + 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    lugar.nombre,
                    textAlign: TextAlign.center,
                    style: TipografiaHaku.titulo(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const LineaEncabezadoInca(altura: 2),
                  const SizedBox(height: 10),
                  Text(
                    '${lugar.categoria.etiqueta} · ${lugar.provincia}'
                    '${lugar.distrito.isEmpty ? '' : ' / ${lugar.distrito}'}',
                    textAlign: TextAlign.center,
                    style: TipografiaHaku.interfaz(
                      color: PaletaRutas.marronCuero,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 18, color: PaletaRutas.terracota),
                      const SizedBox(width: 4),
                      Text(
                        lugar.calificacion.toStringAsFixed(1),
                        style: TipografiaHaku.interfaz(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${lugar.exploradores}',
                        style: TipografiaHaku.interfaz(
                          fontSize: 13,
                          color: PaletaRutas.marronCuero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: PaletaRutas.pergamino,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: PaletaRutas.beigeEnvejecido),
                      ),
                      child: Text(
                        lugar.nivelExploracion.etiqueta,
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.verdeBosque,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _Caja(
                    titulo: 'Descripción',
                    hijo: Text(
                      lugar.descripcion,
                      style: TipografiaHaku.interfaz(height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Datos',
                    style: TipografiaHaku.titulo(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ChipDato(Icons.trending_up, lugar.dificultad),
                      if (lugar.tiempoEstimado.isNotEmpty)
                        _ChipDato(Icons.timer_outlined, lugar.tiempoEstimado),
                      if (lugar.altitud.isNotEmpty)
                        _ChipDato(Icons.landscape_outlined, lugar.altitud),
                      if (lugar.acceso.isNotEmpty)
                        _ChipDato(Icons.directions_walk, lugar.acceso),
                      _ChipDato(
                        Icons.photo_camera_outlined,
                        '${lugar.fotos} fotos',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Salidas',
                    style: TipografiaHaku.titulo(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PantallaSalidas(lugarId: lugar.id),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PaletaRutas.marronOscuro,
                      side: const BorderSide(color: PaletaRutas.marronCuero),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Ver salidas',
                      style: TipografiaHaku.interfaz(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 24),
                  BotonPrimarioRuta(
                    texto: 'Publicar',
                    icono: Icons.add_a_photo_outlined,
                    onPressed: () async {
                      final ok = await asegurarSesion(context, ref);
                      if (!ok || !context.mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PantallaPublicaciones(
                            rutaId: lugar.id,
                            rutaTitulo: lugar.nombre,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  BotonSecundarioRuta(
                    texto: 'Ver salidas',
                    icono: Icons.groups_outlined,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PantallaSalidas(lugarId: lugar.id),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _Caja extends StatelessWidget {
  const _Caja({required this.titulo, required this.hijo});
  final String titulo;
  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletaRutas.crema.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PaletaRutas.beigeEnvejecido),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TipografiaHaku.titulo(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          hijo,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletaRutas.beigeEnvejecido),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: PaletaRutas.verdeBosque),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Abre detalle de lugar por id.
void abrirDetalleLugar(BuildContext context, String lugarId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PantallaDetalleLugar(lugarId: lugarId),
    ),
  );
}
