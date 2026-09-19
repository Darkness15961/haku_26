import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/responsive/espacio_haku.dart';
import '../../../nucleo/widgets/avatar_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../lugares/navegacion_lugar.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelo_publicacion.dart';
import '../datos/publicacion_datasource_supabase.dart';
import '../pantallas/pantalla_detalle_comunidad.dart';
import '../proveedores/proveedor_publicaciones.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import 'video_publicacion_haku.dart';

/// Card remota con lenguaje visual del feed Threads (sin likes inventados).
class TarjetaPublicacionRemota extends ConsumerWidget {
  const TarjetaPublicacionRemota({
    super.key,
    required this.publicacion,
    this.compacta = false,
    this.habilitarComunidad = true,
  });

  final ModeloPublicacionRemota publicacion;
  final bool compacta;
  final bool habilitarComunidad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = publicacion;
    final imagen = p.imagenUrl?.trim() ?? '';
    final video = p.videoUrl?.trim() ?? '';
    final foto = p.autorFotoPerfil?.trim() ?? '';
    final uidActual = ref.watch(sesionProvider.select((s) => s.usuario?.id));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compacta ? 0 : 16),
      child: Container(
        margin: EdgeInsets.only(bottom: compacta ? 12 : 24),
        decoration: BoxDecoration(
          color: PaletaRutas.carbon,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: PaletaRutas.plomoClaro.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. HEADER (Autor, tiempo, privacidad) ──
            Padding(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.etiquetaAutor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TipografiaHaku.interfaz(
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              p.hace,
                              style: TipografiaHaku.interfaz(
                                fontSize: 11,
                                color: PaletaRutas.plomo,
                              ),
                            ),
                            if (p.estado == 'privado') ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.lock_outline,
                                size: 12,
                                color: PaletaRutas.plomo,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _BotonOpcionesPub(publicacion: p, oscuro: true),
                ],
              ),
            ),

            // ── 2. CONTENIDO TEXTUAL ──
            if (p.contenido.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  p.contenido,
                  style: TipografiaHaku.interfaz(
                    fontSize: 14,
                    height: 1.4,
                    color: PaletaRutas.piedra,
                  ),
                ),
              ),

            // ── 3. MEDIA (Foto/Video) ──
            if (video.isNotEmpty || imagen.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: EspacioHaku.aspectPublicacion(context),
                  child: video.isNotEmpty
                      ? VideoPublicacionHaku(
                          publicacionId: p.id,
                          url: video,
                          miniaturaUrl: p.videoMiniaturaUrl,
                          estadoInicial: p.videoEstado ?? 'processing',
                        )
                      : ImagenHaku(url: imagen, fit: BoxFit.cover),
                ),
              ),

            // ── 4. CALL TO ACTION Y ETIQUETAS ──
            if (p.lugarNombre != null ||
                p.comunidades.isNotEmpty ||
                p.rutaNombre != null ||
                p.salidaNombre != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (p.rutaNombre != null && p.rutaNombre!.trim().isNotEmpty)
                      _BotonAccionLlamativa(
                        icono: Icons.route_outlined,
                        texto: 'Explorar Ruta',
                        secundario: p.rutaNombre!,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Abrir ruta (Próximamente)')),
                          );
                        },
                      ),
                    if (p.lugarNombre != null && p.lugarNombre!.trim().isNotEmpty)
                      _BotonAccionLlamativa(
                        icono: Icons.place_outlined,
                        texto: 'Ver Lugar',
                        secundario: p.lugarNombre!,
                        onTap: () {
                          final lid = p.lugarId?.trim() ?? '';
                          if (lid.isNotEmpty && int.tryParse(lid) != null) {
                            abrirDetalleLugar(context, lid);
                          }
                        },
                      ),
                    if (p.salidaNombre != null && p.salidaNombre!.trim().isNotEmpty)
                      _ChipEtiqueta(
                        icono: Icons.hiking,
                        texto: p.salidaNombre!,
                      ),
                    for (final c in p.comunidades)
                      if (c.nombre.trim().isNotEmpty)
                        GestureDetector(
                          onTap: habilitarComunidad
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => PantallaDetalleComunidad(
                                        comunidadId: c.comunidadId,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: _ChipEtiqueta(
                            icono: Icons.groups_outlined,
                            texto: c.nombre,
                          ),
                        ),
                  ],
                ),
              ),

            // ── 5. BARRA SOCIAL ──
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              child: Row(
                children: [
                  _BotonMeGusta(publicacion: p),
                  const SizedBox(width: 8),
                  _BotonSocial(
                    icono: Icons.chat_bubble_outline_rounded,
                    onTap: () => _mostrarProximamente(context, 'Comentarios'),
                  ),
                  _BotonSocial(
                    icono: Icons.send_outlined,
                    onTap: () => _mostrarProximamente(context, 'Compartir'),
                  ),
                  const Spacer(),
                  if (uidActual != p.usuarioId)
                    _BotonGuardarPub(publicacion: p),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarProximamente(BuildContext context, String accion) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$accion próximamente',
          style: TipografiaHaku.interfaz(fontSize: 14, color: PaletaRutas.ink),
        ),
        backgroundColor: PaletaRutas.oro,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _BotonSocial extends StatelessWidget {
  const _BotonSocial({required this.icono, required this.onTap, this.color = PaletaRutas.piedra});
  final IconData icono;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icono, size: 24, color: color),
      onPressed: onTap,
      splashColor: PaletaRutas.oro.withValues(alpha: 0.2),
      highlightColor: PaletaRutas.oro.withValues(alpha: 0.1),
    );
  }
}

class _BotonMeGusta extends ConsumerStatefulWidget {
  const _BotonMeGusta({required this.publicacion});
  final ModeloPublicacionRemota publicacion;

  @override
  ConsumerState<_BotonMeGusta> createState() => _BotonMeGustaState();
}

class _BotonMeGustaState extends ConsumerState<_BotonMeGusta> {
  late bool _leDiMeGusta;
  late int _cantidad;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _leDiMeGusta = widget.publicacion.leDiMeGusta;
    _cantidad = widget.publicacion.cantidadMeGusta;
  }

  @override
  void didUpdateWidget(covariant _BotonMeGusta oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isMutating) {
      _leDiMeGusta = widget.publicacion.leDiMeGusta;
      _cantidad = widget.publicacion.cantidadMeGusta;
    }
  }

  Future<void> _toggle() async {
    HapticFeedback.lightImpact();
    final user = ref.read(sesionProvider).usuario;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Debes iniciar sesión para interactuar',
            style: TipografiaHaku.interfaz(color: PaletaRutas.ink),
          ),
          backgroundColor: PaletaRutas.oro,
        ),
      );
      return;
    }

    final ds = ref.read(publicacionRemotoDataSourceProvider);
    final idPub = widget.publicacion.id;

    _isMutating = true;
    setState(() {
      if (_leDiMeGusta) {
        _leDiMeGusta = false;
        _cantidad = (_cantidad > 0) ? _cantidad - 1 : 0;
      } else {
        _leDiMeGusta = true;
        _cantidad++;
      }
    });

    try {
      if (_leDiMeGusta) {
        await ds.darMeGusta(idPub);
      } else {
        await ds.quitarMeGusta(idPub);
      }
    } catch (_) {
      // Revertir en caso de error
      if (mounted) {
        setState(() {
          if (_leDiMeGusta) {
            _leDiMeGusta = false;
            _cantidad = (_cantidad > 0) ? _cantidad - 1 : 0;
          } else {
            _leDiMeGusta = true;
            _cantidad++;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo registrar la interacción',
              style: TipografiaHaku.interfaz(color: PaletaRutas.ink),
            ),
            backgroundColor: PaletaRutas.oro,
          ),
        );
      }
    } finally {
      if (mounted) _isMutating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(24),
      splashColor: Colors.redAccent.withValues(alpha: 0.2),
      highlightColor: Colors.redAccent.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _leDiMeGusta ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 24,
              color: _leDiMeGusta ? Colors.redAccent : PaletaRutas.piedra,
            ),
            if (_cantidad > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$_cantidad',
                style: TipografiaHaku.interfaz(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _leDiMeGusta ? Colors.redAccent : PaletaRutas.piedra,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BotonGuardarPub extends ConsumerStatefulWidget {
  const _BotonGuardarPub({required this.publicacion});
  final ModeloPublicacionRemota publicacion;

  @override
  ConsumerState<_BotonGuardarPub> createState() => _BotonGuardarPubState();
}

class _BotonGuardarPubState extends ConsumerState<_BotonGuardarPub> {
  late bool _guardado;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _guardado = widget.publicacion.guardadoPorMi;
  }

  @override
  void didUpdateWidget(covariant _BotonGuardarPub oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isMutating) {
      _guardado = widget.publicacion.guardadoPorMi;
    }
  }

  Future<void> _toggle() async {
    HapticFeedback.lightImpact();
    final user = ref.read(sesionProvider).usuario;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Debes iniciar sesión para guardar',
            style: TipografiaHaku.interfaz(color: PaletaRutas.ink),
          ),
          backgroundColor: PaletaRutas.oro,
        ),
      );
      return;
    }

    _isMutating = true;
    setState(() {
      _guardado = !_guardado;
    });

    try {
      final ds = PublicacionDataSourceSupabase();
      if (_guardado) {
        await ds.guardarPublicacion(widget.publicacion.id);
      } else {
        await ds.quitarGuardadoPublicacion(widget.publicacion.id);
      }
      notificarPublicacionesCambiaron(ref);
    } catch (_) {
      if (mounted) {
        setState(() {
          _guardado = !_guardado;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo guardar',
              style: TipografiaHaku.interfaz(color: PaletaRutas.ink),
            ),
            backgroundColor: PaletaRutas.oro,
          ),
        );
      }
    } finally {
      if (mounted) _isMutating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BotonSocial(
      icono: _guardado ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      onTap: _toggle,
      color: _guardado ? PaletaRutas.oro : PaletaRutas.piedra,
    );
  }
}

class _BotonAccionLlamativa extends StatelessWidget {
  const _BotonAccionLlamativa({
    required this.icono,
    required this.texto,
    required this.secundario,
    required this.onTap,
  });

  final IconData icono;
  final String texto;
  final String secundario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [PaletaRutas.oro, PaletaRutas.oroOscuro],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: PaletaRutas.oro.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 16, color: PaletaRutas.ink),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texto,
                  style: TipografiaHaku.interfaz(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: PaletaRutas.ink,
                  ),
                ),
                Text(
                  secundario,
                  style: TipografiaHaku.interfaz(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: PaletaRutas.ink.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _ChipEtiqueta extends StatelessWidget {
  const _ChipEtiqueta({required this.icono, required this.texto});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PaletaRutas.oro.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PaletaRutas.oro.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 12, color: PaletaRutas.oro),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TipografiaHaku.interfaz(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: PaletaRutas.oro,
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonOpcionesPub extends ConsumerWidget {
  const _BotonOpcionesPub({required this.publicacion, this.oscuro = false});
  final ModeloPublicacionRemota publicacion;
  final bool oscuro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(sesionProvider.select((s) => s.usuario?.id));
    if (uid != publicacion.usuarioId) return const SizedBox(width: 8);

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: PaletaRutas.carbon,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: PaletaRutas.plomoOscuro),
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_horiz_rounded,
          color: oscuro ? PaletaRutas.plomo : PaletaRutas.piedra.withValues(alpha: 0.85),
          size: 20,
        ),
        padding: EdgeInsets.zero,
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'eliminar',
            child: Row(
              children: [
                const Icon(Icons.delete_outline, color: PaletaRutas.oro, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Eliminar publicación',
                  style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                ),
              ],
            ),
          ),
        ],
        onSelected: (val) async {
          if (val == 'eliminar') {
            final conf = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: PaletaRutas.carbon,
                title: Text(
                  '¿Eliminar publicación?',
                  style: TipografiaHaku.titulo(color: PaletaRutas.piedra),
                ),
                content: Text(
                  'Esta acción no se puede deshacer.',
                  style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      'Cancelar',
                      style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      'Eliminar',
                      style: TipografiaHaku.interfaz(
                        color: PaletaRutas.oro,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
            if (conf != true) return;
            try {
              final ds = ref.read(publicacionRemotoDataSourceProvider);
              await ds.eliminarLogica(publicacion.id);
              notificarPublicacionesCambiaron(ref);
              if (context.mounted) {
                mostrarSnackHaku(context, 'Publicación eliminada');
              }
            } catch (_) {
              if (context.mounted) {
                mostrarSnackHaku(context, 'No se pudo eliminar la publicación');
              }
            }
          }
        },
      ),
    );
  }
}
