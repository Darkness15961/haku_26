import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../nucleo/recursos/copy_haku.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/lista_rutas_explora.dart';
import '../datos/provincias_datasource_local.dart';
import '../dominio/modelos/modelo_lugar.dart';
import '../proveedores/proveedor_lugares.dart';
import '../widgets/mapa_islas_provincias.dart';
import '../widgets/metricas_comunidad.dart';
import 'pantalla_detalle_lugar.dart';
import 'pantalla_registrar_lugar.dart';
import 'pantalla_sorpresa_lugar.dart';

/// Explora — carrusel de islas primero; acciones abajo (simulación local).
class PantallaExploraLugares extends ConsumerStatefulWidget {
  const PantallaExploraLugares({super.key});

  @override
  ConsumerState<PantallaExploraLugares> createState() =>
      _EstadoPantallaExploraLugares();
}

class _EstadoPantallaExploraLugares
    extends ConsumerState<PantallaExploraLugares> {
  String? _ultimaSorpresaId;
  String? _provinciaVisible;

  void _sorprendeme() {
    final ds = ref.read(lugaresDataSourceProvider);
    final intereses = ref.read(interesesUsuarioProvider);
    final l = ds.sorpresa(
      intereses: intereses,
      evitarId: _ultimaSorpresaId,
      preferirProvincia: _provinciaVisible,
    );
    _ultimaSorpresaId = l.id;
    abrirSorpresaLugar(context, l.id);
  }

  void _abrirRutas() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: PaletaRutas.ink,
          appBar: AppBar(
            backgroundColor: PaletaRutas.ink,
            foregroundColor: PaletaRutas.piedra,
            title: Text(
              'Rutas',
              style: TipografiaHaku.titulo(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: PaletaRutas.piedra,
              ),
            ),
          ),
          body: ListaRutasExplora(
            bottomPadding: MediaQuery.paddingOf(context).bottom + 24,
          ),
        ),
      ),
    );
  }

  Future<void> _registrar({String? provincia}) async {
    await abrirRegistrarLugarFlow(context, ref, provincia: provincia);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(lugaresVersionProvider);
    final todos = ref.watch(lugaresListaProvider);
    final bottom = MediaQuery.paddingOf(context).bottom + 100;
    final huecos = todos
        .where(
          (l) =>
              l.nivelExploracion == NivelExploracion.pocoExplorado ||
              l.nivelExploracion == NivelExploracion.nuevoEnHaku,
        )
        .length;
    final publicaciones = ref.watch(almacenFeedProvider).publicaciones;
    final indice = MetricasComunidad.indiceLugares(publicaciones);
    final totalFotos = indice.totalFotos();
    final fotosHero = MetricasComunidad.etiquetaFotos(totalFotos);
    final nProvinciasConLugar = ProvinciasDataSourceLocal.construirIslas(todos)
        .where((i) => i.lugares.isNotEmpty)
        .length;
    final statsHero = [
      '$nProvinciasConLugar / ${ProvinciasDataSourceLocal.todas.length} provincias',
      CopyHaku.huecosSinNombre(huecos),
      CopyHaku.lugaresEnMapa(todos.length),
      if (fotosHero.isNotEmpty) fotosHero,
    ].join(' · ');

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: FondoSuaveSeccion(
        color: PaletaRutas.ink,
        opacidadImagen: 0,
        opacidadVelo: 0,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    SvgPicture.asset(
                      'assets/iconos/sol_inca.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        PaletaRutas.oro,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Explora',
                      style: TipografiaHaku.titulo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Rutas',
                      onPressed: _abrirRutas,
                      icon: const Icon(
                        Icons.route_rounded,
                        color: PaletaRutas.oro,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: MapaIslasProvincias(
                    lugares: todos,
                    fotosPorLugar: indice.fotos,
                    onTapLugar: (id) => abrirDetalleLugar(context, id),
                    onRegistrarEnProvincia: (prov) =>
                        _registrar(provincia: prov),
                    onProvinciaVisible: (nombre) {
                      if (_provinciaVisible != nombre) {
                        setState(() => _provinciaVisible = nombre);
                      }
                    },
                    altura: MediaQuery.sizeOf(context).height * 0.42,
                  ),
                ),
              ),
              _PanelInferiorIslas(
                statsResumen: statsHero,
                bottomPad: bottom,
                onSorpresa: _sorprendeme,
                onRegistrar: () => _registrar(provincia: _provinciaVisible),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelInferiorIslas extends StatelessWidget {
  const _PanelInferiorIslas({
    required this.statsResumen,
    required this.bottomPad,
    required this.onSorpresa,
    required this.onRegistrar,
  });

  final String statsResumen;
  final double bottomPad;
  final VoidCallback onSorpresa;
  final VoidCallback onRegistrar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad.clamp(16, 120)),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(
          color: PaletaRutas.plomo.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CopyHaku.islasTitulo,
            style: TipografiaHaku.titulo(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: PaletaRutas.piedra,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CopyHaku.islasSubtitulo,
            style: TipografiaHaku.interfaz(
              fontSize: 13,
              color: PaletaRutas.plomoClaro,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            statsResumen,
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              color: PaletaRutas.plomo,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onSorpresa,
                  style: FilledButton.styleFrom(
                    backgroundColor: PaletaRutas.oro,
                    foregroundColor: PaletaRutas.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Sorpréndeme',
                    style: TipografiaHaku.interfaz(
                      fontWeight: FontWeight.w800,
                      color: PaletaRutas.ink,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: PaletaRutas.ink,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: onRegistrar,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: PaletaRutas.oro.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Icon(
                      Icons.add_location_alt_outlined,
                      color: PaletaRutas.oro,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
