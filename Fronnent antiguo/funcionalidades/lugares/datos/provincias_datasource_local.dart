import '../dominio/modelos/modelo_lugar.dart';

/// Provincia de Cusco con assets locales (SVG silueta + PNG portada).
class ProvinciaCatalogo {
  final String id;
  final String nombre;
  final String nombreCorto;
  final String rutaSvg;
  final String rutaPng;
  final String capital;

  const ProvinciaCatalogo({
    required this.id,
    required this.nombre,
    required this.nombreCorto,
    required this.rutaSvg,
    required this.rutaPng,
    required this.capital,
  });
}

/// Catálogo local de las 13 provincias + utilidades de agrupación.
abstract final class ProvinciasDataSourceLocal {
  static const todas = <ProvinciaCatalogo>[
    ProvinciaCatalogo(
      id: 'cusco',
      nombre: 'Cusco',
      nombreCorto: 'Cusco',
      rutaSvg: 'assets/mapas/cusco.svg',
      rutaPng: 'assets/provincias/cusco.png',
      capital: 'Cusco',
    ),
    ProvinciaCatalogo(
      id: 'urubamba',
      nombre: 'Urubamba',
      nombreCorto: 'Urubamba',
      rutaSvg: 'assets/mapas/urubamba.svg',
      rutaPng: 'assets/provincias/URUBAMBA.png',
      capital: 'Urubamba',
    ),
    ProvinciaCatalogo(
      id: 'calca',
      nombre: 'Calca',
      nombreCorto: 'Calca',
      rutaSvg: 'assets/mapas/calca.svg',
      rutaPng: 'assets/provincias/CALCA.png',
      capital: 'Calca',
    ),
    ProvinciaCatalogo(
      id: 'anta',
      nombre: 'Anta',
      nombreCorto: 'Anta',
      rutaSvg: 'assets/mapas/anta.svg',
      rutaPng: 'assets/provincias/ANTA.png',
      capital: 'Anta',
    ),
    ProvinciaCatalogo(
      id: 'quispicanchi',
      nombre: 'Quispicanchi',
      nombreCorto: 'Quispicanchi',
      rutaSvg: 'assets/mapas/quispicanchi.svg',
      rutaPng: 'assets/provincias/QUISPICANCHI.png',
      capital: 'Urcos',
    ),
    ProvinciaCatalogo(
      id: 'paucartambo',
      nombre: 'Paucartambo',
      nombreCorto: 'Paucartambo',
      rutaSvg: 'assets/mapas/paucartambo.svg',
      rutaPng: 'assets/provincias/PAUCARTAMBO.png',
      capital: 'Paucartambo',
    ),
    ProvinciaCatalogo(
      id: 'la_convencion',
      nombre: 'La Convención',
      nombreCorto: 'La Convención',
      rutaSvg: 'assets/mapas/la_convencion.svg',
      rutaPng: 'assets/provincias/LACONVENCION.png',
      capital: 'Quillabamba',
    ),
    ProvinciaCatalogo(
      id: 'canas',
      nombre: 'Canas',
      nombreCorto: 'Canas',
      rutaSvg: 'assets/mapas/canas.svg',
      rutaPng: 'assets/provincias/CANAS.png',
      capital: 'Yanaoca',
    ),
    ProvinciaCatalogo(
      id: 'canchis',
      nombre: 'Canchis',
      nombreCorto: 'Canchis',
      rutaSvg: 'assets/mapas/canchis.svg',
      rutaPng: 'assets/provincias/CANCHIS.png',
      capital: 'Sicuani',
    ),
    ProvinciaCatalogo(
      id: 'acomayo',
      nombre: 'Acomayo',
      nombreCorto: 'Acomayo',
      rutaSvg: 'assets/mapas/acomayo.svg',
      rutaPng: 'assets/provincias/ACOMAYO.png',
      capital: 'Acomayo',
    ),
    ProvinciaCatalogo(
      id: 'paruro',
      nombre: 'Paruro',
      nombreCorto: 'Paruro',
      rutaSvg: 'assets/mapas/paruro.svg',
      rutaPng: 'assets/provincias/PARURO.png',
      capital: 'Paruro',
    ),
    ProvinciaCatalogo(
      id: 'chumbivilcas',
      nombre: 'Chumbivilcas',
      nombreCorto: 'Chumbivilcas',
      rutaSvg: 'assets/mapas/chumbivilcas.svg',
      rutaPng: 'assets/provincias/CHUMBIVILCAS.png',
      capital: 'Santo Tomás',
    ),
    ProvinciaCatalogo(
      id: 'espinar',
      nombre: 'Espinar',
      nombreCorto: 'Espinar',
      rutaSvg: 'assets/mapas/espinar.svg',
      rutaPng: 'assets/provincias/ESPINAR.png',
      capital: 'Yauri',
    ),
  ];

  static String normalizar(String nombre) {
    final n = nombre.trim().toLowerCase();
    return n
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  static ProvinciaCatalogo? porNombre(String nombre) {
    final key = normalizar(nombre);
    for (final p in todas) {
      if (normalizar(p.nombre) == key) return p;
    }
    // Alias frecuentes
    if (key.contains('convencion')) {
      return todas.firstWhere((p) => p.id == 'la_convencion');
    }
    return null;
  }

  /// Prioriza nuevos / poco explorados, luego calificación.
  static int _prioridad(ModeloLugar l) {
    final nivel = switch (l.nivelExploracion) {
      NivelExploracion.nuevoEnHaku => 300,
      NivelExploracion.pocoExplorado => 200,
      NivelExploracion.enCrecimiento => 100,
      NivelExploracion.muyConocido => 0,
    };
    return nivel + (l.calificacion * 10).round() + (l.creadoPorUsuario ? 50 : 0);
  }

  static List<ModeloLugar> ordenarDestacados(List<ModeloLugar> lugares) {
    final lista = [...lugares];
    lista.sort((a, b) => _prioridad(b).compareTo(_prioridad(a)));
    return lista;
  }

  /// Todas las provincias del catálogo (también vacías, para el path completo).
  static List<IslaProvinciaData> construirIslas(List<ModeloLugar> lugares) {
    final porProvincia = <String, List<ModeloLugar>>{};
    for (final l in lugares) {
      final cat = porNombre(l.provincia);
      if (cat == null) continue;
      (porProvincia[cat.id] ??= []).add(l);
    }

    final islas = <IslaProvinciaData>[];
    for (final p in todas) {
      final lista = porProvincia[p.id] ?? const <ModeloLugar>[];
      final ordenados = ordenarDestacados(lista);
      final nuevos = ordenados
          .where(
            (l) =>
                l.nivelExploracion == NivelExploracion.nuevoEnHaku ||
                l.nivelExploracion == NivelExploracion.pocoExplorado ||
                l.creadoPorUsuario,
          )
          .length;
      islas.add(
        IslaProvinciaData(
          provincia: p,
          lugares: ordenados,
          destacados: ordenados.take(4).toList(),
          cantidadNuevos: nuevos,
        ),
      );
    }

    // Con contenido primero; vacías al final del carrusel.
    islas.sort((a, b) {
      final vacA = a.lugares.isEmpty ? 1 : 0;
      final vacB = b.lugares.isEmpty ? 1 : 0;
      if (vacA != vacB) return vacA.compareTo(vacB);
      final c = b.cantidadNuevos.compareTo(a.cantidadNuevos);
      if (c != 0) return c;
      return b.lugares.length.compareTo(a.lugares.length);
    });
    return islas;
  }
}

class IslaProvinciaData {
  final ProvinciaCatalogo provincia;
  final List<ModeloLugar> lugares;
  final List<ModeloLugar> destacados;
  final int cantidadNuevos;

  const IslaProvinciaData({
    required this.provincia,
    required this.lugares,
    required this.destacados,
    required this.cantidadNuevos,
  });
}
