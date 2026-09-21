import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/widgets/imagen_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../chat/indice.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/pantallas/pantalla_detalle_ruta.dart';
import '../../rutas/widgets/boton_fondo_textil.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../../lugares/navegacion_lugar.dart';
import '../dominio/modelo_salida.dart';
import '../pantallas/pantalla_detalle_comunidad.dart';
import '../pantallas/pantalla_configuracion_salida.dart';
import '../proveedores/proveedor_salidas.dart';

class PantallaDetalleSalidaRemota extends ConsumerStatefulWidget {
  const PantallaDetalleSalidaRemota({super.key, required this.salidaId});

  final String salidaId;

  @override
  ConsumerState<PantallaDetalleSalidaRemota> createState() =>
      _EstadoPantallaDetalleSalidaRemota();
}

class _EstadoPantallaDetalleSalidaRemota
    extends ConsumerState<PantallaDetalleSalidaRemota> {
  bool _accionando = false;

  String _estadoLegible(String estado) => switch (estado) {
    'programada' => 'Programada',
    'en_curso' => 'En curso',
    'finalizada' => 'Finalizada',
    'cancelada' => 'Cancelada',
    _ => estado,
  };

  Future<void> _toggleInscripcion(ModeloSalidaRemota s) async {
    if (_accionando) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    final uid = ref.read(sesionProvider).usuario?.id ?? '';
    if (uid.isEmpty) return;

    if (s.inscrito(uid)) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: PaletaRutas.carbon,
          title: const Text('Cancelar inscripción'),
          content: const Text(
            'Tu lugar volverá a quedar disponible para otro explorador.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cancelar inscripción'),
            ),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;
    } else {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: PaletaRutas.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: PaletaRutas.oro.withValues(alpha: 0.3)),
          ),
          title: Text(
            'Reglas de la Salida',
            style: TipografiaHaku.titulo(
              fontSize: 18,
              color: PaletaRutas.piedra,
            ),
          ),
          content: Text(
            'Para unirte a esta salida debes comprometerte a respetar las normas de la comunidad, cuidar la naturaleza y mantener un comportamiento respetuoso con todos los exploradores. ¿Aceptas estas reglas?',
            style: TipografiaHaku.interfaz(
              fontSize: 14,
              color: PaletaRutas.plomoClaro,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: PaletaRutas.oro),
              child: const Text(
                'Acepto',
                style: TextStyle(color: PaletaRutas.ink, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;
    }

    setState(() => _accionando = true);
    try {
      final ds = ref.read(salidaRemotoDataSourceProvider);
      if (s.inscrito(uid)) {
        await ds.cancelarInscripcion(s.id);
      } else {
        await ds.inscribirse(s.id);
      }
      notificarSalidasCambiaron(ref);
    } on AuthException catch (e) {
      if (mounted) mostrarSnackHaku(context, e.message);
    } catch (_) {
      if (mounted) {
        mostrarSnackHaku(context, 'No se pudo actualizar la inscripción');
      }
    } finally {
      if (mounted) setState(() => _accionando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(salidaDetalleProvider(widget.salidaId));
    final uid = ref.watch(sesionProvider).usuario?.id ?? '';
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    final ancho = MediaQuery.sizeOf(context).width;
    final horizontal = ancho > 752 ? (ancho - 720) / 2 : 16.0;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        elevation: 0,
        title: Text(
          'Salida',
          style: TipografiaHaku.titulo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
        actions: [
          async.maybeWhen(
            data: (s) {
              if (s == null) return const SizedBox.shrink();
              final puedeChat = s.organizadorId == uid || s.inscrito(uid);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (puedeChat)
                    IconButton(
                      tooltip: 'Chat de la salida',
                      onPressed: () {
                        abrirChatSalida(
                          context,
                          ref,
                          salidaId: s.id,
                          titulo: s.titulo,
                        );
                      },
                      icon: const Icon(Icons.forum_outlined),
                    ),
                  if (s.organizadorId == uid)
                    IconButton(
                      tooltip: 'Configuración',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PantallaConfiguracionSalida(salida: s),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_outlined),
                    ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: PaletaRutas.oro),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 38,
                color: PaletaRutas.plomo,
              ),
              const SizedBox(height: 10),
              Text(
                'No pudimos cargar la salida.',
                style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(salidaDetalleProvider(widget.salidaId)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (s) {
          if (s == null) {
            return Center(
              child: Text(
                'Salida no encontrada',
                style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
              ),
            );
          }
          final foto = s.lugarFotoPortada?.trim() ?? '';
          final inscrito = s.inscrito(uid);
          final esOrganizador = s.organizadorId == uid;
          final puedeInscribir = s.estado == 'programada' &&
              (inscrito || (s.inscripcionAbierta && !s.llena));

          return ListView(
            padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, bottom),
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: foto.isEmpty
                      ? ColoredBox(
                          color: PaletaRutas.carbon,
                          child: Center(
                            child: Icon(
                              Icons.hiking,
                              size: 40,
                              color: PaletaRutas.plomo.withValues(alpha: 0.85),
                            ),
                          ),
                        )
                      : ImagenHaku(url: foto, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                s.titulo,
                style: TipografiaHaku.titulo(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: PaletaRutas.piedra,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.fechaHoraEtiqueta,
                style: TipografiaHaku.interfaz(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.piedra,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 17,
                    color: PaletaRutas.oro,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.puntoEncuentroEtiqueta,
                      style: TipografiaHaku.interfaz(
                        fontSize: 13,
                        color: PaletaRutas.plomoClaro,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ChipDatoSalida(
                    icono: s.tipo == 'comunidad'
                        ? Icons.groups_outlined
                        : Icons.public_rounded,
                    texto: s.tipo == 'comunidad' ? 'De comunidad' : 'Pública',
                  ),
                  _ChipDatoSalida(
                    icono: Icons.event_available_outlined,
                    texto: _estadoLegible(s.estado),
                  ),
                ],
              ),
              if (s.comunidadNombre != null &&
                  s.comunidadNombre!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    final cid = s.comunidadId?.trim() ?? '';
                    if (cid.isEmpty || int.tryParse(cid) == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            PantallaDetalleComunidad(comunidadId: cid),
                      ),
                    );
                  },
                  child: Text(
                    'Comunidad: ${s.comunidadNombre}',
                    style:
                        TipografiaHaku.interfaz(
                          fontSize: 13,
                          color: PaletaRutas.oro,
                          fontWeight: FontWeight.w700,
                        ).copyWith(
                          decoration:
                              (s.comunidadId != null &&
                                  int.tryParse(s.comunidadId!.trim()) != null)
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationColor: PaletaRutas.oro,
                        ),
                  ),
                ),
              ],
              if (s.organizadorNick.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Organiza: ${s.organizadorNick}',
                  style: TipografiaHaku.interfaz(
                    fontSize: 13,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
              ],
              if (s.lugarId != null &&
                  s.lugarId!.trim().isNotEmpty &&
                  int.tryParse(s.lugarId!.trim()) != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => abrirDetalleLugar(context, s.lugarId!),
                  icon: const Icon(Icons.place_outlined, size: 18),
                  label: Text(
                    'Ver lugar',
                    style: TipografiaHaku.interfaz(
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.oro,
                    ),
                  ),
                ),
              ],
              if (s.rutaId != null &&
                  s.rutaId!.trim().isNotEmpty &&
                  s.rutaNombre?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PantallaDetalleRuta(
                        ruta: ModeloRuta(
                          id: s.rutaId!,
                          titulo: s.rutaNombre!,
                          subtitulo: s.rutaResumen ?? '',
                          descripcion: '',
                          imagenUrl: '',
                          categoria: CategoriaRuta.recomendadas,
                        ),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.route_outlined),
                  label: Text(
                    'Ruta: ${s.rutaNombre}',
                    overflow: TextOverflow.ellipsis,
                    style: TipografiaHaku.interfaz(
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.oro,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Cupos: ${s.inscritos}/${s.cuposTotales} · mínimo ${s.minimoParaSalir}',
                style: TipografiaHaku.interfaz(
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.piedra,
                ),
              ),
              if (s.notasGrupales != null &&
                  s.notasGrupales!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                const LineaEncabezadoInca(altura: 2),
                const SizedBox(height: 10),
                Text(
                  'Mensaje del organizador',
                  style: TipografiaHaku.titulo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.piedra,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.notasGrupales!,
                  style: TipografiaHaku.interfaz(
                    color: PaletaRutas.plomoClaro,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (esOrganizador)
                _ChipDatoSalida(
                  icono: Icons.verified_outlined,
                  texto: 'Organizas esta salida',
                )
              else if (puedeInscribir)
                BotonFondoTextil(
                  texto: _accionando
                      ? '…'
                      : (inscrito ? 'Cancelar inscripción' : 'Inscribirme'),
                  icono: inscrito
                      ? Icons.check_rounded
                      : Icons.person_add_alt_1_outlined,
                  altura: 44,
                  radius: 12,
                  onPressed: _accionando ? null : () => _toggleInscripcion(s),
                )
              else
                Text(
                  s.llena && !inscrito
                      ? 'Sin cupos disponibles.'
                      : (!s.inscripcionAbierta && !inscrito)
                          ? 'Las inscripciones están cerradas.'
                          : 'Inscripción no disponible (${s.estado}).',
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ChipDatoSalida extends StatelessWidget {
  const _ChipDatoSalida({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PaletaRutas.plomo.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: PaletaRutas.oro),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TipografiaHaku.interfaz(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: PaletaRutas.piedra,
            ),
          ),
        ],
      ),
    );
  }
}
