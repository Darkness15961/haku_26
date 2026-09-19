import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../comunidad/widgets/tarjeta_publicacion_remota.dart';
import '../../lugares/pantallas/pantalla_detalle_lugar.dart';
import '../../rutas/pantallas/pantalla_detalle_ruta.dart';
import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../proveedores/proveedores_guardados_remotos.dart';

/// Guardados reales: rutas + publicaciones.
class PantallaFavoritos extends ConsumerWidget {
  const PantallaFavoritos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!supabaseListo) {
      return const Scaffold(
        backgroundColor: PaletaRutas.ink,
        body: Center(
          child: Text(
            'Se requiere conexión',
            style: TextStyle(color: PaletaRutas.plomoClaro),
          ),
        ),
      );
    }

    final rutasAsync = ref.watch(rutasGuardadasRemotasProvider);
    final lugaresAsync = ref.watch(lugaresGuardadosRemotosProvider);
    final pubsAsync = ref.watch(publicacionesGuardadasRemotasProvider);

    final rutas = rutasAsync.valueOrNull ?? [];
    final lugares = lugaresAsync.valueOrNull ?? [];
    final posts = pubsAsync.valueOrNull ?? [];

    final bool estaCargando =
        rutasAsync.isLoading || lugaresAsync.isLoading || pubsAsync.isLoading;
    final bottomPad = MediaQuery.paddingOf(context).bottom + 24;
    final vacio = rutas.isEmpty && lugares.isEmpty && posts.isEmpty && !estaCargando;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Guardados',
                      style: TipografiaHaku.titulo(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LineaEncabezadoInca(altura: 2),
            ),
            Expanded(
              child: vacio
                  ? ListView(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad),
                      children: [
                        Text(
                          'Todavía no hay nada',
                          textAlign: TextAlign.center,
                          style: TipografiaHaku.titulo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                        const SizedBox(height: 16),
                        BotonPrimarioRuta(
                          texto: 'Explorar',
                          icono: Icons.map_outlined,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    )
                  : estaCargando && vacio
                      ? const Center(
                          child: CircularProgressIndicator(color: PaletaRutas.oro),
                        )
                      : ListView(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                      children: [
                        if (lugares.isNotEmpty) ...[
                          Text(
                            'Lugares',
                            style: TipografiaHaku.titulo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final l in lugares) ...[
                            _TileRuta(
                              titulo: l.nombre,
                              imagen: l.imagenUrl,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        PantallaDetalleLugar(lugarId: l.id),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 12),
                        ],
                        if (rutas.isNotEmpty) ...[
                          Text(
                            'Rutas',
                            style: TipografiaHaku.titulo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final r in rutas) ...[
                            _TileRuta(
                              titulo: r.titulo,
                              imagen: r.imagenUrl,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        PantallaDetalleRuta(ruta: r),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 12),
                        ],
                        if (posts.isNotEmpty) ...[
                          Text(
                            'Publicaciones',
                            style: TipografiaHaku.titulo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (var i = 0; i < posts.length; i++) ...[
                            TarjetaPublicacionRemota(
                              publicacion: posts[i],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileRuta extends StatelessWidget {
  final String titulo;
  final String? imagen;
  final VoidCallback? onTap;

  const _TileRuta({
    required this.titulo,
    this.imagen,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PaletaRutas.carbon,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imagen == null
                    ? Container(
                        width: 64,
                        height: 64,
                        color: PaletaRutas.plomoOscuro,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.route_outlined,
                          color: PaletaRutas.plomoClaro,
                        ),
                      )
                    : ImagenHaku(
                        url: imagen!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TipografiaHaku.titulo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                onTap == null
                    ? Icons.info_outline_rounded
                    : Icons.chevron_right,
                color: PaletaRutas.plomo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


