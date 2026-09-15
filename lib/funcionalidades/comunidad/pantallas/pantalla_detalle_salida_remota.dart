import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/widgets/imagen_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../chat/indice.dart';
import '../../rutas/widgets/boton_fondo_textil.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../../lugares/navegacion_lugar.dart';
import '../dominio/modelo_salida.dart';
import '../pantallas/pantalla_detalle_comunidad.dart';
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

  Future<void> _toggleInscripcion(ModeloSalidaRemota s) async {
    if (_accionando) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    final uid = ref.read(sesionProvider).usuario?.id ?? '';
    if (uid.isEmpty) return;

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
              final puedeChat =
                  s.organizadorId == uid || s.inscrito(uid);
              if (!puedeChat) return const SizedBox.shrink();
              return IconButton(
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
          child: Text(
            'No se pudo cargar la salida.',
            style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
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
          final puedeInscribir =
              s.estado == 'programada' && (!s.llena || inscrito);

          return ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
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
                [
                  s.fechaHoraEtiqueta,
                  s.puntoEncuentroEtiqueta,
                  s.tipo,
                  s.estado,
                ].join(' · '),
                style: TipografiaHaku.interfaz(
                  fontSize: 13,
                  color: PaletaRutas.plomoClaro,
                ),
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
                    style: TipografiaHaku.interfaz(
                      fontSize: 13,
                      color: PaletaRutas.oro,
                      fontWeight: FontWeight.w700,
                    ).copyWith(
                      decoration: (s.comunidadId != null &&
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
                TextButton(
                  onPressed: () => abrirDetalleLugar(context, s.lugarId!),
                  child: Text(
                    'Ver ficha del lugar',
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
                  s.notasGrupales!,
                  style: TipografiaHaku.interfaz(
                    color: PaletaRutas.plomoClaro,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (puedeInscribir)
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
                      ? 'Sin cupos.'
                      : 'Inscripción no disponible (${s.estado}).',
                  textAlign: TextAlign.center,
                  style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
                ),
              const SizedBox(height: 12),
              Text(
                'Check-in GPS no está en el esquema actual.',
                textAlign: TextAlign.center,
                style: TipografiaHaku.interfaz(
                  fontSize: 12,
                  color: PaletaRutas.plomo,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
