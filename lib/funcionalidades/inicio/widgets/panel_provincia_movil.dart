import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../lugares/pantallas/pantalla_explora_lugares.dart';
import '../proveedores/proveedor_mapa_cusco.dart';
import 'tarjeta_provincia.dart';

/// Panel inferior deslizable diseñado como un Muro de Cantería Inca con Frizo Dorado.
class PanelProvinciaMobile extends ConsumerWidget {
  const PanelProvinciaMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(mapasCuscoProvider);
    final provincia = estado.provinciaSeleccionada;
    final destinos = estado.top3ProvinciaSeleccionada;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
      child: provincia != null
          ? DraggableScrollableSheet(
              key: ValueKey('panel_${provincia.id}'),
              initialChildSize: 0.45,
              minChildSize: 0.16,
              maxChildSize: 0.85,
              snap: true,
              snapSizes: const [0.16, 0.45, 0.85],
              builder: (context, scrollController) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Frizo Inca Dorado en la cornisa superior del panel
                    SizedBox(
                      height: 10,
                      width: double.infinity,
                      child: SvgPicture.asset(
                        'assets/iconos/lineas_inca.svg',
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          const Color(0xFFD4AF37).withValues(alpha: 0.7),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF231914),
                                  Color(0xFF130D09),
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 35,
                                  offset: const Offset(0, -10),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              controller: scrollController,
                              child: TarjetaProvincia(
                                provincia: provincia,
                                destinos: destinos,
                                onExplorar: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const PantallaExploraLugares(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            )
          : const SizedBox.shrink(key: ValueKey('panel_vacio')),
    );
  }
}
