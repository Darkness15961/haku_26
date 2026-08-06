import 'dart:ui';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../dominio/modelos/destino_experiencia.dart';

/// Componente visual inmersivo a pantalla completa con animaciones de entrada
/// y micro-interacciones que dan vida a la experiencia turística.
class TarjetaExperienciaInmersiva extends StatefulWidget {
  final DestinoExperiencia destino;
  final VoidCallback? onComenzarAventura;

  const TarjetaExperienciaInmersiva({
    super.key,
    required this.destino,
    this.onComenzarAventura,
  });

  @override
  State<TarjetaExperienciaInmersiva> createState() =>
      _EstadoTarjetaExperienciaInmersiva();
}

class _EstadoTarjetaExperienciaInmersiva
    extends State<TarjetaExperienciaInmersiva>
    with TickerProviderStateMixin {
  late AnimationController _controladorEntrada;
  late AnimationController _controladorFlotante;
  late Animation<double> _animacionOpacidad;
  late Animation<Offset> _animacionDeslizar;
  late Animation<double> _animacionEscalaBadge;
  late Animation<double> _animacionBoton;

  @override
  void initState() {
    super.initState();

    // Animación de entrada del contenido inferior
    _controladorEntrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animacionOpacidad = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controladorEntrada,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animacionDeslizar = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controladorEntrada,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _animacionEscalaBadge = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controladorEntrada,
        curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animacionBoton = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controladorEntrada,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Animación flotante sutil continua (breathing effect)
    _controladorFlotante = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Iniciar animación de entrada
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controladorEntrada.forward();
    });
  }

  @override
  void dispose() {
    _controladorEntrada.dispose();
    _controladorFlotante.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destino = widget.destino;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Imagen de Fondo Inmersiva — Pantalla Completa
        CachedNetworkImage(
          imageUrl: destino.rutaImagen,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: const Color(0xFFF0DFC0),
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Color(0xFFF3C677),
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: const Color(0xFFF0DFC0),
            child: Icon(
              Icons.landscape_rounded,
              color: const Color(0xFF8B5E3C).withValues(alpha: 0.4),
              size: 64,
            ),
          ),
        ),

        // 2. Degradado Inferior Mejorado
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.35, 0.65, 0.85, 1.0],
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.4),
                Colors.black.withValues(alpha: 0.78),
                Colors.black.withValues(alpha: 0.95),
              ],
            ),
          ),
        ),

        // 3. Badge de Ubicación con animación de escala
        Positioned(
          top: 14,
          left: 20,
          child: SafeArea(
            child: ScaleTransition(
              scale: _animacionEscalaBadge,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4332).withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFC9A84C).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFF3C677),
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          destino.ubicacionBadge,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 4. Contenido Inferior con animaciones de entrada
        Positioned(
          left: 20,
          right: 20,
          bottom: 24 + bottomPadding,
          child: SlideTransition(
            position: _animacionDeslizar,
            child: FadeTransition(
              opacity: _animacionOpacidad,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Etiqueta de Categoría con punto animado
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _controladorFlotante,
                        builder: (context, child) {
                          return Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.lerp(
                                const Color(0xFFC9A84C),
                                const Color(0xFFF3C677),
                                _controladorFlotante.value,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF3C677).withValues(
                                    alpha: 0.4 + _controladorFlotante.value * 0.3,
                                  ),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      Text(
                        destino.categoriaEtiqueta.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF3C677),
                          letterSpacing: 3.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Título Principal Serif
                  Text(
                    destino.tituloPrincipal,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 46,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: -0.5,
                    ),
                  ),

                  // Subtítulo Resaltado en Color Acento
                  Text(
                    destino.subtituloResaltado,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: destino.colorAccento,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Descripción
                  Text(
                    destino.descripcionDetallada,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.45,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  // Tags en Píldoras
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: destino.tags.map((tag) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFC9A84C).withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Botón CTA con animación
                  ScaleTransition(
                    scale: _animacionBoton,
                    child: AnimatedBuilder(
                      animation: _controladorFlotante,
                      builder: (context, child) {
                        final floatY = math.sin(_controladorFlotante.value * math.pi) * 2;
                        return Transform.translate(
                          offset: Offset(0, -floatY),
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: double.infinity,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onComenzarAventura,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFC9A84C),
                                    Color(0xFF8B5E3C),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFC9A84C).withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    destino.textoAccion,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sub-leyenda
                  Center(
                    child: Text(
                      destino.subtextoAccion,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
