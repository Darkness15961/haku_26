import 'dart:async';

import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/provincias_datasource_local.dart';
import '../dominio/modelos/modelo_lugar.dart';
import 'isla_provincia.dart';
import 'sheet_provincia_lugares.dart';

/// Carrusel horizontal: una isla a la vez, swipe + auto-avance.
class MapaIslasProvincias extends StatefulWidget {
  const MapaIslasProvincias({
    super.key,
    required this.lugares,
    required this.onTapLugar,
    this.fotosPorLugar = const {},
    this.onRegistrarEnProvincia,
    this.onProvinciaVisible,
    this.altura = 320,
  });

  final List<ModeloLugar> lugares;
  final ValueChanged<String> onTapLugar;
  final Map<String, int> fotosPorLugar;
  final ValueChanged<String>? onRegistrarEnProvincia;
  /// Nombre de la provincia centrada en el carrusel.
  final ValueChanged<String>? onProvinciaVisible;
  final double altura;

  @override
  State<MapaIslasProvincias> createState() => _EstadoMapaIslasProvincias();
}

class _EstadoMapaIslasProvincias extends State<MapaIslasProvincias> {
  late final PageController _page;
  Timer? _auto;
  int _indice = 0;
  List<IslaProvinciaData> _islas = const [];

  IslaProvinciaData? get provinciaActual =>
      _islas.isEmpty ? null : _islas[_indice.clamp(0, _islas.length - 1)];

  @override
  void initState() {
    super.initState();
    _page = PageController(viewportFraction: 0.92);
    _islas = ProvinciasDataSourceLocal.construirIslas(widget.lugares);
    _iniciarAuto();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitirProvincia());
  }

  void _emitirProvincia() {
    final p = provinciaActual?.provincia.nombre;
    if (p != null) widget.onProvinciaVisible?.call(p);
  }

  @override
  void didUpdateWidget(MapaIslasProvincias oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lugares != widget.lugares) {
      final prevId = provinciaActual?.provincia.id;
      _islas = ProvinciasDataSourceLocal.construirIslas(widget.lugares);
      if (prevId != null) {
        final i = _islas.indexWhere((e) => e.provincia.id == prevId);
        _indice = i >= 0 ? i : 0;
      } else if (_indice >= _islas.length) {
        _indice = 0;
      }
      _reiniciarAuto();
      WidgetsBinding.instance.addPostFrameCallback((_) => _emitirProvincia());
    }
  }

  void _iniciarAuto() {
    _auto?.cancel();
    if (_islas.length < 2) return;
    _auto = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_page.hasClients) return;
      final next = (_indice + 1) % _islas.length;
      _page.animateToPage(
        next,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _reiniciarAuto() {
    _auto?.cancel();
    _iniciarAuto();
  }

  void _pausarPorUsuario() {
    _auto?.cancel();
    Future<void>.delayed(const Duration(seconds: 8), () {
      if (mounted) _iniciarAuto();
    });
  }

  void _abrirSheet(IslaProvinciaData isla) {
    abrirSheetProvinciaLugares(
      context,
      data: isla,
      fotosPorLugar: widget.fotosPorLugar,
      onTapLugar: (l) => widget.onTapLugar(l.id),
      onRegistrar: widget.onRegistrarEnProvincia == null
          ? null
          : () => widget.onRegistrarEnProvincia!(isla.provincia.nombre),
    );
  }

  @override
  void dispose() {
    _auto?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_islas.isEmpty) {
      return SizedBox(
        height: widget.altura,
        child: Center(
          child: Text(
            'Todavía no hay provincias cargadas.',
            textAlign: TextAlign.center,
            style: TipografiaHaku.interfaz(
              fontSize: 14,
              color: PaletaRutas.plomoClaro,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.altura,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification && n.dragDetails != null) {
                _pausarPorUsuario();
              }
              return false;
            },
            child: PageView.builder(
              controller: _page,
              itemCount: _islas.length,
              onPageChanged: (i) {
                setState(() => _indice = i);
                _emitirProvincia();
              },
              itemBuilder: (context, i) {
                final isla = _islas[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: IslaProvincia(
                    data: isla,
                    indice: i,
                    onTapIsla: () => _abrirSheet(isla),
                    onTapLugar: (l) => widget.onTapLugar(l.id),
                    onRegistrar: widget.onRegistrarEnProvincia == null
                        ? null
                        : () => widget
                            .onRegistrarEnProvincia!(isla.provincia.nombre),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_islas.length, (i) {
            final activo = i == _indice;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: activo ? 16 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: activo
                    ? PaletaRutas.oro
                    : PaletaRutas.plomo.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
