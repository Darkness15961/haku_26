import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import 'feed_inicio_datasource_local.dart';

export '../../comunidad/dominio/modelo_comunidad.dart';

/// Estado en memoria de grupos y comunidades (demo).
class MensajeriaEstado {
  MensajeriaEstado._();
  static final MensajeriaEstado instancia = MensajeriaEstado._();

  final List<GrupoRuta> grupos = [
    GrupoRuta(
      id: 'g_demo',
      nombre: 'Humantay Team',
      creadorId: 'yo',
      esCreador: true,
      rutaId: 'laguna_humantay',
      rutaTitulo: 'Laguna Humantay',
      miembroIds: const ['s1', 's2'],
      ultimoMensaje: 'Nos vemos a las 5 am en el punto.',
      hace: '40m',
    ),
  ];

  void agregarGrupo(GrupoRuta grupo) => grupos.insert(0, grupo);

  void eliminarGrupo(String id) => grupos.removeWhere((g) => g.id == id);

  void reemplazarGrupos(List<GrupoRuta> lista) {
    grupos
      ..clear()
      ..addAll(lista);
  }
}

/// Datos demo de mensajería 1:1.
class MensajesDataSourceLocal {
  static const List<ChatConversacion> chats = [
    ChatConversacion(
      id: 'mariaq',
      nombre: 'María Quispe',
      usuario: '@mariaq',
      avatarUrl: CatalogoImagenesHaku.avatar,
      ultimoMensaje: '¿Salimos mañana a Sacsayhuamán?',
      hace: '12m',
      noLeidos: 2,
    ),
    ChatConversacion(
      id: 's1',
      nombre: 'Andina Trek',
      usuario: '@andinatrek',
      avatarUrl: CatalogoImagenesHaku.avatar,
      ultimoMensaje: 'Te envié el itinerario del Valle.',
      hace: '1h',
      noLeidos: 0,
    ),
    ChatConversacion(
      id: 'diegoandes',
      nombre: 'Diego Andes',
      usuario: '@diegoandes',
      avatarUrl: CatalogoImagenesHaku.avatar,
      ultimoMensaje: 'Lleva bastones para Humantay 👍',
      hace: '3h',
      noLeidos: 1,
    ),
    ChatConversacion(
      id: 'sofiatrek',
      nombre: 'Sofía Trek',
      usuario: '@sofiatrek',
      avatarUrl: CatalogoImagenesHaku.avatar,
      ultimoMensaje: 'Vinicunca quedó brutal.',
      hace: 'Ayer',
      noLeidos: 0,
    ),
    ChatConversacion(
      id: 's3',
      nombre: 'Cusco Walks',
      usuario: '@cuscowalks',
      avatarUrl: CatalogoImagenesHaku.avatar,
      ultimoMensaje: '¿Te interesa el tour urbano?',
      hace: '2d',
      noLeidos: 0,
    ),
  ];

  static List<GrupoRuta> get grupos => MensajeriaEstado.instancia.grupos;
}

class ChatConversacion {
  final String id;
  final String nombre;
  final String usuario;
  final String avatarUrl;
  final String ultimoMensaje;
  final String hace;
  final int noLeidos;

  const ChatConversacion({
    required this.id,
    required this.nombre,
    required this.usuario,
    required this.avatarUrl,
    required this.ultimoMensaje,
    required this.hace,
    required this.noLeidos,
  });

  ChatConversacion copyWith({
    String? ultimoMensaje,
    String? hace,
    int? noLeidos,
  }) {
    return ChatConversacion(
      id: id,
      nombre: nombre,
      usuario: usuario,
      avatarUrl: avatarUrl,
      ultimoMensaje: ultimoMensaje ?? this.ultimoMensaje,
      hace: hace ?? this.hace,
      noLeidos: noLeidos ?? this.noLeidos,
    );
  }
}

class GrupoRuta {
  final String id;
  final String nombre;
  final String creadorId;
  final bool esCreador;
  final String rutaId;
  final String rutaTitulo;
  final List<String> miembroIds;
  final String ultimoMensaje;
  final String hace;

  const GrupoRuta({
    required this.id,
    required this.nombre,
    required this.creadorId,
    required this.esCreador,
    required this.rutaId,
    required this.rutaTitulo,
    required this.miembroIds,
    this.ultimoMensaje = 'Grupo creado. ¡Buena ruta!',
    this.hace = 'ahora',
  });

  factory GrupoRuta.crear({
    required String nombre,
    required ModeloRuta ruta,
    required List<String> miembroIds,
  }) {
    return GrupoRuta(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
      nombre: nombre,
      creadorId: 'yo',
      esCreador: true,
      rutaId: ruta.id,
      rutaTitulo: ruta.titulo,
      miembroIds: List.unmodifiable(miembroIds),
    );
  }

  Map<String, dynamic> aMapa() => {
        'id': id,
        'nombre': nombre,
        'creador_id': creadorId,
        'es_creador': esCreador,
        'ruta_id': rutaId,
        'ruta_titulo': rutaTitulo,
        'miembro_ids': miembroIds,
        'ultimo_mensaje': ultimoMensaje,
        'hace': hace,
      };

  factory GrupoRuta.desdeMapa(Map<String, dynamic> m) {
    return GrupoRuta(
      id: m['id'] as String? ?? '',
      nombre: m['nombre'] as String? ?? '',
      creadorId: m['creador_id'] as String? ?? '',
      esCreador: m['es_creador'] as bool? ?? false,
      rutaId: m['ruta_id'] as String? ?? '',
      rutaTitulo: m['ruta_titulo'] as String? ?? '',
      miembroIds: [
        for (final x in (m['miembro_ids'] as List<dynamic>? ?? []))
          x.toString(),
      ],
      ultimoMensaje: m['ultimo_mensaje'] as String? ?? '',
      hace: m['hace'] as String? ?? '',
    );
  }

  List<SugerenciaSeguimiento> get miembros {
    final mapa = {
      for (final p in FeedInicioDataSourceLocal.sugerencias) p.id: p,
    };
    return [
      for (final id in miembroIds)
        if (mapa[id] != null) mapa[id]!,
    ];
  }
}
