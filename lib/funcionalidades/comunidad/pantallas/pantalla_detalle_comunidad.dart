import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../../nucleo/widgets/avatar_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../rutas/widgets/boton_fondo_textil.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../dominio/modelo_comunidad.dart';
import '../proveedores/proveedor_comunidad.dart';
import '../widgets/chip_categoria_comunidad.dart';
import '../../chat/indice.dart';
import 'pantalla_salidas.dart';

class PantallaDetalleComunidad extends ConsumerStatefulWidget {
  final String comunidadId;

  const PantallaDetalleComunidad({super.key, required this.comunidadId});

  @override
  ConsumerState<PantallaDetalleComunidad> createState() =>
      _EstadoPantallaDetalleComunidad();
}

class _EstadoPantallaDetalleComunidad
    extends ConsumerState<PantallaDetalleComunidad> {
  bool _accionando = false;
  String? _resolviendoUid;

  Future<void> _unirseOSalir(ComunidadHaku c) async {
    if (_accionando) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    final uid = ref.read(sesionProvider).usuario?.id ?? '';
    if (uid.isEmpty) return;

    setState(() => _accionando = true);
    try {
      final ds = ref.read(comunidadRemotoDataSourceProvider);
      if (c.esMiembro(uid) || c.solicitudPendiente(uid)) {
        if (c.creadorId == uid) {
          if (mounted) {
            mostrarSnackHaku(
              context,
              'El creador no puede salir. La comunidad quedaría sin dueño.',
            );
          }
          return;
        }
        await ds.salir(c.id);
        notificarComunidadesCambiaron(ref);
        if (!mounted) return;
        // Privada: al salir deja de ser visible → evitar "no encontrada".
        if (c.esPrivada) {
          Navigator.of(context).pop();
          return;
        }
      } else {
        await ds.unirse(c.id, conocida: c);
        notificarComunidadesCambiaron(ref);
      }
    } on AuthException catch (e) {
      if (mounted) mostrarSnackHaku(context, e.message);
    } catch (_) {
      if (mounted) {
        mostrarSnackHaku(context, 'No se pudo actualizar la membresía');
      }
    } finally {
      if (mounted) setState(() => _accionando = false);
    }
  }

  Future<void> _resolverSolicitud({
    required ComunidadHaku c,
    required String usuarioId,
    required bool aprobar,
  }) async {
    if (_resolviendoUid != null) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    setState(() => _resolviendoUid = usuarioId);
    try {
      await ref.read(comunidadRemotoDataSourceProvider).resolverSolicitud(
            comunidadId: c.id,
            usuarioId: usuarioId,
            aprobar: aprobar,
          );
      notificarComunidadesCambiaron(ref);
      if (mounted) {
        mostrarSnackHaku(
          context,
          aprobar ? 'Solicitud aprobada' : 'Solicitud rechazada',
          destacado: aprobar,
        );
      }
    } on AuthException catch (e) {
      if (mounted) mostrarSnackHaku(context, e.message);
    } catch (_) {
      if (mounted) {
        mostrarSnackHaku(context, 'No se pudo resolver la solicitud');
      }
    } finally {
      if (mounted) setState(() => _resolviendoUid = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remotaAsync = ref.watch(comunidadDetalleProvider(widget.comunidadId));
    final miembrosAsync =
        ref.watch(miembrosComunidadProvider(widget.comunidadId));
    final pendientesAsync =
        ref.watch(pendientesComunidadProvider(widget.comunidadId));
    final store = ref.watch(almacenFeedProvider);
    final uid = ref.watch(sesionProvider).usuario?.id ?? '';

    final comunidadRemota = remotaAsync.valueOrNull;
    ComunidadHaku? comunidadLocal;
    // Con Supabase listo no mezclar demo local (evita IDs/conflictos fantasma).
    if (!supabaseListo) {
      for (final c in store.comunidades) {
        if (c.id == widget.comunidadId) {
          comunidadLocal = c;
          break;
        }
      }
    }

    if (remotaAsync.isLoading &&
        !remotaAsync.hasValue &&
        comunidadRemota == null &&
        comunidadLocal == null) {
      return Scaffold(
        backgroundColor: PaletaRutas.ink,
        appBar: AppBar(
          backgroundColor: PaletaRutas.ink,
          foregroundColor: PaletaRutas.piedra,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: PaletaRutas.oro),
        ),
      );
    }

    final comunidad = comunidadRemota ?? comunidadLocal;
    if (comunidad == null) {
      final msg = remotaAsync.hasError
          ? 'No se pudo cargar la comunidad.\nRevisá conexión o membresía.'
          : 'Comunidad no encontrada';
      return Scaffold(
        backgroundColor: PaletaRutas.ink,
        appBar: AppBar(
          backgroundColor: PaletaRutas.ink,
          foregroundColor: PaletaRutas.piedra,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              msg,
              textAlign: TextAlign.center,
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            ),
          ),
        ),
      );
    }

    final c = comunidad;
    final unida = c.remoto
        ? (c.esMiembro(uid) || c.creadorId == uid)
        : store.comunidadIds.contains(c.id);
    final pendiente = c.remoto && c.solicitudPendiente(uid);
    final soyAdmin = c.remoto && c.esAdminDe(uid);
    final miembrosLocal = [
      for (final id in c.miembroIds)
        if (store.perfilPorId(id) != null) store.perfilPorId(id)!,
    ];
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    final meta = [
      '${c.miembros} miembros',
      if (c.esPrivada) 'privada' else 'pública',
      if (!c.remoto && c.provincia.isNotEmpty) c.provincia,
    ].join(' · ');

    String textoBotonRemoto() {
      if (unida) return 'Salir';
      if (pendiente) return 'Cancelar solicitud';
      return 'Unirme';
    }

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (c.imagenUrl.trim().isEmpty)
                    ColoredBox(
                      color: PaletaRutas.carbon,
                      child: Center(
                        child: Icon(
                          Icons.diversity_3_outlined,
                          size: 56,
                          color: PaletaRutas.plomo.withValues(alpha: 0.85),
                        ),
                      ),
                    )
                  else
                    ImagenHaku(
                      url: c.imagenUrl,
                      fit: BoxFit.cover,
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          PaletaRutas.ink.withValues(alpha: 0.15),
                          PaletaRutas.ink.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Salidas de la comunidad',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => PantallaSalidas(
                                    comunidadId: c.id,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.hiking,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                          if (c.remoto && (unida || c.creadorId == uid))
                            IconButton(
                              tooltip: 'Chat de la comunidad',
                              onPressed: () {
                                abrirChatComunidad(
                                  context,
                                  ref,
                                  comunidadId: c.id,
                                  titulo: c.nombre,
                                );
                              },
                              icon: const Icon(
                                Icons.forum_outlined,
                                color: PaletaRutas.piedra,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (unida || pendiente)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: PaletaRutas.oro,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              unida ? 'Unida' : 'Pendiente',
                              style: TipografiaHaku.interfaz(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: PaletaRutas.ink,
                              ),
                            ),
                          ),
                        Text(
                          c.nombre,
                          style: TipografiaHaku.titulo(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meta,
                          style: TipografiaHaku.interfaz(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PaletaRutas.plomoClaro,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: PaletaRutas.carbon,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: PaletaRutas.plomo.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.descripcion.isEmpty
                              ? 'Sin descripción.'
                              : c.descripcion,
                          style: TipografiaHaku.interfaz(
                            fontSize: 14,
                            color: PaletaRutas.plomoClaro,
                          ),
                        ),
                        if (!c.remoto && c.categorias.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final cat in c.categorias)
                                ChipCategoriaComunidad(
                                  categoria: cat,
                                  sobreOscuro: true,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  BotonFondoTextil(
                    texto: c.remoto
                        ? (_accionando ? '…' : textoBotonRemoto())
                        : (unida ? 'Salir' : 'Unirme'),
                    icono: unida || pendiente
                        ? Icons.check_rounded
                        : Icons.group_add_outlined,
                    altura: 44,
                    radius: 12,
                    onPressed: _accionando
                        ? null
                        : () async {
                            if (c.remoto) {
                              await _unirseOSalir(c);
                              return;
                            }
                            final ok = await asegurarSesion(context, ref);
                            if (!ok) return;
                            await ref
                                .read(almacenFeedProvider.notifier)
                                .toggleUnirseComunidad(c.id);
                          },
                  ),
                  const SizedBox(height: 22),
                  const LineaEncabezadoInca(altura: 2),
                  const SizedBox(height: 14),
                  if (c.remoto && soyAdmin) ...[
                    Text(
                      'Solicitudes',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (pendientesAsync.isLoading &&
                        !pendientesAsync.hasValue)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: PaletaRutas.oro,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else if ((pendientesAsync.valueOrNull ?? const []).isEmpty)
                      Text(
                        'No hay solicitudes pendientes.',
                        style: TipografiaHaku.interfaz(
                          color: PaletaRutas.plomoClaro,
                        ),
                      )
                    else
                      for (final m in pendientesAsync.valueOrNull!)
                        _FilaSolicitudPendiente(
                          miembro: m,
                          ocupado: _resolviendoUid == m.usuarioId,
                          onAprobar: () => _resolverSolicitud(
                            c: c,
                            usuarioId: m.usuarioId,
                            aprobar: true,
                          ),
                          onRechazar: () => _resolverSolicitud(
                            c: c,
                            usuarioId: m.usuarioId,
                            aprobar: false,
                          ),
                        ),
                    const SizedBox(height: 18),
                  ],
                  Text(
                    'Miembros',
                    style: TipografiaHaku.titulo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (c.remoto) ...[
                    if (miembrosAsync.isLoading && !miembrosAsync.hasValue)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: PaletaRutas.oro,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else if ((miembrosAsync.valueOrNull ?? const []).isEmpty)
                      Text(
                        pendiente
                            ? 'Los miembros se verán cuando te aprueben.'
                            : unida
                                ? 'Sin miembros aprobados aún.'
                                : 'Unite para ver a los miembros.',
                        style: TipografiaHaku.interfaz(
                          color: PaletaRutas.plomoClaro,
                        ),
                      )
                    else
                      for (final m in miembrosAsync.valueOrNull!)
                        _FilaMiembroRemoto(
                          miembro: m,
                          esCreador: m.usuarioId == c.creadorId,
                        ),
                  ] else if (miembrosLocal.isEmpty)
                    Text(
                      'Aún no hay miembros visibles',
                      style: TipografiaHaku.interfaz(
                        color: PaletaRutas.plomoClaro,
                      ),
                    )
                  else
                    ...miembrosLocal.map((p) {
                      final admin = p.id == c.creadorId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: PaletaRutas.carbon,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                PaletaRutas.plomo.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            AvatarHaku(url: p.avatarUrl, size: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.nombre,
                                    style: TipografiaHaku.interfaz(
                                      fontWeight: FontWeight.w700,
                                      color: PaletaRutas.piedra,
                                    ),
                                  ),
                                  Text(
                                    admin
                                        ? '${p.usuario} · organizador'
                                        : p.usuario,
                                    style: TipografiaHaku.interfaz(
                                      fontSize: 12,
                                      color: PaletaRutas.plomoClaro,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaSolicitudPendiente extends StatelessWidget {
  const _FilaSolicitudPendiente({
    required this.miembro,
    required this.ocupado,
    required this.onAprobar,
    required this.onRechazar,
  });

  final MiembroComunidadRemoto miembro;
  final bool ocupado;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  @override
  Widget build(BuildContext context) {
    final foto = miembro.fotoPerfil?.trim() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: PaletaRutas.oro.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          AvatarHaku(
            url: foto.isEmpty ? null : foto,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              miembro.etiqueta,
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
              ),
            ),
          ),
          if (ocupado)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: PaletaRutas.oro,
              ),
            )
          else ...[
            IconButton(
              tooltip: 'Rechazar',
              onPressed: onRechazar,
              icon: const Icon(Icons.close_rounded, color: PaletaRutas.plomo),
            ),
            IconButton(
              tooltip: 'Aprobar',
              onPressed: onAprobar,
              icon: const Icon(Icons.check_rounded, color: PaletaRutas.oro),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaMiembroRemoto extends StatelessWidget {
  const _FilaMiembroRemoto({
    required this.miembro,
    required this.esCreador,
  });

  final MiembroComunidadRemoto miembro;
  final bool esCreador;

  @override
  Widget build(BuildContext context) {
    final foto = miembro.fotoPerfil?.trim() ?? '';
    final rolTxt = esCreador
        ? '${miembro.rol} · creador'
        : miembro.rol;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: PaletaRutas.plomo.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          AvatarHaku(
            url: foto.isEmpty ? null : foto,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  miembro.etiqueta,
                  style: TipografiaHaku.interfaz(
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.piedra,
                  ),
                ),
                Text(
                  rolTxt,
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    color: PaletaRutas.plomoClaro,
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
