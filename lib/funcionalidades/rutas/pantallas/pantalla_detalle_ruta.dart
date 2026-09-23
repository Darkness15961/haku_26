import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/recursos/copy_haku.dart';
import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../lugares/widgets/lista_experiencias_lugar.dart';
import '../../lugares/widgets/recuerdos_comunidad.dart';
import '../dominio/modelos/modelo_ruta.dart';
import '../datos/rutas_datasource_supabase.dart';
import '../proveedores/proveedor_rutas.dart';
import '../widgets/decoracion_detalle_fondo.dart';
import '../widgets/estilos_rutas.dart';
import '../widgets/imagen_parallax_ruta.dart';
import '../widgets/linea_encabezado_inca.dart';
import '../widgets/menu_acciones_detalle.dart';
import '../widgets/menu_acciones_flotante.dart';
import 'pantalla_mapa_ruta.dart';

/// Detalle de una ruta: hero + ficha + aporte a la comunidad.
class PantallaDetalleRuta extends ConsumerStatefulWidget {
  final ModeloRuta ruta;

  const PantallaDetalleRuta({super.key, required this.ruta});

  @override
  ConsumerState<PantallaDetalleRuta> createState() =>
      _EstadoPantallaDetalleRuta();
}

class _EstadoPantallaDetalleRuta extends ConsumerState<PantallaDetalleRuta> {
  static const _alturaHero = 300.0;
  static const _adorno = 'public/image/adorno_detalle_ruta.jpg';

  final ScrollController _scroll = ScrollController();
  bool _menuAbierto = false;
  late bool _guardadoOptimista;
  bool _isMutatingGuardado = false;

  @override
  void initState() {
    super.initState();
    _guardadoOptimista = widget.ruta.guardadoPorMi;
  }

  @override
  void didUpdateWidget(covariant PantallaDetalleRuta oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isMutatingGuardado && oldWidget.ruta != widget.ruta) {
      _guardadoOptimista = widget.ruta.guardadoPorMi;
    }
  }

  void _toggleMenu() => setState(() => _menuAbierto = !_menuAbierto);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double get _offset => _scroll.hasClients ? _scroll.offset : 0.0;

  Future<void> _toggleFavorito() async {
    if (_isMutatingGuardado) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;

    setState(() {
      _isMutatingGuardado = true;
      _guardadoOptimista = !_guardadoOptimista;
    });

    try {
      final repo = RutasDataSourceSupabase();
      if (_guardadoOptimista) {
        await repo.guardarRuta(widget.ruta.id);
      } else {
        await repo.quitarGuardadoRuta(widget.ruta.id);
      }
      ref.invalidate(rutaDetalleProvider(widget.ruta.id));
    } catch (e) {
      if (mounted) {
        setState(() => _guardadoOptimista = !_guardadoOptimista);
        _avisar('Error al guardar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isMutatingGuardado = false);
      }
    }
  }

  void _avisar(String mensaje) {
    mostrarSnackHaku(context, mensaje, destacado: true);
  }

  void _abrirMapa(ModeloRuta ruta) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PantallaMapaRuta(ruta: ruta)),
    );
  }

  Widget _rutaNoDisponible() {
    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        title: const Text('Ruta no disponible'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.route_outlined,
                size: 48,
                color: PaletaRutas.plomoClaro,
              ),
              const SizedBox(height: 14),
              Text(
                'Esta ruta ya no está publicada.',
                textAlign: TextAlign.center,
                style: TipografiaHaku.titulo(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.piedra,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Puedes volver a Explora para elegir otra ruta.',
                textAlign: TextAlign.center,
                style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detalleAsync = ref.watch(rutaDetalleProvider(widget.ruta.id));
    if (supabaseListo &&
        detalleAsync.hasValue &&
        detalleAsync.valueOrNull == null) {
      return _rutaNoDisponible();
    }
    final ruta = detalleAsync.valueOrNull ?? widget.ruta;
    final size = MediaQuery.sizeOf(context);
    final alturaHero = size.height < 600 ? 220.0 : _alturaHero;
    final horizontal = size.width > 804 ? (size.width - 760) / 2 : 22.0;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Si la rutaProvider ya nos dio un dato fresco, y no estamos mutando,
    // sincronizamos la variable optimista.
    if (!_isMutatingGuardado) {
      _guardadoOptimista = ruta.guardadoPorMi;
    }

    final favorito = _guardadoOptimista;
    final uidActual = ref.watch(sesionProvider.select((s) => s.usuario?.id));
    final esAutor = uidActual != null && uidActual == ruta.usuarioCreadorId;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: PaletaRutas.ink,
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: alturaHero,
                    child: RepaintBoundary(
                      child: ListenableBuilder(
                        listenable: _scroll,
                        builder: (context, _) {
                          return ImagenParallaxRuta(
                            imagenUrl: ruta.imagenUrl,
                            altura: alturaHero,
                            scrollOffset: _offset,
                            factorParallax: 1.0,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -28),
                    child: ColoredBox(
                      color: PaletaRutas.ink,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.16,
                              child: Image.asset(
                                _adorno,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontal,
                              36,
                              horizontal,
                              100 + bottomInset,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  ruta.titulo,
                                  textAlign: TextAlign.center,
                                  style: TipografiaHaku.titulo(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: PaletaRutas.piedra,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const LineaEncabezadoInca(altura: 2),
                                if (detalleAsync.isLoading &&
                                    !detalleAsync.hasValue) ...[
                                  const SizedBox(height: 12),
                                  const LinearProgressIndicator(
                                    minHeight: 2,
                                    color: PaletaRutas.oro,
                                    backgroundColor: PaletaRutas.plomoOscuro,
                                  ),
                                ],
                                if (detalleAsync.hasError &&
                                    !detalleAsync.hasValue) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      4,
                                      8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: PaletaRutas.carbon,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Mostramos el resumen guardado. El detalle no pudo actualizarse.',
                                            style: TipografiaHaku.interfaz(
                                              fontSize: 12,
                                              color: PaletaRutas.oroSuave,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => ref.invalidate(
                                            rutaDetalleProvider(widget.ruta.id),
                                          ),
                                          child: const Text('Reintentar'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                _MetaAutorRuta(ruta: ruta),
                                if (ruta.subtitulo.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    ruta.subtitulo,
                                    textAlign: TextAlign.center,
                                    style: TipografiaHaku.interfaz(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: PaletaRutas.plomoClaro,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                _ResumenValoracionRuta(ruta: ruta),
                                const SizedBox(height: 12),
                                _ValoracionRutaPanel(
                                  rutaId: ruta.id,
                                  esAutor: esAutor,
                                ),
                                if (ruta.tipoSitio != null) ...[
                                  const SizedBox(height: 10),
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: PaletaRutas.carbon,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: PaletaRutas.plomoOscuro
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                      child: Text(
                                        ruta.tipoSitio!,
                                        style: TipografiaHaku.interfaz(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: PaletaRutas.oro,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (ruta.etiquetas.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 18,
                                    runSpacing: 10,
                                    children: ruta.etiquetas.map((tag) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _iconoEtiqueta(tag),
                                            size: 22,
                                            color: PaletaRutas.oro,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            tag,
                                            style: TipografiaHaku.interfaz(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: PaletaRutas.plomoClaro,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                if (ruta.comoLlegar.isNotEmpty ||
                                    ruta.puntos.isNotEmpty ||
                                    ruta.trazado.length >= 2) ...[
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: PaletaRutas.carbon,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: PaletaRutas.plomo.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Acceso',
                                          style: TipografiaHaku.titulo(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: PaletaRutas.piedra,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        if (ruta.comoLlegar.isNotEmpty) ...[
                                          Text(
                                            ruta.comoLlegar,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: TipografiaHaku.interfaz(
                                              fontSize: 13,
                                              color: PaletaRutas.plomoClaro,
                                            ),
                                          ),
                                        ],
                                        if (ruta.puntos.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            '${ruta.puntos.length} paradas',
                                            style: TipografiaHaku.interfaz(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: PaletaRutas.oro,
                                            ),
                                          ),
                                        ],
                                        if (ruta.puntos.isNotEmpty ||
                                            ruta.trazado.length >= 2) ...[
                                          const SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: OutlinedButton.icon(
                                              onPressed: () => _abrirMapa(ruta),
                                              icon: const Icon(
                                                Icons.route_rounded,
                                                size: 18,
                                              ),
                                              label: const Text(
                                                'Ver recorrido',
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    PaletaRutas.oro,
                                                side: BorderSide(
                                                  color: PaletaRutas.oro
                                                      .withValues(alpha: 0.6),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // Descripción en pergamino (más legible, mismo estilo).
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: PaletaRutas.carbon,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: PaletaRutas.plomoOscuro.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Descripción',
                                        style: TipografiaHaku.titulo(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: PaletaRutas.piedra,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        ruta.descripcion,
                                        style: TipografiaHaku.interfaz(
                                          fontSize: 14,
                                          height: 1.45,
                                          color: PaletaRutas.plomoClaro,
                                        ),
                                      ),
                                      if (ruta.distancia.isNotEmpty) ...[
                                        const SizedBox(height: 14),
                                        Text(
                                          ruta.distancia,
                                          style: TipografiaHaku.interfaz(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: PaletaRutas.oro,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 22),
                                _GrillaInfo(ruta: ruta),
                                const SizedBox(height: 24),
                                RecuerdosComunidad(rutaId: ruta.id),
                                const SizedBox(height: 24),
                                Text(
                                  'Experiencias',
                                  style: TipografiaHaku.titulo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: PaletaRutas.piedra,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CopyHaku.seccionExperienciasSub,
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 12,
                                    color: PaletaRutas.plomoClaro,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ListaExperienciasLugar(rutaId: ruta.id),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Positioned.fill(
              child: VeloAccionesFlotante(
                visible: _menuAbierto,
                onTap: () => setState(() => _menuAbierto = false),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 16 + bottomInset,
              child: MenuAccionesDetalle.ruta(
                ruta: ruta,
                abierto: _menuAbierto,
                onToggle: _toggleMenu,
                onCerrar: () => setState(() => _menuAbierto = false),
              ),
            ),

            Positioned(
              top: topInset + 8,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BotonCircular(
                    tooltip: 'Volver',
                    icono: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  Row(
                    children: [
                      if (!esAutor) ...[
                        _BotonCircular(
                          tooltip: favorito
                              ? 'Quitar de guardados'
                              : 'Guardar ruta',
                          icono: favorito
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          colorIcono: favorito
                              ? PaletaRutas.oro
                              : PaletaRutas.piedra,
                          onTap: _toggleFavorito,
                        ),
                        const SizedBox(width: 8),
                      ],
                      _BotonCircular(
                        tooltip: 'Compartir',
                        icono: Icons.ios_share_rounded,
                        onTap: () => _avisar('Compartido'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconoEtiqueta(String tag) {
    final t = tag.toLowerCase();
    if (t.contains('natur')) return Icons.park_outlined;
    if (t.contains('avent')) return Icons.hiking;
    if (t.contains('foto')) return Icons.photo_camera_outlined;
    if (t.contains('hist') || t.contains('arque')) {
      return Icons.account_balance_outlined;
    }
    if (t.contains('trek') || t.contains('mont')) return Icons.terrain;
    if (t.contains('cult')) return Icons.museum_outlined;
    return Icons.explore_outlined;
  }
}

class _MetaAutorRuta extends StatelessWidget {
  const _MetaAutorRuta({required this.ruta});

  final ModeloRuta ruta;

  @override
  Widget build(BuildContext context) {
    final autor = ruta.usuarioCreadorNombre == null
        ? 'Autor de la comunidad'
        : '@${ruta.usuarioCreadorNombre}';
    final fechaBase = ruta.updatedAt ?? ruta.publicadaEn;
    final etiquetaFecha = ruta.updatedAt != null ? 'Actualizada' : 'Publicada';
    final fecha = fechaBase == null
        ? 'Sin fecha reciente'
        : '$etiquetaFecha ${_formatearFecha(fechaBase)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: PaletaRutas.carbon,
          backgroundImage: ruta.usuarioCreadorFoto == null
              ? null
              : NetworkImage(ruta.usuarioCreadorFoto!),
          child: ruta.usuarioCreadorFoto == null
              ? const Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: PaletaRutas.oro,
                )
              : null,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$autor · $fecha',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: PaletaRutas.plomoClaro,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumenValoracionRuta extends StatelessWidget {
  const _ResumenValoracionRuta({required this.ruta});

  final ModeloRuta ruta;

  @override
  Widget build(BuildContext context) {
    final hayValoraciones = ruta.cantidadResenas > 0 && ruta.calificacion > 0;
    final texto = hayValoraciones
        ? '${ruta.calificacion.toStringAsFixed(1)} (${ruta.cantidadResenas})'
        : 'Sin valoraciones';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          hayValoraciones ? Icons.star_rounded : Icons.star_border_rounded,
          color: PaletaRutas.oro,
          size: 20,
        ),
        const SizedBox(width: 5),
        Text(
          texto,
          style: TipografiaHaku.interfaz(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: PaletaRutas.piedra,
          ),
        ),
      ],
    );
  }
}

class _ValoracionRutaPanel extends ConsumerStatefulWidget {
  const _ValoracionRutaPanel({required this.rutaId, required this.esAutor});

  final String rutaId;
  final bool esAutor;

  @override
  ConsumerState<_ValoracionRutaPanel> createState() =>
      _EstadoValoracionRutaPanel();
}

class _EstadoValoracionRutaPanel extends ConsumerState<_ValoracionRutaPanel> {
  bool _guardando = false;

  Future<void> _valorar(int puntuacion) async {
    if (_guardando || widget.esAutor) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;

    setState(() => _guardando = true);
    try {
      await ref
          .read(rutasDataSourceProvider)
          .valorarRuta(widget.rutaId, puntuacion);
      ref.invalidate(miValoracionRutaProvider(widget.rutaId));
      ref.invalidate(rutaDetalleProvider(widget.rutaId));
      notificarRutasCambiaron(ref);
      if (mounted) {
        mostrarSnackHaku(context, 'Valoracion guardada', destacado: true);
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackHaku(context, 'No se pudo valorar: $e', destacado: true);
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valorAsync = ref.watch(miValoracionRutaProvider(widget.rutaId));
    final valor = valorAsync.valueOrNull ?? 0;
    final texto = widget.esAutor
        ? 'Tu Ruta'
        : valor > 0
        ? 'Tu valoracion'
        : 'Valorar Ruta';

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: PaletaRutas.carbon,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: PaletaRutas.plomoOscuro.withValues(alpha: 0.65),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texto,
              style: TipografiaHaku.interfaz(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: PaletaRutas.plomoClaro,
              ),
            ),
            const SizedBox(width: 8),
            if (_guardando || valorAsync.isLoading && !valorAsync.hasValue)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PaletaRutas.oro,
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final puntuacion = i + 1;
                  final activo = puntuacion <= valor;
                  return Tooltip(
                    message: '$puntuacion estrellas',
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 28,
                        height: 28,
                      ),
                      onPressed: widget.esAutor
                          ? null
                          : () => _valorar(puntuacion),
                      icon: Icon(
                        activo ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 22,
                        color: widget.esAutor
                            ? PaletaRutas.plomo
                            : PaletaRutas.oro,
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatearFecha(DateTime fecha) {
  final local = fecha.toLocal();
  final dia = local.day.toString().padLeft(2, '0');
  final mes = local.month.toString().padLeft(2, '0');
  return '$dia/$mes/${local.year}';
}

class _GrillaInfo extends StatelessWidget {
  final ModeloRuta ruta;

  const _GrillaInfo({required this.ruta});

  @override
  Widget build(BuildContext context) {
    final items = <_InfoItem>[
      if (ruta.altitud.isNotEmpty)
        _InfoItem(Icons.landscape_outlined, 'Altitud', ruta.altitud),
      if (ruta.tiempoCaminata.isNotEmpty)
        _InfoItem(Icons.timer_outlined, 'Tiempo', ruta.tiempoCaminata),
      _InfoItem(Icons.trending_up_rounded, 'Dificultad', ruta.dificultadTexto),
      if (ruta.mejorEpoca.isNotEmpty)
        _InfoItem(Icons.calendar_month_outlined, 'Época', ruta.mejorEpoca),
    ];

    return Column(
      children: [
        for (var i = 0; i < items.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < items.length ? 12 : 0),
            child: Row(
              children: [
                Expanded(
                  child: _InfoItemCard(item: items[i], indice: i),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < items.length
                      ? _InfoItemCard(item: items[i + 1], indice: i + 1)
                      : const SizedBox(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoItem {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _InfoItem(this.icono, this.etiqueta, this.valor);
}

class _InfoItemCard extends StatelessWidget {
  final _InfoItem item;
  final int indice;

  const _InfoItemCard({required this.item, required this.indice});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              FondosDetalleHaku.porIndice(indice),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: PaletaRutas.carbon),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(color: PaletaRutas.ink.withValues(alpha: 0.68)),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: PaletaRutas.plomo.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icono, size: 20, color: PaletaRutas.oro),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.etiqueta,
                        style: TipografiaHaku.interfaz(
                          fontSize: 11,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.valor,
                        style: TipografiaHaku.interfaz(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ],
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

class _BotonCircular extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;
  final Color colorIcono;
  final String tooltip;

  const _BotonCircular({
    required this.icono,
    required this.onTap,
    required this.tooltip,
    this.colorIcono = PaletaRutas.piedra,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: PaletaRutas.ink.withValues(alpha: 0.35),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: AssetImage(FondosDetalleHaku.fondoA),
                fit: BoxFit.cover,
              ),
              border: Border.all(
                color: PaletaRutas.plomo.withValues(alpha: 0.45),
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PaletaRutas.ink.withValues(alpha: 0.55),
              ),
              child: Icon(
                icono,
                size: 18,
                color: colorIcono == PaletaRutas.oro
                    ? PaletaRutas.oro
                    : PaletaRutas.piedra,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
