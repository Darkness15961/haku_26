import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// KPI norte Fase 1 — persistente con semilla demo.
class EstadoMetricas {
  final int documentados;
  final int experienciasPublicadas;
  final int salidasEnroladas;
  final List<String> eventos;
  final bool listo;

  const EstadoMetricas({
    this.documentados = 0,
    this.experienciasPublicadas = 0,
    this.salidasEnroladas = 0,
    this.eventos = const [],
    this.listo = false,
  });

  /// Valores iniciales para poder ver el perfil “vivo”.
  factory EstadoMetricas.demo() => const EstadoMetricas(
        documentados: 14,
        experienciasPublicadas: 8,
        salidasEnroladas: 3,
        listo: true,
      );

  EstadoMetricas copyWith({
    int? documentados,
    int? experienciasPublicadas,
    int? salidasEnroladas,
    List<String>? eventos,
    bool? listo,
  }) {
    return EstadoMetricas(
      documentados: documentados ?? this.documentados,
      experienciasPublicadas:
          experienciasPublicadas ?? this.experienciasPublicadas,
      salidasEnroladas: salidasEnroladas ?? this.salidasEnroladas,
      eventos: eventos ?? this.eventos,
      listo: listo ?? this.listo,
    );
  }
}

class MetricasDescubrimientoNotifier extends StateNotifier<EstadoMetricas> {
  static const _clave = 'haku_metricas_v1';

  MetricasDescubrimientoNotifier() : super(EstadoMetricas.demo()) {
    _restaurar();
  }

  Future<void> _restaurar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_clave);
    if (raw == null || raw.isEmpty) {
      await _persistir();
      return;
    }
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      state = EstadoMetricas(
        documentados: (m['documentados'] as num?)?.toInt() ?? 14,
        experienciasPublicadas:
            (m['experiencias_publicadas'] as num?)?.toInt() ?? 8,
        salidasEnroladas: (m['salidas_enroladas'] as num?)?.toInt() ?? 3,
        eventos: [
          for (final e in (m['eventos'] as List<dynamic>? ?? [])) e.toString(),
        ],
        listo: true,
      );
    } catch (_) {
      state = EstadoMetricas.demo();
      await _persistir();
    }
  }

  Future<void> _persistir() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _clave,
      jsonEncode({
        'documentados': state.documentados,
        'experiencias_publicadas': state.experienciasPublicadas,
        'salidas_enroladas': state.salidasEnroladas,
        'eventos': state.eventos.take(40).toList(),
      }),
    );
  }

  Future<void> registrarDescubrimiento(String lugarId, {String? fuente}) async {
    state = state.copyWith(
      documentados: state.documentados + 1,
      eventos: [
        _linea('descubrimiento_documentado', lugarId, fuente),
        ...state.eventos,
      ],
    );
    // ignore: avoid_print
    print('[HAKU_KPI] ${state.eventos.first}');
    await _persistir();
  }

  Future<void> registrarExperiencia(String lugarId) async {
    state = state.copyWith(
      experienciasPublicadas: state.experienciasPublicadas + 1,
      eventos: [
        _linea('experiencia_publicada', lugarId, null),
        ...state.eventos,
      ],
    );
    // ignore: avoid_print
    print('[HAKU_KPI] ${state.eventos.first}');
    await _persistir();
  }

  Future<void> registrarEnrolamiento(String salidaId) async {
    state = state.copyWith(
      salidasEnroladas: state.salidasEnroladas + 1,
      eventos: [
        _linea('salida_enrolada', salidaId, null),
        ...state.eventos,
      ],
    );
    // ignore: avoid_print
    print('[HAKU_KPI] ${state.eventos.first}');
    await _persistir();
  }

  Future<void> reiniciarDemo() async {
    state = EstadoMetricas.demo();
    await _persistir();
  }

  String _linea(String evento, String id, String? fuente) =>
      '${DateTime.now().toIso8601String()}|$evento|$id|${fuente ?? '-'}';
}

final metricasDescubrimientoProvider = StateNotifierProvider<
    MetricasDescubrimientoNotifier, EstadoMetricas>((ref) {
  return MetricasDescubrimientoNotifier();
});

/// Compat: fuerza rebuild de widgets que escuchaban el tick antiguo.
final metricasTickProvider = StateProvider<int>((ref) => 0);

void bumpMetricas(WidgetRef ref) {
  ref.read(metricasTickProvider.notifier).state++;
}
