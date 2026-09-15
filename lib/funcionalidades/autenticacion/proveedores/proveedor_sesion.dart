import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/recursos/copy_haku.dart';
import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../dominio/servicios/servicio_auth_supabase.dart';

/// Usuario en sesión de app (id = auth.users.id / public.usuario.id).
class UsuarioSesion {
  final String id;
  final String nombreUsuario;
  final String correo;
  final String? avatarUrl;
  final String? bio;
  final String? provincia;
  final String? nombres;
  final String? apellidos;
  final int? nacionalidadId;

  const UsuarioSesion({
    required this.id,
    required this.nombreUsuario,
    required this.correo,
    this.avatarUrl,
    this.bio,
    this.provincia,
    this.nombres,
    this.apellidos,
    this.nacionalidadId,
  });

  /// Placeholder UI hasta Bloque B (Google).
  static const demoGoogle = UsuarioSesion(
    id: AlmacenFeedNotifier.idUsuarioLocal,
    nombreUsuario: 'Lucía',
    correo: 'lucia@haku.app',
    avatarUrl: CatalogoImagenesHaku.avatar,
    bio: CopyHaku.bioDefault,
    provincia: 'Cusco',
  );

  UsuarioSesion copyWith({
    String? id,
    String? nombreUsuario,
    String? correo,
    String? avatarUrl,
    String? bio,
    String? provincia,
    String? nombres,
    String? apellidos,
    int? nacionalidadId,
  }) {
    return UsuarioSesion(
      id: id ?? this.id,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      correo: correo ?? this.correo,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      provincia: provincia ?? this.provincia,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      nacionalidadId: nacionalidadId ?? this.nacionalidadId,
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

/// Sesión real: fuente de verdad = Supabase Auth (JWT).
class SesionNotifier extends StateNotifier<EstadoSesion> {
  SesionNotifier() : super(const EstadoSesion()) {
    _iniciar();
  }

  final _auth = ServicioAuthSupabase();
  StreamSubscription<AuthState>? _authSub;

  Future<void> _iniciar() async {
    try {
      final session = clienteSupabase.auth.currentSession;
      if (session?.user != null) {
        await sincronizarDesdeAuth(session!.user);
      } else {
        state = const EstadoSesion(listo: true);
      }

      _authSub = clienteSupabase.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        final user = data.session?.user;
        if (event == AuthChangeEvent.signedOut) {
          state = const EstadoSesion(listo: true);
          return;
        }
        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.userUpdated ||
            event == AuthChangeEvent.initialSession) {
          if (user != null) {
            await sincronizarDesdeAuth(user);
          } else {
            state = const EstadoSesion(listo: true);
          }
        }
      });
    } catch (e, st) {
      debugPrint('Sesión Auth: $e');
      debugPrint('$st');
      state = const EstadoSesion(listo: true);
    }
  }

  /// Hidrata UI desde Auth (+ fila `public.usuario` si RLS lo permite).
  Future<void> sincronizarDesdeAuth(User user) async {
    final nickMeta = (user.userMetadata?['nombre_nick'] as String?)?.trim();
    var nick = (nickMeta != null && nickMeta.isNotEmpty)
        ? nickMeta
        : (user.email?.split('@').first ?? 'usuario');
    var avatar = user.userMetadata?['avatar_url'] as String? ??
        user.userMetadata?['picture'] as String?;
    var correo = user.email ?? '';
    String? nombres;
    String? apellidos;
    int? nacionalidadId;

    // Tras Google, el trigger puede ir un pelín detrás del JWT.
    Map<String, dynamic>? row;
    try {
      for (var i = 0; i < 4; i++) {
        row = await clienteSupabase
            .from('usuario')
            .select(
              'nombre_nick, foto_perfil, correo, nombres, apellidos, nacionalidad_id',
            )
            .eq('id', user.id)
            .maybeSingle();
        if (row != null) break;
        await Future<void>.delayed(Duration(milliseconds: 150 * (i + 1)));
      }
      if (row != null) {
        final n = (row['nombre_nick'] as String?)?.trim();
        if (n != null && n.isNotEmpty) nick = n;
        final foto = row['foto_perfil'] as String?;
        if (foto != null && foto.isNotEmpty) avatar = foto;
        final c = (row['correo'] as String?)?.trim();
        if (c != null && c.isNotEmpty) correo = c;
        nombres = (row['nombres'] as String?)?.trim();
        apellidos = (row['apellidos'] as String?)?.trim();
        final nacRaw = row['nacionalidad_id'];
        if (nacRaw is int) {
          nacionalidadId = nacRaw;
        } else if (nacRaw != null) {
          nacionalidadId = int.tryParse('$nacRaw');
        }
      } else {
        debugPrint(
          'Perfil public.usuario aún null tras retries (id=${user.id})',
        );
      }
    } catch (e) {
      debugPrint('Perfil public.usuario: $e');
    }

    final avatarResuelto = CatalogoImagenesHaku.resolverAvatar(avatar);

    state = EstadoSesion(
      autenticado: true,
      listo: true,
      usuario: UsuarioSesion(
        id: user.id,
        nombreUsuario: nick,
        correo: correo,
        avatarUrl: avatarResuelto,
        bio: CopyHaku.bioDefault,
        provincia: 'Cusco',
        nombres: nombres,
        apellidos: apellidos,
        nacionalidadId: nacionalidadId,
      ),
    );
  }

  /// Tras signUp / signIn explícito (misma hidratación).
  Future<void> aplicarSesionAuth({
    required String id,
    required String correo,
    required String nombreUsuario,
    String? avatarUrl,
  }) async {
    state = EstadoSesion(
      autenticado: true,
      listo: true,
      usuario: UsuarioSesion(
        id: id,
        nombreUsuario: nombreUsuario,
        correo: correo,
        avatarUrl: avatarUrl ?? CatalogoImagenesHaku.avatar,
        bio: CopyHaku.bioDefault,
        provincia: 'Cusco',
      ),
    );
    final user = _auth.usuarioActual;
    if (user != null && user.id == id) {
      await sincronizarDesdeAuth(user);
    }
  }

  Future<void> actualizarNombre(String nombre) async {
    final u = state.usuario;
    if (u == null || nombre.trim().isEmpty) return;
    state = EstadoSesion(
      autenticado: true,
      listo: true,
      usuario: u.copyWith(nombreUsuario: nombre.trim()),
    );
  }

  Future<void> cerrarSesion() async {
    try {
      await _auth.cerrarSesion();
    } catch (e) {
      debugPrint('signOut: $e');
    }
    state = const EstadoSesion(listo: true);
  }

  /// Espera a que [_iniciar]/sincronizar terminen (evita pedir login con JWT ya vivo).
  Future<void> esperarListo({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (state.listo) return;
    final fin = DateTime.now().add(timeout);
    while (!state.listo && DateTime.now().isBefore(fin)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Google OAuth real (Bloque B). Sin pantalla extra de completar.
  Future<void> iniciarConGoogle() async {
    final resultado = await _auth.iniciarConGoogle();
    await sincronizarDesdeAuth(resultado.usuario);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

final sesionProvider =
    StateNotifierProvider<SesionNotifier, EstadoSesion>((ref) {
  return SesionNotifier();
});
