import '../../../lugares/dominio/modelos/modelo_lugar.dart';
import 'modelo_ruta_propia.dart';

enum TipoRutaEscritura {
  senderismo('senderismo', 'Senderismo'),
  circuito('circuito', 'Circuito'),
  urbana('urbana', 'Urbana'),
  cultural('cultural', 'Cultural'),
  mixta('mixta', 'Mixta');

  const TipoRutaEscritura(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static TipoRutaEscritura desdeValor(Object? raw) {
    final valor = '$raw'.trim().toLowerCase();
    return TipoRutaEscritura.values.firstWhere(
      (t) => t.valor == valor,
      orElse: () => TipoRutaEscritura.senderismo,
    );
  }
}

enum DificultadRutaEscritura {
  facil('facil', 'Facil'),
  moderado('moderado', 'Moderada'),
  exigente('exigente', 'Exigente');

  const DificultadRutaEscritura(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static DificultadRutaEscritura desdeNivel(int nivel) {
    if (nivel <= 1) return DificultadRutaEscritura.facil;
    if (nivel >= 4) return DificultadRutaEscritura.exigente;
    return DificultadRutaEscritura.moderado;
  }
}

enum HiloRutaEscritura {
  camino('camino', 'Camino'),
  tejido('tejido', 'Tejido'),
  ceramica('ceramica', 'Ceramica'),
  comida('comida', 'Comida'),
  teatro('teatro', 'Teatro'),
  pintura('pintura', 'Pintura');

  const HiloRutaEscritura(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static HiloRutaEscritura desdeValor(Object? raw) {
    final valor = '$raw'.trim().toLowerCase();
    return HiloRutaEscritura.values.firstWhere(
      (h) => h.valor == valor,
      orElse: () => HiloRutaEscritura.camino,
    );
  }
}

class ParadaRutaEscritura {
  const ParadaRutaEscritura({
    required this.lugarId,
    required this.nombre,
    this.instrucciones = '',
    this.lat,
    this.lng,
  });

  factory ParadaRutaEscritura.desdeLugar(ModeloLugar lugar) {
    return ParadaRutaEscritura(
      lugarId: lugar.id,
      nombre: lugar.nombre,
      lat: lugar.latitud,
      lng: lugar.longitud,
    );
  }

  final String lugarId;
  final String nombre;
  final String instrucciones;
  final double? lat;
  final double? lng;

  Map<String, dynamic> toRpcJson() => {
    'lugar_id': lugarId,
    if (instrucciones.trim().isNotEmpty) 'instrucciones': instrucciones.trim(),
  };
}

class SolicitudCrearRuta {
  const SolicitudCrearRuta({
    required this.nombre,
    required this.resumen,
    required this.descripcion,
    required this.paradas,
    this.fotoPortadaUrl,
    this.tipo = TipoRutaEscritura.senderismo,
    this.dificultad = DificultadRutaEscritura.moderado,
    this.hilo = HiloRutaEscritura.camino,
    this.zona = '',
    this.acceso = '',
    this.transporte = '',
    this.requisitos = const [],
    this.advertencias = const [],
    this.etiquetas = const [],
  });

  factory SolicitudCrearRuta.desdeRutaPropia(ModeloRutaPropia propia) {
    final ruta = propia.ruta;
    return SolicitudCrearRuta(
      nombre: ruta.titulo,
      resumen: ruta.subtitulo,
      descripcion: ruta.descripcion,
      fotoPortadaUrl: ruta.imagenUrl.trim().isEmpty ? null : ruta.imagenUrl,
      tipo: TipoRutaEscritura.desdeValor(ruta.tipoSitio),
      dificultad: DificultadRutaEscritura.desdeNivel(ruta.nivelDificultad),
      hilo: HiloRutaEscritura.desdeValor(ruta.hilo.name),
      zona: ruta.provincia,
      acceso: ruta.comoLlegar,
      transporte: ruta.transporte,
      requisitos: ruta.requisitos,
      advertencias: ruta.advertencias,
      etiquetas: ruta.etiquetas,
      paradas: ruta.puntos
          .where((p) => (p.lugarId ?? '').trim().isNotEmpty)
          .map(
            (p) => ParadaRutaEscritura(
              lugarId: p.lugarId!,
              nombre: p.nombre,
              instrucciones: p.nota ?? '',
              lat: p.lat,
              lng: p.lng,
            ),
          )
          .toList(growable: false),
    );
  }

  final String nombre;
  final String resumen;
  final String descripcion;
  final String? fotoPortadaUrl;
  final TipoRutaEscritura tipo;
  final DificultadRutaEscritura dificultad;
  final HiloRutaEscritura hilo;
  final String zona;
  final String acceso;
  final String transporte;
  final List<String> requisitos;
  final List<String> advertencias;
  final List<String> etiquetas;
  final List<ParadaRutaEscritura> paradas;

  String? validar() {
    if (nombre.trim().isEmpty) return 'Escribe el nombre de la Ruta';
    if (nombre.trim().length > 120) {
      return 'El nombre no puede superar 120 caracteres';
    }
    if (resumen.trim().isEmpty) return 'Escribe un resumen corto de la Ruta';
    if (resumen.trim().length > 240) {
      return 'El resumen no puede superar 240 caracteres';
    }
    if (descripcion.trim().isEmpty) {
      return 'Escribe una descripcion para la Ruta';
    }
    final ids = <String>{};
    for (final parada in paradas) {
      final id = parada.lugarId.trim();
      if (id.isEmpty || int.tryParse(id) == null) {
        return 'Hay un Lugar invalido en el itinerario';
      }
      if (!ids.add(id)) return 'No repitas el mismo Lugar en la Ruta';
    }
    if (paradas.length < 2) return 'Elige al menos dos Lugares';
    if (zona.trim().isEmpty) return 'Confirma la zona de la Ruta';
    if (acceso.trim().isEmpty) return 'Elige el acceso de la Ruta';
    if (_limpiarLista(requisitos).isEmpty) {
      return 'Agrega al menos un requisito';
    }
    if (_limpiarLista(advertencias).isEmpty) {
      return 'Agrega al menos una advertencia';
    }
    return null;
  }

  Map<String, dynamic> toRpcParams() => {
    'p_nombre': nombre.trim(),
    'p_resumen': resumen.trim(),
    'p_descripcion': descripcion.trim(),
    'p_foto_portada': fotoPortadaUrl?.trim() ?? '',
    'p_tipo': tipo.valor,
    'p_dificultad': dificultad.valor,
    'p_hilo_cultural': hilo.valor,
    'p_zona': zona.trim(),
    'p_acceso': acceso.trim(),
    'p_transporte': transporte.trim(),
    'p_requisitos': _limpiarLista(requisitos),
    'p_advertencias': _limpiarLista(advertencias),
    'p_etiquetas': _limpiarLista(etiquetas),
    'p_paradas': paradas.map((p) => p.toRpcJson()).toList(growable: false),
  };

  Map<String, dynamic> toGuardarRpcParams({
    required String? rutaId,
    required bool publicar,
  }) {
    return {
      'p_ruta_id': int.tryParse((rutaId ?? '').trim()),
      'p_publicar': publicar,
      ...toRpcParams(),
    };
  }

  static List<String> _limpiarLista(List<String> valores) {
    return valores
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}

List<String> listaTextoCsv(String raw) {
  return raw
      .split(',')
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .toList(growable: false);
}
