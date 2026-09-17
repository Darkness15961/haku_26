import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/navegacion/abrir_pantalla_haku.dart';
import '../../../nucleo/responsive/espacio_haku.dart';
import '../../../nucleo/responsive/rejilla_lego_haku.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../lugares/widgets/metricas_comunidad.dart';
import '../dominio/modelos/modelo_ruta.dart';
import '../pantallas/pantalla_detalle_ruta.dart';
import '../proveedores/proveedor_rutas.dart';
import 'estilos_rutas.dart';
import 'tarjeta_ruta.dart';
import 'tarjeta_ruta_lego.dart';

/// Listado de rutas por categoría — Lego en landscape, lista en portrait.
class ListaRutasExplora extends ConsumerStatefulWidget {
  const ListaRutasExplora({super.key, this.bottomPadding = 110});

  final double bottomPadding;

  @override
  ConsumerState<ListaRutasExplora> createState() => _EstadoListaRutasExplora();
}

class _EstadoListaRutasExplora extends ConsumerState<ListaRutasExplora>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _etiquetas = ['Recomendadas', 'Cultura', 'Naturaleza'];

  static const _categorias = [
    CategoriaRuta.recomendadas,
    CategoriaRuta.cultura,
    CategoriaRuta.naturaleza,
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _etiquetas.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _abrirDetalle(ModeloRuta ruta) {
    abrirPantallaHaku<void>(context, PantallaDetalleRuta(ruta: ruta));
  }

  @override
  Widget build(BuildContext context) {
    final indiceRutas = MetricasComunidad.indiceRutas(
      ref.watch(almacenFeedProvider).publicaciones,
    );
    final rutasAsync = ref.watch(rutasPublicadasProvider);
    final catalogo = rutasAsync.valueOrNull ?? const <ModeloRuta>[];
    final cols = RejillaLegoHaku.columnas(context);

    List<ModeloRuta> rutasDe(CategoriaRuta categoria) {
      if (categoria == CategoriaRuta.recomendadas) return catalogo;
      return catalogo
          .where((ruta) => ruta.categoria == categoria)
          .toList(growable: false);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: TipografiaHaku.interfaz(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: TipografiaHaku.interfaz(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
          labelColor: PaletaRutas.piedra,
          unselectedLabelColor: PaletaRutas.plomo,
          indicatorColor: PaletaRutas.oro,
          indicatorWeight: 2.5,
          dividerColor: PaletaRutas.plomoOscuro.withValues(alpha: 0.65),
          tabs: List.generate(_etiquetas.length, (i) {
            final n = rutasDe(_categorias[i]).length;
            return Tab(text: '${_etiquetas[i]} ($n)');
          }),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: _categorias.map((categoria) {
              if (rutasAsync.isLoading && !rutasAsync.hasValue) {
                return const Center(
                  child: CircularProgressIndicator(color: PaletaRutas.oro),
                );
              }
              if (rutasAsync.hasError && !rutasAsync.hasValue) {
                return _ErrorRutas(
                  onReintentar: () => ref.invalidate(rutasPublicadasProvider),
                );
              }
              final rutas = MetricasComunidad.enriquecerRutas(
                rutasDe(categoria),
                indiceRutas,
              );
              if (rutas.isEmpty) {
                final principal = categoria == CategoriaRuta.recomendadas;
                return _EmptyRutas(
                  titulo: principal
                      ? 'Aún no hay rutas publicadas'
                      : 'Todavía no hay rutas aquí',
                  textoBoton: principal ? null : 'Ver todas',
                  onExplorar: principal ? null : () => _tabs.animateTo(0),
                );
              }
              return RejillaLegoHaku.grid(
                context: context,
                itemCount: rutas.length,
                bottomPadding: widget.bottomPadding,
                itemBuilder: (context, index) {
                  final ruta = rutas[index];
                  if (cols > 1) {
                    return TarjetaRutaLego(
                      ruta: ruta,
                      indice: index,
                      onTap: () => _abrirDetalle(ruta),
                    );
                  }
                  return TarjetaRuta(
                    ruta: ruta,
                    indice: index,
                    compacta: EspacioHaku.esHorizontal(context),
                    onTap: () => _abrirDetalle(ruta),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ErrorRutas extends StatelessWidget {
  const _ErrorRutas({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: PaletaRutas.plomo,
            ),
            const SizedBox(height: 14),
            Text(
              'No pudimos cargar las rutas',
              textAlign: TextAlign.center,
              style: TipografiaHaku.titulo(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onReintentar,
              child: Text(
                'Reintentar',
                style: TipografiaHaku.interfaz(
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.oro,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRutas extends StatelessWidget {
  const _EmptyRutas({
    required this.titulo,
    required this.onExplorar,
    required this.textoBoton,
  });

  final String titulo;
  final VoidCallback? onExplorar;
  final String? textoBoton;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 40,
              color: PaletaRutas.plomo.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 14),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TipografiaHaku.titulo(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
              ),
            ),
            if (onExplorar != null && textoBoton != null) ...[
              const SizedBox(height: 18),
              TextButton(
                onPressed: onExplorar,
                style: TextButton.styleFrom(foregroundColor: PaletaRutas.oro),
                child: Text(
                  textoBoton!,
                  style: TipografiaHaku.interfaz(
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.oro,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
