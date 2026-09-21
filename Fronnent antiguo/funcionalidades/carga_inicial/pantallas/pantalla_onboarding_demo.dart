import 'package:flutter/material.dart';

import '../../../nucleo/demo/preferencias_demo_haku.dart';
import '../../../nucleo/recursos/copy_haku.dart';
import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';

/// Intro corta — simulación local, sin backend.
class PantallaOnboardingDemo extends StatefulWidget {
  const PantallaOnboardingDemo({
    super.key,
    required this.siguiente,
    this.alCompletarPop = false,
  });

  final Widget siguiente;
  /// Desde Configuración: cierra al terminar en lugar de reemplazar la ruta.
  final bool alCompletarPop;

  @override
  State<PantallaOnboardingDemo> createState() => _EstadoPantallaOnboardingDemo();
}

class _EstadoPantallaOnboardingDemo extends State<PantallaOnboardingDemo> {
  final _paginas = PageController();
  int _indice = 0;

  static const _pasos = [
    _PasoOnboarding(
      icono: Icons.auto_awesome_rounded,
      titulo: CopyHaku.onboarding1Titulo,
      texto: CopyHaku.onboarding1Texto,
    ),
    _PasoOnboarding(
      icono: Icons.add_a_photo_outlined,
      titulo: CopyHaku.onboarding2Titulo,
      texto: CopyHaku.onboarding2Texto,
    ),
    _PasoOnboarding(
      icono: Icons.groups_rounded,
      titulo: CopyHaku.onboarding3Titulo,
      texto: CopyHaku.onboarding3Texto,
    ),
  ];

  Future<void> _entrar() async {
    await PreferenciasDemoHaku.marcarOnboardingVisto();
    if (!mounted) return;
    if (widget.alCompletarPop) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => widget.siguiente,
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  void _siguiente() {
    if (_indice >= _pasos.length - 1) {
      _entrar();
      return;
    }
    _paginas.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    final ultimo = _indice >= _pasos.length - 1;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _entrar,
                child: Text(
                  'Saltar',
                  style: TipografiaHaku.interfaz(
                    fontWeight: FontWeight.w600,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _paginas,
                itemCount: _pasos.length,
                onPageChanged: (i) => setState(() => _indice = i),
                itemBuilder: (context, i) {
                  final paso = _pasos[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: PaletaRutas.oro.withValues(alpha: 0.14),
                            border: Border.all(
                              color: PaletaRutas.oro.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(
                            paso.icono,
                            size: 40,
                            color: PaletaRutas.oro,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          paso.titulo,
                          textAlign: TextAlign.center,
                          style: TipografiaHaku.titulo(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: PaletaRutas.piedra,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          paso.texto,
                          textAlign: TextAlign.center,
                          style: TipografiaHaku.interfaz(
                            fontSize: 15,
                            height: 1.5,
                            color: PaletaRutas.plomoClaro,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pasos.length, (i) {
                  final activo = i == _indice;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: activo ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: activo
                          ? PaletaRutas.oro
                          : PaletaRutas.plomo.withValues(alpha: 0.45),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: LineaEncabezadoInca(altura: 2),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 18, 24, bottom),
              child: BotonPrimarioRuta(
                texto: ultimo ? 'Empezar' : 'Siguiente',
                icono: ultimo ? Icons.explore_rounded : Icons.arrow_forward_rounded,
                onPressed: _siguiente,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasoOnboarding {
  const _PasoOnboarding({
    required this.icono,
    required this.titulo,
    required this.texto,
  });

  final IconData icono;
  final String titulo;
  final String texto;
}
