/// Catálogo local para opciones avanzadas al publicar (sin servicios externos).
class PistaMusicaDemo {
  const PistaMusicaDemo({
    required this.id,
    required this.titulo,
    required this.artista,
  });

  final String id;
  final String titulo;
  final String artista;

  String get etiqueta => '$titulo · $artista';
}

abstract final class CatalogoPublicacionDemo {
  static const pistasMusica = [
    PistaMusicaDemo(
      id: 'andes_quena',
      titulo: 'Sonido de los Andes',
      artista: 'Quena del Cusco',
    ),
    PistaMusicaDemo(
      id: 'wayna_picchu',
      titulo: 'Amanecer en Wayna',
      artista: 'Lucía & Charango',
    ),
    PistaMusicaDemo(
      id: 'camino_inca',
      titulo: 'Paso del Inca',
      artista: 'HAKU Sessions',
    ),
    PistaMusicaDemo(
      id: 'valle_sagrado',
      titulo: 'Valle Sagrado',
      artista: 'Zampoña Sur',
    ),
    PistaMusicaDemo(
      id: 'fogones_cusco',
      titulo: 'Fogones de Cusco',
      artista: 'María Quispe',
    ),
    PistaMusicaDemo(
      id: 'noche_plaza',
      titulo: 'Noche en la Plaza',
      artista: 'Diego Andes',
    ),
  ];

  static PistaMusicaDemo? pistaPorEtiqueta(String? etiqueta) {
    if (etiqueta == null || etiqueta.trim().isEmpty) return null;
    for (final p in pistasMusica) {
      if (p.etiqueta == etiqueta) return p;
    }
    return null;
  }
}
