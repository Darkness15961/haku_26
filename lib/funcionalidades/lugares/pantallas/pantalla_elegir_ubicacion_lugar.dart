import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/geocodificador_lugar.dart';
import '../dominio/logica_ubicacion_lugar.dart';

/// Mapa para marcar un punto: búsqueda + tap. Confirma lat/lon.
class PantallaElegirUbicacionLugar extends StatefulWidget {
  const PantallaElegirUbicacionLugar({
    super.key,
    this.inicial,
    this.distritoNombre,
    this.provinciaNombre,
  });

  final LatLng? inicial;
  final String? distritoNombre;
  final String? provinciaNombre;

  @override
  State<PantallaElegirUbicacionLugar> createState() =>
      _EstadoPantallaElegirUbicacionLugar();
}

class _EstadoPantallaElegirUbicacionLugar
    extends State<PantallaElegirUbicacionLugar> {
  final _busqueda = TextEditingController();
  final _mapController = MapController();

  late LatLng _punto;
  var _tocoMapa = false;
  var _buscando = false;
  var _centrandoTerritorio = false;

  @override
  void initState() {
    super.initState();
    _punto = widget.inicial ??
        const LatLng(
          LogicaUbicacionLugar.latCusco,
          LogicaUbicacionLugar.lonCusco,
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _intentarCentrarDistrito();
    });
  }

  @override
  void dispose() {
    _busqueda.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _intentarCentrarDistrito() async {
    if (widget.inicial != null) return;
    final dist = widget.distritoNombre?.trim();
    final prov = widget.provinciaNombre?.trim();
    if (dist == null || dist.isEmpty) return;

    setState(() => _centrandoTerritorio = true);
    try {
      final punto = await GeocodificadorLugar.centrarTerritorio(
        distrito: dist,
        provincia: prov ?? 'Cusco',
      );
      if (!mounted || punto == null) return;
      setState(() {
        _punto = punto;
        _tocoMapa = false;
      });
      _mapController.move(punto, 13);
    } catch (e) {
      debugPrint('Centrar distrito: $e');
    } finally {
      if (mounted) setState(() => _centrandoTerritorio = false);
    }
  }

  Future<void> _buscar() async {
    final q = _busqueda.text.trim();
    if (q.isEmpty) {
      mostrarSnackHaku(context, 'Escribe un nombre para buscar');
      return;
    }
    setState(() => _buscando = true);
    try {
      final punto = await GeocodificadorLugar.buscar(
        consulta: q,
        distrito: widget.distritoNombre,
        provincia: widget.provinciaNombre,
      );
      if (!mounted) return;
      if (punto == null) {
        mostrarSnackHaku(context, 'No encontramos ese lugar. Prueba otro nombre.');
        return;
      }
      setState(() {
        _punto = punto;
        _tocoMapa = true;
      });
      _mapController.move(punto, 15);
    } catch (e) {
      debugPrint('Buscar mapa: $e');
      if (mounted) {
        mostrarSnackHaku(context, 'No se pudo buscar. Revisa la conexión.');
      }
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  void _confirmar() {
    final err = LogicaUbicacionLugar.mensajeErrorUbicacion(
      _punto.latitude,
      _punto.longitude,
    );
    if (err != null) {
      mostrarSnackHaku(context, err);
      return;
    }
    Navigator.of(context).pop(_punto);
  }

  @override
  Widget build(BuildContext context) {
    final territorio = [
      if (widget.distritoNombre?.trim().isNotEmpty == true)
        widget.distritoNombre!.trim(),
      if (widget.provinciaNombre?.trim().isNotEmpty == true)
        widget.provinciaNombre!.trim(),
    ].join(' · ');

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        title: Text(
          'Marcar en el mapa',
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: PaletaRutas.piedra,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (territorio.isNotEmpty)
                  Text(
                    territorio,
                    style: TipografiaHaku.interfaz(
                      fontSize: 12,
                      color: PaletaRutas.oro,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  _centrandoTerritorio
                      ? 'Acercando al distrito…'
                      : (_tocoMapa
                          ? 'Punto marcado. Puedes moverlo tocando otra vez.'
                          : 'Busca un nombre o toca el mapa para fijar el punto.'),
                  style: TipografiaHaku.interfaz(
                    fontSize: 13,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _busqueda,
                        style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                        cursorColor: PaletaRutas.oro,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _buscar(),
                        decoration: InputDecoration(
                          hintText: 'Ej. Plaza de Armas, Sacsayhuamán…',
                          hintStyle: TipografiaHaku.interfaz(
                            color: PaletaRutas.plomo,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: PaletaRutas.carbon,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: PaletaRutas.plomoOscuro.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: PaletaRutas.plomoOscuro.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: PaletaRutas.oro),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _buscando ? null : _buscar,
                      style: IconButton.styleFrom(
                        backgroundColor: PaletaRutas.oro,
                        foregroundColor: PaletaRutas.ink,
                      ),
                      icon: _buscando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: PaletaRutas.ink,
                              ),
                            )
                          : const Icon(Icons.search),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _punto,
                initialZoom: 12,
                minZoom: 5,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (_, latLng) {
                  setState(() {
                    _punto = latLng;
                    _tocoMapa = true;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.haku.app',
                  retinaMode: RetinaMode.isHighDensity(context),
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _punto,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        color: PaletaRutas.oro,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${_punto.latitude.toStringAsFixed(5)}, ${_punto.longitude.toStringAsFixed(5)}',
                    textAlign: TextAlign.center,
                    style: TipografiaHaku.interfaz(
                      fontSize: 12,
                      color: PaletaRutas.plomo,
                    ),
                  ),
                  const SizedBox(height: 10),
                  BotonPrimarioRuta(
                    texto: 'Usar este punto',
                    onPressed: _confirmar,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
