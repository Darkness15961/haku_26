import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../proveedores/proveedor_mapa_cusco.dart';
import 'encabezado_explora_cusco.dart';
import 'mapa_cusco_interactivo.dart';
import 'panel_provincia_lateral.dart';
import 'panel_provincia_movil.dart';

/// Contenido principal de la pestaña Inicio en diseño ultra-minimalista moderno.
///
/// Orquesta el mapa interactivo de Cusco, el encabezado minimalista,
/// y los paneles con efecto cristal esmerilado (frosted glass).
class ContenidoInicio extends ConsumerStatefulWidget {
  const ContenidoInicio({super.key});

  @override
  ConsumerState<ContenidoInicio> createState() => _EstadoContenidoInicio();
}

class _EstadoContenidoInicio extends ConsumerState<ContenidoInicio> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(mapasCuscoProvider.notifier).cargarDatos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(mapasCuscoProvider);
    final tamanio = MediaQuery.sizeOf(context);
    final esMovil = tamanio.width < 768;
    final esTablet = tamanio.width >= 768 && tamanio.width < 1200;

    if (estado.estadoCarga == EstadoCarga.cargando ||
        estado.estadoCarga == EstadoCarga.inicial) {
      return const _PantallaCarga();
    }

    if (estado.estadoCarga == EstadoCarga.error) {
      return _PantallaError(
        mensaje: estado.mensajeError ?? 'Error desconocido',
        onReintentar: () {
          ref.read(mapasCuscoProvider.notifier).cargarDatos();
        },
      );
    }

    if (esMovil) {
      return _LayoutMovil(estado: estado);
    } else {
      return _LayoutTabletWeb(
        estado: estado,
        esTablet: esTablet,
      );
    }
  }
}

// ─────────────────────────────────────────────
// Layout Móvil
// ─────────────────────────────────────────────

class _LayoutMovil extends ConsumerWidget {
  final EstadoMapaCusco estado;

  const _LayoutMovil({required this.estado});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Column(
          children: [
            const EncabezadoExploraCusco(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Expanded(
                      child: MapaCuscoInteractivo(),
                    ),
                    // Espacio para la barra flotante inferior
                    const SizedBox(height: 84),
                  ],
                ),
              ),
            ),
          ],
        ),
        const PanelProvinciaMobile(),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Layout Tablet / Web
// ─────────────────────────────────────────────

class _LayoutTabletWeb extends ConsumerWidget {
  final EstadoMapaCusco estado;
  final bool esTablet;

  const _LayoutTabletWeb({
    required this.estado,
    required this.esTablet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              const EncabezadoExploraCusco(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MapaCuscoInteractivo(),
                ),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
        const PanelProvinciaLateral(),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Ranking Global Compacto (Ultra-Minimalista)
// ─────────────────────────────────────────────

class _RankingGlobalCompacto extends StatelessWidget {
  final List destinos;
  final String nombreMes;

  const _RankingGlobalCompacto({
    required this.destinos,
    required this.nombreMes,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF101B15).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF3C677),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Top tendencias — $nombreMes 2026',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(destinos.length, (index) {
                  final destino = destinos[index];
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < destinos.length - 1 ? 6 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '#${destino.posicion}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _colorBadge(destino.posicion),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              destino.nombre,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorBadge(int posicion) {
    switch (posicion) {
      case 1:
        return const Color(0xFFF3C677);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return Colors.white54;
    }
  }
}

// ─────────────────────────────────────────────
// Pantalla de Carga Minimalista
// ─────────────────────────────────────────────

class _PantallaCarga extends StatelessWidget {
  const _PantallaCarga();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: const Color(0xFFF3C677),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando experiencia...',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Pantalla de Error Minimalista
// ─────────────────────────────────────────────

class _PantallaError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _PantallaError({
    required this.mensaje,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudo conectar',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mensaje,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onReintentar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F4231),
                foregroundColor: const Color(0xFFF3C677),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Reintentar',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
