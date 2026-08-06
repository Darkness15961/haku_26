import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dominio/modelos/provincia.dart';
import '../proveedores/proveedor_mapa_cusco.dart';
import 'pieza_provincia.dart';

/// Mapa interactivo de Cusco con sus 13 provincias como piezas de rompecabezas.
///
/// Soporta selección táctil de las 13 provincias, zoom fluido y alineación milimétrica.
class MapaCuscoInteractivo extends ConsumerStatefulWidget {
  const MapaCuscoInteractivo({super.key});

  @override
  ConsumerState<MapaCuscoInteractivo> createState() =>
      _EstadoMapaCuscoInteractivo();
}

class _EstadoMapaCuscoInteractivo extends ConsumerState<MapaCuscoInteractivo>
    with TickerProviderStateMixin {
  late AnimationController _controladorEntrada;
  late TransformationController _controladorTransformacion;
  late AnimationController _controladorZoom;

  final List<Animation<double>> _animacionesPiezas = [];

  @override
  void initState() {
    super.initState();

    _controladorEntrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _controladorTransformacion = TransformationController();

    _controladorZoom = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _crearAnimacionesEscalonadas();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _controladorEntrada.forward().then((_) {
          if (mounted) {
            ref
                .read(mapasCuscoProvider.notifier)
                .completarAnimacionInicial();
          }
        });
      }
    });
  }

  void _crearAnimacionesEscalonadas() {
    _animacionesPiezas.clear();
    const totalPiezas = 13;
    const duracionPieza = 0.35;
    const separacion = (1.0 - duracionPieza) / (totalPiezas - 1);

    for (int i = 0; i < totalPiezas; i++) {
      final inicio = i * separacion;
      final fin = (inicio + duracionPieza).clamp(0.0, 1.0);

      final animacion = CurvedAnimation(
        parent: _controladorEntrada,
        curve: Interval(
          inicio,
          fin,
          curve: Curves.linear,
        ),
      );
      _animacionesPiezas.add(animacion);
    }
  }

  void _animarZoomAProvincia(Provincia provincia, Size tamanioDisponible) {
    final matrizActual = _controladorTransformacion.value.clone();
    final centroProvinciaX =
        provincia.posicionCentro.dx * tamanioDisponible.width;
    final centroProvinciaY =
        provincia.posicionCentro.dy * tamanioDisponible.height;

    final escala = 2.2;
    final centroVistaX = tamanioDisponible.width / 2;
    final centroVistaY = tamanioDisponible.height / 2;

    final dx = centroVistaX - centroProvinciaX * escala;
    final dy = centroVistaY - centroProvinciaY * escala;

    final matrizDestino = Matrix4.identity()
      ..setTranslationRaw(dx, dy, 0);
    matrizDestino.multiply(Matrix4.diagonal3Values(escala, escala, 1.0));

    final animacion = Matrix4Tween(
      begin: matrizActual,
      end: matrizDestino,
    ).animate(CurvedAnimation(
      parent: _controladorZoom,
      curve: Curves.easeOutCubic,
    ));

    void listener() {
      _controladorTransformacion.value = animacion.value;
    }

    _controladorZoom.reset();
    animacion.addListener(listener);
    _controladorZoom.forward().then((_) {
      animacion.removeListener(listener);
    });
  }

  void _restaurarZoom() {
    final matrizActual = _controladorTransformacion.value.clone();
    final matrizIdentidad = Matrix4.identity();

    final animacion = Matrix4Tween(
      begin: matrizActual,
      end: matrizIdentidad,
    ).animate(CurvedAnimation(
      parent: _controladorZoom,
      curve: Curves.easeOutCubic,
    ));

    void listener() {
      _controladorTransformacion.value = animacion.value;
    }

    _controladorZoom.reset();
    animacion.addListener(listener);
    _controladorZoom.forward().then((_) {
      animacion.removeListener(listener);
    });
  }

  /// Procesa los toques táctiles en el mapa y selecciona la provincia correspondiente.
  void _procesarToqueMapa(Offset localPosition, List<Provincia> provincias) {
    final normX = (localPosition.dx / 1000.0).clamp(0.0, 1.0);
    final normY = (localPosition.dy / 1150.0).clamp(0.0, 1.0);

    Provincia? provinciaSeleccionada;
    double menorDistancia = double.infinity;

    for (final p in provincias) {
      final dist = math.sqrt(
        math.pow(p.posicionCentro.dx - normX, 2) +
        math.pow(p.posicionCentro.dy - normY, 2),
      );
      if (dist < menorDistancia) {
        menorDistancia = dist;
        provinciaSeleccionada = p;
      }
    }

    if (provinciaSeleccionada != null && menorDistancia < 0.28) {
      ref
          .read(mapasCuscoProvider.notifier)
          .seleccionarProvincia(provinciaSeleccionada.id);
    }
  }

  @override
  void dispose() {
    _controladorEntrada.dispose();
    _controladorTransformacion.dispose();
    _controladorZoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(mapasCuscoProvider);
    final provincias = estado.provincias;

    ref.listen<EstadoMapaCusco>(mapasCuscoProvider, (anterior, nuevo) {
      if (nuevo.provinciaSeleccionadaId != null &&
          nuevo.provinciaSeleccionadaId !=
              anterior?.provinciaSeleccionadaId) {
        final provincia = nuevo.provinciaSeleccionada;
        if (provincia != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null) {
              _animarZoomAProvincia(provincia, box.size);
            }
          });
        }
      } else if (nuevo.provinciaSeleccionadaId == null &&
          anterior?.provinciaSeleccionadaId != null) {
        _restaurarZoom();
      }
    });

    if (provincias.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC9A84C),
          strokeWidth: 2,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          transformationController: _controladorTransformacion,
          minScale: 0.8,
          maxScale: 4.0,
          boundaryMargin: const EdgeInsets.all(50),
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 1000,
                height: 1150,
                child: GestureDetector(
                  onTapUp: (details) =>
                      _procesarToqueMapa(details.localPosition, provincias),
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    fit: StackFit.expand,
                    children: List.generate(provincias.length, (index) {
                      final provincia = provincias[index];
                      final estaSeleccionada =
                          estado.provinciaSeleccionadaId == provincia.id;
                      final estaDestacada =
                          estado.provinciaDestacadaId == provincia.id;
                      final otraSeleccionada =
                          estado.provinciaSeleccionadaId != null &&
                              !estaSeleccionada;

                      final animacion = index < _animacionesPiezas.length
                          ? _animacionesPiezas[index]
                          : _animacionesPiezas.last;

                      return PiezaProvincia(
                        provincia: provincia,
                        estaSeleccionada: estaSeleccionada,
                        estaDestacada: estaDestacada,
                        otraSeleccionada: otraSeleccionada,
                        animacionEntrada: animacion,
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
