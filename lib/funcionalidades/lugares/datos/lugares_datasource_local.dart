import '../dominio/modelos/modelo_lugar.dart';

/// Catálogo local + lugares creados en sesión (mutables).
class LugaresDataSourceLocal {
  LugaresDataSourceLocal._();
  static final instancia = LugaresDataSourceLocal._();

  final List<ModeloLugar> _creados = [];

  static const _seed = <ModeloLugar>[
    ModeloLugar(
      id: 'laguna_humantay',
      nombre: 'Laguna Humantay',
      descripcion:
          'Laguna turquesa al pie del nevado Humantay. Información enriquecida por la comunidad HAKU.',
      imagenUrl:
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
      galeria: const [
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
        'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&q=80',
      ],
      categoria: CategoriaLugar.naturaleza,
      provincia: 'Anta',
      distrito: 'Mollepata',
      distanciaKm: 24,
      calificacion: 4.8,
      exploradores: 6,
      fotos: 42,
      nivelExploracion: NivelExploracion.enCrecimiento,
      dificultad: 'Moderada',
      tiempoEstimado: '5–6 h',
      altitud: '4200 msnm',
      acceso: 'Caminata desde Soraypampa',
    ),
    ModeloLugar(
      id: 'canon_qeswachaka',
      nombre: 'Cañón Q’eswachaka',
      descripcion:
          'Puente inca vivo y cañón profundo. Descubierto recientemente en HAKU.',
      imagenUrl:
          'https://images.unsplash.com/photo-1548013146-72479768bada?w=800&q=80',
      categoria: CategoriaLugar.misterioso,
      provincia: 'Canas',
      distrito: 'Quehue',
      distanciaKm: 78,
      calificacion: 4.6,
      exploradores: 4,
      fotos: 12,
      nivelExploracion: NivelExploracion.nuevoEnHaku,
      dificultad: 'Fácil',
      tiempoEstimado: '3 h',
      altitud: '3700 msnm',
      acceso: 'Transporte + corto tramo a pie',
      descubiertoEn: null, // set relative in getter
    ),
    ModeloLugar(
      id: 'moray',
      nombre: 'Moray',
      descripcion: 'Anfiteatro agrícola inca con microclimas únicos.',
      imagenUrl: 'assets/destinos/moray.jpg',
      categoria: CategoriaLugar.cultura,
      provincia: 'Urubamba',
      distrito: 'Maras',
      distanciaKm: 38,
      calificacion: 4.7,
      exploradores: 32,
      fotos: 88,
      nivelExploracion: NivelExploracion.muyConocido,
      dificultad: 'Fácil',
      tiempoEstimado: '2 h',
      altitud: '3500 msnm',
      acceso: 'Auto o tour',
    ),
    ModeloLugar(
      id: 'ausangate_vista',
      nombre: 'Mirador Ausangate',
      descripcion: 'Vistas al nevado sagrado. Zona en crecimiento en HAKU.',
      imagenUrl: 'assets/destinos/ausangate.jpg',
      categoria: CategoriaLugar.caminata,
      provincia: 'Quispicanchi',
      distrito: 'Ocongate',
      distanciaKm: 95,
      calificacion: 4.9,
      exploradores: 11,
      fotos: 27,
      nivelExploracion: NivelExploracion.pocoExplorado,
      dificultad: 'Difícil',
      tiempoEstimado: '1 día',
      altitud: '4800 msnm',
      acceso: 'Trekking',
    ),
    ModeloLugar(
      id: 'machu_picchu',
      nombre: 'Machu Picchu',
      descripcion: 'Ciudadela inca. Muy documentada; aún se puede enriquecer.',
      imagenUrl: 'assets/destinos/machu_picchu.jpg',
      categoria: CategoriaLugar.cultura,
      provincia: 'Urubamba',
      distrito: 'Machupicchu',
      distanciaKm: 110,
      calificacion: 4.9,
      exploradores: 120,
      fotos: 400,
      nivelExploracion: NivelExploracion.muyConocido,
      dificultad: 'Moderada',
      tiempoEstimado: '1 día',
      altitud: '2430 msnm',
      acceso: 'Tren + bus',
    ),
    ModeloLugar(
      id: 'laguna_oculta',
      nombre: 'Laguna Escondida de Calca',
      descripcion: 'Poco explorada. Ideal para documentar.',
      imagenUrl:
          'https://images.unsplash.com/photo-1439066615861-d1af74d74000?w=800&q=80',
      categoria: CategoriaLugar.magico,
      provincia: 'Calca',
      distrito: 'Lares',
      distanciaKm: 52,
      calificacion: 4.5,
      exploradores: 2,
      fotos: 5,
      nivelExploracion: NivelExploracion.pocoExplorado,
      dificultad: 'Moderada',
      tiempoEstimado: '4 h',
      altitud: '3900 msnm',
      acceso: 'Caminata',
      descubiertoEn: null,
    ),
  ];

  List<ModeloLugar> todos() {
    final ahora = DateTime.now();
    return [
      ..._seed.map((l) {
        if (l.id == 'canon_qeswachaka') {
          return l.copyWith(
            descubiertoEn: ahora.subtract(const Duration(days: 2)),
          );
        }
        if (l.id == 'laguna_oculta') {
          return l.copyWith(
            descubiertoEn: ahora.subtract(const Duration(days: 5)),
          );
        }
        return l;
      }),
      ..._creados,
    ];
  }

  ModeloLugar? porId(String id) {
    for (final l in todos()) {
      if (l.id == id) return l;
    }
    return null;
  }

  List<ModeloLugar> porIntereses(Set<CategoriaLugar> intereses) {
    final lista = todos();
    if (intereses.isEmpty) return lista;
    return lista.where((l) => intereses.contains(l.categoria)).toList();
  }

  List<ModeloLugar> pocoExplorados() {
    return todos()
        .where(
          (l) =>
              l.nivelExploracion == NivelExploracion.pocoExplorado ||
              l.nivelExploracion == NivelExploracion.nuevoEnHaku,
        )
        .toList();
  }

  List<ModeloLugar> recientes() {
    final conFecha = todos().where((l) => l.descubiertoEn != null).toList()
      ..sort((a, b) => b.descubiertoEn!.compareTo(a.descubiertoEn!));
    return conFecha;
  }

  ModeloLugar sorpresa({Set<CategoriaLugar> intereses = const {}}) {
    final pool = intereses.isEmpty ? pocoExplorados() : porIntereses(intereses);
    final base = pool.isEmpty ? todos() : pool;
    base.shuffle();
    return base.first;
  }

  void agregar(ModeloLugar lugar) {
    _creados.insert(0, lugar);
  }
}
