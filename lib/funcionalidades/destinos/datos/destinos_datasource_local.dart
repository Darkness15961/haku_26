import 'package:flutter/material.dart';

import '../dominio/modelos/destino_experiencia.dart';

/// Fuente de datos local para la pantalla de Destinos e historias inmersivas.
class DestinosDataSourceLocal {
  static const List<DestinoExperiencia> obtenerDestinosExperiencia = [
    DestinoExperiencia(
      id: 'huancayo',
      ubicacionBadge: 'PERÚ · JUNÍN',
      categoriaEtiqueta: 'DESCUBRE',
      tituloPrincipal: 'Huancayo',
      subtituloResaltado: '& Huancán',
      descripcionDetallada:
          'Capital del Valle del Mantaro · Cultura Wanka · Gastronomía Andina · Paisajes únicos a 3,249 m.s.n.m.',
      tags: ['Torre Torre', 'Nevado', 'Gastronomía'],
      rutaImagen: 'https://images.unsplash.com/photo-1526392060635-9d6019884377?q=80&w=1000&auto=format&fit=crop',
      colorAccento: Color(0xFF2D6A4F),
      textoAccion: 'Comenzar Aventura',
      subtextoAccion: 'Personaliza tu experiencia de viaje',
    ),
    DestinoExperiencia(
      id: 'machupicchu',
      ubicacionBadge: 'PERÚ · CUSCO',
      categoriaEtiqueta: 'DESCUBRE',
      tituloPrincipal: 'Machu Picchu',
      subtituloResaltado: '& Valle Sagrado',
      descripcionDetallada:
          'Maravilla del Mundo · Santuario Histórico Inca · Valles Sagrados · Paisajes Místicos a 2,430 m.s.n.m.',
      tags: ['Santuario Inca', 'Camino Inca', 'Valle Sagrado'],
      rutaImagen: 'https://images.unsplash.com/photo-1509299349698-dd22323b5963?q=80&w=1000&auto=format&fit=crop',
      colorAccento: Color(0xFFF3C677),
      textoAccion: 'Explorar Santuario',
      subtextoAccion: 'Reserva tu boleto de ingreso oficial',
    ),
    DestinoExperiencia(
      id: 'cusco_imperial',
      ubicacionBadge: 'PERÚ · CUSCO',
      categoriaEtiqueta: 'DESCUBRE',
      tituloPrincipal: 'Cusco Imperial',
      subtituloResaltado: '& Sacsayhuamán',
      descripcionDetallada:
          'Capital del Tahuantinsuyo · Arquitectura Inca-Colonial · Templo del Qorikancha · Cultura Viva a 3,399 m.s.n.m.',
      tags: ['Centro Histórico', 'Qorikancha', 'Fortaleza'],
      rutaImagen: 'https://images.unsplash.com/photo-1589802829985-817e51171b92?q=80&w=1000&auto=format&fit=crop',
      colorAccento: Color(0xFFE0A94B),
      textoAccion: 'Recorrer la Ciudad',
      subtextoAccion: 'Descubre los pasajes ancestrales del inca',
    ),
    DestinoExperiencia(
      id: 'vinicunca',
      ubicacionBadge: 'PERÚ · CANCHIS',
      categoriaEtiqueta: 'DESCUBRE',
      tituloPrincipal: 'Vinicunca',
      subtituloResaltado: '& Montaña 7 Colores',
      descripcionDetallada:
          'Cordillera de Vilcanota · Minerales Milenarios · Trekking de Alta Montaña · Cumbres a 5,200 m.s.n.m.',
      tags: ['Montaña Arcoíris', 'Nevado Ausangate', 'Trekking'],
      rutaImagen: 'https://images.unsplash.com/photo-1580619305218-8423a7ef79b4?q=80&w=1000&auto=format&fit=crop',
      colorAccento: Color(0xFF40916C),
      textoAccion: 'Iniciar Caminata',
      subtextoAccion: 'Conoce los horarios y guía de aclimatación',
    ),
    DestinoExperiencia(
      id: 'humantay',
      ubicacionBadge: 'PERÚ · ANTA',
      categoriaEtiqueta: 'DESCUBRE',
      tituloPrincipal: 'Humantay',
      subtituloResaltado: '& Nevado Salkantay',
      descripcionDetallada:
          'Laguna Turquesa Glaciar · Ruta Mística Salkantay · Apu Sagrado Inca · Naturaleza Pura a 4,200 m.s.n.m.',
      tags: ['Laguna Turquesa', 'Apu Glaciar', 'Aventura'],
      rutaImagen: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=1000&auto=format&fit=crop',
      colorAccento: Color(0xFF1B4332),
      textoAccion: 'Ver Ruta Turquesa',
      subtextoAccion: 'Planifica tu transporte e itinerario',
    ),
  ];
}
