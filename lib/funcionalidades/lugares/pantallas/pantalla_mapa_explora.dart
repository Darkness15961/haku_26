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

class _EstadoPantallaMapaExplora extends ConsumerState<PantallaMapaExplora> {
  final _mapaKey = GlobalKey<MapaExploraLugaresState>();

  bool _filtroCerca = true;
  bool _ubicando = true;
  ResultadoUbicacionMapa? _gps;
  List<LatLng> _contorno = const [];
  bool _contornoListo = false;

  /// Evita que dos pedidos GPS concurrentes pisen el resultado.
  int _gpsEpoch = 0;

  @override
  void initState() {
    super.initState();
    _cargarContorno();
    _resolverGps();
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
        _filtroCerca = true;
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
    final p = _puntoUsuario;
    if (p == null) return null;
    return ConsultaCercaLugares(
      latitud: p.latitude,
      longitud: p.longitude,
      radioM: 50000,
    );
  }

  String get _subtitulo {
    if (_filtroCerca) {
      if (_ubicando) return CopyHaku.mapaCercaBuscandoGps;
      if (_puntoUsuario == null) return CopyHaku.mapaCercaSinGps;
      return CopyHaku.mapaCercaDeTi;
    }
    return CopyHaku.mapaTodosActivos;
  }

  bool get _mostrarMapa => _contornoListo;

  @override
  Widget build(BuildContext context) {
    final consulta = _consultaCerca;
    final cercaActivo = _filtroCerca && consulta != null;
    final cercaAsync =
        cercaActivo ? ref.watch(lugaresCercaProvider(consulta)) : null;

    List<ModeloLugar> pines;
    var cargandoCerca = false;
    String? errorCerca;
    if (cercaActivo) {
      cargandoCerca = cercaAsync?.isLoading ?? false;
      errorCerca = cercaAsync?.whenOrNull(error: (e, _) => '$e');
      // Mientras carga, no vaciar pines previos: se maneja con overlay.
      pines = cercaAsync?.maybeWhen(
            data: (d) => d,
            orElse: () => const <ModeloLugar>[],
          ) ??
          const [];
    } else if (_filtroCerca) {
      pines = const [];
    } else {
      pines = widget.lugaresTodos;
    }

    final mapaVisible = _mostrarMapa && errorCerca == null;
    final overlayCarga =
        mapaVisible && (_ubicando || (cercaActivo && cargandoCerca));

    return Scaffold(
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
          FilterChip(
            label: Text(
              CopyHaku.mapaChipCerca,
              style: TipografiaHaku.interfaz(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _filtroCerca ? PaletaRutas.oro : PaletaRutas.plomoClaro,
              ),
            ),
            selected: _filtroCerca,
            onSelected: (v) async {
              if (v && _puntoUsuario == null) {
                await _resolverGps(forzarDialogos: true);
                if (!mounted) return;
                if (_puntoUsuario == null) {
                  setState(() => _filtroCerca = false);
                  return;
                }
              }
              setState(() => _filtroCerca = v);
            },
            selectedColor: PaletaRutas.oro.withValues(alpha: 0.2),
            backgroundColor: PaletaRutas.carbon,
            checkmarkColor: PaletaRutas.oro,
            side: BorderSide(
              color: _filtroCerca
                  ? PaletaRutas.oro
                  : PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
            ),
          ),
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
          if (_filtroCerca && !_ubicando && _puntoUsuario == null)
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
                    contornoCusco: _contorno,
                    onAbrirLugar: (id) => abrirDetalleLugar(context, id),
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
                if (mapaVisible && !_ubicando && _puntoUsuario != null)
                  Positioned(
                    right: 16,
                    bottom: 16 + MediaQuery.paddingOf(context).bottom,
                    child: FloatingActionButton.small(
                      heroTag: 'mapa_recentrar_gps',
                      backgroundColor: PaletaRutas.carbon,
                      foregroundColor: PaletaRutas.oro,
                      onPressed: () {
                        _mapaKey.currentState?.recentrarEnUsuario();
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
