/// Contrato único del nickname público de HAKU.
///
/// El UUID sigue siendo la identidad técnica. El nickname es un identificador
/// público legible y, por ello, su unicidad definitiva se valida también en BD.
abstract final class PoliticaNickname {
  static const longitudMinima = 3;
  static const longitudMaxima = 30;

  static const reservados = <String>{
    'haku',
    'admin',
    'administrator',
    'administrador',
    'soporte',
    'support',
    'oficial',
    'official',
    'moderador',
    'moderator',
    'staff',
    'sistema',
    'system',
    'seguridad',
    'security',
    'root',
  };

  static final RegExp _formato = RegExp(r'^[a-z0-9][a-z0-9_]{1,28}[a-z0-9]$');

  static const ayuda =
      'Usa de 3 a 30 caracteres: letras, números y guion bajo (_). '
      'Debe comenzar y terminar con una letra o número. '
      'No uses espacios, tildes ni símbolos. Las mayúsculas se convierten '
      'automáticamente en minúsculas.';

  static String normalizar(String raw) {
    var nick = raw.trim().toLowerCase();
    while (nick.startsWith('@')) {
      nick = nick.substring(1);
    }
    return nick;
  }

  static String? validar(String raw) {
    final nick = normalizar(raw);
    if (nick.length < longitudMinima || nick.length > longitudMaxima) {
      return 'El nickname debe tener entre 3 y 30 caracteres.';
    }
    if (!_formato.hasMatch(nick)) {
      return 'Usa letras minúsculas, números y _. Debe comenzar y terminar con una letra o número.';
    }
    if (reservados.contains(nick)) {
      return 'Ese nickname está reservado. Elige otro.';
    }
    return null;
  }

  static bool esValido(String raw) => validar(raw) == null;
}
