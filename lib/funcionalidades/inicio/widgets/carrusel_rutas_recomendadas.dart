import 'package:flutter/material.dart';

import '../../../nucleo/recursos/copy_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';

/// Texto bajo la tarjeta del carrusel.
enum EstiloPieCarrusel {
  /// Nombre + provincia.
  provincia,
  /// Nombre + subtítulo de experiencia.
  experiencia,
  /// Nombre + tipo (Restaurante, Cerámica…) y provincia.
  tipoYProvincia,
}

/// Carrusel horizontal — imagen dominante + pie con nombre.
class CarruselRutasRecomendadas extends StatelessWidget {
  final List<ModeloRuta> rutas;
  final ValueChanged<ModeloRuta>? onTapRuta;
  final VoidCallback? onVerTodas;
  final String titulo;
  final String? iconoAsset;
  final double? altura;
  final double? anchoTarjeta;
  final String? subtitulo;
  final EstiloPieCarrusel estiloPie;

  const CarruselRutasRecomendadas({
    super.key,
    required this.rutas,
    this.onTapRuta,
    this.onVerTodas,
    this.titulo = 'Cusco',
    this.iconoAsset,
    this.altura,
    this.anchoTarjeta,
    this.subtitulo,
    this.estiloPie = EstiloPieCarrusel.provincia,
  });

  @override
  Widget build(BuildContext context) {
    final h = altura ?? 300;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: TipografiaHaku.titulo(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.piedra,
                  ),
                ),
              ),
              if (onVerTodas != null)
                TextButton(
                  onPressed: onVerTodas,
                  style: TextButton.styleFrom(
                    foregroundColor: PaletaRutas.oroSuave,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'Ver todo',
                    style: TipografiaHaku.interfaz(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: PaletaRutas.oroSuave,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (subtitulo != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
            child: Text(
              subtitulo!,
              style: TipografiaHaku.interfaz(
                fontSize: 12,
                color: PaletaRutas.plomoClaro,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          height: h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rutas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final ruta = rutas[index];
              return _TarjetaCarrusel(
                ruta: ruta,
                ancho: anchoTarjeta ?? 176,
                estiloPie: estiloPie,
                onTap: () => onTapRuta?.call(ruta),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TarjetaCarrusel extends StatelessWidget {
  final ModeloRuta ruta;
  final VoidCallback? onTap;
  final double ancho;
  final EstiloPieCarrusel estiloPie;

  const _TarjetaCarrusel({
    required this.ruta,
    required this.estiloPie,
    this.onTap,
    this.ancho = 176,
  });

  String get _pieSecundario {
    switch (estiloPie) {
      case EstiloPieCarrusel.provincia:
        return ruta.provincia;
      case EstiloPieCarrusel.experiencia:
        return ruta.subtitulo.isNotEmpty
            ? ruta.subtitulo
            : CopyHaku.carruselPieExperiencia;
      case EstiloPieCarrusel.tipoYProvincia:
        final tipo = (ruta.tipoSitio != null && ruta.tipoSitio!.isNotEmpty)
            ? ruta.tipoSitio!
            : (ruta.etiquetas.isNotEmpty ? ruta.etiquetas.first : CopyHaku.tipoLugarFallback);
        return ruta.provincia.isNotEmpty ? '$tipo · ${ruta.provincia}' : tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: ancho,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ImagenHaku(url: ruta.imagenUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ruta.titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TipografiaHaku.interfaz(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.piedra,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _pieSecundario,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TipografiaHaku.interfaz(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: PaletaRutas.plomoClaro,
                ),
              ),
              if (ruta.calificacion > 0) ...[
                const SizedBox(height: 6),
                _ValoracionSitio(
                  calificacion: ruta.calificacion,
                  resenas: ruta.cantidadResenas,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Valoración estilo discovery: número + puntos oro + reseñas.
class _ValoracionSitio extends StatelessWidget {
  const _ValoracionSitio({
    required this.calificacion,
    required this.resenas,
  });

  final double calificacion;
  final int resenas;

  @override
  Widget build(BuildContext context) {
    final textoNota = calificacion.toStringAsFixed(1).replaceAll('.', ',');
    return Row(
      children: [
        Text(
          textoNota,
          style: TipografiaHaku.interfaz(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: PaletaRutas.piedra,
          ),
        ),
        const SizedBox(width: 6),
        ...List.generate(5, (i) {
          final lleno = calificacion >= i + 0.75;
          final medio = !lleno && calificacion >= i + 0.25;
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lleno
                    ? PaletaRutas.oro
                    : medio
                        ? PaletaRutas.oro.withValues(alpha: 0.45)
                        : PaletaRutas.plomoOscuro,
              ),
            ),
          );
        }),
        if (resenas > 0) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '($resenas)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TipografiaHaku.interfaz(
                fontSize: 10,
                color: PaletaRutas.plomo,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
