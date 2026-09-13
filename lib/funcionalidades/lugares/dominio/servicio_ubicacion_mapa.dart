import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'logica_ubicacion_lugar.dart';

/// Resultado de pedir GPS para el mapa Explora.
enum EstadoUbicacionMapa {
  ok,
  gpsApagado,
  permisoDenegado,
  permisoPermanente,
  timeout,
  error,
}

class ResultadoUbicacionMapa {
  const ResultadoUbicacionMapa({
    required this.estado,
    this.latitud,
    this.longitud,
  });

  final EstadoUbicacionMapa estado;
  final double? latitud;
  final double? longitud;

  bool get tienePunto =>
      estado == EstadoUbicacionMapa.ok &&
      LogicaUbicacionLugar.esUbicacionValida(latitud, longitud) &&
      !LogicaUbicacionLugar.esPuntoSospechoso(latitud!, longitud!);
}

/// GPS del turista para centrar el mapa y consultar PostGIS `lugares_cerca`.
abstract final class ServicioUbicacionMapa {
  static Future<ResultadoUbicacionMapa> obtenerActual({
    Duration timeLimit = const Duration(seconds: 20),
  }) async {
    try {
      final servicio = await Geolocator.isLocationServiceEnabled();
      if (!servicio) {
        return const ResultadoUbicacionMapa(
          estado: EstadoUbicacionMapa.gpsApagado,
        );
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied) {
        return const ResultadoUbicacionMapa(
          estado: EstadoUbicacionMapa.permisoDenegado,
        );
      }
      if (permiso == LocationPermission.deniedForever) {
        return const ResultadoUbicacionMapa(
          estado: EstadoUbicacionMapa.permisoPermanente,
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );

      final err = LogicaUbicacionLugar.mensajeErrorUbicacion(
        pos.latitude,
        pos.longitude,
      );
      if (err != null) {
        return const ResultadoUbicacionMapa(
          estado: EstadoUbicacionMapa.error,
        );
      }

      return ResultadoUbicacionMapa(
        estado: EstadoUbicacionMapa.ok,
        latitud: pos.latitude,
        longitud: pos.longitude,
      );
    } on TimeoutException {
      return const ResultadoUbicacionMapa(
        estado: EstadoUbicacionMapa.timeout,
      );
    } catch (_) {
      return const ResultadoUbicacionMapa(
        estado: EstadoUbicacionMapa.error,
      );
    }
  }

  static Future<void> abrirAjustesUbicacion() =>
      Geolocator.openLocationSettings();

  static Future<void> abrirAjustesApp() => Geolocator.openAppSettings();
}
