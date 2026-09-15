import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';

/// Comunidad HAKU.
///
/// Path remoto (`desdeFilaRemota`): columnas de `public.comunidad`.
/// Path demo (`desdeMapa`): almacén local legacy (sin provincia/categorías en BD).
class ComunidadHaku {
  final String id;
  final String nombre;
  final String descripcion;
  final String imagenUrl;
  final String creadorId;
  /// Solo demo local; remoto no tiene provincia.
  final String provincia;
  /// UI: `activa` / `inactiva` (remoto: `estado` bool).
  final String estado;
  /// `publico` | `privado` (enum remoto). Demo: vacío.
  final String tipo;
  /// Solo demo local; remoto no tiene N:N categoría.
  final List<CategoriaLugar> categorias;
  /// Miembros con `estado = aprobado` (conteo / badge Unida).
  final List<String> miembroIds;
  /// usuario_id → `estado_membresia` (aprobado/pendiente/…). Remoto.
  final Map<String, String> estadoMembresiaPorUsuario;
  /// usuario_id → rol (`admin`/`miembro`). Remoto.
  final Map<String, String> rolPorUsuario;
  final DateTime? fechaCreacion;
  final bool remoto;

  const ComunidadHaku({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    required this.creadorId,
    this.provincia = '',
    this.estado = 'activa',
    this.tipo = 'publico',
    this.categorias = const [],
    this.miembroIds = const [],
    this.estadoMembresiaPorUsuario = const {},
    this.rolPorUsuario = const {},
    this.fechaCreacion,
    this.remoto = false,
  });

  int get miembros => miembroIds.length;

  bool get esPrivada => tipo == 'privado';

  bool get activa => estado == 'activa';

  /// Compatibilidad con el formulario anterior.
  List<String> get invitadosIds => miembroIds;

  bool tieneCategoria(CategoriaLugar c) => categorias.contains(c);

  bool esMiembro(String usuarioId) {
    if (usuarioId.isEmpty) return false;
    return miembroIds.contains(usuarioId);
  }

  String? estadoMembresiaDe(String usuarioId) {
    if (usuarioId.isEmpty) return null;
    return estadoMembresiaPorUsuario[usuarioId];
  }

  bool solicitudPendiente(String usuarioId) =>
      estadoMembresiaDe(usuarioId) == 'pendiente';

  bool esAdminDe(String usuarioId) {
    if (usuarioId.isEmpty) return false;
    if (creadorId == usuarioId) return true;
    return (rolPorUsuario[usuarioId] ?? '').toLowerCase() == 'admin' &&
        esMiembro(usuarioId);
  }

  ComunidadHaku copyWith({
    List<String>? miembroIds,
    List<CategoriaLugar>? categorias,
    String? tipo,
    Map<String, String>? estadoMembresiaPorUsuario,
    Map<String, String>? rolPorUsuario,
  }) {
    return ComunidadHaku(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      imagenUrl: imagenUrl,
      creadorId: creadorId,
      provincia: provincia,
      estado: estado,
      tipo: tipo ?? this.tipo,
      categorias: categorias ?? this.categorias,
      miembroIds: miembroIds ?? this.miembroIds,
      estadoMembresiaPorUsuario:
          estadoMembresiaPorUsuario ?? this.estadoMembresiaPorUsuario,
      rolPorUsuario: rolPorUsuario ?? this.rolPorUsuario,
      fechaCreacion: fechaCreacion,
      remoto: remoto,
    );
  }

  /// Fila PostgREST de `public.comunidad` (+ embed `comunidad_miembro`).
  factory ComunidadHaku.desdeFilaRemota(Map<String, dynamic> m) {
    final idRaw = m['id'];
    final id = idRaw == null ? '' : '$idRaw';

    final estadoBool = m['estado'];
    final estadoStr = estadoBool is bool
        ? (estadoBool ? 'activa' : 'inactiva')
        : (m['estado'] as String? ?? 'activa');

    final tipoRaw = (m['tipo'] as String?)?.trim().toLowerCase() ?? 'publico';
    final tipo = (tipoRaw == 'privado') ? 'privado' : 'publico';

    final miembroIds = <String>[];
    final estados = <String, String>{};
    final roles = <String, String>{};
    final embed = m['comunidad_miembro'];
    if (embed is List) {
      for (final raw in embed) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        if (row.containsKey('count') && !row.containsKey('usuario_id')) {
          continue;
        }
        final uid = row['usuario_id'];
        if (uid == null) continue;
        final s = '$uid'.trim();
        if (s.isEmpty) continue;
        final est = (row['estado'] as String?)?.toLowerCase() ?? 'aprobado';
        estados[s] = est;
        final rol = (row['rol'] as String?)?.toLowerCase() ?? 'miembro';
        roles[s] = rol;
        if (est == 'aprobado' && !miembroIds.contains(s)) {
          miembroIds.add(s);
        }
      }
    }

    final foto = (m['foto_portada'] as String?)?.trim() ?? '';

    return ComunidadHaku(
      id: id,
      nombre: (m['nombre'] as String?)?.trim() ?? '',
      descripcion: (m['descripcion'] as String?)?.trim() ?? '',
      imagenUrl: foto,
      creadorId: '${m['usuario_creador_id'] ?? ''}',
      provincia: '',
      estado: estadoStr,
      tipo: tipo,
      categorias: const [],
      miembroIds: miembroIds,
      estadoMembresiaPorUsuario: estados,
      rolPorUsuario: roles,
      fechaCreacion: DateTime.tryParse(m['fecha_creacion'] as String? ?? ''),
      remoto: true,
    );
  }

  factory ComunidadHaku.desdeMapa(
    Map<String, dynamic> m, {
    List<String> miembroIds = const [],
  }) {
    final cats = (m['categoria_ids'] as List<dynamic>? ?? [])
        .map((x) => x.toString())
        .map(_categoriaDe)
        .whereType<CategoriaLugar>()
        .toList();
    return ComunidadHaku(
      id: m['id'] as String? ?? '',
      nombre: m['nombre'] as String? ?? '',
      descripcion: m['descripcion'] as String? ?? '',
      imagenUrl: CatalogoImagenesHaku.resolverImagen(
        m['imagen_url'] as String?,
      ),
      creadorId: m['creador_id'] as String? ?? '',
      provincia: m['provincia'] as String? ?? 'Cusco',
      estado: m['estado'] as String? ?? 'activa',
      tipo: (m['tipo'] as String?) ?? 'publico',
      categorias: cats,
      miembroIds: miembroIds,
      fechaCreacion: DateTime.tryParse(m['fecha_creacion'] as String? ?? ''),
      remoto: false,
    );
  }

  Map<String, dynamic> aMapa() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'imagen_url': imagenUrl,
        'creador_id': creadorId,
        'provincia': provincia,
        'estado': estado,
        'tipo': tipo,
        'categoria_ids': categorias.map((c) => c.name).toList(),
        'fecha_creacion':
            (fechaCreacion ?? DateTime.now()).toIso8601String(),
      };

  static CategoriaLugar? _categoriaDe(String id) {
    for (final c in CategoriaLugar.values) {
      if (c.name == id) return c;
    }
    return null;
  }
}

/// Miembro remoto con perfil de `public.usuario` (si el embed lo permite).
class MiembroComunidadRemoto {
  final String usuarioId;
  final String rol;
  final String estado;
  final String? nombreNick;
  final String? nombres;
  final String? fotoPerfil;

  const MiembroComunidadRemoto({
    required this.usuarioId,
    required this.rol,
    required this.estado,
    this.nombreNick,
    this.nombres,
    this.fotoPerfil,
  });

  /// Etiqueta visible: nick o nombres de `usuario`. Sin inventar.
  String get etiqueta {
    final nick = nombreNick?.trim() ?? '';
    if (nick.isNotEmpty) return nick;
    final nom = nombres?.trim() ?? '';
    if (nom.isNotEmpty) return nom;
    return 'Sin nick';
  }

  factory MiembroComunidadRemoto.desdeFila(Map<String, dynamic> m) {
    Map<String, dynamic>? u;
    final raw = m['usuario'];
    if (raw is Map) u = Map<String, dynamic>.from(raw);

    return MiembroComunidadRemoto(
      usuarioId: '${m['usuario_id'] ?? ''}',
      rol: (m['rol'] as String?)?.trim() ?? 'miembro',
      estado: (m['estado'] as String?)?.trim() ?? 'aprobado',
      nombreNick: u?['nombre_nick'] as String?,
      nombres: u?['nombres'] as String?,
      fotoPerfil: u?['foto_perfil'] as String?,
    );
  }
}

class MiembroComunidad {
  final String id;
  final String comunidadId;
  final String usuarioId;
  final String rol;
  final DateTime? fechaUnion;

  const MiembroComunidad({
    required this.id,
    required this.comunidadId,
    required this.usuarioId,
    this.rol = 'miembro',
    this.fechaUnion,
  });

  Map<String, dynamic> aMapa() => {
        'id': id,
        'comunidad_id': comunidadId,
        'usuario_id': usuarioId,
        'rol': rol,
        'fecha_union': (fechaUnion ?? DateTime.now()).toIso8601String(),
      };
}
