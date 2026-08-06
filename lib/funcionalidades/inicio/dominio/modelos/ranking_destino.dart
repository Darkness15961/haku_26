import 'destino_destacado.dart';

/// Modelo que agrupa el ranking de destinos de un mes específico.
///
/// Contiene la lista de destinos más visitados/populares para una
/// provincia específica o para toda la región en un periodo determinado.
class RankingDestino {
  final int mes;
  final int anio;
  final String? provinciaId;
  final List<DestinoDestacado> destinos;

  const RankingDestino({
    required this.mes,
    required this.anio,
    this.provinciaId,
    required this.destinos,
  });

  /// Retorna el Top N destinos del ranking.
  List<DestinoDestacado> topN(int n) {
    final ordenados = List<DestinoDestacado>.from(destinos)
      ..sort((a, b) => a.posicion.compareTo(b.posicion));
    return ordenados.take(n).toList();
  }

  /// Retorna el nombre del mes en español.
  String get nombreMes {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return meses[mes - 1];
  }

  RankingDestino copyWith({
    int? mes,
    int? anio,
    String? provinciaId,
    List<DestinoDestacado>? destinos,
  }) {
    return RankingDestino(
      mes: mes ?? this.mes,
      anio: anio ?? this.anio,
      provinciaId: provinciaId ?? this.provinciaId,
      destinos: destinos ?? this.destinos,
    );
  }
}
