import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../datos/provincias_datasource_local.dart';
import '../dominio/modelos/provincia.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';

/// Explora: laberinto táctil con relieve, bolita por inclinación y
/// 13 metas (una por provincia de Cusco).
class ContenidoInicio extends StatefulWidget {
  const ContenidoInicio({super.key});

  @override
  State<ContenidoInicio> createState() => _EstadoContenidoInicio();
}

class _EstadoContenidoInicio extends State<ContenidoInicio>
    with SingleTickerProviderStateMixin {
  static const _assetLaberinto = 'public/image/laberinto_explora.webp';
  static const _radioBola = 11.0;
  static const _radioMeta = 14.0;
  static const _margenDeteccion = 6.0;
  /// Grosor del marco de madera (debe coincidir con `_MarcoMaderaLaberinto`).
  static const _insetMarco = 14.5;

  late final AnimationController _ticker;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  late final List<Provincia> _provincias;

  /// Aceleración suavizada (gravedad / inclinación).
  Offset _tilt = Offset.zero;

  /// Posición de la bolita relativa al centro del tablero.
  Offset _bola = Offset.zero;

  /// Velocidad de la bolita.
  Offset _vel = Offset.zero;

  Size _tablero = Size.zero;
  bool _sensoresActivos = false;

  String? _provinciaSeleccionadaId;
  final Set<String> _desbloqueadas = <String>{};

  /// Evita re-disparar snackbar mientras la bola permanece en la meta.
  String? _metaEnContactoId;

  @override
  void initState() {
    super.initState();
    _provincias = ProvinciasDataSourceLocal.obtenerProvincias();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tickFisica)
      ..repeat();
    _iniciarSensores();
  }

  Future<void> _iniciarSensores() async {
    // sensors_plus no tiene implementación en Windows/desktop.
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      if (mounted) setState(() => _sensoresActivos = false);
      return;
    }

    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (e) {
          // En portrait: x = izquierda/derecha, y = adelante/atrás.
          final crudo = Offset(e.x, e.y);
          _tilt = Offset(
            (_tilt.dx * 0.82) + (crudo.dx * 0.18),
            (_tilt.dy * 0.82) + (crudo.dy * 0.18),
          );
          if (!_sensoresActivos && mounted) {
            setState(() => _sensoresActivos = true);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _sensoresActivos = false);
        },
        cancelOnError: true,
      );
    } catch (_) {
      // Emulador / desktop sin sensores: se puede arrastrar la bolita.
      if (mounted) setState(() => _sensoresActivos = false);
    }
  }

  /// Posiciones de meta en anillo, relativas al centro del laberinto.
  List<Offset> _posicionesMetas(double radioAnillo) {
    final n = _provincias.length;
    return List<Offset>.generate(n, (i) {
      final angulo = -math.pi / 2 + (2 * math.pi * i / n);
      return Offset(
        math.cos(angulo) * radioAnillo,
        math.sin(angulo) * radioAnillo,
      );
    });
  }

  void _tickFisica() {
    if (_tablero == Size.zero) return;

    final radioUtil =
        (math.min(_tablero.width, _tablero.height) / 2) - _radioBola - 8;

    // Gravedad desde inclinación (invertimos ejes para sensación natural).
    final ax = -_tilt.dx * 48;
    final ay = _tilt.dy * 48;

    _vel = Offset(
      (_vel.dx + ax * 0.016) * 0.965,
      (_vel.dy + ay * 0.016) * 0.965,
    );
    _bola += _vel * 0.016;

    // Contén dentro del círculo del laberinto.
    final dist = _bola.distance;
    if (dist > radioUtil) {
      final n = _bola / dist;
      _bola = n * radioUtil;
      // Rebote suave contra el borde.
      final vn = _vel.dx * n.dx + _vel.dy * n.dy;
      if (vn > 0) {
        _vel -= n * vn * 1.35;
      }
    }

    _comprobarMetas(radioUtil);

    if (mounted) setState(() {});
  }

  void _comprobarMetas(double radioUtil) {
    final radioAnillo = radioUtil * 0.62;
    final metas = _posicionesMetas(radioAnillo);
    final umbral = _radioBola + _radioMeta + _margenDeteccion;

    String? contacto;
    for (var i = 0; i < metas.length; i++) {
      if ((_bola - metas[i]).distance <= umbral) {
        contacto = _provincias[i].id;
        break;
      }
    }

    if (contacto == null) {
      _metaEnContactoId = null;
      return;
    }

    if (_metaEnContactoId == contacto) return;
    _metaEnContactoId = contacto;

    if (_desbloqueadas.contains(contacto)) return;
    _desbloquearProvincia(contacto);
  }

  void _desbloquearProvincia(String id) {
    Provincia? provincia;
    for (final p in _provincias) {
      if (p.id == id) {
        provincia = p;
        break;
      }
    }
    if (provincia == null) return;

    setState(() => _desbloqueadas.add(id));
    HapticFeedback.mediumImpact();

    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          '¡${provincia.nombre} desbloqueada!',
          style: TipografiaHaku.interfaz(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: PaletaRutas.marronCuero,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1600),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      ),
    );
  }

  void _seleccionarProvincia(String id) {
    setState(() {
      _provinciaSeleccionadaId =
          _provinciaSeleccionadaId == id ? null : id;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_sensoresActivos) return;
    final radioUtil =
        (math.min(_tablero.width, _tablero.height) / 2) - _radioBola - 8;
    var next = _bola + d.delta;
    if (next.distance > radioUtil) {
      next = next / next.distance * radioUtil;
    }
    setState(() {
      _bola = next;
      _vel = Offset.zero;
    });
    _comprobarMetas(radioUtil);
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.paddingOf(context).top;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final progreso = _desbloqueadas.length;
    final total = _provincias.length;

    // Relieve: el tablero se inclina levemente con el celular.
    final rotX = (_tilt.dy / 12).clamp(-0.22, 0.22);
    final rotY = (-_tilt.dx / 12).clamp(-0.22, 0.22);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: const Color(0xFF1A120E),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: Colors.black,
              child: Padding(
                padding: EdgeInsets.fromLTRB(22, topSafe + 8, 22, 10),
                child: Column(
                  children: [
                    Text(
                      'EXPLORA',
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.titulo(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const LineaEncabezadoInca(altura: 2, color: Colors.white),
                    const SizedBox(height: 6),
                    Text(
                      _sensoresActivos
                          ? 'Inclina el celular · llega a una meta'
                          : 'Arrastra la bolita · llega a una meta',
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$progreso / $total provincias',
                      textAlign: TextAlign.center,
                      style: TipografiaHaku.interfaz(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.arena,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FondoSuaveSeccion(
                opacidadImagen: 0.28,
                opacidadVelo: 0.12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: _SelectorProvincias(
                        provincias: _provincias,
                        seleccionadaId: _provinciaSeleccionadaId,
                        desbloqueadas: _desbloqueadas,
                        onSeleccionar: _seleccionarProvincia,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding:
                            EdgeInsets.fromLTRB(18, 10, 18, 24 + bottomSafe),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final lado = math.min(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            // Área jugable = interior del marco (sin disco blanco).
                            final ladoUtil = lado - (2 * _insetMarco);
                            _tablero = Size(ladoUtil, ladoUtil);
                            final cx = lado / 2;
                            final cy = lado / 2;
                            final radioUtil =
                                (ladoUtil / 2) - _radioBola - 4;
                            final radioAnillo = radioUtil * 0.62;
                            final metas = _posicionesMetas(radioAnillo);

                            return Center(
                              child: SizedBox(
                                width: lado,
                                height: lado,
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.0016)
                                    ..rotateX(rotX)
                                    ..rotateY(rotY),
                                  child: GestureDetector(
                                    onPanUpdate: _onPanUpdate,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        // Marco madera con relieve 3D (sin disco blanco).
                                        Positioned.fill(
                                          child: _MarcoMaderaLaberinto(
                                            rotX: rotX,
                                            rotY: rotY,
                                            child: Image.asset(
                                              _assetLaberinto,
                                              fit: BoxFit.cover,
                                              width: ladoUtil,
                                              height: ladoUtil,
                                              filterQuality:
                                                  FilterQuality.high,
                                              errorBuilder: (_, __, ___) =>
                                                  const ColoredBox(
                                                color: Color(0xFF5C3A2A),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.extension,
                                                    color: Colors.white54,
                                                    size: 48,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Relieve suave cálido (no blanco).
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                _insetMarco,
                                              ),
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: RadialGradient(
                                                    center: Alignment(
                                                      (-rotY * 2)
                                                          .clamp(-0.7, 0.7),
                                                      (-rotX * 2)
                                                          .clamp(-0.7, 0.7),
                                                    ),
                                                    radius: 0.95,
                                                    colors: [
                                                      const Color(0xFFD4A574)
                                                          .withValues(
                                                        alpha: 0.10,
                                                      ),
                                                      Colors.transparent,
                                                      Colors.black.withValues(
                                                        alpha: 0.32,
                                                      ),
                                                    ],
                                                    stops: const [
                                                      0.0,
                                                      0.48,
                                                      1.0,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        for (var i = 0;
                                            i < metas.length;
                                            i++)
                                          Positioned(
                                            left: cx +
                                                metas[i].dx -
                                                _radioMeta,
                                            top: cy +
                                                metas[i].dy -
                                                _radioMeta,
                                            child: _HoyoMeta(
                                              radio: _radioMeta,
                                              provincia: _provincias[i],
                                              seleccionada:
                                                  _provinciaSeleccionadaId ==
                                                      _provincias[i].id,
                                              desbloqueada: _desbloqueadas
                                                  .contains(
                                                _provincias[i].id,
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          left: cx + _bola.dx - _radioBola,
                                          top: cy + _bola.dy - _radioBola,
                                          child: _BolitaRompecabezas(
                                            radio: _radioBola,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marco circular de madera con bisel / sombra interna-externa.
class _MarcoMaderaLaberinto extends StatelessWidget {
  final double rotX;
  final double rotY;
  final Widget child;

  const _MarcoMaderaLaberinto({
    required this.rotX,
    required this.rotY,
    required this.child,
  });

  static const _maderaClara = Color(0xFFC9A06A);
  static const _maderaMedia = Color(0xFF8B5A2B);
  static const _maderaOscura = Color(0xFF5C3A1E);
  static const _maderaSombra = Color(0xFF2E1A0E);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Anillo exterior: bisel claro→oscuro (relieve).
        gradient: LinearGradient(
          begin: Alignment(-0.85 - rotY, -0.9 - rotX),
          end: Alignment(0.9 + rotY, 0.95 + rotX),
          colors: const [
            Color(0xFFE0C089),
            _maderaClara,
            _maderaMedia,
            _maderaOscura,
            _maderaSombra,
          ],
          stops: const [0.0, 0.22, 0.48, 0.78, 1.0],
        ),
        boxShadow: [
          // Sombra externa (apoyo sobre el pergamino).
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.48),
            blurRadius: 18,
            spreadRadius: 1,
            offset: Offset(rotY * 28, 10 + rotX * 28),
          ),
          // Destello cálido (no blanco) en el borde superior.
          BoxShadow(
            color: _maderaClara.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: Offset(-rotY * 14, -5 - rotX * 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Capas internas: textura sutil + bisel invertido.
            gradient: SweepGradient(
              colors: [
                _maderaOscura.withValues(alpha: 0.95),
                _maderaMedia,
                _maderaClara.withValues(alpha: 0.85),
                _maderaMedia,
                _maderaSombra,
                _maderaOscura.withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.18, 0.38, 0.58, 0.82, 1.0],
            ),
            border: Border.all(
              color: _maderaSombra.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              // Sombra interna (hundido hacia el laberinto).
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 10,
                spreadRadius: -2,
                offset: Offset(rotY * 6, 3 + rotX * 6),
              ),
              BoxShadow(
                color: _maderaClara.withValues(alpha: 0.22),
                blurRadius: 6,
                spreadRadius: -1,
                offset: Offset(-rotY * 4, -2 - rotX * 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3.5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _maderaSombra.withValues(alpha: 0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipOval(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorProvincias extends StatelessWidget {
  final List<Provincia> provincias;
  final String? seleccionadaId;
  final Set<String> desbloqueadas;
  final ValueChanged<String> onSeleccionar;

  const _SelectorProvincias({
    required this.provincias,
    required this.seleccionadaId,
    required this.desbloqueadas,
    required this.onSeleccionar,
  });


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Provincias de Cusco',
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: provincias.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final p = provincias[index];
              final seleccionada = seleccionadaId == p.id;
              final desbloqueada = desbloqueadas.contains(p.id);
              return _ChipProvincia(
                provincia: p,
                seleccionada: seleccionada,
                desbloqueada: desbloqueada,
                onTap: () => onSeleccionar(p.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChipProvincia extends StatelessWidget {
  final Provincia provincia;
  final bool seleccionada;
  final bool desbloqueada;
  final VoidCallback onTap;

  const _ChipProvincia({
    required this.provincia,
    required this.seleccionada,
    required this.desbloqueada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fondo = seleccionada
        ? PaletaRutas.marronCuero
        : desbloqueada
            ? PaletaRutas.verdeOliva.withValues(alpha: 0.85)
            : const Color(0xFF2A1E18).withValues(alpha: 0.88);
    final borde = seleccionada
        ? PaletaRutas.arena
        : desbloqueada
            ? PaletaRutas.verdeOliva
            : PaletaRutas.beigeEnvejecido.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borde, width: seleccionada ? 1.6 : 1),
            boxShadow: seleccionada
                ? [
                    BoxShadow(
                      color: provincia.colorBase.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (desbloqueada) ...[
                Icon(
                  Icons.check_circle,
                  size: 13,
                  color: seleccionada
                      ? Colors.white
                      : PaletaRutas.crema,
                ),
                const SizedBox(width: 4),
              ] else ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: provincia.colorBase,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                provincia.nombreCorto,
                style: TipografiaHaku.interfaz(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(
                    alpha: seleccionada || desbloqueada ? 1 : 0.82,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoyoMeta extends StatelessWidget {
  final double radio;
  final Provincia provincia;
  final bool seleccionada;
  final bool desbloqueada;

  const _HoyoMeta({
    required this.radio,
    required this.provincia,
    required this.seleccionada,
    required this.desbloqueada,
  });

  @override
  Widget build(BuildContext context) {
    final d = radio * 2;
    final acento = desbloqueada
        ? PaletaRutas.verdeOliva
        : provincia.colorBase;

    return SizedBox(
      width: d,
      height: d,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (seleccionada)
            Container(
              width: d + 10,
              height: d + 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: PaletaRutas.arena.withValues(alpha: 0.95),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: acento.withValues(alpha: 0.55),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.72),
                  Colors.black.withValues(alpha: 0.45),
                  acento.withValues(alpha: desbloqueada ? 0.55 : 0.35),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              border: Border.all(
                color: acento.withValues(alpha: seleccionada ? 1 : 0.75),
                width: seleccionada ? 2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: desbloqueada
                ? Icon(
                    Icons.check,
                    size: radio * 1.1,
                    color: Colors.white.withValues(alpha: 0.9),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _BolitaRompecabezas extends StatelessWidget {
  final double radio;

  const _BolitaRompecabezas({required this.radio});

  @override
  Widget build(BuildContext context) {
    final d = radio * 2;
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.4),
          radius: 0.85,
          colors: [
            Color(0xFFF5F5F5),
            Color(0xFFB8BCC2),
            Color(0xFF6E737A),
            Color(0xFF3A3E44),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(1.5, 2.5),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.35),
            blurRadius: 2,
            offset: const Offset(-1, -1),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 0.6,
        ),
      ),
    );
  }
}
