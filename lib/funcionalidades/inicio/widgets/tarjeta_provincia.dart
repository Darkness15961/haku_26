import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../dominio/modelos/destino_destacado.dart';
import '../dominio/modelos/provincia.dart';
import 'ranking_destinos.dart';

/// Tarjeta informativa de la provincia seleccionada inspirada en portadas y muros de piedra Inca.
class TarjetaProvincia extends StatelessWidget {
  final Provincia provincia;
  final List<DestinoDestacado> destinos;
  final VoidCallback? onExplorar;

  const TarjetaProvincia({
    super.key,
    required this.provincia,
    required this.destinos,
    this.onExplorar,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _ContenidoTarjeta(
        key: ValueKey(provincia.id),
        provincia: provincia,
        destinos: destinos,
        onExplorar: onExplorar,
      ),
    );
  }
}

class _ContenidoTarjeta extends StatelessWidget {
  final Provincia provincia;
  final List<DestinoDestacado> destinos;
  final VoidCallback? onExplorar;

  const _ContenidoTarjeta({
    super.key,
    required this.provincia,
    required this.destinos,
    this.onExplorar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle de Arrastre — Bloque de Piedra Labrada
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: ShapeDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                shape: const BeveledRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                ),
                shadows: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),

          // Cabecera: Nombre + Indicador + Altitud
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Punto de Color Temático
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: provincia.colorBase,
                  boxShadow: [
                    BoxShadow(
                      color: provincia.colorBase.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Nombre de la Provincia
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provincia.nombre,
                      style: GoogleFonts.cinzel(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                        shadows: [
                          Shadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Destino principal: ${provincia.destinoPrincipal}',
                      style: GoogleFonts.crimsonText(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFFF3C677),
                      ),
                    ),
                  ],
                ),
              ),
              // Altitud en Bloque de Piedra Angular (Beveled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: ShapeDecoration(
                  color: const Color(0xFF281E17),
                  shape: const BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                      topRight: Radius.circular(3),
                      bottomLeft: Radius.circular(3),
                    ),
                    side: BorderSide(
                      color: Color(0xFFD4AF37),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  '${provincia.altitudMedia} msnm',
                  style: GoogleFonts.cinzel(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF3C677),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Descripción Breve
          Text(
            provincia.descripcion,
            style: GoogleFonts.crimsonText(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // Ranking de Destinos
          if (destinos.isNotEmpty)
            RankingDestinos(
              destinos: destinos,
              titulo: 'Top destinos en ${provincia.nombreCorto}',
            ),
          const SizedBox(height: 18),

          // Botón Explorar Provincia — Lintel de Piedra Megalítica Inca
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onExplorar,
                customBorder: const BeveledRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: ShapeDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF3B281B),
                        Color(0xFF21140B),
                      ],
                    ),
                    shape: const BeveledRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                      side: BorderSide(
                        color: Color(0xFFD4AF37),
                        width: 1.5,
                      ),
                    ),
                    shadows: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'EXPLORAR ${provincia.nombreCorto.toUpperCase()}',
                        style: GoogleFonts.cinzel(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFF3C677),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFFF3C677),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
