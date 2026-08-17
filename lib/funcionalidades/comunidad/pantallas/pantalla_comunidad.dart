import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../inicio/pantallas/pantalla_crear_grupo_comunidad.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../dominio/modelo_comunidad.dart';
import '../widgets/chip_categoria_comunidad.dart';
import 'pantalla_detalle_comunidad.dart';
import 'pantalla_salidas.dart';

/// Comunidades existentes, clasificadas por categoría (N:N).
class PantallaComunidad extends ConsumerStatefulWidget {
  final bool mostrarAtras;

  const PantallaComunidad({super.key, this.mostrarAtras = false});

  @override
  ConsumerState<PantallaComunidad> createState() => _EstadoPantallaComunidad();
}

class _EstadoPantallaComunidad extends ConsumerState<PantallaComunidad> {
  CategoriaLugar? _filtro;
  bool _soloUnidas = false;
  bool _buscando = false;
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  List<ComunidadHaku> _filtrar(List<ComunidadHaku> todas, Set<String> unidas) {
    var lista = todas;
    if (_soloUnidas) {
      lista = lista.where((c) => unidas.contains(c.id)).toList();
    }
    if (_filtro != null) {
      lista = lista.where((c) => c.tieneCategoria(_filtro!)).toList();
    }
    final q = _busqueda.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      lista = lista
          .where(
            (c) =>
                c.nombre.toLowerCase().contains(q) ||
                c.descripcion.toLowerCase().contains(q) ||
                c.categorias.any((x) => x.etiqueta.toLowerCase().contains(q)),
          )
          .toList();
    }
    return lista;
  }

  Future<void> _crear() async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PantallaCrearComunidad()),
    );
  }

  Future<void> _abrir(ComunidadHaku c) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaDetalleComunidad(comunidadId: c.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom +
        (widget.mostrarAtras ? 24 : 110);
    final store = ref.watch(almacenFeedProvider);
    final visibles = _filtrar(store.comunidades, store.comunidadIds);
    final editorial = _filtro == null && !_buscando && !_soloUnidas;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FondoSuaveSeccion(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
                  child: Row(
                    children: [
                      if (widget.mostrarAtras)
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: PaletaRutas.marronOscuro,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          'Comunidad',
                          style: TipografiaHaku.titulo(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Buscar',
                        onPressed: () => setState(() {
                          _buscando = !_buscando;
                          if (!_buscando) _busqueda.clear();
                        }),
                        icon: Icon(
                          _buscando
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          color: PaletaRutas.marronOscuro,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Crear comunidad',
                        onPressed: _crear,
                        icon: const Icon(
                          Icons.group_add_outlined,
                          color: PaletaRutas.marronOscuro,
                        ),
                      ),
                      IconButton(
                        tooltip: _soloUnidas ? 'Ver todas' : 'Mis comunidades',
                        onPressed: () =>
                            setState(() => _soloUnidas = !_soloUnidas),
                        icon: Icon(
                          _soloUnidas
                              ? Icons.groups_rounded
                              : Icons.groups_outlined,
                          color: PaletaRutas.marronOscuro,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Salidas',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const PantallaSalidas(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.hiking,
                          color: PaletaRutas.marronOscuro,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: LineaEncabezadoInca(altura: 2),
                ),
              ),
              if (_buscando)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: TextField(
                      controller: _busqueda,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      style: TipografiaHaku.interfaz(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: 'Buscar comunidad o categoría…',
                        hintStyle: TipografiaHaku.interfaz(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                        ),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.82),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _ChipFiltro(
                        etiqueta: 'Todas',
                        seleccionado: _filtro == null,
                        onTap: () => setState(() => _filtro = null),
                      ),
                      const SizedBox(width: 8),
                      for (final cat in CategoriaLugar.values) ...[
                        ChipCategoriaComunidad(
                          categoria: cat,
                          seleccionado: _filtro == cat,
                          oscuro: true,
                          onTap: () => setState(() {
                            _filtro = _filtro == cat ? null : cat;
                          }),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (!store.listo)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (visibles.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                    child: Text(
                      _soloUnidas
                          ? 'Aún no te uniste a ninguna comunidad.'
                          : 'No hay comunidades en esta categoría.',
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.interfaz(
                        color: PaletaRutas.marronCuero,
                      ),
                    ),
                  ),
                )
              else if (editorial)
                ..._editorial(visibles, store.comunidadIds, bottom)
              else
                ..._listaFiltrada(visibles, store.comunidadIds, bottom),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _editorial(
    List<ComunidadHaku> visibles,
    Set<String> unidas,
    double bottom,
  ) {
    final ordenadas = [...visibles]
      ..sort((a, b) => b.miembros.compareTo(a.miembros));
    final destacada = ordenadas.first;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Text(
            'Encuentra con quién salir',
            style: TipografiaHaku.interfaz(
              fontSize: 13,
              color: PaletaRutas.marronCuero,
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
          child: _CardDestacada(
            comunidad: destacada,
            unida: unidas.contains(destacada.id),
            onTap: () => _abrir(destacada),
          ),
        ),
      ),
      for (final cat in CategoriaLugar.values)
        ..._carruselCategoria(
          cat,
          visibles.where((c) => c.tieneCategoria(cat)).toList(),
          unidas,
          cat == CategoriaLugar.values.last ? bottom : 18,
        ),
    ];
  }

  List<Widget> _carruselCategoria(
    CategoriaLugar cat,
    List<ComunidadHaku> items,
    Set<String> unidas,
    double bottom,
  ) {
    if (items.isEmpty) return const [];
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              Icon(
                iconoCategoriaComunidad(cat),
                size: 18,
                color: PaletaRutas.marronOscuro,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cat.etiqueta,
                  style: TipografiaHaku.titulo(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _filtro = cat),
                child: Text(
                  'Ver todas',
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.marronCuero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 212,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final c = items[i];
              return _CardCarrusel(
                comunidad: c,
                unida: unidas.contains(c.id),
                onTap: () => _abrir(c),
              );
            },
          ),
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: bottom)),
    ];
  }

  List<Widget> _listaFiltrada(
    List<ComunidadHaku> visibles,
    Set<String> unidas,
    double bottom,
  ) {
    return [
      if (_filtro != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              '${visibles.length} en ${_filtro!.etiqueta}',
              style: TipografiaHaku.interfaz(
                fontSize: 13,
                color: PaletaRutas.marronCuero,
              ),
            ),
          ),
        ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
        sliver: SliverList.separated(
          itemCount: visibles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final c = visibles[i];
            return _CardFilaOscura(
              comunidad: c,
              unida: unidas.contains(c.id),
              onTap: () => _abrir(c),
            );
          },
        ),
      ),
    ];
  }
}

class _ChipFiltro extends StatelessWidget {
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ChipFiltro({
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: seleccionado
          ? Colors.black.withValues(alpha: 0.92)
          : Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            etiqueta,
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardDestacada extends StatelessWidget {
  final ComunidadHaku comunidad;
  final bool unida;
  final VoidCallback onTap;

  const _CardDestacada({
    required this.comunidad,
    required this.unida,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 228,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: comunidad.imagenUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFF1A1A1A)),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x33000000),
                        Color(0xCC000000),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _EtiquetaOscura(
                            texto: unida ? 'Ya unida' : 'Destacada',
                          ),
                          const Spacer(),
                          Text(
                            '${comunidad.miembros} miembros',
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        comunidad.nombre,
                        style: TipografiaHaku.titulo(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comunidad.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.interfaz(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final cat in comunidad.categorias.take(3))
                            ChipCategoriaComunidad(
                              categoria: cat,
                              compacto: true,
                              sobreOscuro: true,
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
      ),
    );
  }
}

class _CardCarrusel extends StatelessWidget {
  final ComunidadHaku comunidad;
  final bool unida;
  final VoidCallback onTap;

  const _CardCarrusel({
    required this.comunidad,
    required this.unida,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 168,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: comunidad.imagenUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFF1A1A1A)),
                ),
                ColoredBox(color: Colors.black.withValues(alpha: 0.52)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (unida) const _EtiquetaOscura(texto: 'Unida'),
                      const Spacer(),
                      Text(
                        comunidad.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.titulo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${comunidad.miembros} · ${comunidad.provincia}',
                        style: TipografiaHaku.interfaz(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.75),
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

class _CardFilaOscura extends StatelessWidget {
  final ComunidadHaku comunidad;
  final bool unida;
  final VoidCallback onTap;

  const _CardFilaOscura({
    required this.comunidad,
    required this.unida,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: comunidad.imagenUrl,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: Color(0xFF333333),
                    child: SizedBox(width: 76, height: 76),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            comunidad.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaHaku.titulo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (unida)
                          Text(
                            'Unida',
                            style: TipografiaHaku.interfaz(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      comunidad.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${comunidad.miembros} miembros · ${comunidad.provincia}',
                      style: TipografiaHaku.interfaz(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
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

class _EtiquetaOscura extends StatelessWidget {
  final String texto;

  const _EtiquetaOscura({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        texto,
        style: TipografiaHaku.interfaz(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
