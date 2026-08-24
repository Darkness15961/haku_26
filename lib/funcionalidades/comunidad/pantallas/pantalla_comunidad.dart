import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../inicio/datos/feed_inicio_datasource_local.dart';
import '../../inicio/pantallas/pantalla_crear_grupo_comunidad.dart';
import '../../inicio/pantallas/pantalla_mensajes_inicio.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../inicio/widgets/publicacion_estilo_threads.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/salidas_datasource_local.dart';
import '../dominio/modelo_comunidad.dart';
import '../util/provincia_comunidad.dart';
import '../widgets/mapa_comunidades_cusco.dart';
import 'pantalla_detalle_comunidad.dart';
import 'pantalla_salidas.dart';

/// Comunidad: feed crudo (publicaciones) + mapa / grupos.
class PantallaComunidad extends ConsumerStatefulWidget {
  final bool mostrarAtras;

  const PantallaComunidad({super.key, this.mostrarAtras = false});

  @override
  ConsumerState<PantallaComunidad> createState() => _EstadoPantallaComunidad();
}

class _EstadoPantallaComunidad extends ConsumerState<PantallaComunidad> {
  String? _provinciaId;
  bool _soloUnidas = false;

  List<ComunidadHaku> _filtrar(List<ComunidadHaku> todas, Set<String> unidas) {
    if (!_soloUnidas) return todas;
    return todas.where((c) => unidas.contains(c.id)).toList();
  }

  Future<void> _crearGrupo() async {
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

  List<ComunidadHaku> _enProvincia(
    List<ComunidadHaku> todas,
    String? provinciaId,
  ) {
    if (provinciaId == null) return todas;
    return todas
        .where((c) => provinciaIdDeNombre(c.provincia) == provinciaId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom +
        (widget.mostrarAtras ? 24 : 88);
    final store = ref.watch(almacenFeedProvider);
    final todas = store.comunidades;
    final visibles = _filtrar(todas, store.comunidadIds);
    final cargando = !store.listo && todas.isEmpty;
    final salidas = SalidasDataSourceLocal.instancia.todas().length;
    final enZona = _enProvincia(visibles, _provinciaId);
    final prov = _provinciaId != null ? provinciaPorId(_provinciaId!) : null;
    final publicaciones = store.listo
        ? store.publicaciones
        : FeedInicioDataSourceLocal.publicaciones;
    final listaComunidades = _provinciaId == null ? visibles : enZona;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
                child: Row(
                  children: [
                    if (widget.mostrarAtras)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comunidad',
                            style: TipografiaHaku.titulo(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                          Text(
                            'Publicaciones y grupos en Cusco',
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: PaletaRutas.plomoClaro,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Mensajes',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PantallaMensajesInicio(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: PaletaRutas.piedra,
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
                        color: PaletaRutas.piedra,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _ChipStat(valor: '${publicaciones.length}', label: 'Posts'),
                    const SizedBox(width: 8),
                    _ChipStat(valor: '${visibles.length}', label: 'Grupos'),
                    const SizedBox(width: 8),
                    _ChipStat(valor: '$salidas', label: 'Salidas'),
                    const Spacer(),
                    TextButton(
                      onPressed: _crearGrupo,
                      child: Text(
                        'Crear',
                        style: TipografiaHaku.interfaz(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.oro,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: Row(
                  children: [
                    Text(
                      'Publicaciones',
                      style: TipografiaHaku.titulo(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(width: 18, height: 2, color: PaletaRutas.oro),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: PublicacionEstiloThreads(
                      publicacion: publicaciones[i],
                      indice: i,
                    ),
                  );
                },
                childCount: publicaciones.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Text(
                      'En el mapa',
                      style: TipografiaHaku.titulo(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const Spacer(),
                    FilterChip(
                      label: Text(
                        'Mías',
                        style: TipografiaHaku.interfaz(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _soloUnidas
                              ? PaletaRutas.ink
                              : PaletaRutas.piedra,
                        ),
                      ),
                      selected: _soloUnidas,
                      onSelected: (_) =>
                          setState(() => _soloUnidas = !_soloUnidas),
                      selectedColor: PaletaRutas.oro,
                      backgroundColor: PaletaRutas.carbon,
                      checkmarkColor: PaletaRutas.ink,
                      side: BorderSide(
                        color: PaletaRutas.plomoOscuro.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: cargando
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: PaletaRutas.oro,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: MapaComunidadesCusco(
                            comunidades: visibles,
                            unidas: store.comunidadIds,
                            provinciaSeleccionadaId: _provinciaId,
                            onProvincia: (id) =>
                                setState(() => _provinciaId = id),
                          ),
                        ),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        prov != null
                            ? '${prov.nombre} · ${listaComunidades.length}'
                            : 'Todas las comunidades',
                        style: TipografiaHaku.interfaz(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ),
                    if (_provinciaId != null)
                      TextButton(
                        onPressed: () => setState(() => _provinciaId = null),
                        child: Text(
                          'Ver todo',
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            color: PaletaRutas.oroSuave,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (listaComunidades.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, bottom),
                  child: Text(
                    'Todavía no hay comunidades aquí',
                    textAlign: TextAlign.center,
                    style: TipografiaHaku.interfaz(
                      color: PaletaRutas.plomoClaro,
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final c = listaComunidades[i];
                    final esUltima = i == listaComunidades.length - 1;
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        esUltima ? bottom : 8,
                      ),
                      child: _FilaComunidadDark(
                        comunidad: c,
                        unida: store.comunidadIds.contains(c.id),
                        onTap: () => _abrir(c),
                      ),
                    );
                  },
                  childCount: listaComunidades.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChipStat extends StatelessWidget {
  const _ChipStat({required this.valor, required this.label});

  final String valor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PaletaRutas.plomoOscuro.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valor,
            style: TipografiaHaku.titulo(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: PaletaRutas.oro,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TipografiaHaku.interfaz(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: PaletaRutas.plomoClaro,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaComunidadDark extends StatelessWidget {
  const _FilaComunidadDark({
    required this.comunidad,
    required this.unida,
    required this.onTap,
  });

  final ComunidadHaku comunidad;
  final bool unida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PaletaRutas.carbon,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comunidad.nombre,
                      style: TipografiaHaku.interfaz(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comunidad.provincia,
                      style: TipografiaHaku.interfaz(
                        fontSize: 11,
                        color: PaletaRutas.plomoClaro,
                      ),
                    ),
                  ],
                ),
              ),
              if (unida)
                Text(
                  'Unida',
                  style: TipografiaHaku.interfaz(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.oro,
                  ),
                ),
              const Icon(
                Icons.chevron_right_rounded,
                color: PaletaRutas.plomo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
