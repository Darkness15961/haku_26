import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';

import '../../inicio/proveedores/proveedor_almacen_feed.dart';

/// Usuario autenticado (demo local persistente).
class UsuarioSesion {
  final String id;
  final String nombreUsuario;
  final String correo;
  final String? avatarUrl;
  final String? bio;
  final String? provincia;
  final String? documento;
  final String? tipoDocumento;

  const UsuarioSesion({
    required this.id,
    required this.nombreUsuario,
    required this.correo,
    this.avatarUrl,
    this.bio,
    this.provincia,
    this.documento,
    this.tipoDocumento,
  });

  /// Usuario demo al iniciar con Google.
  static const demoGoogle = UsuarioSesion(
    id: AlmacenFeedNotifier.idUsuarioLocal,
    nombreUsuario: 'Camila Quispe',
    correo: 'camila.quispe@gmail.com',
    avatarUrl: CatalogoImagenesHaku.avatar,
    bio: 'Cusco.',
    provincia: 'Cusco',
  );

  Map<String, dynamic> aMapa() => {
        'id': id,
        'nombre_usuario': nombreUsuario,
        'correo': correo,
        'avatar_url': avatarUrl,
        'bio': bio,
        'provincia': provincia,
        'documento': documento,
        'tipo_documento': tipoDocumento,
      };

  factory UsuarioSesion.desdeMapa(Map<String, dynamic> m) {
    return UsuarioSesion(
      id: m['id'] as String? ?? AlmacenFeedNotifier.idUsuarioLocal,
      nombreUsuario: m['nombre_usuario'] as String? ?? 'Explorador HAKU',
      correo: m['correo'] as String? ?? '',
      avatarUrl: CatalogoImagenesHaku.resolverAvatar(m['avatar_url'] as String?),
      bio: m['bio'] as String?,
      provincia: m['provincia'] as String?,
      documento: m['documento'] as String?,
      tipoDocumento: m['tipo_documento'] as String?,
    );
  }
}

class EstadoSesion {
  final bool autenticado;
  final UsuarioSesion? usuario;
  final bool listo;

  const EstadoSesion({
    this.autenticado = false,
    this.usuario,
    this.listo = false,
  });

  EstadoSesion copyWith({
    bool? autenticado,
    UsuarioSesion? usuario,
    bool? listo,
    bool limpiarUsuario = false,
  }) {
    return EstadoSesion(
      autenticado: autenticado ?? this.autenticado,
      usuario: limpiarUsuario ? null : (usuario ?? this.usuario),
      listo: listo ?? this.listo,
    );
  }
}

class SesionNotifier extends StateNotifier<EstadoSesion> {
  static const _clave = 'haku_sesion_v1';

  SesionNotifier() : super(const EstadoSesion()) {
    _restaurar();
  }

  Future<void> _restaurar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_clave);
    if (raw == null || raw.isEmpty) {
      state = state.copyWith(listo: true);
      return;
    }
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final u = UsuarioSesion.desdeMapa(m);
      final esLegacyGoogle = u.nombreUsuario == 'Explorador Google' ||
          (u.avatarUrl == null || u.avatarUrl!.isEmpty);
      final base = esLegacyGoogle ? UsuarioSesion.demoGoogle : u;
      state = EstadoSesion(
        autenticado: true,
        usuario: UsuarioSesion(
          id: AlmacenFeedNotifier.idUsuarioLocal,
          nombreUsuario: esLegacyGoogle
              ? UsuarioSesion.demoGoogle.nombreUsuario
              : u.nombreUsuario,
          correo: u.correo.isNotEmpty
              ? u.correo
              : UsuarioSesion.demoGoogle.correo,
          avatarUrl: base.avatarUrl ?? UsuarioSesion.demoGoogle.avatarUrl,
          bio: base.bio ?? UsuarioSesion.demoGoogle.bio,
          provincia: base.provincia ?? UsuarioSesion.demoGoogle.provincia,
          documento: u.documento,
          tipoDocumento: u.tipoDocumento,
        ),
        listo: true,
      );
      if (esLegacyGoogle) await _persistir();
    } catch (_) {
      state = state.copyWith(listo: true);
    }
  }

  Future<void> _persistir() async {
    final prefs = await SharedPreferences.getInstance();
    final u = state.usuario;
    if (!state.autenticado || u == null) {
      await prefs.remove(_clave);
      return;
    }
    await prefs.setString(_clave, jsonEncode(u.aMapa()));
  }

  Future<void> iniciarSesion({
    required String correo,
    required String nombreUsuario,
    String? documento,
    String? tipoDocumento,
  }) async {
    state = EstadoSesion(
      autenticado: true,
      listo: true,
      usuario: UsuarioSesion(
        id: AlmacenFeedNotifier.idUsuarioLocal,
        nombreUsuario: nombreUsuario,
        correo: correo,
        avatarUrl: UsuarioSesion.demoGoogle.avatarUrl,
        bio: 'Cusco.',
        provincia: 'Cusco',
        documento: documento,
        tipoDocumento: tipoDocumento,
      ),
    );
    await _persistir();
  }

  Future<void> iniciarConGoogle() async {
    state = const EstadoSesion(
      autenticado: true,
      listo: true,
      usuario: UsuarioSesion.demoGoogle,
    );
    await _persistir();
  }

  Future<void> actualizarNombre(String nombre) async {
    final u = state.usuario;
    if (u == null || nombre.trim().isEmpty) return;
    state = EstadoSesion(
      autenticado: true,
      listo: true,
      usuario: UsuarioSesion(
        id: AlmacenFeedNotifier.idUsuarioLocal,
        nombreUsuario: nombre.trim(),
        correo: u.correo,
        avatarUrl: u.avatarUrl,
        bio: u.bio,
        provincia: u.provincia,
        documento: u.documento,
        tipoDocumento: u.tipoDocumento,
      ),
    );
    await _persistir();
  }

  Future<void> cerrarSesion() async {
    state = const EstadoSesion(listo: true);
    await _persistir();
  }
}

final sesionProvider =
    StateNotifierProvider<SesionNotifier, EstadoSesion>((ref) {
  return SesionNotifier();
});
