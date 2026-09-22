import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../nucleo/recursos/copy_haku.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/contorno_departamento_cusco.dart';
import '../dominio/modelos/modelo_lugar.dart';
import '../dominio/servicio_ubicacion_mapa.dart';
import '../proveedores/proveedor_lugares.dart';
import '../widgets/mapa_explora_lugares.dart';
import 'pantalla_detalle_lugar.dart';

/// Modo mapa de Explora: contorno Cusco, GPS y cercanía PostGIS 50 km.
class PantallaMapaExplora extends ConsumerStatefulWidget {
  const PantallaMapaExplora({
    super.key,
    required this.lugaresTodos,
    required this.onVolver,
  });

  final List<ModeloLugar> lugaresTodos;
  final VoidCallback onVolver;

  @override
  ConsumerState<PantallaMapaExplora> createState() =>
      _EstadoPantallaMapaExplora();
}

enum ModoMapaUX { limpio, todos, cerca }

class _EstadoPantallaMapaExplora extends ConsumerState<PantallaMapaExplora> {
  final _mapaKey = GlobalKey<MapaExploraLugaresState>();

  ModoMapaUX _modoActual = ModoMapaUX.limpio;
  bool _ubicando = false;
  bool _esEstiloLiberty = true;
  int? _distanciaRadarKm;
  bool _panelInferiorOculto = false;
  ModeloLugar? _lugarSeleccionado;
  ResultadoUbicacionMapa? _gps;
  List<LatLng> _contorno = const [];
  bool _contornoListo = false;

  /// Evita que dos pedidos GPS concurrentes pisen el resultado.
  int _gpsEpoch = 0;

  @override
  void initState() {
    super.initState();
    _cargarContorno();
    // Fase 1: Ya no pedimos GPS al iniciar automáticamente.
  }

  Future<void> _cargarContorno() async {
    try {
      final pts = await ContornoDepartamentoCusco.cargar();
      if (!mounted) return;
      setState(() {
        _contorno = pts;
        _contornoListo = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _contornoListo = true);
    }
  }

  Future<void> _resolverGps({bool forzarDialogos = false}) async {
    final epoch = ++_gpsEpoch;
    setState(() => _ubicando = true);
    final r = await ServicioUbicacionMapa.obtenerActual();
    if (!mounted || epoch != _gpsEpoch) return;

    setState(() {
      _gps = r;
      _ubicando = false;
      if (r.tienePunto) {
        _modoActual = ModoMapaUX.cerca;
      }
    });

    if (!forzarDialogos && !r.tienePunto) {
      return;
    }
    if (r.tienePunto) return;
    await _manejarFalloGps(r);
  }

  Future<void> _manejarFalloGps(ResultadoUbicacionMapa r) async {
    if (!mounted || r.tienePunto) return;
    switch (r.estado) {
      case EstadoUbicacionMapa.gpsApagado:
        final abrir = await _dialogoSiNo(
          titulo: CopyHaku.mapaGpsApagadoTitulo,
          mensaje: CopyHaku.mapaGpsApagadoMensaje,
          accion: CopyHaku.mapaAbrirAjustes,
        );
        if (abrir) await ServicioUbicacionMapa.abrirAjustesUbicacion();
      case EstadoUbicacionMapa.permisoPermanente:
        final abrir = await _dialogoSiNo(
          titulo: CopyHaku.mapaPermisoTitulo,
          mensaje: CopyHaku.mapaPermisoPermanenteMensaje,
          accion: CopyHaku.mapaAbrirAjustes,
        );
        if (abrir) await ServicioUbicacionMapa.abrirAjustesApp();
      case EstadoUbicacionMapa.permisoDenegado:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                CopyHaku.mapaPermisoDenegado,
                style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
              ),
              backgroundColor: PaletaRutas.carbon,
            ),
          );
        }
      case EstadoUbicacionMapa.timeout:
      case EstadoUbicacionMapa.error:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                CopyHaku.mapaGpsError,
                style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
              ),
              backgroundColor: PaletaRutas.carbon,
            ),
          );
        }
      case EstadoUbicacionMapa.ok:
        break;
    }
  }

  Future<bool> _dialogoSiNo({
    required String titulo,
    required String mensaje,
    required String accion,
  }) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PaletaRutas.carbon,
        title: Text(
          titulo,
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
        content: Text(
          mensaje,
          style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Ahora no',
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              accion,
              style: TipografiaHaku.interfaz(
                color: PaletaRutas.oro,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return r == true;
  }

  LatLng? get _puntoUsuario {
    final g = _gps;
    if (g == null || !g.tienePunto) return null;
    return LatLng(g.latitud!, g.longitud!);
  }

  ConsultaCercaLugares? get _consultaCerca {
    if (_distanciaRadarKm == null) return null;
    final p = _puntoUsuario;
    if (p == null) return null;
    return ConsultaCercaLugares(
      latitud: p.latitude,
      longitud: p.longitude,
      radioM: _distanciaRadarKm! * 1000.0,
    );
  }

  String get _subtitulo {
    switch (_modoActual) {
      case ModoMapaUX.cerca:
        if (_ubicando) return CopyHaku.mapaCercaBuscandoGps;
        if (_puntoUsuario == null) return CopyHaku.mapaCercaSinGps;
        return CopyHaku.mapaCercaDeTi;
      case ModoMapaUX.todos:
        return CopyHaku.mapaTodosActivos;
      case ModoMapaUX.limpio:
        return "Explora el mapa";
    }
  }

  bool get _mostrarMapa => _contornoListo;


  @override
  Widget build(BuildContext context) {
    final consulta = _consultaCerca;
    final cercaActivo = _modoActual == ModoMapaUX.cerca && consulta != null;
    final preparandoRadar = _modoActual == ModoMapaUX.cerca && consulta == null;
    final cercaAsync =
        cercaActivo ? ref.watch(lugaresCercaProvider(consulta)) : null;

    List<ModeloLugar> pines;
    var cargandoCerca = false;
    String? errorCerca;
    
    if (_modoActual == ModoMapaUX.limpio) {
      pines = const [];
    } else if (cercaActivo) {
      cargandoCerca = cercaAsync?.isLoading ?? false;
      errorCerca = cercaAsync?.whenOrNull(error: (e, _) => '$e');
      // Conservar los pines previos (o todos) mientras carga para evitar un flash vacío.
      pines = cercaAsync?.value ?? widget.lugaresTodos;
    } else if (_modoActual == ModoMapaUX.todos) {
      pines = widget.lugaresTodos;
    } else {
      pines = const [];
    }

    final mapaVisible = _mostrarMapa && errorCerca == null;
    final overlayCarga =
        mapaVisible && (_ubicando || (cercaActivo && cargandoCerca));

    return PopScope(
      canPop: _lugarSeleccionado == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _lugarSeleccionado != null) {
          setState(() => _lugarSeleccionado = null);
        }
      },
      child: Scaffold(
        backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onVolver,
        ),
        title: Text(
          CopyHaku.mapaTitulo,
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: PaletaRutas.piedra,
          ),
        ),
        actions: [
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _subtitulo,
                style: TipografiaHaku.interfaz(
                  fontSize: 12,
                  color: PaletaRutas.plomoClaro,
                ),
              ),
            ),
          ),
          if (_modoActual == ModoMapaUX.cerca && !_ubicando && _puntoUsuario == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Material(
                color: PaletaRutas.carbon,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _resolverGps(forzarDialogos: true),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.my_location,
                          color: PaletaRutas.oro,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            CopyHaku.mapaActivarUbicacionCta,
                            style: TipografiaHaku.interfaz(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: PaletaRutas.plomo,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                if (!_contornoListo)
                  const Center(
                    child: CircularProgressIndicator(color: PaletaRutas.oro),
                  )
                else if (errorCerca != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            CopyHaku.mapaCercaError,
                            textAlign: TextAlign.center,
                            style: TipografiaHaku.interfaz(
                              color: PaletaRutas.piedra,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              final c = _consultaCerca;
                              if (c != null) {
                                ref.invalidate(lugaresCercaProvider(c));
                              }
                            },
                            child: Text(
                              'Reintentar',
                              style: TipografiaHaku.interfaz(
                                color: PaletaRutas.oro,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  MapaExploraLugares(
                    key: _mapaKey,
                    lugares: pines,
                    ubicacionUsuario: _puntoUsuario,
                    mostrarRadioCerca: cercaActivo,
                    radioCercaM: (_distanciaRadarKm ?? 50) * 1000.0,
                    contornoCusco: _contorno,
                    preparandoRadar: preparandoRadar,
                    onLugarSeleccionado: (lugar) {
                      setState(() {
                        _lugarSeleccionado = lugar;
                      });
                    },
                    estiloMapa: _esEstiloLiberty
                        ? 'https://tiles.openfreemap.org/styles/liberty'
                        : 'https://tiles.openfreemap.org/styles/positron',
                  ),
                if (overlayCarga)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: PaletaRutas.ink.withValues(alpha: 0.25),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: PaletaRutas.oro,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (mapaVisible)
                  Positioned(
                    right: 12,
                    top: 20, // o centrado verticalmente
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 48,
                          decoration: BoxDecoration(
                            color: PaletaRutas.ink.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: PaletaRutas.plomoOscuro.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.my_location, color: PaletaRutas.oro, size: 22),
                                onPressed: () async {
                                  if (_puntoUsuario == null) {
                                    await _resolverGps(forzarDialogos: true);
                                  } else {
                                    _mapaKey.currentState?.recentrarEnUsuario();
                                  }
                                },
                              ),
                              Divider(color: PaletaRutas.plomoOscuro.withValues(alpha: 0.3), height: 1),
                              IconButton(
                                icon: const Icon(Icons.add, color: PaletaRutas.piedra, size: 22),
                                onPressed: () {
                                  _mapaKey.currentState?.zoomIn();
                                },
                              ),
                              Divider(color: PaletaRutas.plomoOscuro.withValues(alpha: 0.3), height: 1),
                              IconButton(
                                icon: const Icon(Icons.remove, color: PaletaRutas.piedra, size: 22),
                                onPressed: () {
                                  _mapaKey.currentState?.zoomOut();
                                },
                              ),
                              Divider(color: PaletaRutas.plomoOscuro.withValues(alpha: 0.3), height: 1),
                              IconButton(
                                icon: const Icon(Icons.layers_rounded, color: PaletaRutas.piedra, size: 22),
                                onPressed: () {
                                  setState(() {
                                    _esEstiloLiberty = !_esEstiloLiberty;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (mapaVisible)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16 + MediaQuery.paddingOf(context).bottom,
                    child: _construirBloqueInferior(),
                  ),
                // Capa Modal (Foco absoluto)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _lugarSeleccionado == null
                      ? const SizedBox.shrink(key: ValueKey('vacio'))
                      : _construirCapaModal(_lugarSeleccionado!),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _construirCapaModal(ModeloLugar lugar) {
    return Positioned.fill(
      key: const ValueKey('modal_lugar'),
      child: GestureDetector(
        onTap: () => setState(() => _lugarSeleccionado = null), // Tocar el fondo oscuro cierra
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withValues(alpha: 0.35), // Sombreado
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            onTap: () {}, // Evita que los toques en la tarjeta cierren el modal
            child: _construirTarjetaLugar(lugar),
          ),
        ),
      ),
      ),
    );
  }

  Widget _construirTarjetaLugar(ModeloLugar lugar) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      decoration: BoxDecoration(
        color: PaletaRutas.ink,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PaletaRutas.oro.withValues(alpha: 0.4), width: 1.5), // Toque premium
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Imagen y botón cerrar
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                  child: lugar.imagenUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: lugar.imagenUrl,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _placeholderLugar(),
                        )
                      : _placeholderLugar(),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => setState(() => _lugarSeleccionado = null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: PaletaRutas.ink.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: PaletaRutas.piedra, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info y botón principal
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lugar.nombre,
                  style: TipografiaHaku.titulo(fontSize: 22, color: PaletaRutas.piedra),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_offer_rounded, color: PaletaRutas.oro, size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        lugar.subtituloClasificacion,
                        style: TipografiaHaku.interfaz(color: PaletaRutas.oro, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _lugarSeleccionado = null);
                      abrirDetalleLugar(context, lugar.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PaletaRutas.oro,
                      foregroundColor: PaletaRutas.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Explorar Lugar",
                          style: TipografiaHaku.interfaz(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: PaletaRutas.ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: PaletaRutas.ink, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderLugar() {
    return Container(
      color: PaletaRutas.carbon,
      child: const Center(
        child: Icon(Icons.landscape_rounded, color: PaletaRutas.plomo, size: 64),
      ),
    );
  }

  Widget _construirBloqueInferior() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Botón Zen (toggle)
        GestureDetector(
          onTap: () => setState(() => _panelInferiorOculto = !_panelInferiorOculto),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8, right: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: PaletaRutas.ink.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(color: PaletaRutas.plomoOscuro.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _panelInferiorOculto ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: PaletaRutas.piedra,
              size: 24,
            ),
          ),
        ),
        // Panel original con animación de cortina hacia abajo
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCirc,
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.hardEdge,
          child: _panelInferiorOculto
              ? const SizedBox(width: double.infinity, height: 0)
              : _construirPanelInferior(),
        ),
      ],
    );
  }

  Widget _construirPanelInferior() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sub-menú de distancias animado
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _modoActual == ModoMapaUX.cerca ? 40 : 0,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [30, 40, 50].map((km) {
                final activo = _distanciaRadarKm == km;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('$km km'),
                    selected: activo,
                    onSelected: (v) {
                      if (v) setState(() => _distanciaRadarKm = km);
                    },
                    selectedColor: PaletaRutas.oro,
                    labelStyle: TipografiaHaku.interfaz(
                      color: activo ? PaletaRutas.ink : PaletaRutas.piedra,
                      fontWeight: activo ? FontWeight.bold : FontWeight.w600,
                      fontSize: 12,
                    ),
                    backgroundColor: PaletaRutas.carbon.withValues(alpha: 0.8),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Panel Principal
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: PaletaRutas.ink.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: PaletaRutas.plomoOscuro.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BotonPanel(
                    icono: Icons.map_rounded,
                    texto: "Todos",
                    activo: _modoActual == ModoMapaUX.todos,
                    onTap: () => setState(() => _modoActual = ModoMapaUX.todos),
                  ),
                  _BotonPanel(
                    icono: Icons.wifi_tethering,
                    texto: "Radar",
                    activo: _modoActual == ModoMapaUX.cerca,
                    onTap: () async {
                      if (_puntoUsuario == null) {
                        await _resolverGps(forzarDialogos: true);
                        if (!mounted) return;
                        if (_puntoUsuario == null) return;
                      }
                      setState(() {
                        _modoActual = ModoMapaUX.cerca;
                        if (_distanciaRadarKm != null) {
                          _distanciaRadarKm = null; // Reiniciar para ver el nacimiento de la ola
                        }
                      });
                    },
                  ),
                  _BotonPanel(
                    icono: Icons.layers_clear_rounded,
                    texto: "Limpiar",
                    activo: _modoActual == ModoMapaUX.limpio,
                    onTap: () => setState(() => _modoActual = ModoMapaUX.limpio),
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

class _BotonPanel extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _BotonPanel({
    required this.icono,
    required this.texto,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? PaletaRutas.oro.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono, 
              color: activo ? PaletaRutas.oro : PaletaRutas.plomoClaro, 
              size: 24
            ),
            const SizedBox(height: 4),
            Text(
              texto,
              style: TipografiaHaku.interfaz(
                fontSize: 11,
                fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                color: activo ? PaletaRutas.oro : PaletaRutas.plomoClaro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
