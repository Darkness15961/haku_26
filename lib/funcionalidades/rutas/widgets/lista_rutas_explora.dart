import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/navegacion/abrir_pantalla_haku.dart';
import '../../../nucleo/responsive/espacio_haku.dart';
import '../../../nucleo/responsive/rejilla_lego_haku.dart';
import '../dominio/modelos/modelo_ruta.dart';
import '../pantallas/pantalla_detalle_ruta.dart';
import '../proveedores/proveedor_rutas.dart';
import 'estilos_rutas.dart';
import 'tarjeta_ruta.dart';
import 'tarjeta_ruta_lego.dart';

enum _EjeFiltroRuta { enfoque, tipo, nivel }

/// Listado publico de rutas con filtros pensados para decidir rapido.
class ListaRutasExplora extends ConsumerStatefulWidget {
  const ListaRutasExplora({super.key, this.bottomPadding = 110});

  final double bottomPadding;

  @override
  ConsumerState<ListaRutasExplora> createState() => _EstadoListaRutasExplora();
}

class _EstadoListaRutasExplora extends ConsumerState<ListaRutasExplora> {
  _EjeFiltroRuta _eje = _EjeFiltroRuta.enfoque;
  String? _enfoque;
  String? _tipo;
  String? _nivel;
  String? _zona;

  bool get _hayFiltro =>
      _enfoque != null || _tipo != null || _nivel != null || _zona != null;

  void _limpiarFiltros() {
    setState(() {
      _enfoque = null;
      _tipo = null;
      _nivel = null;
      _zona = null;
    });
  }

  void _abrirDetalle(ModeloRuta ruta) {
    abrirPantallaHaku<void>(context, PantallaDetalleRuta(ruta: ruta));
  }

  @override
  Widget build(BuildContext context) {
    final rutasAsync = ref.watch(rutasPublicadasProvider);
    final catalogo = rutasAsync.valueOrNull ?? const <ModeloRuta>[];
    final cols = RejillaLegoHaku.columnas(context);

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
    if (catalogo.isEmpty) {
      return const _EmptyRutas(
        titulo: 'Aun no hay rutas publicadas',
        textoBoton: null,
        onExplorar: null,
      );
    }

    final enfoques = _valores(catalogo.map(_enfoqueDe));
    final tipos = _valores(catalogo.map(_tipoDe));
    final niveles = _valores(catalogo.map(_nivelDe));
    final zonas = _valores(catalogo.map((r) => r.provincia.trim()));
    final filtradas = catalogo.where(_pasaFiltros).toList(growable: false);
    final chips = switch (_eje) {
      _EjeFiltroRuta.enfoque => enfoques,
      _EjeFiltroRuta.tipo => tipos,
      _EjeFiltroRuta.nivel => niveles,
    };
    final activo = switch (_eje) {
      _EjeFiltroRuta.enfoque => _enfoque,
      _EjeFiltroRuta.tipo => _tipo,
      _EjeFiltroRuta.nivel => _nivel,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${filtradas.length} de ${catalogo.length} rutas',
                style: TipografiaHaku.interfaz(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.plomoClaro,
                ),
              ),
              const SizedBox(height: 10),
              _SegmentoFiltroRuta(
                activo: _eje,
                onChanged: (eje) => setState(() => _eje = eje),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ChipFiltroRuta(
                    texto: 'Todos',
                    activo: activo == null,
                    onTap: () {
                      setState(() {
                        switch (_eje) {
                          case _EjeFiltroRuta.enfoque:
                            _enfoque = null;
                            break;
                          case _EjeFiltroRuta.tipo:
                            _tipo = null;
                            break;
                          case _EjeFiltroRuta.nivel:
                            _nivel = null;
                            break;
                        }
                      });
                    },
                  ),
                  ...chips.map(
                    (valor) => _ChipFiltroRuta(
                      texto: valor,
                      activo: activo == valor,
                      onTap: () {
                        setState(() {
                          switch (_eje) {
                            case _EjeFiltroRuta.enfoque:
                              _enfoque = _enfoque == valor ? null : valor;
                              break;
                            case _EjeFiltroRuta.tipo:
                              _tipo = _tipo == valor ? null : valor;
                              break;
                            case _EjeFiltroRuta.nivel:
                              _nivel = _nivel == valor ? null : valor;
                              break;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (zonas.length > 1) ...[
                const SizedBox(height: 12),
                Text(
                  'Zona',
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChipFiltroRuta(
                      texto: 'Todas',
                      activo: _zona == null,
                      onTap: () => setState(() => _zona = null),
                    ),
                    ...zonas.map(
                      (zona) => _ChipFiltroRuta(
                        texto: zona,
                        activo: _zona == zona,
                        onTap: () => setState(
                          () => _zona = _zona == zona ? null : zona,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_hayFiltro) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _limpiarFiltros,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                  label: const Text('Quitar filtros'),
                  style: TextButton.styleFrom(
                    foregroundColor: PaletaRutas.oro,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: filtradas.isEmpty
              ? _EmptyRutas(
                  titulo: 'No hay rutas con esos filtros',
                  textoBoton: 'Quitar filtros',
                  onExplorar: _limpiarFiltros,
                )
              : RejillaLegoHaku.grid(
                  context: context,
                  itemCount: filtradas.length,
                  bottomPadding: widget.bottomPadding,
                  itemBuilder: (context, index) {
                    final ruta = filtradas[index];
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
                ),
        ),
      ],
    );
  }

  bool _pasaFiltros(ModeloRuta ruta) {
    final enfoque = _enfoque;
    if (enfoque != null && _enfoqueDe(ruta) != enfoque) return false;
    final tipo = _tipo;
    if (tipo != null && _tipoDe(ruta) != tipo) return false;
    final nivel = _nivel;
    if (nivel != null && _nivelDe(ruta) != nivel) return false;
    final zona = _zona;
    if (zona != null && ruta.provincia.trim() != zona) return false;
    return true;
  }
}

class _SegmentoFiltroRuta extends StatelessWidget {
  const _SegmentoFiltroRuta({required this.activo, required this.onChanged});

  final _EjeFiltroRuta activo;
  final ValueChanged<_EjeFiltroRuta> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PaletaRutas.plomo.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          for (final eje in _EjeFiltroRuta.values)
            Expanded(
              child: _BotonSegmentoRuta(
                texto: _labelEje(eje),
                activo: activo == eje,
                onTap: () => onChanged(eje),
              ),
            ),
        ],
      ),
    );
  }
}

class _BotonSegmentoRuta extends StatelessWidget {
  const _BotonSegmentoRuta({
    required this.texto,
    required this.activo,
    required this.onTap,
  });

  final String texto;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: activo ? PaletaRutas.ink : PaletaRutas.piedra,
        backgroundColor: activo ? PaletaRutas.oro : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: EdgeInsets.zero,
      ),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TipografiaHaku.interfaz(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ChipFiltroRuta extends StatelessWidget {
  const _ChipFiltroRuta({
    required this.texto,
    required this.activo,
    required this.onTap,
  });

  final String texto;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(texto),
      selected: activo,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: PaletaRutas.oro.withValues(alpha: 0.22),
      backgroundColor: PaletaRutas.carbon,
      side: BorderSide(
        color: activo
            ? PaletaRutas.oro
            : PaletaRutas.plomo.withValues(alpha: 0.4),
      ),
      labelStyle: TipografiaHaku.interfaz(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: activo ? PaletaRutas.oro : PaletaRutas.piedra,
      ),
      visualDensity: VisualDensity.compact,
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

List<String> _valores(Iterable<String> valores) {
  final list = valores
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .toSet()
      .toList(growable: false);
  list.sort();
  return list;
}

String _labelEje(_EjeFiltroRuta eje) {
  return switch (eje) {
    _EjeFiltroRuta.enfoque => 'Enfoque',
    _EjeFiltroRuta.tipo => 'Tipo',
    _EjeFiltroRuta.nivel => 'Nivel',
  };
}

String _enfoqueDe(ModeloRuta ruta) {
  if (ruta.hilo != HiloCultura.camino) return _hiloEtiqueta(ruta.hilo);
  return switch (ruta.categoria) {
    CategoriaRuta.cultura => 'Cultura',
    CategoriaRuta.naturaleza => 'Naturaleza',
    _ => 'Recorrido',
  };
}

String _tipoDe(ModeloRuta ruta) {
  final raw = (ruta.tipoSitio ?? '').trim().toLowerCase();
  return switch (raw) {
    'senderismo' => 'Senderismo',
    'cultural' => 'Cultural',
    'urbana' => 'Urbana',
    'naturaleza' => 'Naturaleza',
    '' => 'Ruta',
    _ => raw
        .split(RegExp(r'[_\s-]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' '),
  };
}

String _nivelDe(ModeloRuta ruta) {
  if (ruta.nivelDificultad <= 1) return 'Facil';
  if (ruta.nivelDificultad >= 4) return 'Exigente';
  return 'Moderada';
}

String _hiloEtiqueta(HiloCultura hilo) {
  return switch (hilo) {
    HiloCultura.camino => 'Recorrido',
    HiloCultura.tejido => 'Tejido',
    HiloCultura.ceramica => 'Ceramica',
    HiloCultura.comida => 'Gastronomia',
    HiloCultura.teatro => 'Teatro',
    HiloCultura.pintura => 'Pintura',
  };
}
