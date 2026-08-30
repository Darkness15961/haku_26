import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/lista_rutas_explora.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../dominio/modelos/modelo_lugar.dart';
import '../proveedores/proveedor_explora_ui.dart';
import '../proveedores/proveedor_lugares.dart';
import '../widgets/mapa_explora_lugares.dart';
import 'pantalla_detalle_lugar.dart';
import 'pantalla_registrar_lugar.dart';
import 'pantalla_sorpresa_lugar.dart';

/// Explora — mapa de huecos + lugares con portadas grandes.
class PantallaExploraLugares extends ConsumerStatefulWidget {
  const PantallaExploraLugares({super.key});

  @override
  ConsumerState<PantallaExploraLugares> createState() =>
      _EstadoPantallaExploraLugares();
}

class _EstadoPantallaExploraLugares
    extends ConsumerState<PantallaExploraLugares> {
  bool _soloPocoExplorados = true;
  CategoriaLugar? _filtroCat;

  void _sorprendeme() {
    final ds = ref.read(lugaresDataSourceProvider);
    final intereses = ref.read(interesesUsuarioProvider);
    final l = ds.sorpresa(intereses: intereses);
    abrirSorpresaLugar(context, l.id);
  }

  List<ModeloLugar> _filtrar(List<ModeloLugar> todos) {
    var lugares = todos;
    if (_soloPocoExplorados) {
      lugares = lugares
          .where(
            (l) =>
                l.nivelExploracion == NivelExploracion.pocoExplorado ||
                l.nivelExploracion == NivelExploracion.nuevoEnHaku,
          )
          .toList();
    }
    if (_filtroCat != null) {
      lugares = lugares.where((l) => l.categoria == _filtroCat).toList();
    }
    return lugares;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(lugaresVersionProvider);
    final modo = ref.watch(modoExploraProvider);
    final todos = ref.watch(lugaresListaProvider);
    final lugares = _filtrar(todos);
    final bottom = MediaQuery.paddingOf(context).bottom + 110;
    final destacado = lugares.isNotEmpty ? lugares.first : null;
    final huecos = todos
        .where(
          (l) =>
              l.nivelExploracion == NivelExploracion.pocoExplorado ||
              l.nivelExploracion == NivelExploracion.nuevoEnHaku,
        )
        .length;
    final recientes = todos
        .where(
          (l) =>
              l.nivelExploracion == NivelExploracion.nuevoEnHaku ||
              l.creadoPorUsuario,
        )
        .take(6)
        .toList();
    final totalFotos = todos.fold<int>(0, (s, l) => s + l.fotos);

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: FondoSuaveSeccion(
        color: PaletaRutas.ink,
        opacidadImagen: 0,
        opacidadVelo: 0,
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeroExplora(
                  huecos: huecos,
                  totalLugares: todos.length,
                  totalFotos: totalFotos,
                  onSorpresa: _sorprendeme,
                  onRegistrar: () => abrirRegistrarLugarFlow(context, ref),
                  onRutas: () => ref.read(modoExploraProvider.notifier).state =
                      ModoExplora.rutas,
                ),
              ),
              if (modo == ModoExplora.lugares && recientes.isNotEmpty)
                SliverToBoxAdapter(
                  child: _CarruselRecientes(
                    lugares: recientes,
                    onTap: (id) => abrirDetalleLugar(context, id),
                  ),
                ),
              if (modo == ModoExplora.lugares && destacado != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _TarjetaDestacadaLugar(
                      lugar: destacado,
                      onTap: () => abrirDetalleLugar(context, destacado.id),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      _Segmento(
                        label: 'Mapa',
                        selected: modo == ModoExplora.mapa,
                        onTap: () => ref
                            .read(modoExploraProvider.notifier)
                            .state = ModoExplora.mapa,
                      ),
                      const SizedBox(width: 8),
                      _Segmento(
                        label: 'Lugares',
                        selected: modo == ModoExplora.lugares,
                        onTap: () => ref
                            .read(modoExploraProvider.notifier)
                            .state = ModoExplora.lugares,
                      ),
                      const SizedBox(width: 8),
                      _Segmento(
                        label: 'Rutas',
                        selected: modo == ModoExplora.rutas,
                        onTap: () => ref
                            .read(modoExploraProvider.notifier)
                            .state = ModoExplora.rutas,
                      ),
                      if (modo != ModoExplora.rutas) ...[
                        const Spacer(),
                        Flexible(
                          child: _ChipFiltro(
                            label: 'Poco explorado',
                            selected: _soloPocoExplorados,
                            onTap: () => setState(
                              () => _soloPocoExplorados = !_soloPocoExplorados,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (modo != ModoExplora.rutas)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final c in CategoriaLugar.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _ChipFiltro(
                              label: c.etiqueta,
                              selected: _filtroCat == c,
                              onTap: () => setState(
                                () => _filtroCat = _filtroCat == c ? null : c,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (modo == ModoExplora.rutas)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ListaRutasExplora(bottomPadding: bottom),
                )
              else if (modo == ModoExplora.mapa)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.52,
                        child: Column(
                          children: [
                            Expanded(
                              child: MapaExploraLugares(
                                lugares: lugares,
                                onTap: (id) => abrirDetalleLugar(context, id),
                              ),
                            ),
                            _LeyendaMapa(),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else if (lugares.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_location_alt_outlined,
                          size: 48,
                          color: PaletaRutas.plomo.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aún no hay lugares aquí',
                          style: TipografiaHaku.titulo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () =>
                              abrirRegistrarLugarFlow(context, ref),
                          style: FilledButton.styleFrom(
                            backgroundColor: PaletaRutas.oro,
                            foregroundColor: PaletaRutas.ink,
                          ),
                          child: Text(
                            'Agregar lugar',
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
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final l = lugares[i];
                        final grande = i % 5 == 0;
                        return _CeldaLugar(
                          lugar: l,
                          indice: i,
                          grande: grande,
                          onTap: () => abrirDetalleLugar(context, l.id),
                        );
                      },
                      childCount: lugares.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroExplora extends StatelessWidget {
  const _HeroExplora({
    required this.huecos,
    required this.totalLugares,
    required this.totalFotos,
    required this.onSorpresa,
    required this.onRegistrar,
    required this.onRutas,
  });

  final int huecos;
  final int totalLugares;
  final int totalFotos;
  final VoidCallback onSorpresa;
  final VoidCallback onRegistrar;
  final VoidCallback onRutas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 188,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'public/image/fondo_explora.jpg',
                fit: BoxFit.cover,
              ),
              // Velo oscuro para legibilidad del texto blanco
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xCC141210),
                      Color(0xE6141210),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/iconos/sol_inca.svg',
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(
                            PaletaRutas.oro,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Explora',
                          style: TipografiaHaku.titulo(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Encuentra lugares en el mapa',
                      style: TipografiaHaku.interfaz(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: PaletaRutas.plomoClaro,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$huecos por explorar · $totalLugares lugares · $totalFotos fotos',
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PaletaRutas.plomoClaro,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: onSorpresa,
                            style: FilledButton.styleFrom(
                              backgroundColor: PaletaRutas.oro,
                              foregroundColor: PaletaRutas.ink,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Sorpréndeme',
                              style: TipografiaHaku.interfaz(
                                fontWeight: FontWeight.w800,
                                color: PaletaRutas.ink,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _BotonIconoHero(
                          icono: Icons.add_location_alt_outlined,
                          tooltip: 'Agregar lugar',
                          onTap: onRegistrar,
                        ),
                        const SizedBox(width: 8),
                        _BotonIconoHero(
                          icono: Icons.route_outlined,
                          tooltip: 'Itinerarios',
                          onTap: onRutas,
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
    );
  }
}

class _BotonIconoHero extends StatelessWidget {
  const _BotonIconoHero({
    required this.icono,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PaletaRutas.oro.withValues(alpha: 0.55)),
            ),
            child: Icon(icono, color: PaletaRutas.oro, size: 22),
          ),
        ),
      ),
    );
  }
}

class _CarruselRecientes extends StatelessWidget {
  const _CarruselRecientes({
    required this.lugares,
    required this.onTap,
  });

  final List<ModeloLugar> lugares;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              'Recién en HAKU',
              style: TipografiaHaku.titulo(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: PaletaRutas.piedra,
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: lugares.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final l = lugares[i];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(l.id),
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      width: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: PaletaRutas.ink.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            l.imagenUrl.startsWith('assets/')
                                ? Image.asset(l.imagenUrl, fit: BoxFit.cover)
                                : CachedNetworkImage(
                                    imageUrl: l.imagenUrl,
                                    fit: BoxFit.cover,
                                  ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    PaletaRutas.ink.withValues(alpha: 0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: PaletaRutas.oro,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'NUEVO',
                                      style: TipografiaHaku.interfaz(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: PaletaRutas.ink,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    l.nombre,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TipografiaHaku.titulo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: PaletaRutas.piedra,
                                    ),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LeyendaMapa extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: PaletaRutas.carbon,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _punto(PaletaRutas.oro, 'Por explorar'),
          const SizedBox(width: 20),
          _punto(PaletaRutas.plomoClaro, 'Con fotos'),
        ],
      ),
    );
  }

  Widget _punto(Color c, String t) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            t,
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: PaletaRutas.piedra,
            ),
          ),
        ],
      );
}

class _TarjetaDestacadaLugar extends StatelessWidget {
  const _TarjetaDestacadaLugar({
    required this.lugar,
    required this.onTap,
  });

  final ModeloLugar lugar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final img = lugar.imagenUrl.startsWith('assets/')
        ? Image.asset(lugar.imagenUrl, fit: BoxFit.cover)
        : CachedNetworkImage(imageUrl: lugar.imagenUrl, fit: BoxFit.cover);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: PaletaRutas.ink.withValues(alpha: 0.14),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      img,
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              PaletaRutas.ink.withValues(alpha: 0.65),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        bottom: 12,
                        child: Container(
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
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: PaletaRutas.ink,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: PaletaRutas.carbon,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lugar.nivelExploracion.etiqueta,
                        style: TipografiaHaku.interfaz(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.oro,
                        ),
                      ),
                      Text(
                        lugar.nombre,
                        style: TipografiaHaku.titulo(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      Text(
                        '${lugar.categoria.etiqueta} · ${lugar.provincia}',
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const LineaEncabezadoInca(altura: 2),
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

class _CeldaLugar extends StatelessWidget {
  const _CeldaLugar({
    required this.lugar,
    required this.indice,
    required this.onTap,
    this.grande = false,
  });

  final ModeloLugar lugar;
  final int indice;
  final VoidCallback onTap;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final alto = indice.isEven || grande;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: PaletaRutas.ink.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                lugar.imagenUrl.startsWith('assets/')
                    ? Image.asset(lugar.imagenUrl, fit: BoxFit.cover)
                    : CachedNetworkImage(
                        imageUrl: lugar.imagenUrl,
                        fit: BoxFit.cover,
                      ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: alto ? Alignment.topCenter : Alignment.center,
                      colors: [
                        PaletaRutas.ink.withValues(alpha: 0.78),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: PaletaRutas.oro.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          lugar.categoria.etiqueta,
                          style: TipografiaHaku.interfaz(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: PaletaRutas.ink,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        lugar.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.titulo(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      Text(
                        '${lugar.fotos} fotos · ${lugar.exploradores} exploradores',
                        style: TipografiaHaku.interfaz(
                          fontSize: 10,
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
      ),
    );
  }
}

class _Segmento extends StatelessWidget {
  const _Segmento({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? PaletaRutas.oro : PaletaRutas.carbon,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? null
                : Border.all(color: PaletaRutas.plomoOscuro),
          ),
          child: Text(
            label,
            style: TipografiaHaku.interfaz(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? PaletaRutas.ink : PaletaRutas.piedra,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? PaletaRutas.oro : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? PaletaRutas.oro
                  : PaletaRutas.plomo.withValues(alpha: 0.7),
            ),
          ),
          child: Text(
            label,
            softWrap: false,
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? PaletaRutas.ink : PaletaRutas.piedra,
            ),
          ),
        ),
      ),
    );
  }
}
