import 'package:flutter/material.dart';

import '../datos/rutas_datasource_local.dart';
import '../dominio/modelos/modelo_ruta.dart';
import '../widgets/estilos_rutas.dart';
import '../widgets/fondo_suave_seccion.dart';
import '../widgets/linea_encabezado_inca.dart';
import '../widgets/logo_haku_encabezado.dart';
import '../widgets/tarjeta_ruta.dart';
import 'pantalla_detalle_ruta.dart';

/// Lista de rutas con pestañas Recomendadas / Populares / Naturaleza.
class PantallaRutas extends StatefulWidget {
  const PantallaRutas({super.key});

  @override
  State<PantallaRutas> createState() => _EstadoPantallaRutas();
}

class _EstadoPantallaRutas extends State<PantallaRutas>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _etiquetas = [
    'RECOMENDADAS',
    'POPULARES',
    'NATURALEZA',
  ];

  static const _categorias = [
    CategoriaRuta.recomendadas,
    CategoriaRuta.populares,
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
    final bottomPad = MediaQuery.paddingOf(context).bottom + 110;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Column(
                  children: [
                    const LogoHakuEncabezado(height: 64),
                    const SizedBox(height: 4),
                    Text(
                      'Rutas',
                      style: TipografiaHaku.titulo(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explora nuevos territorios',
                      style: TipografiaHaku.interfaz(
                        fontSize: 13,
                        color: PaletaRutas.marronCuero,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const LineaEncabezadoInca(altura: 2),
                  ],
                ),
              ),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                labelStyle: TipografiaHaku.interfaz(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
                unselectedLabelStyle: TipografiaHaku.interfaz(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
                labelColor: PaletaRutas.marronCuero,
                unselectedLabelColor:
                    PaletaRutas.marronOscuro.withValues(alpha: 0.45),
                indicatorColor: PaletaRutas.marronCuero,
                indicatorWeight: 2.5,
                dividerColor: PaletaRutas.beigeEnvejecido.withValues(alpha: 0.5),
                tabs: _etiquetas.map((e) => Tab(text: e)).toList(),
              ),
              Expanded(
                child: FondoSuaveSeccion(
                  child: TabBarView(
                    controller: _tabs,
                    children: _categorias.map((categoria) {
                      final rutas =
                          RutasDataSourceLocal.obtenerPorCategoria(categoria);
                      if (rutas.isEmpty) {
                        return Center(
                          child: Text(
                            'Pronto más rutas aquí',
                            style: TipografiaHaku.interfaz(
                              color: PaletaRutas.marronCuero,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
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
              ),
            ],
          ),
      ),
    );
  }
}
