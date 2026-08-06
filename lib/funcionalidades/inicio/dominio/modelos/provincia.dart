import 'package:flutter/material.dart';

/// Modelo que representa una provincia de la región Cusco.
///
/// Cada provincia contiene información geográfica, visual y turística
/// necesaria para renderizarla en el mapa interactivo.
class Provincia {
  final String id;
  final String nombre;
  final String nombreCorto;
  final String rutaSvg;
  final String? imagenUrl;
  final String destinoPrincipal;
  final String descripcion;
  final Color colorBase;
  final Offset posicionCentro;
  final String capital;
  final int altitudMedia;

  const Provincia({
    required this.id,
    required this.nombre,
    required this.nombreCorto,
    required this.rutaSvg,
    this.imagenUrl,
    required this.destinoPrincipal,
    required this.descripcion,
    required this.colorBase,
    required this.posicionCentro,
    required this.capital,
    required this.altitudMedia,
  });

  Provincia copyWith({
    String? id,
    String? nombre,
    String? nombreCorto,
    String? rutaSvg,
    String? imagenUrl,
    String? destinoPrincipal,
    String? descripcion,
    Color? colorBase,
    Offset? posicionCentro,
    String? capital,
    int? altitudMedia,
  }) {
    return Provincia(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      nombreCorto: nombreCorto ?? this.nombreCorto,
      rutaSvg: rutaSvg ?? this.rutaSvg,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      destinoPrincipal: destinoPrincipal ?? this.destinoPrincipal,
      descripcion: descripcion ?? this.descripcion,
      colorBase: colorBase ?? this.colorBase,
      posicionCentro: posicionCentro ?? this.posicionCentro,
      capital: capital ?? this.capital,
      altitudMedia: altitudMedia ?? this.altitudMedia,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Provincia && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
