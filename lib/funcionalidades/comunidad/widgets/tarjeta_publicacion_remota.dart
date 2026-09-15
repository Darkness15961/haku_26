import 'package:flutter/material.dart';

import '../../../nucleo/responsive/espacio_haku.dart';
import '../../../nucleo/widgets/avatar_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../lugares/navegacion_lugar.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../dominio/modelo_publicacion.dart';
import '../pantallas/pantalla_detalle_comunidad.dart';

/// Card remota con lenguaje visual del feed Threads (sin likes inventados).
class TarjetaPublicacionRemota extends StatelessWidget {
  const TarjetaPublicacionRemota({
    super.key,
    required this.publicacion,
    this.compacta = false,
  });

  final ModeloPublicacionRemota publicacion;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final p = publicacion;
    final imagen = p.imagenUrl?.trim() ?? '';
    final foto = p.autorFotoPerfil?.trim() ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compacta ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imagen.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: EspacioHaku.aspectPublicacion(context),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImagenHaku(url: imagen, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x00000000),
                            Color(0x99000000),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Row(
                        children: [
                          if (foto.isEmpty)
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: PaletaRutas.ink,
                              child: Icon(
                                Icons.person_outline,
                                size: 16,
                                color: PaletaRutas.plomo.withValues(alpha: 0.9),
                              ),
                            )
                          else
                            AvatarHaku(url: foto, size: 28),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.etiquetaAutor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TipografiaHaku.interfaz(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: PaletaRutas.piedra,
                              ),
                            ),
                          ),
                          Text(
                            p.hace,
                            style: TipografiaHaku.interfaz(
                              fontSize: 11,
                              color: PaletaRutas.piedra.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Material(
              color: PaletaRutas.carbon,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    if (foto.isEmpty)
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: PaletaRutas.ink,
                        child: Icon(
                          Icons.person_outline,
                          size: 20,
                          color: PaletaRutas.plomo.withValues(alpha: 0.9),
                        ),
                      )
                    else
                      AvatarHaku(url: foto, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.etiquetaAutor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.interfaz(
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ),
                    Text(
                      p.hace,
                      style: TipografiaHaku.interfaz(
                        fontSize: 11,
                        color: PaletaRutas.plomo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 2, bottom: 2),
            child: LineaEncabezadoInca(altura: 2.5),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 4),
            child: Text(
              p.contenido,
              style: TipografiaHaku.interfaz(
                fontSize: 14,
                height: 1.4,
                color: PaletaRutas.piedra,
              ),
            ),
          ),
          if (p.lugarNombre != null && p.lugarNombre!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 4),
              child: GestureDetector(
                onTap: () {
                  final lid = p.lugarId?.trim() ?? '';
                  if (lid.isEmpty || int.tryParse(lid) == null) return;
                  abrirDetalleLugar(context, lid);
                },
                child: Text(
                  p.lugarNombre!,
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.oro,
                  ).copyWith(
                    decoration: (p.lugarId != null &&
                            int.tryParse(p.lugarId!.trim()) != null)
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: PaletaRutas.oro,
                  ),
                ),
              ),
            ),
          if (p.comunidades.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 6, top: 2),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in p.comunidades)
                    if (c.nombre.trim().isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PantallaDetalleComunidad(
                                comunidadId: c.comunidadId,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: PaletaRutas.oro.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: PaletaRutas.oro.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            c.nombre,
                            style: TipografiaHaku.interfaz(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.oro,
                            ),
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
}
