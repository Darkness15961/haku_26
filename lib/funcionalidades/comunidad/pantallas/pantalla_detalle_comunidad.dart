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
import '../dominio/modelo_publicacion.dart';
import '../proveedores/proveedor_comunidad.dart';
import '../proveedores/proveedor_publicaciones.dart';
import '../widgets/chip_categoria_comunidad.dart';
import '../widgets/tarjeta_publicacion_remota.dart';
import '../../chat/indice.dart';
import '../../lugares/widgets/lista_experiencias_lugar.dart';
import 'pantalla_salidas.dart';
import 'pantalla_configuracion_comunidad.dart';

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

  Future<bool> _confirmarAccion({
    required String titulo,
    required String mensaje,
    required String confirmar,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PaletaRutas.carbon,
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmar),
          ),
        ],
      ),
    );
    return resultado == true;
  }

  Future<void> _unirseOSalir(ComunidadHaku c) async {
    if (_accionando) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    final uid = ref.read(sesionProvider).usuario?.id ?? '';
    if (uid.isEmpty) return;

    if (c.esMiembro(uid) || c.solicitudPendiente(uid)) {
      final pendiente = c.solicitudPendiente(uid);
      final confirmado = await _confirmarAccion(
        titulo: pendiente ? 'Cancelar solicitud' : 'Salir de la comunidad',
        mensaje: pendiente
            ? 'Tu solicitud dejará de estar pendiente.'
            : 'Dejarás de ver el contenido reservado para miembros.',
        confirmar: pendiente ? 'Cancelar solicitud' : 'Salir',
      );
      if (!confirmado || !mounted) return;
    }

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
        if (c.esPrivada) {
          final confirmado = await _confirmarAccion(
            titulo: 'Solicitar unirse',
            mensaje:
                'Esta comunidad es privada. Para poder unirte se enviará una solicitud y deberás esperar a que el administrador la apruebe.',
            confirmar: 'Enviar solicitud',
          );
          if (!confirmado || !mounted) {
            if (mounted) setState(() => _accionando = false);
            return;
          }
        } else {
          final confirmado = await _confirmarAccion(
            titulo: 'Normas de la Comunidad',
            mensaje:
                'Al unirte a esta comunidad, aceptas mantener el respeto hacia los demás miembros y cumplir con las normas de convivencia.',
            confirmar: 'Aceptar y unirme',
          );
          if (!confirmado || !mounted) {
            if (mounted) setState(() => _accionando = false);
            return;
          }
        }
        
        await ds.unirse(c.id, conocida: c);
        notificarComunidadesCambiaron(ref);
        
        if (mounted && c.esPrivada) {
          mostrarSnackHaku(context, 'Solicitud enviada exitosamente', destacado: true);
        }
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

  @override
  Widget build(BuildContext context) {
    final remotaAsync = ref.watch(comunidadDetalleProvider(widget.comunidadId));
    final miembrosAsync = ref.watch(
      miembrosComunidadProvider(widget.comunidadId),
    );
    final pendientesAsync = ref.watch(
      pendientesComunidadProvider(widget.comunidadId),
    );
    final publicacionesAsync = ref.watch(
      publicacionesPorComunidadProvider(widget.comunidadId),
    );
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
          ? 'No se pudo cargar la comunidad.\nRevisa tu conexión o acceso.'
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
                ),
                if (remotaAsync.hasError) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(
                      comunidadDetalleProvider(widget.comunidadId),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ],
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
    final soyCreador = c.creadorId == uid;
    final miembrosLocal = [
      for (final id in c.miembroIds)
        if (store.perfilPorId(id) != null) store.perfilPorId(id)!,
    ];
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    final ancho = MediaQuery.sizeOf(context).width;
    final horizontal = ancho > 752 ? (ancho - 720) / 2 : 16.0;
    final meta = [
      '${c.miembros} miembros',
      if (c.esPrivada) 'privada' else 'pública',
      if (!c.remoto && c.provincia.isNotEmpty) c.provincia,
    ].join(' · ');

    String textoBotonRemoto() {
      if (unida) return 'Salir de la comunidad';
      if (pendiente) return 'Cancelar solicitud';
      if (!c.inscripcionAbierta) return 'Inscripciones cerradas';
      return 'Unirme';
    }

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: PaletaRutas.ink,
            iconTheme: const IconThemeData(color: PaletaRutas.piedra),
            elevation: 0,
            actions: [
              IconButton(
                tooltip: 'Salidas de la comunidad',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PantallaSalidas(
                        comunidadId: c.id,
                        comunidadTitulo: c.nombre,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.hiking),
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
                  icon: const Icon(Icons.forum_outlined),
                ),
              if (c.remoto && soyAdmin) ...[
                if (c.tipo == 'privado' &&
                    (pendientesAsync.valueOrNull?.isNotEmpty ?? false))
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Solicitudes pendientes',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  PantallaConfiguracionComunidad(comunidad: c),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD32F2F),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                IconButton(
                  tooltip: 'Configuración',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            PantallaConfiguracionComunidad(comunidad: c),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
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
                    ImagenHaku(url: c.imagenUrl, fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          PaletaRutas.ink.withValues(alpha: 0.65),
                          Colors.transparent,
                          PaletaRutas.ink,
                        ],
                        stops: const [0.0, 0.6, 1.0],
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
                              soyCreador
                                  ? 'Administrador'
                                  : (unida ? 'Miembro' : 'Pendiente'),
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
              padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, bottom),
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
                        : (unida ? 'Salir de la comunidad' : 'Unirme'),
                    icono: pendiente
                        ? Icons.pending_actions_outlined
                        : (unida
                              ? Icons.logout_rounded
                              : (!c.inscripcionAbierta && c.remoto
                                    ? Icons.lock_outline
                                    : Icons.group_add_outlined)),
                    altura: 44,
                    radius: 12,
                    onPressed:
                        (_accionando ||
                            (c.remoto &&
                                !unida &&
                                !pendiente &&
                                !c.inscripcionAbierta))
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
                  if (c.remoto && (!c.esPrivada || unida)) ...[
                    Text(
                      'Publicaciones',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (publicacionesAsync.isLoading &&
                        !publicacionesAsync.hasValue)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: PaletaRutas.oro,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else if (publicacionesAsync.hasError &&
                        !publicacionesAsync.hasValue)
                      _ErrorSeccion(
                        texto: 'No pudimos cargar las publicaciones.',
                        onReintentar: () => ref.invalidate(
                          publicacionesPorComunidadProvider(widget.comunidadId),
                        ),
                      )
                    else if ((publicacionesAsync.valueOrNull ?? const [])
                        .isEmpty)
                      Text(
                        'Todavía no hay publicaciones en esta comunidad.',
                        style: TipografiaHaku.interfaz(
                          color: PaletaRutas.plomoClaro,
                        ),
                      )
                    else
                      _GaleriaPublicacionesComunidad(
                        publicaciones: publicacionesAsync.valueOrNull!,
                      ),
                    const SizedBox(height: 8),
                    const LineaEncabezadoInca(altura: 2),
                    const SizedBox(height: 14),
                    const LineaEncabezadoInca(altura: 2),
                    const SizedBox(height: 14),
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
                    else if (miembrosAsync.hasError && !miembrosAsync.hasValue)
                      _ErrorSeccion(
                        texto: 'No pudimos cargar los miembros.',
                        onReintentar: () => ref.invalidate(
                          miembrosComunidadProvider(widget.comunidadId),
                        ),
                      )
                    else if ((miembrosAsync.valueOrNull ?? const []).isEmpty)
                      Text(
                        pendiente
                            ? 'Los miembros se verán cuando te aprueben.'
                            : unida
                            ? 'Sin miembros aprobados aún.'
                            : 'Únete para ver a los miembros.',
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
                            color: PaletaRutas.plomo.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            AvatarHaku(url: p.avatarUrl, size: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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

class _ErrorSeccion extends StatelessWidget {
  const _ErrorSeccion({required this.texto, required this.onReintentar});

  final String texto;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            texto,
            style: TipografiaHaku.interfaz(color: PaletaRutas.oroSuave),
          ),
        ),
        TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
      ],
    );
  }
}

class _FilaMiembroRemoto extends StatelessWidget {
  const _FilaMiembroRemoto({required this.miembro, required this.esCreador});

  final MiembroComunidadRemoto miembro;
  final bool esCreador;

  @override
  Widget build(BuildContext context) {
    final foto = miembro.fotoPerfil?.trim() ?? '';
    final rolTxt = esCreador ? '${miembro.rol} · creador' : miembro.rol;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PaletaRutas.plomo.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          AvatarHaku(url: foto.isEmpty ? null : foto, size: 44),
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

class _GaleriaPublicacionesComunidad extends StatelessWidget {
  final List<ModeloPublicacionRemota> publicaciones;

  const _GaleriaPublicacionesComunidad({required this.publicaciones});

  void _abrirFeedCompleto(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PaletaRutas.ink,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.9,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Publicaciones',
                        style: TipografiaHaku.titulo(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: PaletaRutas.plomo,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: LineaEncabezadoInca(altura: 2),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: publicaciones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    return TarjetaPublicacionRemota(
                      publicacion: publicaciones[i],
                      compacta: false,
                      habilitarComunidad: false,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tomar las primeras 3 para la previsualización
    final top3 = publicaciones.take(3).toList();
    final extras = publicaciones.length > 3 ? publicaciones.length - 3 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < top3.length; i++)
          TarjetaExperienciaLugarRemota(
            publicacion: top3[i],
            onTap: () => _abrirFeedCompleto(context),
          ),
        if (extras > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InkWell(
              onTap: () => _abrirFeedCompleto(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ver $extras publicaciones más',
                      style: TipografiaHaku.interfaz(
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.oro,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: PaletaRutas.oro,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
