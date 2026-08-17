import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rutas/pantallas/pantalla_rutas.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../dominio/modelos/modelo_lugar.dart';
import '../proveedores/proveedor_lugares.dart';
import 'pantalla_detalle_lugar.dart';
import 'pantalla_registrar_lugar.dart';

/// Explora = biblioteca territorial (lista + filtros). Sorpréndeme sutil.
class PantallaExploraLugares extends ConsumerStatefulWidget {
  const PantallaExploraLugares({super.key});

  @override
  ConsumerState<PantallaExploraLugares> createState() =>
      _EstadoPantallaExploraLugares();
}

class _EstadoPantallaExploraLugares
    extends ConsumerState<PantallaExploraLugares> {
  bool _modoMapa = false;
  bool _soloPocoExplorados = false;
  CategoriaLugar? _filtroCat;

  static TextStyle get _ui => TipografiaHaku.interfaz(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1A1A1A),
      );

  void _sorprendeme() {
    final ds = ref.read(lugaresDataSourceProvider);
    final intereses = ref.read(interesesUsuarioProvider);
    final l = ds.sorpresa(intereses: intereses);
    abrirDetalleLugar(context, l.id);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(lugaresVersionProvider);
    var lugares = ref.watch(lugaresListaProvider);
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

    final bottom = MediaQuery.paddingOf(context).bottom + 110;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FondoSuaveSeccion(
        child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Explora',
                      style: TipografiaHaku.titulo(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Registrar lugar',
                    onPressed: () => abrirRegistrarLugarFlow(context, ref),
                    icon: Icon(
                      Icons.add_location_alt_outlined,
                      size: 22,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sorpréndeme',
                    onPressed: _sorprendeme,
                    icon: Icon(
                      Icons.auto_awesome_outlined,
                      size: 22,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PantallaRutas(),
                        ),
                      );
                    },
                    child: Text(
                      'Rutas',
                      style: _ui.copyWith(
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.verdeBosque,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  _Segmento(
                    label: 'Lista',
                    selected: !_modoMapa,
                    onTap: () => setState(() => _modoMapa = false),
                  ),
                  const SizedBox(width: 8),
                  _Segmento(
                    label: 'Mapa',
                    selected: _modoMapa,
                    onTap: () => setState(() => _modoMapa = true),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('Poco explorados', style: _ui.copyWith(fontSize: 12)),
                      selected: _soloPocoExplorados,
                      onSelected: (v) =>
                          setState(() => _soloPocoExplorados = v),
                      selectedColor: PaletaRutas.terracota.withValues(alpha: 0.2),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  ...CategoriaLugar.values.take(6).map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c.etiqueta, style: _ui.copyWith(fontSize: 12)),
                        selected: _filtroCat == c,
                        onSelected: (v) => setState(
                          () => _filtroCat = v ? c : null,
                        ),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE8E8E8)),
            Expanded(
              child: _modoMapa
                  ? _MapaSimple(
                      lugares: lugares,
                      onTap: (id) => abrirDetalleLugar(context, id),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
                      itemCount: lugares.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final l = lugares[i];
                        return _TileLugar(
                          lugar: l,
                          onTap: () => abrirDetalleLugar(context, l.id),
                        );
                      },
                    ),
            ),
          ],
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
      color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F2),
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
              color: selected ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
        ),
      ),
    );
  }
}

class _TileLugar extends StatelessWidget {
  const _TileLugar({required this.lugar, required this.onTap});
  final ModeloLugar lugar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F7F7),
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
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: lugar.imagenUrl.startsWith('assets/')
                      ? Image.asset(lugar.imagenUrl, fit: BoxFit.cover)
                      : CachedNetworkImage(
                          imageUrl: lugar.imagenUrl,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lugar.nombre,
                      style: TipografiaHaku.interfaz(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lugar.provincia} · ${lugar.nivelExploracion.etiqueta}',
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: const Color(0xFF6B6B6B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9A9A9A)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapaSimple extends StatelessWidget {
  const _MapaSimple({required this.lugares, required this.onTap});
  final List<ModeloLugar> lugares;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFF0F0F0)),
        ...List.generate(lugares.length.clamp(0, 8), (i) {
          final l = lugares[i];
          final left = 40.0 + (i % 4) * 70.0;
          final top = 80.0 + (i ~/ 4) * 120.0 + (i % 3) * 30.0;
          return Positioned(
            left: left,
            top: top,
            child: GestureDetector(
              onTap: () => onTap(l.id),
              child: Column(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 36,
                    color: l.nivelExploracion == NivelExploracion.pocoExplorado ||
                            l.nivelExploracion == NivelExploracion.nuevoEnHaku
                        ? PaletaRutas.terracota
                        : PaletaRutas.verdeBosque,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      l.nombre,
                      style: TipografiaHaku.interfaz(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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
  }
}
