import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Usuario autenticado (demo local).
class UsuarioSesion {
  final String id;
  final String nombreUsuario;
  final String correo;
  final String? documento;
  final String? tipoDocumento;

  const UsuarioSesion({
    required this.id,
    required this.nombreUsuario,
    required this.correo,
    this.documento,
    this.tipoDocumento,
  });
}

class EstadoSesion {
  final bool autenticado;
  final UsuarioSesion? usuario;

  const EstadoSesion({
    this.autenticado = false,
    this.usuario,
  });

  EstadoSesion copyWith({
    bool? autenticado,
    UsuarioSesion? usuario,
    bool limpiarUsuario = false,
  }) {
    return EstadoSesion(
      autenticado: autenticado ?? this.autenticado,
      usuario: limpiarUsuario ? null : (usuario ?? this.usuario),
    );
  }
}

class SesionNotifier extends StateNotifier<EstadoSesion> {
  SesionNotifier() : super(const EstadoSesion());

  void iniciarSesion({
    required String correo,
    required String nombreUsuario,
    String? documento,
    String? tipoDocumento,
  }) {
    state = EstadoSesion(
      autenticado: true,
      usuario: UsuarioSesion(
        id: 'u_${DateTime.now().millisecondsSinceEpoch}',
        nombreUsuario: nombreUsuario,
        correo: correo,
        documento: documento,
        tipoDocumento: tipoDocumento,
      ),
    );
  }

  void iniciarConGoogle() {
    state = const EstadoSesion(
      autenticado: true,
      usuario: UsuarioSesion(
        id: 'google_demo',
        nombreUsuario: 'Explorador Google',
        correo: 'explorador@gmail.com',
      ),
    );
  }

  void cerrarSesion() {
    state = const EstadoSesion();
  }
}

final sesionProvider =
    StateNotifierProvider<SesionNotifier, EstadoSesion>((ref) {
  return SesionNotifier();
});
