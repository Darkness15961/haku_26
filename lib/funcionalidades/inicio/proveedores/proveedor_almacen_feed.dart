import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/almacenamiento/almacenamiento_haku.dart';
import '../../comunidad/dominio/modelo_comunidad.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../datos/semilla_almacen_haku.dart';

class EstadoAlmacenFeed {
  final bool listo;
  final List<SugerenciaSeguimiento> perfiles;
  final List<PublicacionFeed> publicaciones;
  final Set<String> siguiendoIds;
  final Set<String> likesPublicacionIds;
  final Set<String> likesClipIds;
  final Set<String> guardadosIds;
  final Set<String> favoritosClipIds;
  final Set<String> favoritosRutaIds;
  final List<ComunidadHaku> comunidades;
  final Set<String> comunidadIds;

  const EstadoAlmacenFeed({
    this.listo = false,
    this.perfiles = const [],
    this.publicaciones = const [],
    this.siguiendoIds = const {},
    this.likesPublicacionIds = const {},
    this.likesClipIds = const {},
    this.guardadosIds = const {},
    this.favoritosClipIds = const {},
    this.favoritosRutaIds = const {},
    this.comunidades = const [],
    this.comunidadIds = const {},
  });

  List<SugerenciaSeguimiento> get exploradores =>
      perfiles.where((p) => RegExp(r'^s\d+$').hasMatch(p.id)).toList();

  EstadoAlmacenFeed copyWith({
    bool? listo,
    List<SugerenciaSeguimiento>? perfiles,
    List<PublicacionFeed>? publicaciones,
    Set<String>? siguiendoIds,
    Set<String>? likesPublicacionIds,
    Set<String>? likesClipIds,
    Set<String>? guardadosIds,
    Set<String>? favoritosClipIds,
    Set<String>? favoritosRutaIds,
    List<ComunidadHaku>? comunidades,
    Set<String>? comunidadIds,
  }) {
    return EstadoAlmacenFeed(
      listo: listo ?? this.listo,
      perfiles: perfiles ?? this.perfiles,
      publicaciones: publicaciones ?? this.publicaciones,
      siguiendoIds: siguiendoIds ?? this.siguiendoIds,
      likesPublicacionIds: likesPublicacionIds ?? this.likesPublicacionIds,
      likesClipIds: likesClipIds ?? this.likesClipIds,
      guardadosIds: guardadosIds ?? this.guardadosIds,
      favoritosClipIds: favoritosClipIds ?? this.favoritosClipIds,
      favoritosRutaIds: favoritosRutaIds ?? this.favoritosRutaIds,
      comunidades: comunidades ?? this.comunidades,
      comunidadIds: comunidadIds ?? this.comunidadIds,
    );
  }

  SugerenciaSeguimiento? perfilPorId(String id) {
    for (final p in perfiles) {
      if (p.id == id || p.usuario == id) return p;
    }
    return null;
  }
}

class AlmacenFeedNotifier extends StateNotifier<EstadoAlmacenFeed> {
  AlmacenFeedNotifier() : super(const EstadoAlmacenFeed()) {
    cargar();
  }

  AlmacenamientoHaku? _db;

  Future<void> cargar() async {
    _db ??= await AlmacenamientoHaku.abrir();
    var doc = _db!.leer();
    if (doc == null) {
      doc = SemillaAlmacenHaku.documento();
      await _db!.guardar(doc);
    } else {
      doc = SemillaAlmacenHaku.fusionar(doc);
      await _db!.guardar(doc);
    }
    state = _desdeDocumento(doc);
  }

  Future<void> _persistir() async {
    final db = _db;
    if (db == null) return;
    await db.guardar(_aDocumento());
  }

  Future<void> toggleSeguir(String perfilId) async {
    final next = {...state.siguiendoIds};
    final perfiles = [...state.perfiles];
    final i = perfiles.indexWhere((p) => p.id == perfilId);
    if (i < 0) return;
    if (next.contains(perfilId)) {
      next.remove(perfilId);
      perfiles[i] = perfiles[i].copyWith(
        seguidores: (perfiles[i].seguidores - 1).clamp(0, 999999999),
      );
    } else {
      next.add(perfilId);
      perfiles[i] = perfiles[i].copyWith(
        seguidores: perfiles[i].seguidores + 1,
      );
    }
    state = state.copyWith(siguiendoIds: next, perfiles: perfiles);
    await _persistir();
  }

  Future<void> toggleLikePublicacion(String publicacionId) async {
    final next = {...state.likesPublicacionIds};
    final posts = [...state.publicaciones];
    final i = posts.indexWhere((p) => p.id == publicacionId);
    if (i < 0) return;
    if (next.contains(publicacionId)) {
      next.remove(publicacionId);
      posts[i] = posts[i].copyWith(likes: (posts[i].likes - 1).clamp(0, 999999999));
    } else {
      next.add(publicacionId);
      posts[i] = posts[i].copyWith(likes: posts[i].likes + 1);
    }
    state = state.copyWith(likesPublicacionIds: next, publicaciones: posts);
    await _persistir();
  }

  Future<void> toggleGuardarPublicacion(String publicacionId) async {
    final next = {...state.guardadosIds};
    if (next.contains(publicacionId)) {
      next.remove(publicacionId);
    } else {
      next.add(publicacionId);
    }
    state = state.copyWith(guardadosIds: next);
    await _persistir();
  }

  Future<void> toggleFavoritoRuta(String rutaId) async {
    final next = {...state.favoritosRutaIds};
    if (next.contains(rutaId)) {
      next.remove(rutaId);
    } else {
      next.add(rutaId);
    }
    state = state.copyWith(favoritosRutaIds: next);
    await _persistir();
  }

  Future<void> toggleLikeClip(String clipId) async {
    final next = {...state.likesClipIds};
    final liked = next.contains(clipId);
    if (liked) {
      next.remove(clipId);
    } else {
      next.add(clipId);
    }
    final perfiles = state.perfiles.map((p) {
      return p.copyWith(
        publicaciones: p.publicaciones
            .map(
              (c) => c.id == clipId
                  ? c.copyWith(
                      likes: liked
                          ? (c.likes - 1).clamp(0, 999999999)
                          : c.likes + 1,
                    )
                  : c,
            )
            .toList(),
      );
    }).toList();
    state = state.copyWith(likesClipIds: next, perfiles: perfiles);
    await _persistir();
  }

  Future<void> registrarVistaClip(String clipId) async {
    final perfiles = state.perfiles.map((p) {
      return p.copyWith(
        publicaciones: p.publicaciones
            .map(
              (c) => c.id == clipId ? c.copyWith(vistas: c.vistas + 1) : c,
            )
            .toList(),
      );
    }).toList();
    state = state.copyWith(perfiles: perfiles);
    await _persistir();
  }

  Future<void> crearPublicacion(PublicacionFeed publicacion) async {
    state = state.copyWith(
      publicaciones: [publicacion, ...state.publicaciones],
    );
    await _persistir();
  }

  Future<void> incrementarComentarios(String publicacionId) async {
    final posts = [...state.publicaciones];
    final i = posts.indexWhere((p) => p.id == publicacionId);
    if (i < 0) return;
    posts[i] = posts[i].copyWith(comentarios: posts[i].comentarios + 1);
    state = state.copyWith(publicaciones: posts);
    await _persistir();
  }

  static const idUsuarioLocal = 'yo';

  Future<void> toggleUnirseComunidad(String comunidadId) async {
    final comunidades = [...state.comunidades];
    final i = comunidades.indexWhere((c) => c.id == comunidadId);
    if (i < 0) return;
    final next = {...state.comunidadIds};
    final miembros = [...comunidades[i].miembroIds];
    if (next.contains(comunidadId)) {
      next.remove(comunidadId);
      miembros.remove(idUsuarioLocal);
    } else {
      next.add(comunidadId);
      if (!miembros.contains(idUsuarioLocal)) miembros.add(idUsuarioLocal);
    }
    comunidades[i] = comunidades[i].copyWith(miembroIds: miembros);
    state = state.copyWith(comunidades: comunidades, comunidadIds: next);
    await _persistir();
  }

  Future<void> crearComunidad({
    required String nombre,
    required String descripcion,
    required List<CategoriaLugar> categorias,
    required List<String> invitadosIds,
    String imagenUrl =
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
  }) async {
    final id = 'com_${DateTime.now().millisecondsSinceEpoch}';
    final miembros = {idUsuarioLocal, ...invitadosIds}.toList();
    final comunidad = ComunidadHaku(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      imagenUrl: imagenUrl,
      creadorId: idUsuarioLocal,
      categorias: categorias,
      miembroIds: miembros,
      fechaCreacion: DateTime.now(),
    );
    state = state.copyWith(
      comunidades: [comunidad, ...state.comunidades],
      comunidadIds: {...state.comunidadIds, id},
    );
    await _persistir();
  }

  EstadoAlmacenFeed _desdeDocumento(Map<String, dynamic> doc) {
    final clipsRaw = (doc['clips'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => ClipPerfil.desdeMapa(Map<String, dynamic>.from(e)))
        .toList();
    final clipsPorAutor = <String, List<ClipPerfil>>{};
    final clipsPorId = <String, ClipPerfil>{};
    for (final c in clipsRaw) {
      clipsPorAutor.putIfAbsent(c.autorId, () => []).add(c);
      clipsPorId[c.id] = c;
    }

    final perfiles = (doc['perfiles'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) {
          final m = Map<String, dynamic>.from(e);
          final id = m['id'] as String? ?? '';
          final pubs = clipsPorAutor[id] ?? const <ClipPerfil>[];
          final favIds = (m['favorito_ids'] as List<dynamic>? ?? [])
              .map((x) => x.toString())
              .toList();
          final favs = [
            for (final fid in favIds)
              if (clipsPorId[fid] != null) clipsPorId[fid]!,
          ];
          return SugerenciaSeguimiento.desdeMapa(
            m,
            publicaciones: pubs,
            favoritos: favs.isEmpty ? pubs.reversed.take(6).toList() : favs,
          );
        })
        .toList();

    final porId = {for (final p in perfiles) p.id: p};
    final publicaciones = (doc['publicaciones'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) {
          final m = Map<String, dynamic>.from(e);
          final autorId = m['autor_id'] as String? ?? '';
          final autor = porId[autorId];
          final creado = DateTime.tryParse(m['creado_en'] as String? ?? '');
          return PublicacionFeed(
            id: m['id'] as String? ?? '',
            autorId: autorId,
            autor: autor?.nombre ?? autorId,
            usuario: autor?.usuario ?? '@$autorId',
            avatarUrl: autor?.avatarUrl ?? '',
            hace: _hace(creado),
            texto: m['texto'] as String? ?? '',
            imagenUrl: m['imagen_url'] as String?,
            likes: (m['likes'] as num?)?.toInt() ?? 0,
            comentarios: (m['comentarios'] as num?)?.toInt() ?? 0,
            estiloFondo: EstiloFondoPublicacion.veloNegro,
            creadoEn: creado,
            lugarId: m['lugar_id'] as String?,
            lugarNombre: m['lugar_nombre'] as String?,
            categoria: m['categoria'] as String?,
          );
        })
        .toList();

    final inter = Map<String, dynamic>.from(
      doc['interacciones'] as Map? ?? const {},
    );
    Set<String> ids(String k) => {
          for (final x in (inter[k] as List<dynamic>? ?? [])) x.toString(),
        };

    final miembrosPorCom = <String, List<String>>{};
    for (final raw in (doc['miembros_comunidad'] as List<dynamic>? ?? [])) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final cid = m['comunidad_id'] as String? ?? '';
      final uid = m['usuario_id'] as String? ?? '';
      if (cid.isEmpty || uid.isEmpty) continue;
      miembrosPorCom.putIfAbsent(cid, () => []).add(uid);
    }

    final comunidadIds = ids('comunidad_ids');
    for (final cid in comunidadIds) {
      final lista = miembrosPorCom.putIfAbsent(cid, () => []);
      if (!lista.contains(AlmacenFeedNotifier.idUsuarioLocal)) {
        lista.add(AlmacenFeedNotifier.idUsuarioLocal);
      }
    }

    final comunidades = (doc['comunidades'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) {
          final m = Map<String, dynamic>.from(e);
          final id = m['id'] as String? ?? '';
          return ComunidadHaku.desdeMapa(
            m,
            miembroIds: miembrosPorCom[id] ?? const [],
          );
        })
        .toList();

    return EstadoAlmacenFeed(
      listo: true,
      perfiles: perfiles,
      publicaciones: publicaciones,
      siguiendoIds: ids('siguiendo_ids'),
      likesPublicacionIds: ids('likes_publicacion_ids'),
      likesClipIds: ids('likes_clip_ids'),
      guardadosIds: ids('guardados_publicacion_ids'),
      favoritosClipIds: ids('favoritos_clip_ids'),
      favoritosRutaIds: ids('favoritos_ruta_ids'),
      comunidades: comunidades,
      comunidadIds: comunidadIds,
    );
  }

  Map<String, dynamic> _aDocumento() {
    final clips = <Map<String, dynamic>>[];
    for (final p in state.perfiles) {
      for (final c in p.publicaciones) {
        clips.add(c.aMapa());
      }
    }
    final miembros = <Map<String, dynamic>>[];
    var n = 0;
    for (final c in state.comunidades) {
      for (var i = 0; i < c.miembroIds.length; i++) {
        n++;
        miembros.add(
          MiembroComunidad(
            id: 'mc_${c.id}_$n',
            comunidadId: c.id,
            usuarioId: c.miembroIds[i],
            rol: c.miembroIds[i] == c.creadorId ? 'admin' : 'miembro',
          ).aMapa(),
        );
      }
    }
    return {
      'version': AlmacenamientoHaku.versionEsquema,
      'perfiles': state.perfiles.map((p) => p.aMapa()).toList(),
      'clips': clips,
      'publicaciones': state.publicaciones.map((p) => p.aMapa()).toList(),
      'categorias_actividad': [
        for (final c in CategoriaLugar.values)
          {'id': c.name, 'nombre': c.etiqueta},
      ],
      'comunidades': state.comunidades.map((c) => c.aMapa()).toList(),
      'miembros_comunidad': miembros,
      'interacciones': {
        'demo_usuario_v1': true,
        'siguiendo_ids': state.siguiendoIds.toList(),
        'likes_publicacion_ids': state.likesPublicacionIds.toList(),
        'likes_clip_ids': state.likesClipIds.toList(),
        'guardados_publicacion_ids': state.guardadosIds.toList(),
        'favoritos_clip_ids': state.favoritosClipIds.toList(),
        'favoritos_ruta_ids': state.favoritosRutaIds.toList(),
        'comunidad_ids': state.comunidadIds.toList(),
      },
    };
  }

  static String _hace(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

final almacenFeedProvider =
    StateNotifierProvider<AlmacenFeedNotifier, EstadoAlmacenFeed>((ref) {
  return AlmacenFeedNotifier();
});
