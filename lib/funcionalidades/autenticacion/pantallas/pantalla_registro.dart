import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../proveedores/proveedor_sesion.dart';
import 'pantalla_iniciar_sesion.dart';

enum TipoDocumentoRegistro { dni, carnetExtranjeria }

/// Registro con DNI / carnet, usuario, correo y contraseñas.
class PantallaRegistro extends ConsumerStatefulWidget {
  const PantallaRegistro({super.key});

  @override
  ConsumerState<PantallaRegistro> createState() => _EstadoPantallaRegistro();
}

class _EstadoPantallaRegistro extends ConsumerState<PantallaRegistro> {
  final _docCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  final _clave2Ctrl = TextEditingController();
  TipoDocumentoRegistro _tipoDoc = TipoDocumentoRegistro.dni;
  bool _ocultar1 = true;
  bool _ocultar2 = true;
  bool _cargando = false;

  @override
  void dispose() {
    _docCtrl.dispose();
    _usuarioCtrl.dispose();
    _correoCtrl.dispose();
    _claveCtrl.dispose();
    _clave2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final doc = _docCtrl.text.trim();
    final usuario = _usuarioCtrl.text.trim();
    final correo = _correoCtrl.text.trim();
    final clave = _claveCtrl.text;
    final clave2 = _clave2Ctrl.text;

    if (doc.isEmpty || usuario.isEmpty || correo.isEmpty || clave.isEmpty) {
      _aviso('Completa todos los campos');
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

    setState(() => _cargando = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    ref.read(sesionProvider.notifier).iniciarSesion(
          correo: correo,
          nombreUsuario: usuario,
          documento: doc,
          tipoDocumento: _tipoDoc == TipoDocumentoRegistro.dni
              ? 'DNI'
              : 'Carnet de extranjería',
        );
    setState(() => _cargando = false);
    Navigator.of(context).pop(true);
  }

  Future<void> _google() async {
    setState(() => _cargando = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    ref.read(sesionProvider.notifier).iniciarConGoogle();
    setState(() => _cargando = false);
    Navigator.of(context).pop(true);
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withValues(alpha: 0.9),
      ),
    );
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
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PaletaRutas.marronOscuro,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Crear cuenta',
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.titulo(
                        fontSize: 22,
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
                  padding: EdgeInsets.fromLTRB(20, 18, 20, bottom),
                  children: [
                    Text(
                      'Tipo de documento',
                      style: TipografiaHaku.interfaz(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ChipDoc(
                            etiqueta: 'DNI',
                            activo: _tipoDoc == TipoDocumentoRegistro.dni,
                            onTap: () => setState(
                              () => _tipoDoc = TipoDocumentoRegistro.dni,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ChipDoc(
                            etiqueta: 'Carnet de extranjería',
                            activo: _tipoDoc ==
                                TipoDocumentoRegistro.carnetExtranjeria,
                            onTap: () => setState(
                              () => _tipoDoc =
                                  TipoDocumentoRegistro.carnetExtranjeria,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Número de documento',
                      style: TipografiaHaku.interfaz(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _docCtrl,
                      keyboardType: TextInputType.number,
                      style: TipografiaHaku.interfaz(fontSize: 14),
                      decoration: decoracionCampoAuth(
                        _tipoDoc == TipoDocumentoRegistro.dni
                            ? '8 dígitos'
                            : 'Número de carnet',
                        icono: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Nombre de usuario',
                      style: TipografiaHaku.interfaz(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _usuarioCtrl,
                      style: TipografiaHaku.interfaz(fontSize: 14),
                      decoration: decoracionCampoAuth(
                        '@tuusuario',
                        icono: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Correo electrónico',
                      style: TipografiaHaku.interfaz(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _correoCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TipografiaHaku.interfaz(fontSize: 14),
                      decoration: decoracionCampoAuth(
                        'tu@correo.com',
                        icono: Icons.mail_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Contraseña',
                      style: TipografiaHaku.interfaz(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _claveCtrl,
                      obscureText: _ocultar1,
                      style: TipografiaHaku.interfaz(fontSize: 14),
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
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Confirmar contraseña',
                      style: TipografiaHaku.interfaz(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _clave2Ctrl,
                      obscureText: _ocultar2,
                      style: TipografiaHaku.interfaz(fontSize: 14),
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
                          backgroundColor: Colors.black.withValues(alpha: 0.92),
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
                                'Crear cuenta',
                                style: TipografiaHaku.interfaz(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
                          foregroundColor: PaletaRutas.marronOscuro,
                          side: BorderSide(
                            color: Colors.black.withValues(alpha: 0.22),
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.75),
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
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Al continuar aceptas nuestros Términos y Condiciones',
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.interfaz(
                        fontSize: 11,
                        color: PaletaRutas.marronOscuro.withValues(alpha: 0.55),
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

class _ChipDoc extends StatelessWidget {
  final String etiqueta;
  final bool activo;
  final VoidCallback onTap;

  const _ChipDoc({
    required this.etiqueta,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: activo
                ? Colors.black.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.black.withValues(alpha: activo ? 0.9 : 0.16),
            ),
          ),
          child: Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: activo ? Colors.white : PaletaRutas.marronOscuro,
            ),
          ),
        ),
      ),
    );
  }
}
