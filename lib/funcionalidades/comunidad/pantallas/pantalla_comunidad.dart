import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../inicio/dominio/modelos/provincia.dart';
import '../../inicio/pantallas/pantalla_crear_grupo_comunidad.dart';
import '../../inicio/pantallas/pantalla_mensajes_inicio.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/salidas_datasource_local.dart';
import '../dominio/modelo_comunidad.dart';
import '../util/provincia_comunidad.dart';
import '../widgets/mapa_comunidades_cusco.dart';
import 'pantalla_detalle_comunidad.dart';
import 'pantalla_salidas.dart';

/// Comunidades como agrupaciones sobre el mapa de Cusco.
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
        (widget.mostrarAtras ? 24 : 110);
    final store = ref.watch(almacenFeedProvider);
    final todas = store.comunidades;
    final visibles = _filtrar(todas, store.comunidadIds);
    final cargando = !store.listo && todas.isEmpty;
    final salidas = SalidasDataSourceLocal.instancia.todas().length;
    final enZona = _enProvincia(visibles, _provinciaId);
    final prov = _provinciaId != null ? provinciaPorId(_provinciaId!) : null;

    return Scaffold(
      backgroundColor: PaletaRutas.crema,
      body: FondoSuaveSeccion(
        opacidadImagen: 0.28,
        opacidadVelo: 0.35,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CabeceraMapaComunidad(
                mostrarAtras: widget.mostrarAtras,
                total: visibles.length,
                unidas: store.comunidadIds.length,
                salidas: salidas,
                soloUnidas: _soloUnidas,
                onToggleUnidas: () => setState(() => _soloUnidas = !_soloUnidas),
                onCrear: _crearGrupo,
                onSalidas: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PantallaSalidas(),
                    ),
                  );
                },
                onMensajes: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PantallaMensajesInicio(),
                    ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: LineaEncabezadoInca(altura: 2),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 5,
                child: cargando
                    ? const Center(child: CircularProgressIndicator())
                    : MapaComunidadesCusco(
                        comunidades: visibles,
                        unidas: store.comunidadIds,
                        provinciaSeleccionadaId: _provinciaId,
                        onProvincia: (id) => setState(() => _provinciaId = id),
                      ),
              ),
              Expanded(
                flex: 4,
                child: _PanelAgrupaciones(
                  provincia: prov,
                  comunidades: _provinciaId == null ? visibles : enZona,
                  unidas: store.comunidadIds,
                  bottom: bottom,
                  onLimpiarProvincia: () => setState(() => _provinciaId = null),
                  onAbrir: _abrir,
                  onCrear: _crearGrupo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CabeceraMapaComunidad extends StatelessWidget {
  const _CabeceraMapaComunidad({
    required this.mostrarAtras,
    required this.total,
    required this.unidas,
    required this.salidas,
    required this.soloUnidas,
    required this.onToggleUnidas,
    required this.onCrear,
    required this.onSalidas,
    required this.onMensajes,
  });

  final bool mostrarAtras;
  final int total;
  final int unidas;
  final int salidas;
  final bool soloUnidas;
  final VoidCallback onToggleUnidas;
  final VoidCallback onCrear;
  final VoidCallback onSalidas;
  final VoidCallback onMensajes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (mostrarAtras)
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: PaletaRutas.marronOscuro,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agrupaciones',
                      style: TipografiaHaku.titulo(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: PaletaRutas.marronOscuro,
                      ),
                    ),
                    Text(
                      'Comunidades distribuidas en el mapa de Cusco',
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: PaletaRutas.marronCuero,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Mensajes',
                onPressed: onMensajes,
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: PaletaRutas.marronOscuro,
                ),
              ),
              IconButton(
                tooltip: 'Salidas',
                onPressed: onSalidas,
                icon: const Icon(Icons.hiking, color: PaletaRutas.marronOscuro),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniStat(valor: '$total', label: 'Grupos'),
              const SizedBox(width: 8),
              _MiniStat(valor: '$unidas', label: 'Unidas'),
              const SizedBox(width: 8),
              _MiniStat(valor: '$salidas', label: 'Salidas'),
              const Spacer(),
              FilterChip(
                label: Text(
                  'Mis grupos',
                  style: TipografiaHaku.interfaz(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: soloUnidas ? Colors.white : PaletaRutas.marronOscuro,
                  ),
                ),
                selected: soloUnidas,
                onSelected: (_) => onToggleUnidas(),
                selectedColor: PaletaRutas.terracota,
                backgroundColor: PaletaRutas.crema,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: PaletaRutas.terracota.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: onCrear,
                style: FilledButton.styleFrom(
                  backgroundColor: PaletaRutas.terracota,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: Text(
                  'Crear',
                  style: TipografiaHaku.interfaz(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.valor, required this.label});

  final String valor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: PaletaRutas.pergamino.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PaletaRutas.terracota.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valor,
            style: TipografiaHaku.titulo(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: PaletaRutas.terracota,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TipografiaHaku.interfaz(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: PaletaRutas.marronCuero,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelAgrupaciones extends StatelessWidget {
  const _PanelAgrupaciones({
    required this.provincia,
    required this.comunidades,
    required this.unidas,
    required this.bottom,
    required this.onLimpiarProvincia,
    required this.onAbrir,
    required this.onCrear,
  });

  final Provincia? provincia;
  final List<ComunidadHaku> comunidades;
  final Set<String> unidas;
  final double bottom;
  final VoidCallback onLimpiarProvincia;
  final ValueChanged<ComunidadHaku> onAbrir;
  final VoidCallback onCrear;

  @override
  Widget build(BuildContext context) {
    final titulo = provincia != null
        ? '${provincia!.nombre} · ${comunidades.length} agrupaciones'
        : 'Todas las agrupaciones';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: PaletaRutas.marronOscuro.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: TipografiaHaku.titulo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (provincia != null)
                  TextButton(
                    onPressed: onLimpiarProvincia,
                    child: Text(
                      'Ver mapa completo',
                      style: TipografiaHaku.interfaz(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.crema,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: comunidades.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 40,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provincia != null
                                ? 'Sin agrupaciones en esta zona'
                                : 'Aún no hay agrupaciones visibles',
                            textAlign: TextAlign.center,
                            style: TipografiaHaku.interfaz(
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: onCrear,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: PaletaRutas.terracota),
                            ),
                            child: const Text('Crear agrupación'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 8),
                    itemCount: comunidades.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final c = comunidades[i];
                      return FilaAgrupacionComunidad(
                        comunidad: c,
                        unida: unidas.contains(c.id),
                        onTap: () => onAbrir(c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
