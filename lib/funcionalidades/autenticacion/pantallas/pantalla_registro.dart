import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../../nucleo/supabase/config_supabase.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/nacionalidad_datasource.dart';
import '../dominio/modelos/modelo_nacionalidad.dart';
import '../dominio/servicios/servicio_auth_supabase.dart';
import '../proveedores/proveedor_sesion.dart';
import '../widgets/selector_nacionalidad.dart';
import 'pantalla_iniciar_sesion.dart';

/// Registro MVP alineado a `public.usuario`.
/// Campos: nombres, apellidos, nickname, correo, contraseñas ×2, nacionalidad.
/// Sin foto ni documento (después).
class PantallaRegistro extends ConsumerStatefulWidget {
  const PantallaRegistro({super.key});

  @override
  ConsumerState<PantallaRegistro> createState() => _EstadoPantallaRegistro();
}

class _EstadoPantallaRegistro extends ConsumerState<PantallaRegistro> {
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _nickCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  final _clave2Ctrl = TextEditingController();
  final _auth = ServicioAuthSupabase();
  final _nacionalidadesDs = NacionalidadDataSource();

  bool _ocultar1 = true;
  bool _ocultar2 = true;
  bool _cargando = false;
  bool _cargandoNac = true;
  String? _errorNac;
  List<ModeloNacionalidad> _nacionalidades = const [];
  ModeloNacionalidad? _nacionalidad;

  @override
  void initState() {
    super.initState();
    _cargarNacionalidades();
  }

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _nickCtrl.dispose();
    _correoCtrl.dispose();
    _claveCtrl.dispose();
    _clave2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _cargarNacionalidades() async {
    setState(() {
      _cargandoNac = true;
      _errorNac = null;
    });
    try {
      if (!supabaseListo) {
        throw StateError('Supabase no listo');
      }
      final lista = await _nacionalidadesDs.listar();
      if (!mounted) return;
      if (lista.isEmpty) {
        setState(() {
          _nacionalidades = const [];
          _nacionalidad = null;
          _cargandoNac = false;
          _errorNac =
              'Catálogo vacío en el servidor. Semilla public.nacionalidad.';
        });
        return;
      }
      setState(() {
        _nacionalidades = lista;
        _nacionalidad = NacionalidadDataSource.sugerida(
          lista,
          preferirId: ConfigSupabase.nacionalidadIdDefault,
        );
        _cargandoNac = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoNac = false;
        _errorNac = 'No se pudo cargar nacionalidades';
      });
      debugPrint('Nacionalidades: $e');
    }
  }

  Future<void> _abrirNacionalidad() async {
    if (_nacionalidades.isEmpty) {
      _aviso(_errorNac ?? 'Sin nacionalidades disponibles');
      await _cargarNacionalidades();
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

  Future<void> _crear() async {
    final nombres = _nombresCtrl.text.trim();
    final apellidos = _apellidosCtrl.text.trim();
    final nickRaw = _nickCtrl.text.trim();
    final correo = _correoCtrl.text.trim();
    final clave = _claveCtrl.text;
    final clave2 = _clave2Ctrl.text;
    final nac = _nacionalidad;

    if (nombres.isEmpty ||
        apellidos.isEmpty ||
        nickRaw.isEmpty ||
        correo.isEmpty ||
        clave.isEmpty) {
      _aviso('Completa todos los campos');
      return;
    }
    if (nac == null) {
      _aviso('Elige tu nacionalidad');
      return;
    }
    if (nombres.length > 100 || apellidos.length > 100) {
      _aviso('Nombres y apellidos: máximo 100 caracteres');
      return;
    }
    if (!_correoOk(correo)) {
      _aviso('Ingresa un correo válido');
      return;
    }
    if (correo.length > 255) {
      _aviso('El correo es demasiado largo');
      return;
    }
    final nick = _normalizarNick(nickRaw);
    if (nick.length < 3) {
      _aviso('El nickname debe tener al menos 3 caracteres');
      return;
    }
    if (nick.length > 50) {
      _aviso('El nickname puede tener máximo 50 caracteres');
      return;
    }
    if (!_nickOk(nick)) {
      _aviso('Nickname: solo letras, números y _');
      return;
    }
    if (clave != clave2) {
      _aviso('Las contraseñas no coinciden');
      return;
    }
    if (clave.length < 6) {
      _aviso('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (ConfigSupabase.url.isEmpty || ConfigSupabase.anonKey.isEmpty) {
      _aviso('Supabase no está configurado (URL / anon key)');
      return;
    }
    if (!supabaseListo) {
      _aviso(
        'No hay conexión con Auth. Revisa la configuración / reinicia la app.',
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      final resultado = await _auth.registrarConCorreo(
        correo: correo,
        clave: clave,
        nombreNick: nick,
        nombres: nombres,
        apellidos: apellidos,
        nacionalidadId: nac.id,
      );

      if (!resultado.tieneSesion) {
        if (!mounted) return;
        _aviso(
          'Cuenta creada. Confirma el correo e inicia sesión '
          '(el servidor aún pide verificación).',
        );
        return;
      }
      await ref
          .read(sesionProvider.notifier)
          .sincronizarDesdeAuth(resultado.usuario);
      await ref.read(almacenFeedProvider.notifier).cargar();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (!mounted) return;
      _aviso(e.message);
    } catch (e) {
      if (!mounted) return;
      _aviso('No se pudo registrar. Revisa conexión y configuración.');
      debugPrint('Registro: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _google() async {
    _aviso('Google OAuth llega en el Bloque B');
  }

  void _aviso(String texto) {
    mostrarSnackHaku(context, texto);
  }

  static String _normalizarNick(String raw) {
    var n = raw.trim();
    if (n.startsWith('@')) n = n.substring(1);
    return n;
  }

  static bool _nickOk(String nick) {
    return RegExp(r'^[A-Za-z0-9_]+$').hasMatch(nick);
  }

  static bool _correoOk(String correo) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo);
  }

  Widget _etiqueta(String texto) {
    return Text(
      texto,
      style: TipografiaHaku.interfaz(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: PaletaRutas.piedra,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 20;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Crear cuenta',
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.titulo(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LineaEncabezadoInca(altura: 2),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 18, 20, bottom),
                children: [
                  _etiqueta('Nombres'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nombresCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    style: TipografiaHaku.interfaz(
                      fontSize: 14,
                      color: PaletaRutas.piedra,
                    ),
                    cursorColor: PaletaRutas.oro,
                    decoration: decoracionCampoAuth(
                      'Tus nombres',
                      icono: Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _etiqueta('Apellidos'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _apellidosCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    style: TipografiaHaku.interfaz(
                      fontSize: 14,
                      color: PaletaRutas.piedra,
                    ),
                    cursorColor: PaletaRutas.oro,
                    decoration: decoracionCampoAuth(
                      'Tus apellidos',
                      icono: Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _etiqueta('Nickname'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nickCtrl,
                    textInputAction: TextInputAction.next,
                    style: TipografiaHaku.interfaz(
                      fontSize: 14,
                      color: PaletaRutas.piedra,
                    ),
                    cursorColor: PaletaRutas.oro,
                    decoration: decoracionCampoAuth(
                      '@cómo te ven en HAKU',
                      icono: Icons.alternate_email_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _etiqueta('Correo electrónico'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: TipografiaHaku.interfaz(
                      fontSize: 14,
                      color: PaletaRutas.piedra,
                    ),
                    cursorColor: PaletaRutas.oro,
                    decoration: decoracionCampoAuth(
                      'tu@correo.com',
                      icono: Icons.mail_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _etiqueta('Nacionalidad'),
                  const SizedBox(height: 6),
                  SelectorNacionalidad(
                    seleccionada: _nacionalidad,
                    cargando: _cargandoNac,
                    error: _errorNac,
                    onTap: _abrirNacionalidad,
                  ),
                  if (_errorNac != null && !_cargandoNac) ...[
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _cargarNacionalidades,
                      child: Text(
                        'Reintentar catálogo',
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          color: PaletaRutas.oro,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _etiqueta('Contraseña'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _claveCtrl,
                    obscureText: _ocultar1,
                    textInputAction: TextInputAction.next,
                    style: TipografiaHaku.interfaz(
                      fontSize: 14,
                      color: PaletaRutas.piedra,
                    ),
                    cursorColor: PaletaRutas.oro,
                    decoration: decoracionCampoAuth(
                      'Mínimo 6 caracteres',
                      icono: Icons.lock_outline_rounded,
                      suffix: IconButton(
                        onPressed: () =>
                            setState(() => _ocultar1 = !_ocultar1),
                        icon: Icon(
                          _ocultar1
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _etiqueta('Confirmar contraseña'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _clave2Ctrl,
                    obscureText: _ocultar2,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_cargando) _crear();
                    },
                    style: TipografiaHaku.interfaz(
                      fontSize: 14,
                      color: PaletaRutas.piedra,
                    ),
                    cursorColor: PaletaRutas.oro,
                    decoration: decoracionCampoAuth(
                      'Repite tu contraseña',
                      icono: Icons.lock_outline_rounded,
                      suffix: IconButton(
                        onPressed: () =>
                            setState(() => _ocultar2 = !_ocultar2),
                        icon: Icon(
                          _ocultar2
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _cargando ? null : _crear,
                      style: FilledButton.styleFrom(
                        backgroundColor: PaletaRutas.oro,
                        foregroundColor: PaletaRutas.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _cargando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: PaletaRutas.ink,
                              ),
                            )
                          : Text(
                              'Crear cuenta',
                              style: TipografiaHaku.interfaz(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: PaletaRutas.ink,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _cargando ? null : _google,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PaletaRutas.piedra,
                        side: BorderSide(
                          color: PaletaRutas.plomoOscuro.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        backgroundColor: PaletaRutas.carbon,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                      label: Text(
                        'Continuar con Google',
                        style: TipografiaHaku.interfaz(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Términos y Condiciones',
                    textAlign: TextAlign.center,
                    style: TipografiaHaku.interfaz(
                      fontSize: 11,
                      color: PaletaRutas.plomo,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
