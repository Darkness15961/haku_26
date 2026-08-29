import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../../../nucleo/metricas/metricas_descubrimiento.dart';
import '../proveedores/proveedor_sesion.dart';
import 'pantalla_recuperar_contrasena.dart';
import 'pantalla_registro.dart';

/// Iniciar sesión: correo, contraseña, Google, registro y recuperación.
class PantallaIniciarSesion extends ConsumerStatefulWidget {
  const PantallaIniciarSesion({super.key});

  @override
  ConsumerState<PantallaIniciarSesion> createState() =>
      _EstadoPantallaIniciarSesion();
}

class _EstadoPantallaIniciarSesion
    extends ConsumerState<PantallaIniciarSesion> {
  final _correoCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  bool _ocultarClave = true;
  bool _cargando = false;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _claveCtrl.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    final correo = _correoCtrl.text.trim();
    final clave = _claveCtrl.text;
    if (correo.isEmpty || clave.isEmpty) {
      _aviso('Ingresa correo y contraseña');
      return;
    }
    setState(() => _cargando = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    await ref.read(sesionProvider.notifier).iniciarSesion(
          correo: correo,
          nombreUsuario: correo.split('@').first,
        );
    await ref.read(almacenFeedProvider.notifier).cargar();
    if (!mounted) return;
    setState(() => _cargando = false);
    Navigator.of(context).pop(true);
  }

  Future<void> _google() async {
    setState(() => _cargando = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await ref.read(sesionProvider.notifier).iniciarConGoogle();
    await ref.read(almacenFeedProvider.notifier).cargar();
    await ref.read(metricasDescubrimientoProvider.notifier).reiniciarDemo();
    if (!mounted) return;
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
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
                        Icons.close_rounded,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Iniciar sesión',
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
                  padding: EdgeInsets.fromLTRB(20, 24, 20, bottom),
                  children: [
                    Text(
                      'HAKU',
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.logo(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.oro,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Entrar',
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.interfaz(
                        fontSize: 14,
                        color: PaletaRutas.plomoClaro,
                      ),
                    ),
                    const SizedBox(height: 28),
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
                    Text(
                      'Contraseña',
                      style: TipografiaHaku.interfaz(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _claveCtrl,
                      obscureText: _ocultarClave,
                      style: TipografiaHaku.interfaz(
                        fontSize: 14,
                        color: PaletaRutas.piedra,
                      ),
                      cursorColor: PaletaRutas.oro,
                      decoration: decoracionCampoAuth(
                        '••••••••',
                        icono: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          onPressed: () => setState(
                            () => _ocultarClave = !_ocultarClave,
                          ),
                          icon: Icon(
                            _ocultarClave
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: PaletaRutas.plomoClaro,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const PantallaRecuperarContrasena(),
                            ),
                          );
                        },
                        child: Text(
                          '¿Olvidaste?',
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.oro,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _cargando ? null : _ingresar,
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
                                'Iniciar sesión',
                                style: TipografiaHaku.interfaz(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: PaletaRutas.ink,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: PaletaRutas.plomoOscuro.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'o',
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: PaletaRutas.plomo,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: PaletaRutas.plomoOscuro.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
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
                          'Iniciar sesión con Google',
                          style: TipografiaHaku.interfaz(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '¿Sin cuenta? ',
                          style: TipografiaHaku.interfaz(
                            fontSize: 13,
                            color: PaletaRutas.plomoClaro,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final ok = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => const PantallaRegistro(),
                              ),
                            );
                            if (!mounted) return;
                            if (ok == true) {
                              Navigator.of(context).pop(true);
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Crear',
                            style: TipografiaHaku.interfaz(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: PaletaRutas.oro,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
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
      ),
    );
  }
}

InputDecoration decoracionCampoAuth(
  String hint, {
  IconData? icono,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TipografiaHaku.interfaz(
      fontSize: 14,
      color: PaletaRutas.plomo,
    ),
    prefixIcon: icono == null
        ? null
        : Icon(icono, color: PaletaRutas.plomoClaro),
    suffixIcon: suffix,
    filled: true,
    fillColor: PaletaRutas.carbon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
      borderSide: const BorderSide(color: PaletaRutas.oro, width: 1.2),
    ),
  );
}
