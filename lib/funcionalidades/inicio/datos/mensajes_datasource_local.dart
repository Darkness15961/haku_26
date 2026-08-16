import '../../rutas/dominio/modelos/modelo_ruta.dart';
import 'feed_inicio_datasource_local.dart';

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

  final List<ComunidadHaku> comunidades = [
    ComunidadHaku(
      id: 'com1',
      nombre: 'Trekkers Cusco',
      descripcion: 'Salidas semanales y tips de altura.',
      miembros: 1280,
      imagenUrl:
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400&q=80',
    ),
    ComunidadHaku(
      id: 'com2',
      nombre: 'Fotógrafos Andinos',
      descripcion: 'Amaneceres, niebla y color.',
      miembros: 642,
      imagenUrl:
          'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=400&q=80',
    ),
    ComunidadHaku(
      id: 'com3',
      nombre: 'Ruta Inca Crew',
      descripcion: 'Preparación y logística del Camino Inca.',
      miembros: 910,
      imagenUrl:
          'https://images.unsplash.com/photo-1587595431973-160d0d94add1?w=400&q=80',
    ),
  ];

  final Set<String> solicitudesComunidad = {};

  void agregarGrupo(GrupoRuta grupo) => grupos.insert(0, grupo);

  void eliminarGrupo(String id) => grupos.removeWhere((g) => g.id == id);

  void agregarComunidad(ComunidadHaku comunidad) =>
      comunidades.insert(0, comunidad);

  void solicitarUnirse(String comunidadId) =>
      solicitudesComunidad.add(comunidadId);

  bool solicitudEnviada(String comunidadId) =>
      solicitudesComunidad.contains(comunidadId);
}

/// Datos demo de mensajería 1:1.
class MensajesDataSourceLocal {
  static const List<ChatConversacion> chats = [
    ChatConversacion(
      id: 'c1',
      nombre: 'María Quispe',
      usuario: '@mariaq',
      avatarUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&q=80',
      ultimoMensaje: '¿Salimos mañana a Sacsayhuamán?',
      hace: '12m',
      noLeidos: 2,
    ),
    ChatConversacion(
      id: 'c2',
      nombre: 'Andina Trek',
      usuario: '@andinatrek',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
      ultimoMensaje: 'Te envié el itinerario del Valle.',
      hace: '1h',
      noLeidos: 0,
    ),
    ChatConversacion(
      id: 'c3',
      nombre: 'Diego Andes',
      usuario: '@diegoandes',
      avatarUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&q=80',
      ultimoMensaje: 'Lleva bastones para Humantay 👍',
      hace: '3h',
      noLeidos: 1,
    ),
    ChatConversacion(
      id: 'c4',
      nombre: 'Sofía Trek',
      usuario: '@sofiatrek',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
      ultimoMensaje: 'Vinicunca quedó brutal.',
      hace: 'Ayer',
      noLeidos: 0,
    ),
    ChatConversacion(
      id: 'c5',
      nombre: 'Cusco Walks',
      usuario: '@cuscowalks',
      avatarUrl:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&q=80',
      ultimoMensaje: '¿Te interesa el tour urbano?',
      hace: '2d',
      noLeidos: 0,
    ),
  ];

  static List<ComunidadHaku> get comunidades =>
      MensajeriaEstado.instancia.comunidades;

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
}

class ComunidadHaku {
  final String id;
  final String nombre;
  final String descripcion;
  final int miembros;
  final String imagenUrl;
  final List<String> invitadosIds;

  const ComunidadHaku({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.miembros,
    required this.imagenUrl,
    this.invitadosIds = const [],
  });
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
