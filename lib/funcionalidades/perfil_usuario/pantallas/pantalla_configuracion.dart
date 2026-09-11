import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../autenticacion/datos/nacionalidad_datasource.dart';
import '../../autenticacion/dominio/modelos/modelo_nacionalidad.dart';
import '../../autenticacion/dominio/servicios/servicio_perfil_supabase.dart';
import '../../autenticacion/mensajes_auth_haku.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../autenticacion/widgets/selector_nacionalidad.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';

/// Configuración de cuenta: perfil BD + Auth (correo/clave) + foto (URL Storage/S3).
class PantallaConfiguracion extends ConsumerStatefulWidget {
  const PantallaConfiguracion({super.key});

  @override
  ConsumerState<PantallaConfiguracion> createState() =>
      _EstadoPantallaConfiguracion();
}

class _EstadoPantallaConfiguracion
    extends ConsumerState<PantallaConfiguracion> {
  final _perfilSvc = ServicioPerfilSupabase();
  final _picker = ImagePicker();

  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _nick = TextEditingController();
  final _correo = TextEditingController();
  final _claveActual = TextEditingController();
  final _claveNueva = TextEditingController();
  final _claveNueva2 = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;
  bool _ocultarActual = true;
  bool _ocultarNueva = true;
  bool _ocultarNueva2 = true;

  List<ModeloNacionalidad> _nacionalidades = const [];
  ModeloNacionalidad? _nacionalidad;
  String? _fotoUrl;
  String? _errorNac;

  /// Tiene identidad `email` en Auth (= puede cambiar clave con la actual).
  /// Solo Google → UI de «Crear contraseña» (opción A, sin SMTP).
  bool _tieneClaveEmail = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombres.dispose();
    _apellidos.dispose();
    _nick.dispose();
    _correo.dispose();
    _claveActual.dispose();
    _claveNueva.dispose();
    _claveNueva2.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final sesion = ref.read(sesionProvider);
    final u = sesion.usuario;

    try {
      if (supabaseListo) {
        final lista = await NacionalidadDataSource().listar();
        _nacionalidades = lista;
      }
    } catch (e) {
      _errorNac = 'No se pudo cargar nacionalidades';
      debugPrint('Config nac: $e');
    }

    if (u != null && sesion.autenticado && supabaseListo) {
      _tieneClaveEmail = await _resolverTieneClaveEmail(u.id);
      try {
        final perfil = await _perfilSvc.cargarPerfil(u.id);
        if (perfil != null) {
          _nombres.text = perfil.nombres;
          _apellidos.text = perfil.apellidos;
          _nick.text = perfil.nombreNick;
          _correo.text = perfil.correo;
          _fotoUrl = perfil.fotoPerfil;
          _nacionalidad = perfil.nacionalidad ??
              NacionalidadDataSource.sugerida(
                _nacionalidades,
                preferirId: perfil.nacionalidadId,
              );
        } else {
          _aplicarDesdeSesion(u);
        }
      } catch (e) {
        debugPrint('Config perfil: $e');
        _aplicarDesdeSesion(u);
      }
    } else if (u != null) {
      _tieneClaveEmail = false;
      _aplicarDesdeSesion(u);
    }

    if (mounted) setState(() => _cargando = false);
  }

  /// Identidad `email` en GoTrue = hay contraseña de HAKU.
  /// Si solo hay Google, miramos flag local (tras «Crear contraseña» sin SMTP).
  static bool _detectarIdentidadEmail() {
    final identidades = clienteSupabase.auth.currentUser?.identities;
    if (identidades == null || identidades.isEmpty) return false;
    return identidades.any((i) => i.provider == 'email');
  }

  static String _prefsClaveCreada(String userId) => 'haku_clave_creada_$userId';

  Future<bool> _resolverTieneClaveEmail(String userId) async {
    if (_detectarIdentidadEmail()) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefsClaveCreada(userId)) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _marcarClaveCreadaLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsClaveCreada(userId), true);
    } catch (e) {
      debugPrint('prefs clave: $e');
    }
  }

  void _aplicarDesdeSesion(UsuarioSesion u) {
    _nombres.text = u.nombres ?? '';
    _apellidos.text = u.apellidos ?? '';
    _nick.text = u.nombreUsuario;
    _correo.text = u.correo;
    _fotoUrl = u.avatarUrl;
    if (u.nacionalidadId != null) {
      _nacionalidad = NacionalidadDataSource.sugerida(
        _nacionalidades,
        preferirId: u.nacionalidadId,
      );
    }
  }

  Future<void> _abrirNacionalidad() async {
    if (_nacionalidades.isEmpty) {
      mostrarSnackHaku(context, _errorNac ?? 'Sin nacionalidades');
      return;
    }
    final elegida = await abrirBusquedaNacionalidad(
      context,
      opciones: _nacionalidades,
      actual: _nacionalidad,
    );
    if (elegida != null && mounted) {
      setState(() => _nacionalidad = elegida);
    }
  }

  Future<void> _cambiarFoto() async {
    final sesion = ref.read(sesionProvider);
    if (!sesion.autenticado || sesion.usuario == null) {
      mostrarSnackHaku(context, 'Inicia sesión para cambiar la foto');
      return;
    }
    if (!supabaseListo) {
      mostrarSnackHaku(context, 'Sin conexión. Intenta de nuevo.');
      return;
    }

    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: PaletaRutas.carbon,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: PaletaRutas.piedra),
              title: Text(
                'Galería',
                style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_camera_outlined, color: PaletaRutas.piedra),
              title: Text(
                'Cámara',
                style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (origen == null) return;

    final file = await _picker.pickImage(
      source: origen,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _guardando = true);
    try {
      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();
      final ext = name.endsWith('.png')
          ? 'png'
          : (name.endsWith('.webp') ? 'webp' : 'jpg');
      final contentType = ext == 'png'
          ? 'image/png'
          : (ext == 'webp' ? 'image/webp' : 'image/jpeg');

      final url = await _perfilSvc.subirFotoPerfil(
        userId: sesion.usuario!.id,
        bytes: bytes,
        contentType: contentType,
        extension: ext,
      );
      await ref
          .read(sesionProvider.notifier)
          .sincronizarDesdeAuth(clienteSupabase.auth.currentUser!);
      if (!mounted) return;
      setState(() => _fotoUrl = url);
      mostrarSnackHaku(context, 'Foto actualizada', destacado: true);
    } on StorageException catch (e) {
      if (!mounted) return;
      mostrarSnackHaku(context, e.message);
    } catch (e) {
      if (!mounted) return;
      mostrarSnackHaku(context, 'No se pudo subir la foto');
      debugPrint('Foto perfil: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _guardarPerfil() async {
    final sesion = ref.read(sesionProvider);
    if (!sesion.autenticado || sesion.usuario == null) {
      mostrarSnackHaku(context, 'Inicia sesión para guardar');
      return;
    }
    final nombres = _nombres.text.trim();
    final apellidos = _apellidos.text.trim();
    final nickRaw = _nick.text.trim();
    final nac = _nacionalidad;

    if (nombres.isEmpty || apellidos.isEmpty || nickRaw.isEmpty) {
      mostrarSnackHaku(context, 'Completa nombres, apellidos y nickname');
      return;
    }
    if (nac == null) {
      mostrarSnackHaku(context, 'Elige tu nacionalidad');
      return;
    }
    var nick = nickRaw;
    if (nick.startsWith('@')) nick = nick.substring(1);
    if (nick.length < 3 || nick.length > 50) {
      mostrarSnackHaku(context, 'Nickname: 3 a 50 caracteres');
      return;
    }
    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(nick)) {
      mostrarSnackHaku(context, 'Nickname: solo letras, números y _');
      return;
    }

    setState(() => _guardando = true);
    try {
      await _perfilSvc.actualizarDatosPerfil(
        userId: sesion.usuario!.id,
        nombres: nombres,
        apellidos: apellidos,
        nombreNick: nick,
        nacionalidadId: nac.id,
      );
      final user = clienteSupabase.auth.currentUser;
      if (user != null) {
        await ref.read(sesionProvider.notifier).sincronizarDesdeAuth(user);
      }
      if (!mounted) return;
      mostrarSnackHaku(context, 'Perfil guardado', destacado: true);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (msg.contains('nombre_nick') || msg.contains('duplicate')) {
        mostrarSnackHaku(context, 'Ese nickname ya está en uso');
      } else {
        mostrarSnackHaku(context, e.message);
      }
    } catch (e) {
      if (!mounted) return;
      mostrarSnackHaku(context, 'No se pudo guardar el perfil');
      debugPrint('Guardar perfil: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _guardarClave() async {
    final sesion = ref.read(sesionProvider);
    if (!sesion.autenticado || sesion.usuario == null) {
      mostrarSnackHaku(context, 'Inicia sesión');
      return;
    }
    if (_guardando) return;

    final nueva = _claveNueva.text.trim();
    final nueva2 = _claveNueva2.text.trim();

    if (nueva.isEmpty || nueva2.isEmpty) {
      mostrarSnackHaku(
        context,
        _tieneClaveEmail
            ? 'Completa la contraseña actual y la nueva'
            : 'Completa la nueva contraseña y la confirmación',
      );
      return;
    }
    if (nueva.length < 6) {
      mostrarSnackHaku(context, 'La nueva debe tener al menos 6 caracteres');
      return;
    }
    if (nueva != nueva2) {
      mostrarSnackHaku(context, 'Las contraseñas nuevas no coinciden');
      return;
    }

    if (_tieneClaveEmail) {
      final actual = _claveActual.text;
      if (actual.isEmpty) {
        mostrarSnackHaku(context, 'Completa la contraseña actual y la nueva');
        return;
      }
      setState(() => _guardando = true);
      try {
        await _perfilSvc.actualizarContrasena(
          correo: sesion.usuario!.correo,
          claveActual: actual,
          claveNueva: nueva,
        );
        _claveActual.clear();
        _claveNueva.clear();
        _claveNueva2.clear();
        if (!mounted) return;
        mostrarSnackHaku(context, 'Contraseña actualizada', destacado: true);
      } on AuthException catch (e) {
        if (!mounted) return;
        mostrarSnackHaku(
          context,
          MensajesAuthHaku.desdeAuthException(e, ctx: AuthContexto.clave),
        );
      } catch (e) {
        if (!mounted) return;
        mostrarSnackHaku(context, 'No se pudo cambiar la contraseña');
        debugPrint('Clave: $e');
      } finally {
        if (mounted) setState(() => _guardando = false);
      }
      return;
    }

    // Opción A: Google-only → crear clave con JWT.
    setState(() => _guardando = true);
    try {
      await _perfilSvc.crearContrasena(nueva);
      _claveNueva.clear();
      _claveNueva2.clear();
      await _marcarClaveCreadaLocal(sesion.usuario!.id);
      if (!mounted) return;
      setState(() => _tieneClaveEmail = true);
      mostrarSnackHaku(
        context,
        'Contraseña agregada. Ya puedes usarla al iniciar sesión.',
        destacado: true,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      mostrarSnackHaku(
        context,
        MensajesAuthHaku.desdeAuthException(e, ctx: AuthContexto.clave),
      );
    } catch (e) {
      if (!mounted) return;
      mostrarSnackHaku(context, 'No se pudo crear la contraseña');
      debugPrint('Crear clave: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _deco(String label, {Widget? suffix, IconData? icono}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
      prefixIcon: icono == null
          ? null
          : Icon(icono, color: PaletaRutas.plomoClaro, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: PaletaRutas.ink,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PaletaRutas.oro),
      ),
    );
  }

  Widget _seccion({
    required String titulo,
    String? subtitulo,
    required List<Widget> hijos,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TipografiaHaku.titulo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: PaletaRutas.piedra,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitulo,
              style: TipografiaHaku.interfaz(
                fontSize: 12,
                color: PaletaRutas.plomoClaro,
              ),
            ),
          ],
          SizedBox(height: subtitulo != null ? 12 : 14),
          ...hijos,
        ],
      ),
    );
  }

  Widget _botonOro(String texto, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: FilledButton(
        onPressed: (_guardando || onPressed == null) ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: PaletaRutas.oro,
          foregroundColor: PaletaRutas.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _guardando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PaletaRutas.ink,
                ),
              )
            : Text(
                texto,
                style: TipografiaHaku.interfaz(
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.ink,
                ),
              ),
      ),
    );
  }

  /// Con clave HAKU: cambiar (actual + nueva).
  /// Solo Google: crear clave con sesión activa (opción A, sin SMTP).
  Widget _seccionClave() {
    if (_tieneClaveEmail) {
      return _seccion(
        titulo: 'Contraseña',
        subtitulo: 'Usa tu contraseña actual para cambiarla',
        hijos: [
          _campoClave(
            controller: _claveActual,
            label: 'Contraseña actual',
            ocultar: _ocultarActual,
            onToggle: () => setState(() => _ocultarActual = !_ocultarActual),
          ),
          const SizedBox(height: 10),
          _campoClave(
            controller: _claveNueva,
            label: 'Nueva contraseña (mín. 6)',
            ocultar: _ocultarNueva,
            onToggle: () => setState(() => _ocultarNueva = !_ocultarNueva),
          ),
          const SizedBox(height: 10),
          _campoClave(
            controller: _claveNueva2,
            label: 'Confirmar nueva',
            ocultar: _ocultarNueva2,
            onToggle: () => setState(() => _ocultarNueva2 = !_ocultarNueva2),
          ),
          const SizedBox(height: 14),
          _botonOro('Cambiar contraseña', _guardarClave),
        ],
      );
    }

    return _seccion(
      titulo: 'Contraseña',
      subtitulo:
          'Entraste con Google. Crea una contraseña para también '
          'iniciar sesión con tu correo.',
      hijos: [
        _campoClave(
          controller: _claveNueva,
          label: 'Nueva contraseña (mín. 6)',
          ocultar: _ocultarNueva,
          onToggle: () => setState(() => _ocultarNueva = !_ocultarNueva),
        ),
        const SizedBox(height: 10),
        _campoClave(
          controller: _claveNueva2,
          label: 'Confirmar nueva',
          ocultar: _ocultarNueva2,
          onToggle: () => setState(() => _ocultarNueva2 = !_ocultarNueva2),
        ),
        const SizedBox(height: 14),
        _botonOro('Crear contraseña', _guardarClave),
      ],
    );
  }

  Widget _campoClave({
    required TextEditingController controller,
    required String label,
    required bool ocultar,
    required VoidCallback? onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: ocultar,
      style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
      cursorColor: PaletaRutas.oro,
      decoration: _deco(
        label,
        icono: Icons.lock_outline_rounded,
        suffix: IconButton(
          onPressed: onToggle,
          icon: Icon(
            ocultar
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: PaletaRutas.plomoClaro,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    final foto = CatalogoImagenesHaku.resolverAvatar(_fotoUrl);

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: FondoSuaveSeccion(
        color: PaletaRutas.ink,
        opacidadImagen: 0,
        opacidadVelo: 0,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Configuración',
                        style: TipografiaHaku.titulo(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: LineaEncabezadoInca(altura: 2),
              ),
              Expanded(
                child: _cargando
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: PaletaRutas.oro,
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
                        children: [
                          _seccion(
                            titulo: 'Foto de perfil',
                            subtitulo: 'Toca la cámara para cambiar tu foto',
                            hijos: [
                              Center(
                                child: Stack(
                                  children: [
                                    ClipOval(
                                      child: SizedBox(
                                        width: 96,
                                        height: 96,
                                        child: ImagenHaku(
                                          url: foto,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Material(
                                        color: PaletaRutas.oro,
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap:
                                              _guardando ? null : _cambiarFoto,
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.camera_alt_rounded,
                                              size: 18,
                                              color: PaletaRutas.ink,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _seccion(
                            titulo: 'Datos personales',
                            hijos: [
                              TextField(
                                controller: _nombres,
                                textCapitalization: TextCapitalization.words,
                                style: TipografiaHaku.interfaz(
                                  color: PaletaRutas.piedra,
                                ),
                                cursorColor: PaletaRutas.oro,
                                decoration: _deco(
                                  'Nombres',
                                  icono: Icons.badge_outlined,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _apellidos,
                                textCapitalization: TextCapitalization.words,
                                style: TipografiaHaku.interfaz(
                                  color: PaletaRutas.piedra,
                                ),
                                cursorColor: PaletaRutas.oro,
                                decoration: _deco(
                                  'Apellidos',
                                  icono: Icons.badge_outlined,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _nick,
                                style: TipografiaHaku.interfaz(
                                  color: PaletaRutas.piedra,
                                ),
                                cursorColor: PaletaRutas.oro,
                                decoration: _deco(
                                  'Nickname',
                                  icono: Icons.alternate_email_rounded,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  'Así te ven en HAKU',
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 12,
                                    color: PaletaRutas.plomoClaro,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Nacionalidad',
                                style: TipografiaHaku.interfaz(
                                  fontSize: 12,
                                  color: PaletaRutas.plomoClaro,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SelectorNacionalidad(
                                seleccionada: _nacionalidad,
                                cargando: false,
                                error: _errorNac,
                                onTap: _abrirNacionalidad,
                              ),
                              const SizedBox(height: 14),
                              _botonOro('Guardar perfil', _guardarPerfil),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _seccion(
                            titulo: 'Correo',
                            subtitulo: 'Por ahora no se puede cambiar',
                            hijos: [
                              Opacity(
                                opacity: 0.55,
                                child: IgnorePointer(
                                  child: TextField(
                                    controller: _correo,
                                    enabled: false,
                                    readOnly: true,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TipografiaHaku.interfaz(
                                      color: PaletaRutas.piedra,
                                    ),
                                    decoration: _deco(
                                      'Correo electrónico',
                                      icono: Icons.mail_outline_rounded,
                                      suffix: const Icon(
                                        Icons.lock_outline_rounded,
                                        color: PaletaRutas.plomo,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _seccionClave(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
