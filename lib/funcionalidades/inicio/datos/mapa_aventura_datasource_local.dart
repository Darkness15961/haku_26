import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Dirección del joystick (solo cambia selección de nodo).
enum DireccionJoystick { arriba, abajo, izquierda, derecha }

/// Tipo de ilustración “dibujada” del nodo (sin fotografías).
enum TipoIlustracionNodo {
  montana,
  laguna,
  bosque,
  ruinas,
  pueblo,
  catarata,
  nevado,
  terrazas,
}

/// Nodo del mapa de aventura (datos de presentación; no modifica dominio).
@immutable
class NodoMapaAventura {
  final String id;
  final String nombre;
  /// Posición normalizada en el lienzo (0–1 en X e Y).
  final Offset posicion;
  final TipoIlustracionNodo tipo;
  final String duracion;
  final String dificultad;
  final String distancia;
  final String elevacion;
  /// Asset opcional (ej. `assets/provincias/CUSCO.png`).
  final String? rutaIlustracion;
  final Map<DireccionJoystick, String> vecinos;

  const NodoMapaAventura({
    required this.id,
    required this.nombre,
    required this.posicion,
    required this.tipo,
    required this.duracion,
    required this.dificultad,
    required this.distancia,
    required this.elevacion,
    this.rutaIlustracion,
    this.vecinos = const {},
  });
}

@immutable
class AristaMapaAventura {
  final String desdeId;
  final String hastaId;

  const AristaMapaAventura({
    required this.desdeId,
    required this.hastaId,
  });
}

/// Las 13 provincias de Cusco con posiciones tipo mapa + red de caminos.
class MapaAventuraDataSourceLocal {
  static const Size tamanioLienzo = Size(360, 560);

  static const List<_ProvinciaMapa> _provincias = [
    _ProvinciaMapa(
      id: 'la_convencion',
      nombre: 'La Convención',
      asset: 'assets/provincias/LACONVENCION.png',
      elevacion: '1,050 m',
      tipo: TipoIlustracionNodo.bosque,
      // 0–1 = bordes del área útil (márgenes + joystick los aplica el mapa).
      posicion: Offset(0.00, 0.00),
    ),
    _ProvinciaMapa(
      id: 'urubamba',
      nombre: 'Urubamba',
      asset: 'assets/provincias/URUBAMBA.png',
      elevacion: '2,871 m',
      tipo: TipoIlustracionNodo.ruinas,
      posicion: Offset(0.50, 0.00),
    ),
    _ProvinciaMapa(
      id: 'calca',
      nombre: 'Calca',
      asset: 'assets/provincias/CALCA.png',
      elevacion: '2,926 m',
      tipo: TipoIlustracionNodo.laguna,
      posicion: Offset(1.00, 0.00),
    ),
    _ProvinciaMapa(
      id: 'paucartambo',
      nombre: 'Paucartambo',
      asset: 'assets/provincias/PAUCARTAMBO.png',
      elevacion: '2,906 m',
      tipo: TipoIlustracionNodo.montana,
      posicion: Offset(1.00, 0.28),
    ),
    _ProvinciaMapa(
      id: 'anta',
      nombre: 'Anta',
      asset: 'assets/provincias/ANTA.png',
      elevacion: '3,337 m',
      tipo: TipoIlustracionNodo.terrazas,
      posicion: Offset(0.00, 0.28),
    ),
    _ProvinciaMapa(
      id: 'cusco',
      nombre: 'Cusco',
      asset: 'assets/provincias/cusco.png',
      elevacion: '3,399 m',
      tipo: TipoIlustracionNodo.pueblo,
      posicion: Offset(0.50, 0.32),
    ),
    _ProvinciaMapa(
      id: 'quispicanchi',
      nombre: 'Quispicanchi',
      asset: 'assets/provincias/QUISPICANCHI.png',
      elevacion: '3,150 m',
      tipo: TipoIlustracionNodo.nevado,
      posicion: Offset(1.00, 0.52),
    ),
    _ProvinciaMapa(
      id: 'paruro',
      nombre: 'Paruro',
      asset: 'assets/provincias/PARURO.png',
      elevacion: '3,051 m',
      tipo: TipoIlustracionNodo.pueblo,
      posicion: Offset(0.00, 0.54),
    ),
    _ProvinciaMapa(
      id: 'acomayo',
      nombre: 'Acomayo',
      asset: 'assets/provincias/ACOMAYO.png',
      elevacion: '3,207 m',
      tipo: TipoIlustracionNodo.laguna,
      posicion: Offset(0.42, 0.56),
    ),
    _ProvinciaMapa(
      id: 'canchis',
      nombre: 'Canchis',
      asset: 'assets/provincias/CANCHIS.png',
      elevacion: '3,548 m',
      tipo: TipoIlustracionNodo.ruinas,
      posicion: Offset(0.78, 0.74),
    ),
    _ProvinciaMapa(
      id: 'chumbivilcas',
      nombre: 'Chumbivilcas',
      asset: 'assets/provincias/CHUMBIVILCAS.png',
      elevacion: '3,660 m',
      tipo: TipoIlustracionNodo.pueblo,
      posicion: Offset(0.00, 1.00),
    ),
    _ProvinciaMapa(
      id: 'canas',
      nombre: 'Canas',
      asset: 'assets/provincias/CANAS.png',
      elevacion: '3,910 m',
      tipo: TipoIlustracionNodo.laguna,
      posicion: Offset(0.48, 1.00),
    ),
    _ProvinciaMapa(
      id: 'espinar',
      nombre: 'Espinar',
      asset: 'assets/provincias/ESPINAR.png',
      elevacion: '3,915 m',
      tipo: TipoIlustracionNodo.montana,
      posicion: Offset(1.00, 1.00),
    ),
  ];

  /// Enlaces tipo mapa (un nodo puede unirse a varios).
  static const List<(String, String)> _conexiones = [
    ('la_convencion', 'urubamba'),
    ('la_convencion', 'anta'),
    ('urubamba', 'calca'),
    ('urubamba', 'cusco'),
    ('urubamba', 'anta'),
    ('calca', 'paucartambo'),
    ('calca', 'cusco'),
    ('calca', 'quispicanchi'),
    ('paucartambo', 'quispicanchi'),
    ('anta', 'cusco'),
    ('anta', 'paruro'),
    ('cusco', 'quispicanchi'),
    ('cusco', 'paruro'),
    ('cusco', 'acomayo'),
    ('quispicanchi', 'acomayo'),
    ('quispicanchi', 'canchis'),
    ('paruro', 'acomayo'),
    ('paruro', 'chumbivilcas'),
    ('acomayo', 'canchis'),
    ('acomayo', 'canas'),
    ('canchis', 'canas'),
    ('canchis', 'espinar'),
    ('chumbivilcas', 'canas'),
    ('chumbivilcas', 'espinar'),
    ('canas', 'espinar'),
  ];

  static final List<NodoMapaAventura> nodos = List.unmodifiable(
    _provincias.map((p) {
      return NodoMapaAventura(
        id: p.id,
        nombre: p.nombre,
        posicion: p.posicion,
        tipo: p.tipo,
        duracion: '1 - 2 días',
        dificultad: 'Moderada',
        distancia: '—',
        elevacion: p.elevacion,
        rutaIlustracion: p.asset,
        vecinos: _vecinosJoystick(p.id, p.posicion),
      );
    }).toList(),
  );

  static List<AristaMapaAventura> get aristas {
    return _conexiones
        .map((c) => AristaMapaAventura(desdeId: c.$1, hastaId: c.$2))
        .toList(growable: false);
  }

  static NodoMapaAventura? porId(String id) {
    for (final n in nodos) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// Vecino más cercano en cada eje (para el joystick).
  static Map<DireccionJoystick, String> _vecinosJoystick(
    String id,
    Offset yo,
  ) {
    String? mejorArriba;
    String? mejorAbajo;
    String? mejorIzq;
    String? mejorDer;
    var dArriba = double.infinity;
    var dAbajo = double.infinity;
    var dIzq = double.infinity;
    var dDer = double.infinity;

    for (final p in _provincias) {
      if (p.id == id) continue;
      final dx = p.posicion.dx - yo.dx;
      final dy = p.posicion.dy - yo.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < 0.001) continue;

      if (dy < -0.02 && dy.abs() >= dx.abs() * 0.55 && dist < dArriba) {
        dArriba = dist;
        mejorArriba = p.id;
      }
      if (dy > 0.02 && dy.abs() >= dx.abs() * 0.55 && dist < dAbajo) {
        dAbajo = dist;
        mejorAbajo = p.id;
      }
      if (dx < -0.02 && dx.abs() >= dy.abs() * 0.55 && dist < dIzq) {
        dIzq = dist;
        mejorIzq = p.id;
      }
      if (dx > 0.02 && dx.abs() >= dy.abs() * 0.55 && dist < dDer) {
        dDer = dist;
        mejorDer = p.id;
      }
    }

    return {
      if (mejorArriba != null) DireccionJoystick.arriba: mejorArriba,
      if (mejorAbajo != null) DireccionJoystick.abajo: mejorAbajo,
      if (mejorIzq != null) DireccionJoystick.izquierda: mejorIzq,
      if (mejorDer != null) DireccionJoystick.derecha: mejorDer,
    };
  }
}

@immutable
class _ProvinciaMapa {
  final String id;
  final String nombre;
  final String asset;
  final String elevacion;
  final TipoIlustracionNodo tipo;
  final Offset posicion;

  const _ProvinciaMapa({
    required this.id,
    required this.nombre,
    required this.asset,
    required this.elevacion,
    required this.tipo,
    required this.posicion,
  });
}
