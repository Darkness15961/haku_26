import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../rutas/pantallas/pantalla_rutas.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../dominio/modelos/modelo_lugar.dart';
import '../proveedores/proveedor_lugares.dart';
import 'pantalla_detalle_lugar.dart';
import 'pantalla_registrar_lugar.dart';

/// Explora — mapa de huecos + lugares con portadas grandes.
class PantallaExploraLugares extends ConsumerStatefulWidget {
  const PantallaExploraLugares({super.key});

  @override
  ConsumerState<PantallaExploraLugares> createState() =>
      _EstadoPantallaExploraLugares();
}

class _EstadoPantallaExploraLugares
    extends ConsumerState<PantallaExploraLugares> {
  bool _modoMapa = false;
  bool _soloPocoExplorados = true;
  CategoriaLugar? _filtroCat;

  void _sorprendeme() {
    final ds = ref.read(lugaresDataSourceProvider);
    final intereses = ref.read(interesesUsuarioProvider);
    final l = ds.sorpresa(intereses: intereses);
    abrirDetalleLugar(context, l.id);
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
      backgroundColor: Colors.white,
      body: FondoSuaveSeccion(
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
                  onRutas: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PantallaRutas(),
                      ),
                    );
                  },
                ),
              ),
              if (recientes.isNotEmpty && !_modoMapa)
                SliverToBoxAdapter(
                  child: _CarruselRecientes(
                    lugares: recientes,
                    onTap: (id) => abrirDetalleLugar(context, id),
                  ),
                ),
              if (destacado != null && !_modoMapa)
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Row(
                    children: [
                      _Segmento(
                        label: 'Mosaico',
                        selected: !_modoMapa,
                        onTap: () => setState(() => _modoMapa = false),
                      ),
                      const SizedBox(width: 8),
                      _Segmento(
                        label: 'Mapa',
                        selected: _modoMapa,
                        onTap: () => setState(() => _modoMapa = true),
                      ),
                      const Spacer(),
                      FilterChip(
                        label: Text(
                          'Poco',
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        selected: _soloPocoExplorados,
                        onSelected: (v) =>
                            setState(() => _soloPocoExplorados = v),
                        selectedColor:
                            PaletaRutas.terracota.withValues(alpha: 0.25),
                        checkmarkColor: PaletaRutas.marronOscuro,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final c in CategoriaLugar.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              c.etiqueta,
                              style: TipografiaHaku.interfaz(fontSize: 12),
                            ),
                            selected: _filtroCat == c,
                            onSelected: (v) => setState(
                              () => _filtroCat = v ? c : null,
                            ),
                            selectedColor:
                                PaletaRutas.marronOscuro.withValues(alpha: 0.88),
                            labelStyle: TextStyle(
                              color: _filtroCat == c
                                  ? Colors.white
                                  : PaletaRutas.marronOscuro,
                              fontWeight: FontWeight.w700,
                            ),
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (_modoMapa)
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
                              child: _MapaExplora(
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
                          color: PaletaRutas.marronCuero.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hueco en el mapa',
                          style: TipografiaHaku.titulo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () =>
                              abrirRegistrarLugarFlow(context, ref),
                          style: FilledButton.styleFrom(
                            backgroundColor: PaletaRutas.terracota,
                          ),
                          child: const Text('Registrar lugar'),
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
        child: Stack(
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.asset(
                'public/image/fondo_explora.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      PaletaRutas.marronOscuro.withValues(alpha: 0.55),
                      PaletaRutas.terracota.withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/iconos/sol_inca.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Explora',
                        style: TipografiaHaku.titulo(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$huecos huecos · $totalLugares lugares · $totalFotos fotos',
                    style: TipografiaHaku.interfaz(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: onSorpresa,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: PaletaRutas.marronOscuro,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Sorpréndeme',
                            style: TipografiaHaku.interfaz(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: onRegistrar,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.22),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add_location_alt_outlined),
                        tooltip: 'Registrar',
                      ),
                      IconButton(
                        onPressed: onRutas,
                        icon: const Icon(Icons.route_outlined, color: Colors.white),
                        tooltip: 'Cultura',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
                            color: Colors.black.withValues(alpha: 0.12),
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
                                    Colors.black.withValues(alpha: 0.7),
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
                                      color: PaletaRutas.terracota,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'NUEVO',
                                      style: TipografiaHaku.interfaz(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
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
                                      color: Colors.white,
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
      color: PaletaRutas.crema,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _punto(PaletaRutas.terracota, 'Hueco'),
          const SizedBox(width: 16),
          _punto(PaletaRutas.marronOscuro, 'Documentado'),
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
              fontSize: 11,
              fontWeight: FontWeight.w700,
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
                color: Colors.black.withValues(alpha: 0.14),
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
                              Colors.black.withValues(alpha: 0.65),
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
                            color: PaletaRutas.terracota,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            lugar.nivelExploracion.etiqueta.toUpperCase(),
                            style: TipografiaHaku.interfaz(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: PaletaRutas.crema,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Por documentar',
                        style: TipografiaHaku.interfaz(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.terracota,
                        ),
                      ),
                      Text(
                        lugar.nombre,
                        style: TipografiaHaku.titulo(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${lugar.categoria.etiqueta} · ${lugar.provincia}',
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          color: PaletaRutas.marronCuero,
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
                color: Colors.black.withValues(alpha: 0.1),
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
                        Colors.black.withValues(alpha: 0.78),
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
                          color: PaletaRutas.terracota.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          lugar.categoria.etiqueta,
                          style: TipografiaHaku.interfaz(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${lugar.fotos} fotos · ${lugar.exploradores} gente',
                        style: TipografiaHaku.interfaz(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.88),
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
      color: selected ? PaletaRutas.marronOscuro : PaletaRutas.crema,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TipografiaHaku.interfaz(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : PaletaRutas.marronOscuro,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapaExplora extends StatelessWidget {
  const _MapaExplora({required this.lugares, required this.onTap});
  final List<ModeloLugar> lugares;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (lugares.isEmpty) {
      return ColoredBox(
        color: PaletaRutas.pergamino,
        child: Center(
          child: Text(
            'Sin lugares',
            style: TipografiaHaku.interfaz(color: PaletaRutas.marronCuero),
          ),
        ),
      );
    }
    final lats = lugares.map((l) => l.latitud);
    final lngs = lugares.map((l) => l.longitud);
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);
    final dLat = (maxLat - minLat).abs() < 0.0001 ? 0.08 : (maxLat - minLat);
    final dLng = (maxLng - minLng).abs() < 0.0001 ? 0.08 : (maxLng - minLng);

    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'public/image/laberinto_explora.webp',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.35),
            ),
            ColoredBox(color: PaletaRutas.pergamino.withValues(alpha: 0.55)),
            ...lugares.map((l) {
              final nx = ((l.longitud - minLng) / dLng).clamp(0.0, 1.0);
              final ny = (1 - (l.latitud - minLat) / dLat).clamp(0.0, 1.0);
              final hueco =
                  l.nivelExploracion == NivelExploracion.pocoExplorado ||
                      l.nivelExploracion == NivelExploracion.nuevoEnHaku;
              return Positioned(
                left: 20 + nx * (w - 100),
                top: 20 + ny * (h - 100),
                child: GestureDetector(
                  onTap: () => onTap(l.id),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: hueco
                              ? PaletaRutas.terracota
                              : PaletaRutas.marronOscuro,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: PaletaRutas.terracota.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          l.nombre,
                          style: TipografiaHaku.interfaz(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: PaletaRutas.marronOscuro,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
