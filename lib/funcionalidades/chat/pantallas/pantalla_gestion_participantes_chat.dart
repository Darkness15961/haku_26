import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/widgets/avatar_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../comunidad/dominio/modelo_comunidad.dart';
import '../../comunidad/proveedores/proveedor_comunidad.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../dominio/modelo_mensaje_chat.dart';
import '../proveedores/proveedor_chat.dart';

/// Admin: meter/sacar miembros del chat (no cambia membresía de comunidad).
class PantallaGestionParticipantesChat extends ConsumerStatefulWidget {
  const PantallaGestionParticipantesChat({
    super.key,
    required this.salaId,
    required this.comunidadId,
    this.titulo,
  });

  final String salaId;
  final String comunidadId;
  final String? titulo;

  @override
  ConsumerState<PantallaGestionParticipantesChat> createState() =>
      _EstadoGestionParticipantesChat();
}

class _EstadoGestionParticipantesChat
    extends ConsumerState<PantallaGestionParticipantesChat> {
  final _seleccion = <String>{};
  bool _cargando = true;
  bool _guardando = false;
  String? _error;
  List<ParticipanteSalaChat> _filas = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final miembros = await ref.read(
        miembrosComunidadProvider(widget.comunidadId).future,
      );
      final aprobados = [
        ...miembros.where((m) => m.estado == 'aprobado'),
      ];
      // Creador puede ser admin sin fila en comunidad_miembro: incluirlo.
      final comunidad =
          await ref.read(comunidadDetalleProvider(widget.comunidadId).future);
      final creadorId = comunidad?.creadorId.trim() ?? '';
      if (creadorId.isNotEmpty &&
          aprobados.every((m) => m.usuarioId != creadorId)) {
        aprobados.add(
          MiembroComunidadRemoto(
            usuarioId: creadorId,
            rol: 'admin',
            estado: 'aprobado',
            nombreNick: null,
            nombres: 'Creador',
          ),
        );
      }
      final roster =
          await ref.read(chatDataSourceProvider).rosterComunidadParaPicker(
                salaId: widget.salaId,
                miembrosAprobados: aprobados,
              );
      if (!mounted) return;
      setState(() {
        _filas = roster;
        _seleccion
          ..clear()
          ..addAll(roster.where((e) => e.enChat).map((e) => e.usuarioId));
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo cargar el roster del chat.';
      });
    }
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;

    final uid = ref.read(sesionProvider).usuario?.id ?? '';
    final iniciales = {
      for (final f in _filas)
        if (f.enChat) f.usuarioId,
    };
    final agregar = _seleccion.difference(iniciales).toList();
    final quitar = iniciales.difference(_seleccion).toList();
    // Nunca quitar al admin actual desde UI (RPC también lo bloquea).
    quitar.removeWhere((id) => id == uid);

    if (agregar.isEmpty && quitar.isEmpty) {
      if (mounted) Navigator.of(context).pop(false);
      return;
    }

    setState(() => _guardando = true);
    try {
      await ref.read(chatDataSourceProvider).setParticipantesComunidadBatch(
            salaId: widget.salaId,
            agregar: agregar,
            quitar: quitar,
          );
      notificarChatCambio(ref);
      if (mounted) {
        mostrarSnackHaku(context, 'Chat actualizado');
        Navigator.of(context).pop(true);
      }
    } on AuthException catch (e) {
      if (mounted) mostrarSnackHaku(context, e.message);
    } catch (_) {
      if (mounted) {
        mostrarSnackHaku(context, 'No se pudo guardar el roster');
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(sesionProvider.select((s) => s.usuario?.id ?? ''));
    final titulo = (widget.titulo?.trim().isNotEmpty ?? false)
        ? widget.titulo!.trim()
        : 'Miembros del chat';

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        elevation: 0,
        title: Text(
          titulo,
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _guardando || _cargando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PaletaRutas.oro,
                    ),
                  )
                : Text(
                    'Guardar',
                    style: TipografiaHaku.interfaz(
                      fontWeight: FontWeight.w800,
                      color: PaletaRutas.oro,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LineaEncabezadoInca(altura: 2),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Marcá quién puede escribir en este chat.\n'
              'Sacar a alguien del chat no lo saca de la comunidad.',
              style: TipografiaHaku.interfaz(
                fontSize: 13,
                color: PaletaRutas.plomoClaro,
                height: 1.4,
              ),
            ),
          ),
          if (!_cargando && _error == null && _filas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                '${_seleccion.length} de ${_filas.length} en el chat',
                style: TipografiaHaku.interfaz(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.oro,
                ),
              ),
            ),
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(color: PaletaRutas.oro),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TipografiaHaku.interfaz(
                                  color: PaletaRutas.plomoClaro,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _cargar,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filas.isEmpty
                        ? Center(
                            child: Text(
                              'No hay miembros aprobados todavía.',
                              style: TipografiaHaku.interfaz(
                                color: PaletaRutas.plomoClaro,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                            itemCount: _filas.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: PaletaRutas.plomoOscuro.withValues(
                                alpha: 0.45,
                              ),
                            ),
                            itemBuilder: (context, i) {
                              final f = _filas[i];
                              final soyYo = f.usuarioId == uid;
                              final checked = _seleccion.contains(f.usuarioId);
                              return CheckboxListTile(
                                value: checked,
                                onChanged: soyYo
                                    ? null
                                    : (v) {
                                        setState(() {
                                          if (v == true) {
                                            _seleccion.add(f.usuarioId);
                                          } else {
                                            _seleccion.remove(f.usuarioId);
                                          }
                                        });
                                      },
                                activeColor: PaletaRutas.oro,
                                checkColor: PaletaRutas.ink,
                                secondary: AvatarHaku(
                                  url: f.fotoPerfil,
                                  size: 40,
                                ),
                                title: Text(
                                  soyYo ? '${f.etiqueta} (vos)' : f.etiqueta,
                                  style: TipografiaHaku.interfaz(
                                    fontWeight: FontWeight.w700,
                                    color: PaletaRutas.piedra,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    if (soyYo) 'Vos',
                                    if (f.rolComunidad == 'admin') 'Admin',
                                    checked ? 'En el chat' : 'Fuera del chat',
                                  ].join(' · '),
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 12,
                                    color: checked
                                        ? PaletaRutas.oro
                                        : PaletaRutas.plomoClaro,
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
