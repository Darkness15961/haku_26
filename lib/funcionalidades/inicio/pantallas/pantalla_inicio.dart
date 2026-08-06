import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../destinos/indice.dart';
import '../../favoritos/indice.dart';
import '../../perfil_usuario/indice.dart';
import '../../rutas/indice.dart';
import '../proveedores/proveedor_mapa_cusco.dart';
import '../widgets/contenido_inicio.dart';

/// Pantalla principal inspirada en la arquitectura de piedra inca.
///
/// Gestiona la navegación entre pestañas y resetea automáticamente el zoom
/// del mapa de Cusco a su estado original al cambiar de vista.
class PantallaInicio extends ConsumerStatefulWidget {
  const PantallaInicio({super.key});

  @override
  ConsumerState<PantallaInicio> createState() => _EstadoPantallaInicio();
}

class _EstadoPantallaInicio extends ConsumerState<PantallaInicio> {
  int _indiceSeleccionado = 0;

  static const List<Widget> _pantallas = [
    ContenidoInicio(),
    PantallaDestinos(),
    PantallaRutas(),
    PantallaFavoritos(),
    PantallaPerfilUsuario(),
  ];

  static const List<_ItemNavegacionData> _itemsNavegacion = [
    _ItemNavegacionData(
      iconoNormal: Icons.grid_view_outlined,
      iconoActivo: Icons.grid_view_rounded,
      etiqueta: 'Inicio',
    ),
    _ItemNavegacionData(
      iconoNormal: Icons.compass_calibration_outlined,
      iconoActivo: Icons.compass_calibration_rounded,
      etiqueta: 'Explora',
    ),
    _ItemNavegacionData(
      iconoNormal: Icons.map_outlined,
      iconoActivo: Icons.map_rounded,
      etiqueta: 'Rutas',
    ),
    _ItemNavegacionData(
      iconoNormal: Icons.bookmark_border_rounded,
      iconoActivo: Icons.bookmark_rounded,
      etiqueta: 'Guardados',
    ),
    _ItemNavegacionData(
      iconoNormal: Icons.person_outline_rounded,
      iconoActivo: Icons.person_rounded,
      etiqueta: 'Perfil',
    ),
  ];

  /// Cambia de pestaña y restaura el mapa de Cusco a su estado original.
  void _seleccionarPestania(int index) {
    // Si hay una provincia seleccionada o estamos cambiando de vista, resetear el mapa
    ref.read(mapasCuscoProvider.notifier).deseleccionarProvincia();

    setState(() {
      _indiceSeleccionado = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Pantalla actual
          IndexedStack(index: _indiceSeleccionado, children: _pantallas),

          // Marco Lateral Izquierdo (Líneas Inca SVG rotadas)
          Positioned(
            left: -8,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: SizedBox(
                width: 28,
                child: RotatedBox(
                  quarterTurns: 1,
                  child: SvgPicture.asset(
                    'assets/iconos/lineas_inca.svg',
                    fit: BoxFit.fill,
                    colorFilter: ColorFilter.mode(
                      const Color(0xFF4A2E18).withValues(alpha: 0.75),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Marco Lateral Derecho (Líneas Inca SVG rotadas)
          Positioned(
            right: -8,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: SizedBox(
                width: 28,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SvgPicture.asset(
                    'assets/iconos/lineas_inca.svg',
                    fit: BoxFit.fill,
                    colorFilter: ColorFilter.mode(
                      const Color(0xFF4A2E18).withValues(alpha: 0.75),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Frizo Inca Superior
          SizedBox(
            height: 10,
            width: double.infinity,
            child: SvgPicture.asset(
              'assets/iconos/lineas_inca.svg',
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                const Color(0xFFC9A84C).withValues(alpha: 0.6),
                BlendMode.srcIn,
              ),
            ),
          ),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 60 + bottomInset,
                padding: EdgeInsets.only(bottom: bottomInset),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF261D18),
                      Color(0xFF140E0A),
                    ],
                  ),
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 25,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_itemsNavegacion.length, (index) {
                    final item = _itemsNavegacion[index];
                    final esActivo = _indiceSeleccionado == index;

                    return GestureDetector(
                      onTap: () => _seleccionarPestania(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: ShapeDecoration(
                          color: esActivo
                              ? const Color(0xFF2E2218)
                              : Colors.transparent,
                          shape: BeveledRectangleBorder(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                              topRight: Radius.circular(3),
                              bottomLeft: Radius.circular(3),
                            ),
                            side: esActivo
                                ? const BorderSide(
                                    color: Color(0xFFD4AF37),
                                    width: 1.5,
                                  )
                                : BorderSide.none,
                          ),
                          shadows: esActivo
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (esActivo)
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 2),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFF3C677),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFF3C677),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            Icon(
                              esActivo ? item.iconoActivo : item.iconoNormal,
                              color: esActivo
                                  ? const Color(0xFFF3C677)
                                  : const Color(0xFF8B7355),
                              size: 20,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.etiqueta,
                              style: GoogleFonts.cinzel(
                                fontSize: 10,
                                fontWeight:
                                    esActivo ? FontWeight.w900 : FontWeight.w500,
                                color: esActivo
                                    ? const Color(0xFFF3C677)
                                    : const Color(0xFF8B7355),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemNavegacionData {
  final IconData iconoNormal;
  final IconData iconoActivo;
  final String etiqueta;

  const _ItemNavegacionData({
    required this.iconoNormal,
    required this.iconoActivo,
    required this.etiqueta,
  });
}
