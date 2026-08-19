import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../../../nucleo/widgets/avatar_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../pantallas/pantalla_exploradores_deslizables.dart';
import '../proveedores/proveedor_almacen_feed.dart';

/// Exploradores en recuadros redondeados, con botón Seguir (estilo Instagram).
class CarruselSugerenciasSeguimiento extends ConsumerStatefulWidget {
  final List<SugerenciaSeguimiento> sugerencias;
  final String titulo;
  final String? subtitulo;

  const CarruselSugerenciasSeguimiento({
    super.key,
    required this.sugerencias,
    this.titulo = 'Exploradores',
    this.subtitulo,
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
          child: Column(
            children: [
              SizedBox(
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
              if (widget.subtitulo != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.subtitulo!,
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    color: PaletaRutas.marronCuero,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 168,
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 118,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (sugerencia.portadaUrl.isNotEmpty)
                  ImagenHaku(
                    url: sugerencia.portadaUrl,
                    fit: BoxFit.cover,
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                  child: Column(
                    children: [
                      AvatarHaku(
                        url: sugerencia.avatarUrl,
                        size: 48,
                        borderWidth: 2,
                        borderColor: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sugerencia.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TipografiaHaku.titulo(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        sugerencia.bioCorta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TipografiaHaku.interfaz(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
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
              ],
            ),
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
