import 'package:flutter/material.dart';

import '../dominio/modelos/destino_experiencia.dart';

/// Fuente de datos local para el feed inmersivo (tab Inicio).
///
/// Imagenes locales en `assets/destinos/` (copiadas desde Downloads/APLICACION).
/// Para cambiar una foto: reemplaza el archivo o edita `rutaImagen`.
class DestinosDataSourceLocal {
  static const List<DestinoExperiencia> obtenerDestinosExperiencia = [
    DestinoExperiencia(
      id: 'machupicchu',
      ubicacionBadge: 'CUSCO',
      categoriaEtiqueta: 'AVENTURA',
      tituloPrincipal: 'Machu Picchu',
      subtituloResaltado: '',
      descripcionDetallada: 'La ciudadela entre montanas.',
      tags: const [],
      rutaImagen: 'assets/destinos/machu_picchu.jpg',
      colorAccento: Color(0xFF3F5E3B),
      textoAccion: 'Explorar',
      subtextoAccion: '',
    ),
    DestinoExperiencia(
      id: 'humantay',
      ubicacionBadge: 'CUSCO',
      categoriaEtiqueta: 'NATURALEZA',
      tituloPrincipal: 'Ausangate',
      subtituloResaltado: '',
      descripcionDetallada: 'Lagunas y nevados andinos.',
      tags: const [],
      rutaImagen: 'assets/destinos/ausangate.jpg',
      colorAccento: Color(0xFF2D432B),
      textoAccion: 'Explorar',
      subtextoAccion: '',
    ),
    DestinoExperiencia(
      id: 'vinicunca',
      ubicacionBadge: 'CUSCO',
      categoriaEtiqueta: 'CULTURA',
      tituloPrincipal: 'Moray',
      subtituloResaltado: '',
      descripcionDetallada: 'Laboratorio agricola inca.',
      tags: const [],
      rutaImagen: 'assets/destinos/moray.jpg',
      colorAccento: Color(0xFF6E8B4A),
      textoAccion: 'Explorar',
      subtextoAccion: '',
    ),
    DestinoExperiencia(
      id: 'cusco_imperial',
      ubicacionBadge: 'CUSCO',
      categoriaEtiqueta: 'EXPERIENCIA',
      tituloPrincipal: 'Aventura',
      subtituloResaltado: '',
      descripcionDetallada: 'Dunas, oasis y adrenalina.',
      tags: const [],
      rutaImagen: 'assets/destinos/huacachina.jpg',
      colorAccento: Color(0xFF3F5E3B),
      textoAccion: 'Explorar',
      subtextoAccion: '',
    ),
    DestinoExperiencia(
      id: 'llama_machu',
      ubicacionBadge: 'CUSCO',
      categoriaEtiqueta: 'DESCUBRE',
      tituloPrincipal: 'Cusco vivo',
      subtituloResaltado: '',
      descripcionDetallada: 'Encuentros con la tierra inca.',
      tags: const [],
      rutaImagen: 'assets/destinos/llama_machu.jpg',
      colorAccento: Color(0xFF3F5E3B),
      textoAccion: 'Explorar',
      subtextoAccion: '',
    ),
  ];
}
