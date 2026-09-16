import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/widgets/avatar_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../comunidad/dominio/modelo_comunidad.dart';
import '../../comunidad/proveedores/proveedor_comunidad.dart';
import '../../comunidad/proveedores/proveedor_salidas.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../dominio/modelo_mensaje_chat.dart';
import '../proveedores/proveedor_chat.dart';
import 'pantalla_perfil_participante_chat.dart';

/// Lista / gestión de quién está en el chat (comunidad o salida).
///
/// [modoCreacion]: no hay sala todavía. Atrás = cancelar (no crea).
/// «Crear chat» recién llama al RPC + roster.
class PantallaGestionParticipantesChat extends ConsumerStatefulWidget {
  const PantallaGestionParticipantesChat({
    super.key,
    this.salaId = '',
    this.comunidadId,
    this.salidaId,
    this.titulo,
    this.puedeEditar = false,
    this.modoCreacion = false,
  });

  final String salaId;
  final String? comunidadId;
  final String? salidaId;
  final String? titulo;
  final bool puedeEditar;

  /// Si true: el chat aún no existe; se crea solo al confirmar.
  final bool modoCreacion;

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

  bool get _esSalida =>
      (widget.salidaId?.trim().isNotEmpty ?? false) &&
      (widget.comunidadId == null || widget.comunidadId!.trim().isEmpty);

  bool get _creando => widget.modoCreacion;

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
      final uid = ref.read(sesionProvider).usuario?.id ?? '';
      final salaParaRoster = _creando ? '' : widget.salaId;
      List<ParticipanteSalaChat> roster;
      if (_esSalida) {
        final sid = widget.salidaId!.trim();
        final salida = await ref.read(salidaDetalleProvider(sid).future);
        if (salida == null) {
          throw StateError('salida');
        }
        roster = await ref
            .read(chatDataSourceProvider)
            .rosterSalidaParaPicker(
              salaId: salaParaRoster,
              organizadorId: salida.organizadorId,
              organizadorNick: salida.organizadorNick,
              confirmadoIds: salida.participanteIds,
            );
      } else {
        final cid = widget.comunidadId?.trim() ?? '';
        if (cid.isEmpty) throw StateError('comunidad');
        final miembros = await ref.read(miembrosComunidadProvider(cid).future);
        final aprobados = [...miembros.where((m) => m.estado == 'aprobado')];
        final comunidad = await ref.read(comunidadDetalleProvider(cid).future);
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
        roster = await ref
            .read(chatDataSourceProvider)
            .rosterComunidadParaPicker(
              salaId: salaParaRoster,
              miembrosAprobados: aprobados,
            );
      }

      final visibles = widget.puedeEditar || _creando
          ? roster
          : roster.where((e) => e.enChat).toList();

      if (!mounted) return;
      setState(() {
        _filas = visibles;
        _seleccion
          ..clear()
          ..addAll(
            _creando
                ? {if (uid.isNotEmpty) uid}
                : roster.where((e) => e.enChat).map((e) => e.usuarioId),
          );
        // Asegurar que el admin/org quede marcado en creación.
        if (_creando && uid.isNotEmpty) {
          _seleccion.add(uid);
        }
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
    if ((!widget.puedeEditar && !_creando) || _guardando) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;

    final uid = ref.read(sesionProvider).usuario?.id ?? '';
    if (_creando && uid.isNotEmpty) {
      _seleccion.add(uid);
    }

    setState(() => _guardando = true);
    try {
      final ds = ref.read(chatDataSourceProvider);

      if (_creando) {
        late final String salaId;
        if (_esSalida) {
          final sid = widget.salidaId!.trim();
          salaId = await ds.crearSalaSalidaConParticipantes(
            salidaId: sid,
            participantes: _seleccion.where((id) => id.isNotEmpty && id != uid),
          );
        } else {
          final cid = widget.comunidadId!.trim();
          salaId = await ds.crearSalaComunidadConParticipantes(
            comunidadId: cid,
            participantes: _seleccion.where((id) => id.isNotEmpty && id != uid),
          );
        }
        notificarChatCambio(ref);
        if (mounted) {
          mostrarSnackHaku(context, 'Chat creado');
          Navigator.of(context).pop(salaId);
        }
        return;
      }

      final enChatAlCargar = {
        for (final f in _filas)
          if (f.enChat) f.usuarioId,
      };
      final agregar = _seleccion.difference(enChatAlCargar).toList();
      final quitar = enChatAlCargar.difference(_seleccion).toList();
      quitar.removeWhere((id) => id == uid);

      if (agregar.isEmpty && quitar.isEmpty) {
        if (mounted) Navigator.of(context).pop(false);
        return;
      }

      if (_esSalida) {
        await ds.setParticipantesSalidaBatch(
          salaId: widget.salaId,
          agregar: agregar,
          quitar: quitar,
        );
      } else {
        await ds.setParticipantesComunidadBatch(
          salaId: widget.salaId,
          agregar: agregar,
          quitar: quitar,
        );
      }
      notificarChatCambio(ref);
      if (mounted) {
        mostrarSnackHaku(context, 'Chat actualizado');
        Navigator.of(context).pop(true);
      }
    } on AuthException catch (e) {
      if (mounted) mostrarSnackHaku(context, e.message);
    } catch (_) {
      if (mounted) {
        mostrarSnackHaku(
          context,
          _creando
              ? 'No se pudo crear el chat'
              : 'No se pudo guardar el roster',
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _abrirPerfil(ParticipanteSalaChat participante) async {
    final uid = ref.read(sesionProvider).usuario?.id ?? '';
    if (_creando ||
        participante.usuarioId.isEmpty ||
        participante.usuarioId == uid ||
        !participante.enChat) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaPerfilParticipanteChat(
          usuarioId: participante.usuarioId,
          salaOrigenId: widget.salaId,
          contextoCompartido: _esSalida ? 'esta salida' : 'esta comunidad',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(sesionProvider.select((s) => s.usuario?.id ?? ''));
    final editar = widget.puedeEditar || _creando;
    final titulo = (widget.titulo?.trim().isNotEmpty ?? false)
        ? widget.titulo!.trim()
        : (_creando
              ? 'Elegí quién entra'
              : (editar ? 'Miembros del chat' : 'Quién está en el chat'));

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
          if (editar)
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
                      _creando ? 'Crear chat' : 'Guardar',
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
              _creando
                  ? 'Marcá a quién incluir. El chat se crea solo cuando '
                        'pulses «Crear chat». Si volvés atrás, no se crea nada.'
                  : (editar
                        ? (_esSalida
                              ? 'Marcá quién puede escribir en este chat.\n'
                                    'Sacar a alguien no lo saca de la salida.'
                              : 'Marcá quién puede escribir en este chat.\n'
                                    'Sacar a alguien no lo saca de la comunidad.')
                        : 'Solo lectura: quién está en este chat grupal.'),
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
                editar
                    ? '${_seleccion.length} de ${_filas.length} seleccionados'
                    : '${_filas.length} en el chat',
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
                      editar
                          ? 'No hay personas para agregar todavía.'
                          : 'Todavía no hay nadie en el chat.',
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
                      color: PaletaRutas.plomoOscuro.withValues(alpha: 0.45),
                    ),
                    itemBuilder: (context, i) {
                      final f = _filas[i];
                      final soyYo = f.usuarioId == uid;
                      final checked = _seleccion.contains(f.usuarioId);
                      if (!editar) {
                        return ListTile(
                          leading: AvatarHaku(url: f.fotoPerfil, size: 40),
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
                              if (f.rolComunidad == 'admin')
                                (_esSalida ? 'Organizador' : 'Admin'),
                              'En el chat',
                            ].join(' · '),
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: PaletaRutas.oro,
                            ),
                          ),
                          trailing: soyYo
                              ? null
                              : const Icon(
                                  Icons.chevron_right_rounded,
                                  color: PaletaRutas.plomo,
                                ),
                          onTap: soyYo ? null : () => _abrirPerfil(f),
                        );
                      }
                      void cambiar(bool? valor) {
                        if (soyYo) return;
                        setState(() {
                          if (valor == true) {
                            _seleccion.add(f.usuarioId);
                          } else {
                            _seleccion.remove(f.usuarioId);
                          }
                        });
                      }

                      return ListTile(
                        onTap: !_creando && f.enChat && !soyYo
                            ? () => _abrirPerfil(f)
                            : (soyYo ? null : () => cambiar(!checked)),
                        leading: AvatarHaku(url: f.fotoPerfil, size: 40),
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
                            if (f.rolComunidad == 'admin')
                              (_esSalida ? 'Organizador' : 'Admin'),
                            checked
                                ? (_creando ? 'Se va a incluir' : 'En el chat')
                                : (_creando ? 'No incluido' : 'Fuera del chat'),
                          ].join(' · '),
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            color: checked
                                ? PaletaRutas.oro
                                : PaletaRutas.plomoClaro,
                          ),
                        ),
                        trailing: Checkbox(
                          value: checked,
                          onChanged: soyYo ? null : cambiar,
                          activeColor: PaletaRutas.oro,
                          checkColor: PaletaRutas.ink,
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
