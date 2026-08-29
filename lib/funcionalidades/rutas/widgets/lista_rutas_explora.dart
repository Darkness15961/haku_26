import 'package:flutter/material.dart';

import '../datos/rutas_datasource_local.dart';
import '../dominio/modelos/modelo_ruta.dart';
import '../pantallas/pantalla_detalle_ruta.dart';
import 'estilos_rutas.dart';
import 'tarjeta_ruta.dart';

/// Listado de rutas por categoría — embebido en Explora.
class ListaRutasExplora extends StatefulWidget {
  const ListaRutasExplora({super.key, this.bottomPadding = 110});

  final double bottomPadding;

  @override
  State<ListaRutasExplora> createState() => _EstadoListaRutasExplora();
}

class _EstadoListaRutasExplora extends State<ListaRutasExplora>
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaDetalleRuta(ruta: ruta),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
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
            final n = RutasDataSourceLocal.obtenerPorCategoria(
              _categorias[i],
            ).length;
            return Tab(text: '${_etiquetas[i]} ($n)');
          }),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: _categorias.map((categoria) {
              final rutas = RutasDataSourceLocal.obtenerPorCategoria(categoria);
              if (rutas.isEmpty) {
                return _EmptyRutas(onExplorar: () => _tabs.animateTo(0));
              }
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(16, 16, 16, widget.bottomPadding),
                itemCount: rutas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ruta = rutas[index];
                  return TarjetaRuta(
                    ruta: ruta,
                    indice: index,
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

class _EmptyRutas extends StatelessWidget {
  const _EmptyRutas({required this.onExplorar});

  final VoidCallback onExplorar;

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
              'Todavía no hay rutas aquí',
              textAlign: TextAlign.center,
              style: TipografiaHaku.titulo(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: onExplorar,
              style: TextButton.styleFrom(foregroundColor: PaletaRutas.oro),
              child: Text(
                'Ver recomendadas',
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
