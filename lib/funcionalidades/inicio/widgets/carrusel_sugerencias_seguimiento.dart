import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../perfil_usuario/navegacion_perfil_ajeno.dart';
import '../datos/feed_inicio_datasource_local.dart';

/// Carrusel de perfiles sugeridos para seguir.
class CarruselSugerenciasSeguimiento extends ConsumerStatefulWidget {
  final List<SugerenciaSeguimiento> sugerencias;

  const CarruselSugerenciasSeguimiento({
    super.key,
    required this.sugerencias,
  });

  @override
  ConsumerState<CarruselSugerenciasSeguimiento> createState() =>
      _EstadoCarruselSugerenciasSeguimiento();
}

class _EstadoCarruselSugerenciasSeguimiento
    extends ConsumerState<CarruselSugerenciasSeguimiento> {
  final Set<String> _siguiendo = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Sugerencias de seguimiento',
            style: TipografiaHaku.titulo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: PaletaRutas.marronOscuro,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.sugerencias.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final s = widget.sugerencias[index];
              final siguiendo = _siguiendo.contains(s.id);
              return _TarjetaSugerencia(
                sugerencia: s,
                indice: index,
                siguiendo: siguiendo,
                onSeguir: () async {
                  final ok = await asegurarSesion(context, ref);
                  if (!ok || !mounted) return;
                  setState(() {
                    if (siguiendo) {
                      _siguiendo.remove(s.id);
                    } else {
                      _siguiendo.add(s.id);
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TarjetaSugerencia extends StatelessWidget {
  final SugerenciaSeguimiento sugerencia;
  final int indice;
  final bool siguiendo;
  final VoidCallback onSeguir;

  const _TarjetaSugerencia({
    required this.sugerencia,
    required this.indice,
    required this.siguiendo,
    required this.onSeguir,
  });

  @override
  Widget build(BuildContext context) {
    final veloNegro = indice % 3 != 1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => abrirPerfilAjeno(
          context,
          id: sugerencia.id,
          nombre: sugerencia.nombre,
          usuario: sugerencia.usuario,
          avatarUrl: sugerencia.avatarUrl,
          bioCorta: sugerencia.bioCorta,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 142,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            image: DecorationImage(
              image: AssetImage(FondosDetalleHaku.porIndice(indice)),
              fit: BoxFit.cover,
              opacity: 0.55,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: veloNegro
                        ? Colors.black.withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.62),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                  child: Column(
                    children: [
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: sugerencia.avatarUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ColoredBox(
                            color: Color(0xFFCCCCCC),
                            child: SizedBox(width: 56, height: 56),
                          ),
                          errorWidget: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFBBBBBB),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: Icon(Icons.person, color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sugerencia.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TipografiaHaku.interfaz(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: veloNegro
                              ? Colors.white
                              : PaletaRutas.marronOscuro,
                        ),
                      ),
                      Text(
                        sugerencia.usuario,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.interfaz(
                          fontSize: 11,
                          color: veloNegro
                              ? Colors.white.withValues(alpha: 0.7)
                              : PaletaRutas.marronOscuro.withValues(alpha: 0.65),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: TextButton(
                          onPressed: onSeguir,
                          style: TextButton.styleFrom(
                            backgroundColor: siguiendo
                                ? Colors.transparent
                                : (veloNegro
                                    ? Colors.white.withValues(alpha: 0.92)
                                    : Colors.black.withValues(alpha: 0.88)),
                            foregroundColor: siguiendo
                                ? (veloNegro
                                    ? Colors.white
                                    : PaletaRutas.marronOscuro)
                                : (veloNegro
                                    ? PaletaRutas.marronOscuro
                                    : Colors.white),
                            side: siguiendo
                                ? BorderSide(
                                    color: veloNegro
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : PaletaRutas.marronOscuro
                                            .withValues(alpha: 0.45),
                                  )
                                : BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            siguiendo ? 'Siguiendo' : 'Seguir',
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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
