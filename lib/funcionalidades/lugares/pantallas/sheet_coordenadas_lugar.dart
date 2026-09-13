import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/logica_ubicacion_lugar.dart';

/// Tercera vía: latitud / longitud en decimal (WGS84).
Future<LatLng?> abrirIngresoCoordenadasLugar(
  BuildContext context, {
  double? latInicial,
  double? lonInicial,
}) {
  return showModalBottomSheet<LatLng>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SheetCoordenadas(
      latInicial: latInicial,
      lonInicial: lonInicial,
    ),
  );
}

class _SheetCoordenadas extends StatefulWidget {
  const _SheetCoordenadas({this.latInicial, this.lonInicial});

  final double? latInicial;
  final double? lonInicial;

  @override
  State<_SheetCoordenadas> createState() => _EstadoSheetCoordenadas();
}

class _EstadoSheetCoordenadas extends State<_SheetCoordenadas> {
  late final TextEditingController _lat;
  late final TextEditingController _lon;

  @override
  void initState() {
    super.initState();
    _lat = TextEditingController(
      text: widget.latInicial != null
          ? widget.latInicial!.toStringAsFixed(6)
          : '',
    );
    _lon = TextEditingController(
      text: widget.lonInicial != null
          ? widget.lonInicial!.toStringAsFixed(6)
          : '',
    );
  }

  @override
  void dispose() {
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
      hintStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomo, fontSize: 13),
      filled: true,
      fillColor: PaletaRutas.ink,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: PaletaRutas.plomoOscuro.withValues(alpha: 0.55),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: PaletaRutas.plomoOscuro.withValues(alpha: 0.55),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PaletaRutas.oro),
      ),
    );
  }

  void _confirmar() {
    final lat = double.tryParse(_lat.text.trim().replaceAll(',', '.'));
    final lon = double.tryParse(_lon.text.trim().replaceAll(',', '.'));
    final err = LogicaUbicacionLugar.mensajeErrorUbicacion(lat, lon);
    if (err != null) {
      mostrarSnackHaku(context, err);
      return;
    }
    Navigator.of(context).pop(LatLng(lat!, lon!));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: PaletaRutas.carbon,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(
            color: PaletaRutas.plomo.withValues(alpha: 0.28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PaletaRutas.plomoOscuro,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Coordenadas exactas',
                style: TipografiaHaku.titulo(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: PaletaRutas.piedra,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Para cuando ya conoces el punto preciso (GPS de otro aparato, '
                'mapa externo o ficha técnica).\n\n'
                'Usa grados decimales (no grados-minutos-segundos).\n'
                'En el Perú la latitud suele ser negativa (sur) y la longitud '
                'también (oeste). Ejemplo Cusco: −13.5167 , −71.9788.',
                style: TipografiaHaku.interfaz(
                  fontSize: 13,
                  height: 1.4,
                  color: PaletaRutas.plomoClaro,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _lat,
                style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                cursorColor: PaletaRutas.oro,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
                ],
                decoration: _dec('Latitud', 'Ej. -13.516700'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lon,
                style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                cursorColor: PaletaRutas.oro,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
                ],
                decoration: _dec('Longitud', 'Ej. -71.978800'),
              ),
              const SizedBox(height: 18),
              BotonPrimarioRuta(
                texto: 'Usar estas coordenadas',
                onPressed: _confirmar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
