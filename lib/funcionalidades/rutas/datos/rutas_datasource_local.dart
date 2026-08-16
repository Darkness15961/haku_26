import '../dominio/modelos/modelo_ruta.dart';

/// Fuente local de rutas (preparada para reemplazo por backend).
class RutasDataSourceLocal {
  static const List<ModeloRuta> _rutas = [
    ModeloRuta(
      id: 'ruta_inca_clasica',
      titulo: 'Ruta Inca Clásica',
      subtitulo: 'Camino ancestral al santuario',
      descripcion:
          'El legendario Camino Inca hasta Machu Picchu. Cuatro días de trekking entre bosques de nubes, ruinas y vistas inolvidables del Valle Sagrado.',
      imagenUrl:
          'https://images.unsplash.com/photo-1587595431973-160d0d94add1?q=80&w=1000&auto=format&fit=crop',
      categoria: CategoriaRuta.recomendadas,
      cantidadLugares: 5,
      dias: 4,
      distancia: '42 km',
      nivelDificultad: 4,
      dificultadTexto: 'Alta',
      altitud: '4,200 m.s.n.m.',
      tiempoCaminata: '4 días',
      mejorEpoca: 'Mayo - Septiembre',
      etiquetas: ['Aventura', 'Historia', 'Trekking'],
      calificacion: 4.9,
      cantidadResenas: 3120,
      textoBoton: 'Cómo llegar',
      tipoSitio: 'Trekking',
    ),
    ModeloRuta(
      id: 'valle_sagrado',
      titulo: 'Valle Sagrado',
      subtitulo: 'Pisac, Ollantaytambo y más',
      descripcion:
          'Recorre los pueblos vivos del Valle Sagrado: mercados, terrazas agrícolas y fortalezas incas en un circuito de dos días.',
      imagenUrl:
          'https://images.unsplash.com/photo-1526392060635-9d6019884377?q=80&w=1000&auto=format&fit=crop',
      categoria: CategoriaRuta.recomendadas,
      cantidadLugares: 6,
      dias: 2,
      distancia: '85 km',
      nivelDificultad: 2,
      dificultadTexto: 'Moderada',
      altitud: '2,800 m.s.n.m.',
      tiempoCaminata: '2 días',
      mejorEpoca: 'Abril - Octubre',
      etiquetas: ['Cultura', 'Pueblos', 'Miradores'],
      calificacion: 4.7,
      cantidadResenas: 2180,
      textoBoton: 'Ver en el mapa',
      tipoSitio: 'Circuito',
    ),
    ModeloRuta(
      id: 'cusco_historico',
      titulo: 'Cusco Histórico',
      subtitulo: 'Centro y Sacsayhuamán',
      descripcion:
          'Camina el casco histórico cusqueño: Plaza de Armas, Qorikancha y la fortaleza de Sacsayhuamán en una jornada cultural intensa.',
      imagenUrl:
          'https://images.unsplash.com/photo-1589802829985-817e51171b92?q=80&w=1000&auto=format&fit=crop',
      categoria: CategoriaRuta.recomendadas,
      cantidadLugares: 4,
      dias: 1,
      distancia: '8 km',
      nivelDificultad: 1,
      dificultadTexto: 'Baja',
      altitud: '3,399 m.s.n.m.',
      tiempoCaminata: '5 - 6 horas',
      mejorEpoca: 'Todo el año',
      etiquetas: ['Historia', 'Ciudad', 'Arquitectura'],
      calificacion: 4.8,
      cantidadResenas: 4560,
      textoBoton: 'Iniciar aventura',
      tipoSitio: 'Urbana',
    ),
    ModeloRuta(
      id: 'machu_picchu',
      titulo: 'Machu Picchu',
      subtitulo: 'Maravilla del Mundo',
      descripcion:
          'La ciudadela inca más famosa del mundo. Explora templos, plazas y terrazas con vistas al valle del Urubamba.',
      imagenUrl:
          'https://images.unsplash.com/photo-1509299349698-dd22323b5963?q=80&w=1000&auto=format&fit=crop',
      categoria: CategoriaRuta.populares,
      cantidadLugares: 3,
      dias: 1,
      distancia: '12 km',
      nivelDificultad: 2,
      dificultadTexto: 'Moderada',
      altitud: '2,430 m.s.n.m.',
      tiempoCaminata: '3 - 4 horas',
      mejorEpoca: 'Mayo - Septiembre',
      etiquetas: ['Sitio Arqueológico', 'Patrimonio', 'Mirador'],
      calificacion: 4.8,
      cantidadResenas: 2345,
      textoBoton: 'Ver en el mapa',
      tipoSitio: 'Sitio Arqueológico',
    ),
    ModeloRuta(
      id: 'laguna_humantay',
      titulo: 'Laguna Humantay',
      subtitulo: 'Turquesa bajo el Apu',
      descripcion:
          'Ascenso hacia una laguna glaciar de aguas turquesas al pie del nevado Humantay. Una de las caminatas más fotogénicas de Cusco.',
      imagenUrl:
          'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=1000&auto=format&fit=crop',
      categoria: CategoriaRuta.naturaleza,
      cantidadLugares: 2,
      dias: 1,
      distancia: '6 km',
      nivelDificultad: 3,
      dificultadTexto: 'Moderada',
      altitud: '4,200 m.s.n.m.',
      tiempoCaminata: '1.5 - 2 horas',
      mejorEpoca: 'Abril - Octubre',
      etiquetas: ['Naturaleza', 'Aventura', 'Fotografía'],
      calificacion: 4.9,
      cantidadResenas: 1890,
      textoBoton: 'Cómo llegar',
      tipoSitio: 'Naturaleza',
    ),
    ModeloRuta(
      id: 'vinicunca',
      titulo: 'Montaña de 7 Colores',
      subtitulo: 'Vinicunca y Ausangate',
      descripcion:
          'Trekking de alta montaña hacia Vinicunca, la montaña arcoíris. Paisajes extremos, minerales y el imponente Ausangate.',
      imagenUrl:
          'https://images.unsplash.com/photo-1580619305218-8423a7ef79b4?q=80&w=1000&auto=format&fit=crop',
      categoria: CategoriaRuta.naturaleza,
      cantidadLugares: 3,
      dias: 1,
      distancia: '10 km',
      nivelDificultad: 4,
      dificultadTexto: 'Alta',
      altitud: '5,200 m.s.n.m.',
      tiempoCaminata: '5 - 6 horas',
      mejorEpoca: 'Abril - Octubre',
      etiquetas: ['Naturaleza', 'Trekking', 'Alta montaña'],
      calificacion: 4.6,
      cantidadResenas: 2740,
      textoBoton: 'Iniciar aventura',
      tipoSitio: 'Trekking',
    ),
    ModeloRuta(
      id: 'maras_moray',
      titulo: 'Maras y Moray',
      subtitulo: 'Salineras y laboratorios incas',
      descripcion:
          'Combina las terrazas circulares de Moray con las salineras de Maras en un día de paisaje y cultura andina.',
      imagenUrl:
          'https://images.unsplash.com/photo-1531065204914-ece6be9353f2?q=80&w=1000&auto=format&fit=crop',
      categoria: CategoriaRuta.populares,
      cantidadLugares: 2,
      dias: 1,
      distancia: '15 km',
      nivelDificultad: 1,
      dificultadTexto: 'Baja',
      altitud: '3,500 m.s.n.m.',
      tiempoCaminata: '4 - 5 horas',
      mejorEpoca: 'Todo el año',
      etiquetas: ['Cultura', 'Paisaje', 'Fotografía'],
      calificacion: 4.7,
      cantidadResenas: 1650,
      textoBoton: 'Ver ruta',
      tipoSitio: 'Circuito',
    ),
  ];

  static List<ModeloRuta> obtenerTodas() => List.unmodifiable(_rutas);

  static List<ModeloRuta> obtenerPorCategoria(CategoriaRuta categoria) {
    return _rutas.where((r) => r.categoria == categoria).toList();
  }

  static ModeloRuta? obtenerPorId(String id) {
    try {
      return _rutas.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
