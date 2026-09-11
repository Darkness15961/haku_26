import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../nucleo/recursos/copy_haku.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/provincias_datasource_local.dart';
import '../dominio/modelos/modelo_lugar.dart';
import 'foto_enmarcada_lugar.dart';

/// Isla dominante de provincia (Clash-like) con fotos enmarcadas encima.
class IslaProvincia extends StatelessWidget {
  const IslaProvincia({
    super.key,
    required this.data,
    required this.indice,
    required this.onTapIsla,
    required this.onTapLugar,
    this.onRegistrar,
  });

  final IslaProvinciaData data;
  final int indice;
  final VoidCallback onTapIsla;
  final ValueChanged<ModeloLugar> onTapLugar;
  final VoidCallback? onRegistrar;

  @override
  Widget build(BuildContext context) {
    final provincia = data.provincia;
    final fotos = data.destacados;

    final anchors = <Offset>[
      const Offset(0.06, 0.10),
      const Offset(0.64, 0.06),
      const Offset(0.08, 0.50),
      const Offset(0.60, 0.46),
    ];
    final rots = [-0.08, 0.06, 0.05, -0.05];

    return LayoutBuilder(
      builder: (context, constraints) {
        final islaW = constraints.maxWidth;
        final islaH = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : 280.0;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTapIsla();
          },
          child: SizedBox(
            width: islaW,
            height: islaH,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: CustomPaint(
                      painter: _PintorIsla(semilla: indice),
                    ),
                  ),
                ),
                Positioned(
                  left: islaW * 0.18,
                  top: islaH * 0.12,
                  right: islaW * 0.18,
                  bottom: islaH * 0.28,
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          provincia.rutaPng,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: PaletaRutas.carbon,
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                PaletaRutas.ink.withValues(alpha: 0.1),
                                PaletaRutas.ink.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: Transform.scale(
                            scale: 3.6,
                            child: Opacity(
                              opacity: 0.7,
                              child: SvgPicture.asset(
                                provincia.rutaSvg,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      Text(
                        provincia.nombre,
                        textAlign: TextAlign.center,
                        style: TipografiaHaku.titulo(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Badge(
                            texto: CopyHaku.islaLugares(data.lugares.length),
                          ),
                          if (data.cantidadNuevos > 0) ...[
                            const SizedBox(width: 6),
                            _Badge(
                              texto:
                                  CopyHaku.islaNuevos(data.cantidadNuevos),
                              destacado: true,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < fotos.length && i < anchors.length; i++)
                  Positioned(
                    left: anchors[i].dx * islaW,
                    top: anchors[i].dy * islaH,
                    child: FotoEnmarcadaLugar(
                      lugar: fotos[i],
                      ancho: i == 0 ? 90 : 76,
                      rotacion: rots[i],
                      onTap: () => onTapLugar(fotos[i]),
                    ),
                  ),
                if (fotos.isEmpty)
                  Positioned(
                    left: 24,
                    right: 24,
                    top: islaH * 0.28,
                    child: Column(
                      children: [
                        Text(
                          CopyHaku.sheetProvinciaVacia,
                          textAlign: TextAlign.center,
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            height: 1.35,
                            color: PaletaRutas.piedra.withValues(alpha: 0.9),
                          ),
                        ),
                        if (onRegistrar != null) ...[
                          const SizedBox(height: 10),
                          FilledButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              onRegistrar!();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: PaletaRutas.oro,
                              foregroundColor: PaletaRutas.ink,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(
                              CopyHaku.sheetCtaRegistrar,
                              style: TipografiaHaku.interfaz(
                                fontWeight: FontWeight.w800,
                                color: PaletaRutas.ink,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.texto, this.destacado = false});

  final String texto;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: destacado
            ? PaletaRutas.oro.withValues(alpha: 0.92)
            : PaletaRutas.ink.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: destacado
              ? PaletaRutas.oroOscuro
              : PaletaRutas.plomo.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        texto,
        style: TipografiaHaku.interfaz(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: destacado ? PaletaRutas.ink : PaletaRutas.piedra,
        ),
      ),
    );
  }
}

class _PintorIsla extends CustomPainter {
  _PintorIsla({required this.semilla});

  final int semilla;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width * 0.47;
    final ry = size.height * 0.43;
    const n = 16;
    for (var i = 0; i <= n; i++) {
      final t = i / n * math.pi * 2;
      final wobble = 0.86 + 0.14 * (((semilla * 3 + i * 7) % 5) / 4);
      final x = cx + rx * wobble * math.cos(t);
      final y = cy + ry * wobble * math.sin(t);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path.shift(const Offset(0, 10)),
      Paint()
        ..color = PaletaRutas.ink.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B5330),
            PaletaRutas.carbon,
            Color(0xFF8A6F38),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..color = PaletaRutas.oro.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _PintorIsla oldDelegate) =>
      oldDelegate.semilla != semilla;
}
