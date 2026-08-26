import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/widgets/imagen_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../publicaciones/pantallas/pantalla_publicaciones.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelos/modelo_lugar.dart';
import '../proveedores/proveedor_lugares.dart';
import '../widgets/boton_ver_salidas_lugar.dart';

/// Frase épica según el destino (destino / oportunidad / llamado).
String mensajeDestinoSorpresa(ModeloLugar lugar) {
  final c = lugar.categoria;
  final n = lugar.nivelExploracion;
  final nombre = lugar.nombre;

  if (n == NivelExploracion.nuevoEnHaku ||
      n == NivelExploracion.pocoExplorado) {
    return 'Pocos han cruzado este umbral. Hoy $nombre te espera en silencio.';
  }

  switch (c) {
    case CategoriaLugar.misterioso:
    case CategoriaLugar.magico:
      return 'Hay secretos que el Cusco solo entrega a quien se atreve. Este es el tuyo.';
    case CategoriaLugar.naturaleza:
      return 'Los apus abrieron un sendero. $nombre late ahora frente a ti.';
    case CategoriaLugar.aventura:
    case CategoriaLugar.caminata:
      return 'El camino eligió tu nombre. La oportunidad se llama $nombre.';
    case CategoriaLugar.fotografia:
      return 'La luz de este instante no se repite. Captúrala en $nombre.';
    case CategoriaLugar.gastronomia:
      return 'Hay mesas que saben a destino. Hoy te invita $nombre.';
    case CategoriaLugar.cultura:
      return 'La piedra recuerda. Hoy te llama desde $nombre.';
  }
}

String subtituloDestino(ModeloLugar lugar) {
  switch (lugar.categoria) {
    case CategoriaLugar.misterioso:
    case CategoriaLugar.magico:
      return 'Un llamado que no llega dos veces';
    case CategoriaLugar.naturaleza:
      return 'Cuando el paisaje te elige';
    case CategoriaLugar.aventura:
    case CategoriaLugar.caminata:
      return 'Tu próxima huella empieza aquí';
    case CategoriaLugar.fotografia:
      return 'Una ventana que se abre ahora';
    case CategoriaLugar.gastronomia:
      return 'Sabor que marca el viaje';
    case CategoriaLugar.cultura:
      return 'Memoria viva del valle';
  }
}

/// Revelación de Sorpréndeme — destino épico + ficha limpia.
class PantallaSorpresaLugar extends ConsumerWidget {
  const PantallaSorpresaLugar({super.key, required this.lugarId});

  final String lugarId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lugar = ref.watch(lugaresDataSourceProvider).porId(lugarId);
    if (lugar == null) {
      return Scaffold(
        backgroundColor: PaletaRutas.ink,
        appBar: AppBar(
          backgroundColor: PaletaRutas.ink,
          foregroundColor: PaletaRutas.piedra,
        ),
        body: Center(
          child: Text(
            'Destino no encontrado',
            style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
          ),
        ),
      );
    }

    final bottom = MediaQuery.paddingOf(context).bottom;
    final frase = mensajeDestinoSorpresa(lugar);
    final eco = subtituloDestino(lugar);

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
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
                        stops: [0, 0.35, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 28,
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
                            'DESTINO',
                            style: TipografiaHaku.interfaz(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: PaletaRutas.ink,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          lugar.nombre,
                          style: TipografiaHaku.titulo(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: PaletaRutas.piedra,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          eco,
                          style: TipografiaHaku.interfaz(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PaletaRutas.oroSuave,
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
              padding: EdgeInsets.fromLTRB(20, 8, 20, 28 + bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: PaletaRutas.carbon,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: PaletaRutas.oro.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: PaletaRutas.oro.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'El llamado',
                              style: TipografiaHaku.interfaz(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: PaletaRutas.oro,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          frase,
                          style: TipografiaHaku.titulo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '${lugar.categoria.etiqueta} · ${lugar.provincia}'
                    '${lugar.distrito.isEmpty ? '' : ' / ${lugar.distrito}'}',
                    style: TipografiaHaku.interfaz(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: PaletaRutas.plomoClaro,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: PaletaRutas.oro,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lugar.calificacion.toStringAsFixed(1),
                        style: TipografiaHaku.interfaz(
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: PaletaRutas.carbon,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: PaletaRutas.plomoOscuro,
                          ),
                        ),
                        child: Text(
                          lugar.nivelExploracion.etiqueta,
                          style: TipografiaHaku.interfaz(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.oroSuave,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    lugar.descripcion,
                    style: TipografiaHaku.interfaz(
                      fontSize: 14,
                      height: 1.45,
                      color: PaletaRutas.piedra.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ChipOscuro(Icons.trending_up, lugar.dificultad),
                      if (lugar.tiempoEstimado.isNotEmpty)
                        _ChipOscuro(
                          Icons.timer_outlined,
                          lugar.tiempoEstimado,
                        ),
                      if (lugar.altitud.isNotEmpty)
                        _ChipOscuro(
                          Icons.landscape_outlined,
                          lugar.altitud,
                        ),
                      if (lugar.acceso.isNotEmpty)
                        _ChipOscuro(Icons.directions_walk, lugar.acceso),
                    ],
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
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
                    style: FilledButton.styleFrom(
                      backgroundColor: PaletaRutas.oro,
                      foregroundColor: PaletaRutas.ink,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      'Documentar este destino',
                      style: TipografiaHaku.interfaz(
                        fontWeight: FontWeight.w800,
                        color: PaletaRutas.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  BotonVerSalidasLugar(
                    lugarId: lugar.id,
                    lugarNombre: lugar.nombre,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      final ds = ref.read(lugaresDataSourceProvider);
                      final intereses = ref.read(interesesUsuarioProvider);
                      final otro = ds.sorpresa(intereses: intereses);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              PantallaSorpresaLugar(lugarId: otro.id),
                        ),
                      );
                    },
                    child: Text(
                      'Otro destino',
                      style: TipografiaHaku.interfaz(
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.oro,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipOscuro extends StatelessWidget {
  const _ChipOscuro(this.icono, this.texto);
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
              fontWeight: FontWeight.w600,
              color: PaletaRutas.piedra,
            ),
          ),
        ],
      ),
    );
  }
}

void abrirSorpresaLugar(BuildContext context, String lugarId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PantallaSorpresaLugar(lugarId: lugarId),
    ),
  );
}
