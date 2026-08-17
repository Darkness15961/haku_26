import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lugares/pantallas/pantalla_explora_lugares.dart';
import '../proveedores/proveedor_mapa_cusco.dart';
import 'tarjeta_provincia.dart';

/// Panel lateral para dispositivos tablet y web.
///
/// Se muestra a la derecha del mapa con la información de la
/// provincia seleccionada. Usa [AnimatedSlide] para la entrada.
class PanelProvinciaLateral extends ConsumerWidget {
  const PanelProvinciaLateral({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(mapasCuscoProvider);
    final provincia = estado.provinciaSeleccionada;
    final destinos = estado.top3ProvinciaSeleccionada;
    final haySeleccion = provincia != null;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      offset: haySeleccion ? Offset.zero : const Offset(1, 0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: haySeleccion ? 1 : 0,
        child: provincia != null
            ? ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(24),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 360,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF1B2B23).withValues(alpha: 0.92),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(24),
                      ),
                      border: Border(
                        left: BorderSide(
                          color: const Color(0xFFC9A84C)
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(-10, 0),
                        ),
                      ],
                    ),
                    child: TarjetaProvincia(
                      provincia: provincia,
                      destinos: destinos,
                      onExplorar: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PantallaExploraLugares(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
