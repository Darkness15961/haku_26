import 'dart:ui';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';
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

    _controladorFlotante = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

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
        _ImagenDestinoFondo(ruta: destino.rutaImagen),
        // Solo un velo inferior minimo para leer el texto (foto tal cual arriba).
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.55, 1.0],
              colors: [
                Colors.transparent,
                Colors.transparent,
                Color(0xB3000000),
              ],
            ),
          ),
        ),
        Positioned(
          top: 14,
          left: 20,
          child: SafeArea(
            child: ScaleTransition(
              scale: _animacionEscalaBadge,
              child: _PildoraGlass(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      destino.ubicacionBadge,
                      style: TipografiaHaku.interfaz(
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
                  Text(
                    destino.categoriaEtiqueta.toUpperCase(),
                    style: TipografiaHaku.interfaz(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB8D4A8),
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    destino.subtituloResaltado.isEmpty
                        ? destino.tituloPrincipal
                        : '${destino.tituloPrincipal}\n${destino.subtituloResaltado}',
                    style: TipografiaHaku.titulo(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.05,
                    ).copyWith(
                      shadows: const [
                        Shadow(
                          color: Color(0x99000000),
                          blurRadius: 14,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  if (destino.descripcionDetallada.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      destino.descripcionDetallada,
                      style: TipografiaHaku.interfaz(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 18),
                  ScaleTransition(
                    scale: _animacionBoton,
                    child: AnimatedBuilder(
                      animation: _controladorFlotante,
                      builder: (context, child) {
                        final floatY =
                            math.sin(_controladorFlotante.value * math.pi) * 2;
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
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    destino.textoAccion,
                                    style: TipografiaHaku.interfaz(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Soporta URL (http) o asset local (`assets/...`).
class _ImagenDestinoFondo extends StatelessWidget {
  final String ruta;

  const _ImagenDestinoFondo({required this.ruta});

  @override
  Widget build(BuildContext context) {
    final esRed = ruta.startsWith('http');
    if (esRed) {
      return CachedNetworkImage(
        imageUrl: ruta,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => const ColoredBox(
          color: PaletaRutas.arena,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: PaletaRutas.crema,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => ColoredBox(
          color: PaletaRutas.arena,
          child: Icon(
            Icons.landscape_rounded,
            color: PaletaRutas.marronCuero.withValues(alpha: 0.4),
            size: 64,
          ),
        ),
      );
    }

    return Image.asset(
      ruta,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: PaletaRutas.arena,
        child: Icon(
          Icons.landscape_rounded,
          color: PaletaRutas.marronCuero.withValues(alpha: 0.4),
          size: 64,
        ),
      ),
    );
  }
}

/// Vidrio vintage: blanco translúcido + borde blanco + blur.
class _PildoraGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double opacidadFondo;

  const _PildoraGlass({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    this.borderRadius = 20,
    this.opacidadFondo = 0.16,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacidadFondo),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
