import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../dominio/servicios/servicio_auth_supabase.dart';
import 'pantalla_iniciar_sesion.dart';

/// Recuperación de contraseña por correo (SDK).
/// También sirve si la cuenta nació en Google y quieres agregar clave (1 correo = 1 usuario).
class PantallaRecuperarContrasena extends StatefulWidget {
  const PantallaRecuperarContrasena({super.key});

  @override
  State<PantallaRecuperarContrasena> createState() =>
      _EstadoPantallaRecuperarContrasena();
}

class _EstadoPantallaRecuperarContrasena
    extends State<PantallaRecuperarContrasena> {
  final _correoCtrl = TextEditingController();
  final _auth = ServicioAuthSupabase();
  bool _enviado = false;
  bool _cargando = false;

  @override
  void dispose() {
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final correo = _correoCtrl.text.trim();
    if (correo.isEmpty || !correo.contains('@')) {
      mostrarSnackHaku(context, 'Ingresa un correo válido');
      return;
    }
    if (!supabaseListo) {
      mostrarSnackHaku(
        context,
        'No hay conexión con Auth. Revisa la configuración / reinicia la app.',
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      await _auth.enviarRecuperacionContrasena(correo);
      if (!mounted) return;
      setState(() {
        _enviado = true;
        _cargando = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      // Sin SMTP el servidor puede fallar: mensaje claro, sin jerga técnica.
      final raw = e.message.toLowerCase();
      if (raw.contains('smtp') ||
          raw.contains('error sending') ||
          raw.contains('email')) {
        mostrarSnackHaku(
          context,
          'Ahora no pudimos enviar el correo. Si tu cuenta es de Google, '
          'entra con Google. El envío de recuperación se activará con el correo del servidor.',
        );
      } else {
        mostrarSnackHaku(context, e.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      mostrarSnackHaku(
        context,
        'No se pudo enviar el correo. Si tu cuenta es de Google, entra con Google.',
      );
      debugPrint('Recuperar clave: $e');
    }
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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '¿Olvidaste?',
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.titulo(
                        fontSize: 18,
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
                padding: EdgeInsets.fromLTRB(20, 24, 20, bottom),
                children: [
                  Text(
                    _enviado
                        ? 'Si ese correo tiene cuenta, te enviamos un enlace para crear o cambiar tu contraseña.'
                        : 'Te enviaremos un enlace para crear o recuperar tu contraseña. '
                            'También sirve si entraste primero con Google.',
                    textAlign: TextAlign.center,
                    style: TipografiaHaku.interfaz(
                      fontSize: 14,
                      height: 1.4,
                      color: PaletaRutas.plomoClaro,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Correo',
                    style: TipografiaHaku.interfaz(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_enviado,
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
                  const SizedBox(height: 20),
                  if (!_enviado)
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _cargando ? null : _enviar,
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
                                'Enviar enlace',
                                style: TipografiaHaku.interfaz(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: PaletaRutas.ink,
                                ),
                              ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: PaletaRutas.carbon,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: PaletaRutas.oro.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'Revisa tu correo (y spam). Luego podrás entrar con contraseña o con Google: es la misma cuenta.',
                        textAlign: TextAlign.center,
                        style: TipografiaHaku.interfaz(
                          fontSize: 13,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Volver al inicio de sesión',
                      style: TipografiaHaku.interfaz(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.oro,
                      ),
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
