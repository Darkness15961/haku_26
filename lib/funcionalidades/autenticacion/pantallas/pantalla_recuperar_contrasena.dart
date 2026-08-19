import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import 'pantalla_iniciar_sesion.dart';

/// Recuperación de contraseña por correo.
class PantallaRecuperarContrasena extends StatefulWidget {
  const PantallaRecuperarContrasena({super.key});

  @override
  State<PantallaRecuperarContrasena> createState() =>
      _EstadoPantallaRecuperarContrasena();
}

class _EstadoPantallaRecuperarContrasena
    extends State<PantallaRecuperarContrasena> {
  final _correoCtrl = TextEditingController();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ingresa un correo válido'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black.withValues(alpha: 0.9),
        ),
      );
      return;
    }
    setState(() => _cargando = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _enviado = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 20;

    return Scaffold(
      backgroundColor: Colors.white,
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
                      color: PaletaRutas.marronOscuro,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '¿Olvidaste?',
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.titulo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
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
              child: FondoSuaveSeccion(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, bottom),
                  children: [
                    Text(
                      'Te enviamos un enlace al correo.',
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.interfaz(
                        fontSize: 14,
                        height: 1.4,
                        color: PaletaRutas.marronOscuro.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Correo',
                      style: TipografiaHaku.interfaz(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _correoCtrl,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_enviado,
                      style: TipografiaHaku.interfaz(fontSize: 14),
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
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.92),
                            foregroundColor: Colors.white,
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
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Enviar correo de recuperación',
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Revisa tu correo.',
                          textAlign: TextAlign.center,
                          style: TipografiaHaku.interfaz(
                            fontSize: 13,
                            color: Colors.white,
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
                          color: PaletaRutas.verdeBosque,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Caduca en 24 h.',
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.interfaz(
                        fontSize: 11,
                        color: PaletaRutas.marronOscuro.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
