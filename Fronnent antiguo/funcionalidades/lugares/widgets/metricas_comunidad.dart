import '../../../nucleo/recursos/copy_haku.dart';
import '../../inicio/datos/feed_inicio_datasource_local.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';

/// Métricas derivadas de publicaciones de experiencia (un solo barrido).
class MetricasExperienciaComunidad {
  const MetricasExperienciaComunidad({
    required this.experiencias,
    required this.fotosUrls,
    required this.exploradores,
    required this.valoraciones,
    this.calificacionPromedio,
  });

  static const vacias = MetricasExperienciaComunidad(
    experiencias: [],
    fotosUrls: [],
    exploradores: 0,
    valoraciones: 0,
  );

  final List<PublicacionFeed> experiencias;
  final List<String> fotosUrls;
  final int exploradores;
  final int valoraciones;
  final double? calificacionPromedio;

  int get fotos => fotosUrls.length;

  bool get tieneComunidad => experiencias.isNotEmpty;

  double calificacionMostrar(double catalogo) =>
      calificacionPromedio ?? catalogo;

  int resenasMostrar(int catalogoResenas) =>
      calificacionPromedio != null ? valoraciones : catalogoResenas;

  String get etiquetaFotos => MetricasComunidad.etiquetaFotos(fotos);

  String get etiquetaExploradores =>
      MetricasComunidad.etiquetaExploradores(exploradores);
}

/// Índice por lugar (feed / explora — un solo recorrido del feed).
class IndiceMetricasLugares {
  const IndiceMetricasLugares({
    required this.fotos,
    required this.exploradores,
    required this.calificaciones,
  });

  static const vacio = IndiceMetricasLugares(
    fotos: {},
    exploradores: {},
    calificaciones: {},
  );

  final Map<String, int> fotos;
  final Map<String, int> exploradores;
  final Map<String, double> calificaciones;

  int totalFotos() => fotos.values.fold(0, (s, n) => s + n);
}

/// Índice por ruta (carruseles / tarjetas — un solo recorrido del feed).
class IndiceMetricasRutas {
  const IndiceMetricasRutas({
    required this.fotos,
    required this.exploradores,
    required this.calificaciones,
    required this.valoraciones,
  });

  static const vacio = IndiceMetricasRutas(
    fotos: {},
    exploradores: {},
    calificaciones: {},
    valoraciones: {},
  );

  final Map<String, int> fotos;
  final Map<String, int> exploradores;
  final Map<String, double> calificaciones;
  final Map<String, int> valoraciones;
}

/// Cálculo centralizado de fotos, exploradores y valoración comunitaria.
abstract final class MetricasComunidad {
  static List<PublicacionFeed> experienciasDe(
    List<PublicacionFeed> todas, {
    String? lugarId,
    String? rutaId,
  }) {
    assert(
      lugarId != null || rutaId != null,
      'Indica lugarId o rutaId',
    );
    final lista = todas.where((p) {
      if (p.esInvitacionSalida) return false;
      if (lugarId != null && p.lugarId == lugarId) return true;
      if (rutaId != null && p.rutaId == rutaId) return true;
      return false;
    }).toList();
    lista.sort((a, b) {
      final ta = a.creadoEn ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.creadoEn ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });
    return lista;
  }

  static MetricasExperienciaComunidad calcular(
    List<PublicacionFeed> publicaciones, {
    String? lugarId,
    String? rutaId,
  }) {
    final experiencias = experienciasDe(
      publicaciones,
      lugarId: lugarId,
      rutaId: rutaId,
    );
    if (experiencias.isEmpty) return MetricasExperienciaComunidad.vacias;

    final fotosVistas = <String>{};
    final fotosUrls = <String>[];
    final autores = <String>{};
    final notas = <double>[];

    for (final p in experiencias) {
      final url = p.imagenUrl?.trim();
      if (url != null && url.isNotEmpty && fotosVistas.add(url)) {
        fotosUrls.add(url);
      }
      final autor = p.autorId.trim();
      if (autor.isNotEmpty) autores.add(autor);
      final nota = p.calificacion;
      if (nota != null && nota > 0) notas.add(nota);
    }

    return MetricasExperienciaComunidad(
      experiencias: experiencias,
      fotosUrls: fotosUrls,
      exploradores: autores.length,
      valoraciones: notas.length,
      calificacionPromedio:
          notas.isEmpty ? null : notas.reduce((a, b) => a + b) / notas.length,
    );
  }

  static IndiceMetricasLugares indiceLugares(List<PublicacionFeed> todas) {
    final fotosSets = <String, Set<String>>{};
    final autores = <String, Set<String>>{};
    final notas = <String, List<double>>{};

    for (final p in todas) {
      if (p.esInvitacionSalida) continue;
      final id = p.lugarId?.trim();
      if (id == null || id.isEmpty) continue;

      final url = p.imagenUrl?.trim();
      if (url != null && url.isNotEmpty) {
        fotosSets.putIfAbsent(id, () => {}).add(url);
      }
      final autor = p.autorId.trim();
      if (autor.isNotEmpty) {
        autores.putIfAbsent(id, () => {}).add(autor);
      }
      final nota = p.calificacion;
      if (nota != null && nota > 0) {
        notas.putIfAbsent(id, () => []).add(nota);
      }
    }

    return IndiceMetricasLugares(
      fotos: {for (final e in fotosSets.entries) e.key: e.value.length},
      exploradores: {for (final e in autores.entries) e.key: e.value.length},
      calificaciones: {
        for (final e in notas.entries)
          e.key: e.value.reduce((a, b) => a + b) / e.value.length,
      },
    );
  }

  static IndiceMetricasRutas indiceRutas(List<PublicacionFeed> todas) {
    final fotosSets = <String, Set<String>>{};
    final autores = <String, Set<String>>{};
    final notas = <String, List<double>>{};

    for (final p in todas) {
      if (p.esInvitacionSalida) continue;
      final id = p.rutaId?.trim();
      if (id == null || id.isEmpty) continue;

      final url = p.imagenUrl?.trim();
      if (url != null && url.isNotEmpty) {
        fotosSets.putIfAbsent(id, () => {}).add(url);
      }
      final autor = p.autorId.trim();
      if (autor.isNotEmpty) {
        autores.putIfAbsent(id, () => {}).add(autor);
      }
      final nota = p.calificacion;
      if (nota != null && nota > 0) {
        notas.putIfAbsent(id, () => []).add(nota);
      }
    }

    return IndiceMetricasRutas(
      fotos: {for (final e in fotosSets.entries) e.key: e.value.length},
      exploradores: {for (final e in autores.entries) e.key: e.value.length},
      calificaciones: {
        for (final e in notas.entries)
          e.key: e.value.reduce((a, b) => a + b) / e.value.length,
      },
      valoraciones: {for (final e in notas.entries) e.key: e.value.length},
    );
  }

  /// Aplica ★ y reseñas comunitarias sobre el catálogo (tarjetas / carruseles).
  static ModeloRuta enriquecerRuta(
    ModeloRuta ruta,
    IndiceMetricasRutas indice,
  ) {
    if (ruta.id.startsWith('lugar_')) return ruta;
    final calComunidad = indice.calificaciones[ruta.id];
    if (calComunidad == null) return ruta;
    return ruta.copyWith(
      calificacion: calComunidad,
      cantidadResenas: indice.valoraciones[ruta.id] ?? 0,
    );
  }

  static List<ModeloRuta> enriquecerRutas(
    Iterable<ModeloRuta> rutas,
    IndiceMetricasRutas indice,
  ) =>
      [for (final r in rutas) enriquecerRuta(r, indice)];

  static String etiquetaFotos(int cantidad) {
    if (cantidad <= 0) return '';
    return cantidad == 1 ? '1 foto' : '$cantidad fotos';
  }

  static String etiquetaExploradores(int cantidad) =>
      CopyHaku.etiquetaVecinos(cantidad);

  static String resumenFotosExploradores({
    required int fotos,
    required int exploradores,
  }) {
    final partes = <String>[];
    final f = etiquetaFotos(fotos);
    if (f.isNotEmpty) partes.add(f);
    final e = etiquetaExploradores(exploradores);
    if (e.isNotEmpty) partes.add(e);
    return partes.join(' · ');
  }
}
