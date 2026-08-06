import 'package:flutter/material.dart';

/// Modelo de datos para las experiencias e imágenes inmersivas de la pantalla Destinos.
class DestinoExperiencia {
  final String id;
  final String ubicacionBadge;
  final String categoriaEtiqueta;
  final String tituloPrincipal;
  final String subtituloResaltado;
  final String descripcionDetallada;
  final List<String> tags;
  final String rutaImagen;
  final Color colorAccento;
  final String textoAccion;
  final String subtextoAccion;

  const DestinoExperiencia({
    required this.id,
    required this.ubicacionBadge,
    this.categoriaEtiqueta = 'DESCUBRE',
    required this.tituloPrincipal,
    required this.subtituloResaltado,
    required this.descripcionDetallada,
    required this.tags,
    required this.rutaImagen,
    this.colorAccento = const Color(0xFF4EBA87),
    this.textoAccion = 'Comenzar Aventura',
    this.subtextoAccion = 'Personaliza tu experiencia de viaje',
  });
}
