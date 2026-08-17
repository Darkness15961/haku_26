import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../pantallas/pantalla_exploradores_deslizables.dart';
import '../proveedores/proveedor_almacen_feed.dart';

/// Exploradores en recuadros redondeados, con botón Seguir (estilo Instagram).
class CarruselSugerenciasSeguimiento extends ConsumerStatefulWidget {
  final List<SugerenciaSeguimiento> sugerencias;
  final String titulo;

  const CarruselSugerenciasSeguimiento({
    super.key,
    required this.sugerencias,
    this.titulo = 'Sugerencias de seguimiento',
  });

  @override
  ConsumerState<CarruselSugerenciasSeguimiento> createState() =>
      _EstadoCarruselSugerenciasSeguimiento();
}

class _EstadoCarruselSugerenciasSeguimiento
    extends ConsumerState<CarruselSugerenciasSeguimiento> {
  Future<void> _toggleSeguir(SugerenciaSeguimiento s) async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    await ref.read(almacenFeedProvider.notifier).toggleSeguir(s.id);
  }

  Future<void> _abrirPerfil(int indice) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaExploradoresDeslizables(
          exploradores: widget.sugerencias,
          indiceInicial: indice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  widget.titulo,
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.titulo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.marronOscuro,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SvgPicture.asset(
                    'assets/iconos/llama.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      PaletaRutas.marronCuero,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.sugerencias.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final s = widget.sugerencias[index];
              final siguiendo =
                  ref.watch(almacenFeedProvider).siguiendoIds.contains(s.id);
              return _TarjetaExplorador(
                sugerencia: s,
                indice: index,
                siguiendo: siguiendo,
                onTap: () => _abrirPerfil(index),
                onSeguir: () => _toggleSeguir(s),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TarjetaExplorador extends StatelessWidget {
  final SugerenciaSeguimiento sugerencia;
  final int indice;
  final bool siguiendo;
  final VoidCallback onTap;
  final VoidCallback onSeguir;

  const _TarjetaExplorador({
    required this.sugerencia,
    required this.indice,
    required this.siguiendo,
    required this.onTap,
    required this.onSeguir,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          child: Column(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: sugerencia.avatarUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const ColoredBox(color: Color(0xFFD4C8B8)),
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: Color(0xFFBBBBBB),
                    child: Icon(Icons.person, size: 22, color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sugerencia.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TipografiaHaku.titulo(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.marronOscuro,
                ),
              ),
              const Spacer(),
              _BotonSeguirTextil(
                siguiendo: siguiendo,
                indice: indice,
                onPressed: onSeguir,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonSeguirTextil extends StatelessWidget {
  final bool siguiendo;
  final int indice;
  final VoidCallback onPressed;

  const _BotonSeguirTextil({
    required this.siguiendo,
    required this.indice,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 24,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  FondosDetalleHaku.porIndice(indice),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Colors.black87),
                ),
                ColoredBox(
                  color: Colors.black.withValues(
                    alpha: siguiendo ? 0.62 : 0.38,
                  ),
                ),
                Center(
                  child: Text(
                    siguiendo ? 'Siguiendo' : 'Seguir',
                    style: TipografiaHaku.titulo(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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
