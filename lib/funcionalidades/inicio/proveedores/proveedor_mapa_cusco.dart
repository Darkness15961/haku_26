import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datos/provincias_datasource_local.dart';
import '../dominio/modelos/destino_destacado.dart';
import '../dominio/modelos/provincia.dart';
import '../dominio/modelos/ranking_destino.dart';

// ─────────────────────────────────────────────
// Estado del Mapa
// ─────────────────────────────────────────────

/// Estados posibles de carga del mapa.
enum EstadoCarga { inicial, cargando, completado, error }

/// Estado inmutable del mapa interactivo de Cusco.
@immutable
class EstadoMapaCusco {
  final String? provinciaSeleccionadaId;
  final String? provinciaDestacadaId;
  final bool animacionInicialCompletada;
  final List<Provincia> provincias;
  final Map<String, List<DestinoDestacado>> destinosPorProvincia;
  final RankingDestino? rankingMensual;
  final EstadoCarga estadoCarga;
  final String? mensajeError;
  final double nivelZoom;

  const EstadoMapaCusco({
    this.provinciaSeleccionadaId,
    this.provinciaDestacadaId,
    this.animacionInicialCompletada = false,
    this.provincias = const [],
    this.destinosPorProvincia = const {},
    this.rankingMensual,
    this.estadoCarga = EstadoCarga.inicial,
    this.mensajeError,
    this.nivelZoom = 1.0,
  });

  EstadoMapaCusco copyWith({
    String? provinciaSeleccionadaId,
    String? provinciaDestacadaId,
    bool? animacionInicialCompletada,
    List<Provincia>? provincias,
    Map<String, List<DestinoDestacado>>? destinosPorProvincia,
    RankingDestino? rankingMensual,
    EstadoCarga? estadoCarga,
    String? mensajeError,
    double? nivelZoom,
    bool limpiarSeleccion = false,
    bool limpiarError = false,
  }) {
    return EstadoMapaCusco(
      provinciaSeleccionadaId: limpiarSeleccion
          ? null
          : (provinciaSeleccionadaId ?? this.provinciaSeleccionadaId),
      provinciaDestacadaId:
          provinciaDestacadaId ?? this.provinciaDestacadaId,
      animacionInicialCompletada:
          animacionInicialCompletada ?? this.animacionInicialCompletada,
      provincias: provincias ?? this.provincias,
      destinosPorProvincia:
          destinosPorProvincia ?? this.destinosPorProvincia,
      rankingMensual: rankingMensual ?? this.rankingMensual,
      estadoCarga: estadoCarga ?? this.estadoCarga,
      mensajeError: limpiarError ? null : (mensajeError ?? this.mensajeError),
      nivelZoom: nivelZoom ?? this.nivelZoom,
    );
  }

  /// Provincia actualmente seleccionada (objeto completo).
  Provincia? get provinciaSeleccionada {
    if (provinciaSeleccionadaId == null) return null;
    return provincias.cast<Provincia?>().firstWhere(
      (p) => p?.id == provinciaSeleccionadaId,
      orElse: () => null,
    );
  }

  /// Destinos de la provincia seleccionada.
  List<DestinoDestacado> get destinosProvinciaSeleccionada {
    if (provinciaSeleccionadaId == null) return [];
    return destinosPorProvincia[provinciaSeleccionadaId] ?? [];
  }

  /// Top 3 destinos de la provincia seleccionada.
  List<DestinoDestacado> get top3ProvinciaSeleccionada {
    final destinos = destinosProvinciaSeleccionada;
    final ordenados = List<DestinoDestacado>.from(destinos)
      ..sort((a, b) => a.posicion.compareTo(b.posicion));
    return ordenados.take(3).toList();
  }
}

// ─────────────────────────────────────────────
// Notifier del Mapa
// ─────────────────────────────────────────────

/// Controlador del estado del mapa interactivo de Cusco.
///
/// Gestiona la carga de datos, selección de provincias,
/// animaciones y zoom del mapa.
class MapaCuscoNotifier extends StateNotifier<EstadoMapaCusco> {
  MapaCuscoNotifier() : super(const EstadoMapaCusco());

  /// Carga las provincias y datos iniciales.
  Future<void> cargarDatos() async {
    state = state.copyWith(estadoCarga: EstadoCarga.cargando);

    try {
      // Simula un delay de red (eliminar cuando se conecte Supabase)
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final provincias = ProvinciasDataSourceLocal.obtenerProvincias();
      final destinos =
          ProvinciasDataSourceLocal.obtenerDestinosPorProvincia();
      final ranking = ProvinciasDataSourceLocal.obtenerRankingMensual();

      state = state.copyWith(
        provincias: provincias,
        destinosPorProvincia: destinos,
        rankingMensual: ranking,
        estadoCarga: EstadoCarga.completado,
        provinciaDestacadaId: 'cusco', // Provincia sugerida inicial
        limpiarError: true,
      );
    } catch (e) {
      state = state.copyWith(
        estadoCarga: EstadoCarga.error,
        mensajeError: e.toString(),
      );
    }
  }

  /// Selecciona una provincia por su ID.
  void seleccionarProvincia(String provinciaId) {
    // Si ya está seleccionada, deseleccionar
    if (state.provinciaSeleccionadaId == provinciaId) {
      state = state.copyWith(
        limpiarSeleccion: true,
        nivelZoom: 1.0,
      );
      return;
    }

    state = state.copyWith(
      provinciaSeleccionadaId: provinciaId,
      provinciaDestacadaId: provinciaId,
      nivelZoom: 2.0,
    );
  }

  /// Deselecciona la provincia actual.
  void deseleccionarProvincia() {
    state = state.copyWith(
      limpiarSeleccion: true,
      nivelZoom: 1.0,
    );
  }

  /// Marca la animación inicial como completada.
  void completarAnimacionInicial() {
    state = state.copyWith(animacionInicialCompletada: true);
  }

  /// Actualiza el nivel de zoom actual del mapa.
  void actualizarZoom(double zoom) {
    state = state.copyWith(nivelZoom: zoom);
  }
}

// ─────────────────────────────────────────────
// Providers de Riverpod
// ─────────────────────────────────────────────

/// Provider principal del mapa de Cusco.
final mapasCuscoProvider =
    StateNotifierProvider<MapaCuscoNotifier, EstadoMapaCusco>(
  (ref) => MapaCuscoNotifier(),
);

/// Provider de la lista de provincias.
final listaProvinciasProvider = Provider<List<Provincia>>((ref) {
  return ref.watch(mapasCuscoProvider).provincias;
});

/// Provider de la provincia seleccionada.
final provinciaSeleccionadaProvider = Provider<Provincia?>((ref) {
  return ref.watch(mapasCuscoProvider).provinciaSeleccionada;
});

/// Provider del ranking mensual.
final rankingMensualProvider = Provider<RankingDestino?>((ref) {
  return ref.watch(mapasCuscoProvider).rankingMensual;
});

/// Provider de los destinos de la provincia seleccionada.
final destinosProvinciaProvider = Provider<List<DestinoDestacado>>((ref) {
  return ref.watch(mapasCuscoProvider).top3ProvinciaSeleccionada;
});

/// Provider del estado de carga.
final estadoCargaProvider = Provider<EstadoCarga>((ref) {
  return ref.watch(mapasCuscoProvider).estadoCarga;
});
