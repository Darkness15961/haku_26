import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/widgets/avatar_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelo_comunidad.dart';
import '../proveedores/proveedor_comunidad.dart';
import 'pantalla_editar_comunidad.dart';

class PantallaConfiguracionComunidad extends ConsumerStatefulWidget {
  final ComunidadHaku comunidad;

  const PantallaConfiguracionComunidad({super.key, required this.comunidad});

  @override
  ConsumerState<PantallaConfiguracionComunidad> createState() =>
      _EstadoPantallaConfiguracionComunidad();
}

class _EstadoPantallaConfiguracionComunidad
    extends ConsumerState<PantallaConfiguracionComunidad> {
  String? _resolviendoUid;

  Future<void> _resolverSolicitud({
    required ComunidadHaku c,
    required String usuarioId,
    required bool aprobar,
  }) async {
    if (_resolviendoUid != null) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    if (!aprobar) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: PaletaRutas.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: PaletaRutas.oro.withValues(alpha: 0.3)),
          ),
          title: Text(
            'Rechazar solicitud',
            style: TipografiaHaku.titulo(
              color: PaletaRutas.piedra,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Esta persona tendrá que solicitar acceso nuevamente.',
            style: TipografiaHaku.interfaz(
              color: PaletaRutas.plomoClaro,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancelar',
                style: TipografiaHaku.interfaz(
                  color: PaletaRutas.plomo,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PaletaRutas.oro,
                foregroundColor: PaletaRutas.ink,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Rechazar',
                style: TipografiaHaku.interfaz(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;
    }

    setState(() => _resolviendoUid = usuarioId);
    try {
      await ref
          .read(comunidadRemotoDataSourceProvider)
          .resolverSolicitud(
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
    // Usamos el provider para tener la comunidad actualizada (si cambia algo, se refleja)
    final remotaAsync = ref.watch(
      comunidadDetalleProvider(widget.comunidad.id),
    );
    final c = remotaAsync.valueOrNull ?? widget.comunidad;

    final pendientesAsync = ref.watch(pendientesComunidadProvider(c.id));

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        elevation: 0,
        title: Text(
          'Configuraciones',
          style: TipografiaHaku.titulo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Información de la Comunidad',
                style: TipografiaHaku.titulo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.piedra,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PantallaEditarComunidad(comunidad: c),
                    ),
                  );
                },
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_rounded, color: PaletaRutas.oro),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PaletaRutas.carbon,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PaletaRutas.plomo.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre: ${c.nombre}',
                  style: TipografiaHaku.interfaz(
                    color: PaletaRutas.piedra,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Descripción: ${c.descripcion.isEmpty ? 'Ninguna' : c.descripcion}',
                  style: TipografiaHaku.interfaz(
                    color: PaletaRutas.plomoClaro,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Visibilidad: ${c.tipo == 'privado' ? 'Privada 🔒' : 'Pública 🌍'}',
                  style: TipografiaHaku.interfaz(
                    color: PaletaRutas.plomoClaro,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Privacidad y Acceso',
            style: TipografiaHaku.titulo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: PaletaRutas.piedra,
            ),
          ),
          const SizedBox(height: 12),
          _SeccionAdminComunidad(comunidad: c, ref: ref),

          if (c.tipo == 'privado') ...[
            const SizedBox(height: 32),
            Text(
              'Solicitudes de Ingreso',
              style: TipografiaHaku.titulo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
              ),
            ),
            const SizedBox(height: 12),
            if (pendientesAsync.isLoading && !pendientesAsync.hasValue)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    color: PaletaRutas.oro,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (pendientesAsync.hasError && !pendientesAsync.hasValue)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'No pudimos cargar las solicitudes.',
                      style: TipografiaHaku.interfaz(
                        color: PaletaRutas.oroSuave,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(pendientesComunidadProvider(c.id)),
                    child: const Text('Reintentar'),
                  ),
                ],
              )
            else if ((pendientesAsync.valueOrNull ?? const []).isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PaletaRutas.carbon,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: PaletaRutas.plomo.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'No hay solicitudes pendientes en este momento.',
                  style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
                  textAlign: TextAlign.center,
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
          ],

          const SizedBox(height: 32),
          Text(
            'Zona de Peligro',
            style: TipografiaHaku.titulo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD32F2F).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Eliminar comunidad',
                  style: TipografiaHaku.interfaz(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD32F2F),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Al eliminar la comunidad, se borrarán permanentemente todos los miembros, publicaciones y el chat grupal.',
                  style: TipografiaHaku.interfaz(
                    color: const Color(0xFFD32F2F).withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                _BotonEliminarComunidad(comunidad: c, ref: ref),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _BotonEliminarComunidad extends StatefulWidget {
  final ComunidadHaku comunidad;
  final WidgetRef ref;

  const _BotonEliminarComunidad({required this.comunidad, required this.ref});

  @override
  State<_BotonEliminarComunidad> createState() =>
      _BotonEliminarComunidadState();
}

class _BotonEliminarComunidadState extends State<_BotonEliminarComunidad> {
  bool _eliminando = false;

  Future<void> _intentarEliminar() async {
    if (_eliminando) return;

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DialogoConfirmarEliminar(
        nombreComunidad: widget.comunidad.nombre,
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _eliminando = true);
    try {
      await widget.ref
          .read(comunidadRemotoDataSourceProvider)
          .eliminarComunidad(widget.comunidad.id);

      notificarComunidadesCambiaron(widget.ref);

      if (mounted) {
        mostrarSnackHaku(
          context,
          'Comunidad eliminada con éxito.',
          destacado: true,
        );
        final nav = Navigator.of(context);
        nav.pop();
        nav.pop();
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackHaku(context, 'Ocurrió un error al eliminar la comunidad.');
      }
    } finally {
      if (mounted) setState(() => _eliminando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_eliminando) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD32F2F),
            strokeWidth: 2,
          ),
        ),
      );
    }
    return FilledButton(
      onPressed: _intentarEliminar,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: PaletaRutas.ink,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        'Eliminar comunidad',
        style: TipografiaHaku.interfaz(
          fontWeight: FontWeight.w800,
          color: PaletaRutas.ink,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Componentes extraídos de pantalla_detalle_comunidad.dart
// ---------------------------------------------------------------------------

class _SeccionAdminComunidad extends StatefulWidget {
  final ComunidadHaku comunidad;
  final WidgetRef ref;

  const _SeccionAdminComunidad({required this.comunidad, required this.ref});

  @override
  State<_SeccionAdminComunidad> createState() => _SeccionAdminComunidadState();
}

class _SeccionAdminComunidadState extends State<_SeccionAdminComunidad> {
  bool _cambiando = false;

  Future<void> _toggleInscripciones() async {
    if (_cambiando) return;

    final abierta = widget.comunidad.inscripcionAbierta;
    final accion = abierta ? 'Cerrar inscripciones' : 'Abrir inscripciones';
    final mensaje = abierta
        ? 'Nadie más podrá unirse a la comunidad (incluso si tienen el enlace) hasta que vuelvas a abrir las puertas.'
        : 'Cualquier persona podrá volver a unirse o mandar solicitud.';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PaletaRutas.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: PaletaRutas.oro.withValues(alpha: 0.3)),
        ),
        title: Text(
          accion,
          style: TipografiaHaku.titulo(color: PaletaRutas.piedra, fontSize: 18),
        ),
        content: Text(
          mensaje,
          style: TipografiaHaku.interfaz(
            color: PaletaRutas.plomoClaro,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: TipografiaHaku.interfaz(
                color: PaletaRutas.plomo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PaletaRutas.oro,
              foregroundColor: PaletaRutas.ink,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Confirmar',
              style: TipografiaHaku.interfaz(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _cambiando = true);
    try {
      await widget.ref
          .read(comunidadRemotoDataSourceProvider)
          .cambiarEstadoInscripcion(widget.comunidad.id, !abierta);
      notificarComunidadesCambiaron(widget.ref);
      if (mounted) {
        mostrarSnackHaku(
          context,
          !abierta ? 'Inscripciones abiertas' : 'Inscripciones cerradas',
          destacado: true,
        );
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackHaku(context, 'Error al cambiar estado de inscripción');
      }
    } finally {
      if (mounted) setState(() => _cambiando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletaRutas.oro.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, size: 24, color: PaletaRutas.oro),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de Inscripciones',
                  style: TipografiaHaku.interfaz(
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.piedra,
                    fontSize: 15,
                  ),
                ),
                Text(
                  widget.comunidad.inscripcionAbierta
                      ? 'Se aceptan ingresos'
                      : 'Ingresos bloqueados',
                  style: TipografiaHaku.interfaz(
                    color: PaletaRutas.plomoClaro,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_cambiando)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: PaletaRutas.oro,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              tooltip: widget.comunidad.inscripcionAbierta
                  ? 'Cerrar inscripciones'
                  : 'Abrir inscripciones',
              onPressed: _toggleInscripciones,
              icon: Icon(
                widget.comunidad.inscripcionAbierta
                    ? Icons.lock_open_rounded
                    : Icons.lock_rounded,
                color: widget.comunidad.inscripcionAbierta
                    ? const Color(0xFF4CAF50) // Verde
                    : const Color(0xFFD32F2F), // Rojo
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
        border: Border.all(color: PaletaRutas.oro.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          AvatarHaku(url: foto.isEmpty ? null : foto, size: 44),
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

class _DialogoConfirmarEliminar extends StatefulWidget {
  final String nombreComunidad;
  const _DialogoConfirmarEliminar({required this.nombreComunidad});

  @override
  State<_DialogoConfirmarEliminar> createState() =>
      _DialogoConfirmarEliminarState();
}

class _DialogoConfirmarEliminarState extends State<_DialogoConfirmarEliminar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texto = _controller.text.trim();
    final coincide = texto == widget.nombreComunidad;

    return AlertDialog(
      backgroundColor: PaletaRutas.ink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFFD32F2F).withValues(alpha: 0.4),
        ),
      ),
      title: Text(
        '¿Eliminar comunidad?',
        style: TipografiaHaku.titulo(
          color: const Color(0xFFD32F2F),
          fontSize: 18,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Esta acción es irreversible.',
            style: TipografiaHaku.interfaz(
              color: PaletaRutas.plomoClaro,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Escribe el nombre para confirmar:\n${widget.nombreComunidad}',
            style: TipografiaHaku.interfaz(
              color: PaletaRutas.piedra,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
            cursorColor: const Color(0xFFD32F2F),
            decoration: InputDecoration(
              hintText: 'Nombre de la comunidad',
              hintStyle: TipografiaHaku.interfaz(
                color: PaletaRutas.plomo,
              ),
              filled: true,
              fillColor: PaletaRutas.carbon,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: PaletaRutas.plomo.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD32F2F)),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancelar',
            style: TipografiaHaku.interfaz(
              color: PaletaRutas.plomo,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                coincide ? const Color(0xFFD32F2F) : PaletaRutas.carbon,
            foregroundColor: PaletaRutas.ink,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: coincide ? () => Navigator.of(context).pop(true) : null,
          child: Text(
            'Eliminar para siempre',
            style: TipografiaHaku.interfaz(
              fontWeight: FontWeight.w700,
              color: coincide ? PaletaRutas.ink : PaletaRutas.plomo,
            ),
          ),
        ),
      ],
    );
  }
}
