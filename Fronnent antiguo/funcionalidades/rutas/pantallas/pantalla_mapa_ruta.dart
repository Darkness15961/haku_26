import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dominio/modelos/modelo_ruta.dart';
import '../widgets/boton_primario_ruta.dart';
import '../widgets/estilos_rutas.dart';
import '../widgets/linea_encabezado_inca.dart';

/// Mapa simulado + cómo llegar (sin SDK externo).
class PantallaMapaRuta extends StatefulWidget {
  final ModeloRuta ruta;

  const PantallaMapaRuta({super.key, required this.ruta});

  @override
  State<PantallaMapaRuta> createState() => _EstadoPantallaMapaRuta();
}

class _EstadoPantallaMapaRuta extends State<PantallaMapaRuta> {
  int _paradaSeleccionada = 0;

  ModeloRuta get ruta => widget.ruta;

  List<PuntoRuta> get _puntos =>
      ruta.puntos.isNotEmpty ? ruta.puntos : _fallback;

  List<PuntoRuta> get _fallback => [
        PuntoRuta(
          id: 'f1',
          nombre: ruta.puntoPartida.isEmpty ? 'Inicio' : ruta.puntoPartida,
          tipo: 'inicio',
          lat: -13.5167,
          lng: -71.9788,
        ),
        PuntoRuta(
          id: 'f2',
          nombre: ruta.titulo,
          tipo: 'destino',
          lat: -13.40,
          lng: -72.10,
        ),
      ];

  Future<void> _copiarCoords(PuntoRuta p) async {
    await Clipboard.setData(ClipboardData(text: '${p.lat}, ${p.lng}'));
    if (!mounted) return;
    mostrarSnackHaku(context, 'Copiado', destacado: true);
  }

  @override
  Widget build(BuildContext context) {
    final puntos = _puntos;
    final sel = puntos[_paradaSeleccionada.clamp(0, puntos.length - 1)];
    final bottom = MediaQuery.paddingOf(context).bottom + 20;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Cómo llegar',
                      style: TipografiaHaku.titulo(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                  ),
                ],
              ),
            ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: LineaEncabezadoInca(altura: 2),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, bottom),
                  children: [
                    Text(
                      ruta.titulo,
                      style: TipografiaHaku.titulo(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    if (ruta.puntoPartida.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Partida: ${ruta.puntoPartida}',
                        style: TipografiaHaku.interfaz(
                          fontSize: 13,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 1.15,
                        child: Stack(
                          children: [
                            CustomPaint(
                              painter: _MapaRutaPainter(
                                puntos: puntos,
                                seleccionado: _paradaSeleccionada,
                              ),
                              size: Size.infinite,
                            ),
                            Positioned(
                              left: 10,
                              top: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: PaletaRutas.carbon.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Mapa',
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: PaletaRutas.piedra,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: PaletaRutas.carbon.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  ruta.distancia.isEmpty
                                      ? '${puntos.length} puntos'
                                      : ruta.distancia,
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: PaletaRutas.piedra,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Paradas',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < puntos.length; i++)
                      _TileParada(
                        punto: puntos[i],
                        indice: i + 1,
                        seleccionado: i == _paradaSeleccionada,
                        onTap: () => setState(() => _paradaSeleccionada = i),
                        onCopiar: () => _copiarCoords(puntos[i]),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: PaletaRutas.carbon,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: PaletaRutas.plomo.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cómo llegar',
                            style: TipografiaHaku.titulo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ruta.comoLlegar.isEmpty
                                ? 'Sigue las paradas.'
                                : ruta.comoLlegar,
                            style: TipografiaHaku.interfaz(
                              fontSize: 13,
                              height: 1.4,
                              color: PaletaRutas.plomoClaro,
                            ),
                          ),
                          if (ruta.transporte.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              ruta.transporte,
                              style: TipografiaHaku.interfaz(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: PaletaRutas.oro,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            '${sel.nombre}\n'
                            '${sel.lat.toStringAsFixed(4)}, ${sel.lng.toStringAsFixed(4)}',
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: PaletaRutas.plomo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (ruta.tips.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Tips',
                        style: TipografiaHaku.titulo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final t in ruta.tips)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                                color: PaletaRutas.oro,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t,
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 13,
                                    color: PaletaRutas.plomoClaro,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 18),
                    BotonPrimarioRuta(
                      texto: 'Copiar',
                      icono: Icons.copy_rounded,
                      onPressed: () => _copiarCoords(sel),
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

class _TileParada extends StatelessWidget {
  final PuntoRuta punto;
  final int indice;
  final bool seleccionado;
  final VoidCallback onTap;
  final VoidCallback onCopiar;

  const _TileParada({
    required this.punto,
    required this.indice,
    required this.seleccionado,
    required this.onTap,
    required this.onCopiar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: seleccionado
            ? PaletaRutas.carbon
            : PaletaRutas.carbon.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: seleccionado
                      ? PaletaRutas.oro.withValues(alpha: 0.22)
                      : PaletaRutas.plomo.withValues(alpha: 0.35),
                  child: Text(
                    '$indice',
                    style: TipografiaHaku.interfaz(
                      fontWeight: FontWeight.w800,
                      color: seleccionado
                          ? PaletaRutas.oro
                          : PaletaRutas.piedra,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        punto.nombre,
                        style: TipografiaHaku.interfaz(
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      Text(
                        [
                          punto.tipo,
                          if (punto.nota != null) punto.nota!,
                        ].join(' · '),
                        style: TipografiaHaku.interfaz(
                          fontSize: 11,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar coordenadas',
                  onPressed: onCopiar,
                  icon: const Icon(
                    Icons.my_location_rounded,
                    color: PaletaRutas.oro,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapaRutaPainter extends CustomPainter {
  final List<PuntoRuta> puntos;
  final int seleccionado;

  const _MapaRutaPainter({
    required this.puntos,
    required this.seleccionado,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        const [
          PaletaRutas.ink,
          PaletaRutas.carbon,
          PaletaRutas.plomoOscuro,
        ],
      );
    canvas.drawRect(Offset.zero & size, bg);

    // Relieve simulado
    final relieve = Paint()
      ..color = PaletaRutas.ink.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 1; i <= 6; i++) {
      final r = size.shortestSide * (0.12 * i);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.45, size.height * 0.55),
          width: r * 1.6,
          height: r,
        ),
        relieve,
      );
    }

    if (puntos.isEmpty) return;

    double minLat = puntos.first.lat;
    double maxLat = puntos.first.lat;
    double minLng = puntos.first.lng;
    double maxLng = puntos.first.lng;
    for (final p in puntos) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }
    final dLat = (maxLat - minLat).abs() < 0.001 ? 0.02 : (maxLat - minLat);
    final dLng = (maxLng - minLng).abs() < 0.001 ? 0.02 : (maxLng - minLng);
    const pad = 36.0;

    Offset toXy(PuntoRuta p) {
      final x = pad + ((p.lng - minLng) / dLng) * (size.width - pad * 2);
      final y = pad +
          (1 - ((p.lat - minLat) / dLat)) * (size.height - pad * 2);
      return Offset(x, y);
    }

    final path = Path();
    for (var i = 0; i < puntos.length; i++) {
      final o = toXy(puntos[i]);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }

    final trazo = Paint()
      ..color = PaletaRutas.oroSuave
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, trazo);

    for (var i = 0; i < puntos.length; i++) {
      final o = toXy(puntos[i]);
      final sel = i == seleccionado;
      final fill = Paint()
        ..color = sel ? PaletaRutas.oro : PaletaRutas.piedra;
      canvas.drawCircle(o, sel ? 11 : 8, fill);
      canvas.drawCircle(
        o,
        sel ? 11 : 8,
        Paint()
          ..color = PaletaRutas.ink.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapaRutaPainter oldDelegate) {
    return oldDelegate.seleccionado != seleccionado ||
        oldDelegate.puntos != puntos;
  }
}
