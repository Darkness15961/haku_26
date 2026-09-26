import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/widgets/avatar_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelo_salida.dart';
import '../proveedores/proveedor_salidas.dart';

class PantallaConfiguracionSalida extends ConsumerStatefulWidget {
  final ModeloSalidaRemota salida;

  const PantallaConfiguracionSalida({super.key, required this.salida});

  @override
  ConsumerState<PantallaConfiguracionSalida> createState() =>
      _EstadoPantallaConfiguracionSalida();
}

class _EstadoPantallaConfiguracionSalida
    extends ConsumerState<PantallaConfiguracionSalida> {
  bool _cambiandoInscripcion = false;
  bool _cambiandoEstado = false;
  bool _guardandoEdicion = false;

  late final TextEditingController _titulo;
  late final TextEditingController _cupos;
  late final TextEditingController _minimo;
  late final TextEditingController _notas;
  late DateTime _fechaHora;

  @override
  void initState() {
    super.initState();
    final s = widget.salida;
    _titulo = TextEditingController(text: s.titulo);
    _cupos = TextEditingController(text: '${s.cuposTotales}');
    _minimo = TextEditingController(text: '${s.minimoParaSalir}');
    _notas = TextEditingController(text: s.notasGrupales ?? '');
    _fechaHora = s.fechaHoraInicio;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _cupos.dispose();
    _minimo.dispose();
    _notas.dispose();
    super.dispose();
  }

  bool _esEditable(ModeloSalidaRemota s) =>
      s.estado == 'programada' || s.estado == 'en_curso';

  Future<void> _toggleInscripcion(ModeloSalidaRemota s) async {
    if (_cambiandoInscripcion || !_esEditable(s)) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;

    final nuevoEstado = !s.inscripcionAbierta;
    if (!nuevoEstado) {
      final confirmar = await _confirmar(
        titulo: 'Cerrar inscripciones',
        cuerpo: 'Nadie más podrá unirse a la salida.',
        accion: 'Sí, cerrar',
      );
      if (confirmar != true || !mounted) return;
    }

    setState(() => _cambiandoInscripcion = true);
    try {
      await ref
          .read(salidaRemotoDataSourceProvider)
          .cambiarEstadoInscripcionSalida(s.id, nuevoEstado);
      notificarSalidasCambiaron(ref);
      if (mounted) {
        mostrarSnackHaku(
          context,
          nuevoEstado ? 'Inscripciones abiertas' : 'Inscripciones cerradas',
          destacado: true,
        );
      }
    } catch (_) {
      if (mounted) {
        mostrarSnackHaku(context, 'No se pudo actualizar la inscripción');
      }
    } finally {
      if (mounted) setState(() => _cambiandoInscripcion = false);
    }
  }

  Future<void> _cambiarEstado(ModeloSalidaRemota s, String nuevo) async {
    if (_cambiandoEstado) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;

    final etiqueta = switch (nuevo) {
      'en_curso' => 'Marcar en curso',
      'finalizada' => 'Finalizar salida',
      'cancelada' => 'Cancelar salida',
      'programada' => 'Volver a programada',
      _ => 'Cambiar estado',
    };
    final cuerpo = switch (nuevo) {
      'cancelada' =>
        'La salida quedará cancelada. Quienes estaban inscritos lo verán así.',
      'finalizada' => 'Marca la salida como terminada.',
      'en_curso' => 'Indica que la salida ya empezó.',
      _ => '¿Confirmas el cambio de estado?',
    };

    final confirmar = await _confirmar(
      titulo: etiqueta,
      cuerpo: cuerpo,
      accion: 'Confirmar',
      peligro: nuevo == 'cancelada',
    );
    if (confirmar != true || !mounted) return;

    setState(() => _cambiandoEstado = true);
    try {
      await ref
          .read(salidaRemotoDataSourceProvider)
          .cambiarEstadoSalida(s.id, nuevo);
      notificarSalidasCambiaron(ref);
      if (mounted) {
        mostrarSnackHaku(context, 'Estado actualizado', destacado: true);
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackHaku(
          context,
          e.toString().replaceFirst('AuthException: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _cambiandoEstado = false);
    }
  }

  Future<void> _guardarEdicion(ModeloSalidaRemota s) async {
    if (_guardandoEdicion || !_esEditable(s)) return;
    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;

    final cupos = int.tryParse(_cupos.text.trim()) ?? 0;
    final minimo = int.tryParse(_minimo.text.trim()) ?? 0;

    setState(() => _guardandoEdicion = true);
    try {
      await ref.read(salidaRemotoDataSourceProvider).editarSalida(
            salidaId: s.id,
            titulo: _titulo.text,
            fechaHoraInicio: _fechaHora,
            cuposTotales: cupos,
            minimoParaSalir: minimo,
            notasGrupales: _notas.text,
          );
      notificarSalidasCambiaron(ref);
      if (mounted) {
        mostrarSnackHaku(context, 'Salida actualizada', destacado: true);
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackHaku(
          context,
          e.toString().replaceFirst('AuthException: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _guardandoEdicion = false);
    }
  }

  Future<void> _elegirFechaHora() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaHora,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (fecha == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fechaHora),
    );
    if (hora == null || !mounted) return;
    setState(() {
      _fechaHora = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<bool?> _confirmar({
    required String titulo,
    required String cuerpo,
    required String accion,
    bool peligro = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PaletaRutas.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: PaletaRutas.oro.withValues(alpha: 0.3)),
        ),
        title: Text(
          titulo,
          style: TipografiaHaku.titulo(
            color: PaletaRutas.piedra,
            fontSize: 18,
          ),
        ),
        content: Text(
          cuerpo,
          style: TipografiaHaku.interfaz(
            color: PaletaRutas.plomoClaro,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Volver',
              style: TipografiaHaku.interfaz(
                color: PaletaRutas.plomo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: peligro ? Colors.redAccent : PaletaRutas.oro,
              foregroundColor: peligro ? Colors.white : PaletaRutas.ink,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              accion,
              style: TipografiaHaku.interfaz(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
        filled: true,
        fillColor: PaletaRutas.ink,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: PaletaRutas.plomo.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: PaletaRutas.plomo.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PaletaRutas.oro),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final remotaAsync = ref.watch(salidaDetalleProvider(widget.salida.id));
    final s = remotaAsync.valueOrNull ?? widget.salida;
    final editable = _esEditable(s);
    final roster = s.participantes.isNotEmpty
        ? s.participantes
        : [
            for (final uid in s.participanteIds)
              ParticipanteSalidaRemoto(usuarioId: uid),
          ];

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        elevation: 0,
        title: Text(
          'Configurar salida',
          style: TipografiaHaku.titulo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Estado de la salida',
            style: TipografiaHaku.titulo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: PaletaRutas.piedra,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Actual: ${_etiquetaEstado(s.estado)}',
            style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (s.estado == 'programada') ...[
                _ChipAccion(
                  texto: 'En curso',
                  cargando: _cambiandoEstado,
                  onTap: () => _cambiarEstado(s, 'en_curso'),
                ),
                _ChipAccion(
                  texto: 'Cancelar',
                  peligro: true,
                  cargando: _cambiandoEstado,
                  onTap: () => _cambiarEstado(s, 'cancelada'),
                ),
              ],
              if (s.estado == 'en_curso') ...[
                _ChipAccion(
                  texto: 'Finalizar',
                  cargando: _cambiandoEstado,
                  onTap: () => _cambiarEstado(s, 'finalizada'),
                ),
                _ChipAccion(
                  texto: 'Cancelar',
                  peligro: true,
                  cargando: _cambiandoEstado,
                  onTap: () => _cambiarEstado(s, 'cancelada'),
                ),
              ],
              if (s.estado == 'cancelada' || s.estado == 'finalizada')
                Text(
                  s.estado == 'cancelada'
                      ? 'Esta salida está cancelada.'
                      : 'Esta salida ya finalizó.',
                  style: TipografiaHaku.interfaz(color: PaletaRutas.plomo),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Inscripciones',
            style: TipografiaHaku.titulo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: PaletaRutas.piedra,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PaletaRutas.carbon,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: PaletaRutas.plomo.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Abiertas',
                        style: TipografiaHaku.interfaz(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.inscripcionAbierta
                            ? 'Los usuarios pueden unirse.'
                            : 'Nadie más puede unirse.',
                        style: TipografiaHaku.interfaz(
                          fontSize: 13,
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_cambiandoInscripcion)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: PaletaRutas.oro,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Switch(
                    value: s.inscripcionAbierta,
                    activeThumbColor: PaletaRutas.oro,
                    onChanged: editable ? (_) => _toggleInscripcion(s) : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Editar datos',
            style: TipografiaHaku.titulo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: PaletaRutas.piedra,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titulo,
            enabled: editable,
            style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
            decoration: _deco('Título'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            enabled: editable,
            title: Text(
              'Fecha y hora',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
              ),
            ),
            subtitle: Text(
              () {
                final d = _fechaHora;
                final hh = d.hour.toString().padLeft(2, '0');
                final mm = d.minute.toString().padLeft(2, '0');
                return '${d.day}/${d.month} · $hh:$mm';
              }(),
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            ),
            trailing: Icon(
              Icons.event_outlined,
              color: editable ? PaletaRutas.oro : PaletaRutas.plomo,
            ),
            onTap: editable ? _elegirFechaHora : null,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cupos,
                  enabled: editable,
                  keyboardType: TextInputType.number,
                  style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                  decoration: _deco('Cupos'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _minimo,
                  enabled: editable,
                  keyboardType: TextInputType.number,
                  style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                  decoration: _deco('Mínimo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notas,
            enabled: editable,
            maxLines: 3,
            style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
            decoration: _deco('Notas'),
          ),
          const SizedBox(height: 12),
          if (editable)
            FilledButton(
              onPressed: _guardandoEdicion ? null : () => _guardarEdicion(s),
              style: FilledButton.styleFrom(
                backgroundColor: PaletaRutas.oro,
                foregroundColor: PaletaRutas.ink,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _guardandoEdicion
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PaletaRutas.ink,
                      ),
                    )
                  : Text(
                      'Guardar cambios',
                      style: TipografiaHaku.interfaz(
                        fontWeight: FontWeight.w800,
                        color: PaletaRutas.ink,
                      ),
                    ),
            ),
          const SizedBox(height: 32),
          Text(
            'Inscritos confirmados',
            style: TipografiaHaku.titulo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: PaletaRutas.piedra,
            ),
          ),
          const SizedBox(height: 16),
          if (roster.isEmpty)
            Text(
              'Aún no hay inscritos.',
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            )
          else
            ...roster.map((p) {
              final esOrg = p.usuarioId == s.organizadorId;
              final foto = p.fotoPerfil?.trim() ?? '';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: foto.isEmpty
                    ? const CircleAvatar(
                        backgroundColor: PaletaRutas.carbon,
                        child: Icon(Icons.person, color: PaletaRutas.oro),
                      )
                    : AvatarHaku(url: foto, size: 40),
                title: Text(
                  esOrg ? '${p.etiqueta} · organizador' : p.etiqueta,
                  style: TipografiaHaku.interfaz(
                    color: PaletaRutas.piedra,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _etiquetaEstado(String e) => switch (e) {
        'programada' => 'Programada',
        'en_curso' => 'En curso',
        'finalizada' => 'Finalizada',
        'cancelada' => 'Cancelada',
        _ => e,
      };
}

class _ChipAccion extends StatelessWidget {
  const _ChipAccion({
    required this.texto,
    required this.onTap,
    this.peligro = false,
    this.cargando = false,
  });

  final String texto;
  final VoidCallback onTap;
  final bool peligro;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: cargando ? null : onTap,
      backgroundColor: peligro
          ? Colors.redAccent.withValues(alpha: 0.15)
          : PaletaRutas.oro.withValues(alpha: 0.15),
      side: BorderSide(
        color: peligro
            ? Colors.redAccent.withValues(alpha: 0.5)
            : PaletaRutas.oro.withValues(alpha: 0.5),
      ),
      label: Text(
        texto,
        style: TipografiaHaku.interfaz(
          fontWeight: FontWeight.w700,
          color: peligro ? Colors.redAccent : PaletaRutas.oro,
        ),
      ),
    );
  }
}
