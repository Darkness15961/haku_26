import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../proveedores/proveedor_mapa_cusco.dart';

/// Encabezado basado en la arquitectura Inca de Megalitos y Piedras de Ángulos Definidos.
class EncabezadoExploraCusco extends ConsumerWidget {
  const EncabezadoExploraCusco({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fila Superior: Bloque de Piedra HAKU + Botones de Acción de Piedra Tallada
            Row(
              children: [
                // Badge HAKU — Tocar restaura el mapa completo
                Material(
                  color: Colors.transparent,
                  shape: const BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      ref.read(mapasCuscoProvider.notifier).deseleccionarProvincia();
                    },
                    customBorder: const BeveledRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFF3F5E3B),
                        shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                            topRight: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                          ),
                          side: BorderSide(
                            color: Color(0xFF2D432B),
                            width: 1,
                          ),
                        ),
                        shadows: [
                          BoxShadow(
                            color: const Color(0xFF3B2E22).withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/iconos/chacana.svg',
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFF6F0E2),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'HAKU',
                            style: TipografiaHaku.logo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF6F0E2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Botón Búsqueda — Bloque de Piedra Angular
                _BotonAccionPiedraInca(
                  icono: Icons.search_rounded,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                // Botón Filtros — Bloque de Piedra Angular
                _BotonAccionPiedraInca(
                  icono: Icons.tune_rounded,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Franja Inca Horizontal
            ClipRect(
              child: SizedBox(
                height: 10,
                width: double.infinity,
                child: SvgPicture.asset(
                  'assets/iconos/lineas_inca.svg',
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    const Color(0xFF8B5E3C).withValues(alpha: 0.55),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Título Principal Estilo Grabado — Tocar deselecciona la provincia y restaura el mapa completo
            GestureDetector(
              onTap: () {
                ref.read(mapasCuscoProvider.notifier).deseleccionarProvincia();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explora Cusco',
                    style: TipografiaHaku.titulo(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3B2E22),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '13 provincias',
                    style: TipografiaHaku.interfaz(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8A5A3C),
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

/// Botón de Acción con Forma de Bloque de Piedra Polygonal Inca (Beveled)
class _BotonAccionPiedraInca extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;

  const _BotonAccionPiedraInca({
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const BeveledRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
            topRight: Radius.circular(3),
            bottomLeft: Radius.circular(3),
          ),
        ),
        child: Container(
          width: 38,
          height: 38,
          decoration: ShapeDecoration(
            color: const Color(0xFF3F5E3B),
            shape: const BeveledRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
                topRight: Radius.circular(3),
                bottomLeft: Radius.circular(3),
              ),
              side: BorderSide(
                color: Color(0xFF2D432B),
                width: 1,
              ),
            ),
            shadows: [
              BoxShadow(
                color: const Color(0xFF3B2E22).withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icono,
            color: const Color(0xFFF6F0E2),
            size: 18,
          ),
        ),
      ),
    );
  }
}
