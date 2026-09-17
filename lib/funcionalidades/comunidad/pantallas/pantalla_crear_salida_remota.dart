import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../lugares/proveedores/proveedor_lugares.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/proveedores/proveedor_rutas.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelo_comunidad.dart';
import '../proveedores/proveedor_comunidad.dart';
import '../proveedores/proveedor_salidas.dart';
import 'pantalla_detalle_salida_remota.dart';

/// Alta remota de `public.salida` — solo columnas reales.
class PantallaCrearSalidaRemota extends ConsumerStatefulWidget {
  const PantallaCrearSalidaRemota({
    super.key,
    this.lugarId,
    this.comunidadId,
    this.comunidadTitulo,
    this.rutaId,
    this.rutaTitulo,
  });

  final String? lugarId;
  final String? comunidadId;
  final String? comunidadTitulo;
  final String? rutaId;
  final String? rutaTitulo;

  @override
  ConsumerState<PantallaCrearSalidaRemota> createState() =>
      _EstadoPantallaCrearSalidaRemota();
}

class _EstadoPantallaCrearSalidaRemota
    extends ConsumerState<PantallaCrearSalidaRemota> {
  final _tituloCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  DateTime _fecha = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _hora = const TimeOfDay(hour: 6, minute: 0);
  int _cupos = 8;
  int _minimo = 2;
  String? _lugarId;
  String? _comunidadId;
  String? _rutaId;
  bool _conComunidad = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _lugarId = widget.lugarId;
    _comunidadId = widget.comunidadId;
    _rutaId = widget.rutaId;
    _conComunidad =
        widget.comunidadId != null && widget.comunidadId!.isNotEmpty;
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  DateTime get _fechaHora {
    final local = DateTime(
      _fecha.year,
      _fecha.month,
      _fecha.day,
      _hora.hour,
      _hora.minute,
    );
    return local;
  }

  Future<void> _elegirFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: PaletaRutas.oro,
              surface: PaletaRutas.carbon,
              onSurface: PaletaRutas.piedra,
            ),
          ),
          child: child!,
        );
      },
    );
    if (d != null && mounted) setState(() => _fecha = d);
  }

  Future<void> _elegirHora() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _hora,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: PaletaRutas.oro,
              surface: PaletaRutas.carbon,
              onSurface: PaletaRutas.piedra,
            ),
          ),
          child: child!,
        );
      },
    );
    if (t != null && mounted) setState(() => _hora = t);
  }

  Future<void> _crear(
    List<ModeloLugar> lugares,
    List<ModeloRuta> rutas, {
    required bool catalogoRutasDisponible,
    required List<ComunidadHaku> misComunidades,
    required bool catalogoComunidadesDisponible,
  }) async {
    if (_guardando) return;
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) {
      mostrarSnackHaku(context, 'Escribe un título');
      return;
    }
    if (_lugarId == null || _lugarId!.isEmpty) {
      mostrarSnackHaku(context, 'Elige un lugar de Explora');
      return;
    }
    ModeloLugar? lugar;
    for (final l in lugares) {
      if (l.id == _lugarId) {
        lugar = l;
        break;
      }
    }
    if (lugar == null) {
      mostrarSnackHaku(context, 'Lugar no encontrado');
      return;
    }
    final rutaElegida = _rutaId?.trim() ?? '';
    if (rutaElegida.isNotEmpty &&
        catalogoRutasDisponible &&
        !rutas.any((ruta) => ruta.id == rutaElegida)) {
      mostrarSnackHaku(context, 'La ruta elegida ya no está publicada');
      return;
    }
    final lugarOk = lugar;
    if (_conComunidad && (_comunidadId == null || _comunidadId!.isEmpty)) {
      mostrarSnackHaku(context, 'Elige una comunidad');
      return;
    }
    if (_conComunidad &&
        catalogoComunidadesDisponible &&
        !misComunidades.any((comunidad) => comunidad.id == _comunidadId)) {
      mostrarSnackHaku(context, 'Ya no tienes acceso a esa comunidad');
      return;
    }
    if (!_fechaHora.isAfter(DateTime.now())) {
      mostrarSnackHaku(context, 'Elige una fecha y hora futuras');
      return;
    }

    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    if (clienteSupabase.auth.currentUser == null) {
      mostrarSnackHaku(context, 'Inicia sesión');
      return;
    }

    setState(() => _guardando = true);
    try {
      final ds = ref.read(salidaRemotoDataSourceProvider);
      final notas = _notasCtrl.text.trim();
      final creada = await ds.crear(
        titulo: titulo,
        fechaHoraInicio: _fechaHora,
        latitud: lugarOk.latitud,
        longitud: lugarOk.longitud,
        cuposTotales: _cupos,
        minimoParaSalir: _minimo,
        lugarId: lugarOk.id,
        rutaId: _rutaId,
        comunidadId: _conComunidad ? _comunidadId : null,
        notasGrupales: notas.isEmpty ? null : notas,
      );
      notificarSalidasCambiaron(ref);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, bool>(
        MaterialPageRoute<void>(
          builder: (_) => PantallaDetalleSalidaRemota(salidaId: creada.id),
        ),
        result: true,
      );
    } on AuthException catch (e) {
      if (mounted) mostrarSnackHaku(context, e.message);
    } catch (_) {
      if (mounted) mostrarSnackHaku(context, 'No se pudo crear la salida');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label,
    labelStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
    filled: true,
    fillColor: PaletaRutas.carbon,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: PaletaRutas.plomo.withValues(alpha: 0.45)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: PaletaRutas.oro),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final lugaresAsync = ref.watch(lugaresRemotosProvider);
    final comunidadesAsync = ref.watch(comunidadesRemotasProvider);
    final rutasAsync = ref.watch(rutasPublicadasProvider);
    final uid = clienteSupabase.auth.currentUser?.id ?? '';
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    final ancho = MediaQuery.sizeOf(context).width;
    final horizontal = ancho > 752 ? (ancho - 720) / 2 : 16.0;

    final lugares = lugaresAsync.valueOrNull ?? const <ModeloLugar>[];
    final rutas = rutasAsync.valueOrNull ?? const <ModeloRuta>[];
    final rutaInicialId = widget.rutaId?.trim() ?? '';
    final rutaInicialTitulo = widget.rutaTitulo?.trim() ?? '';
    final rutaInicialAusente =
        rutaInicialId.isNotEmpty &&
        _rutaId == rutaInicialId &&
        !rutas.any((ruta) => ruta.id == rutaInicialId);
    final misComunidades =
        (comunidadesAsync.valueOrNull ?? const <ComunidadHaku>[])
            .where((c) => c.esMiembro(uid) || c.creadorId == uid)
            .toList();
    final comunidadInicialId = widget.comunidadId?.trim() ?? '';
    final comunidadInicialTitulo = widget.comunidadTitulo?.trim() ?? '';
    final comunidadInicialAusente =
        comunidadInicialId.isNotEmpty &&
        _comunidadId == comunidadInicialId &&
        !misComunidades.any((comunidad) => comunidad.id == comunidadInicialId);

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _guardando
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Crear salida',
                      style: TipografiaHaku.titulo(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, bottom),
                children: [
                  TextField(
                    controller: _tituloCtrl,
                    enabled: !_guardando,
                    style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                    cursorColor: PaletaRutas.oro,
                    decoration: _deco('Nombre de la salida'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value:
                        rutas.any((r) => r.id == _rutaId) || rutaInicialAusente
                        ? _rutaId
                        : '',
                    dropdownColor: PaletaRutas.carbon,
                    decoration: _deco('Ruta (opcional)'),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(
                          rutasAsync.isLoading
                              ? 'Cargando rutas…'
                              : 'Sin ruta definida',
                          style: TipografiaHaku.interfaz(
                            color: PaletaRutas.plomoClaro,
                          ),
                        ),
                      ),
                      if (rutaInicialAusente)
                        DropdownMenuItem(
                          value: rutaInicialId,
                          child: Text(
                            rutaInicialTitulo.isEmpty
                                ? 'Ruta seleccionada'
                                : rutaInicialTitulo,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaHaku.interfaz(
                              color: PaletaRutas.piedra,
                            ),
                          ),
                        ),
                      for (final ruta in rutas)
                        DropdownMenuItem(
                          value: ruta.id,
                          child: Text(
                            ruta.titulo,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaHaku.interfaz(
                              color: PaletaRutas.piedra,
                            ),
                          ),
                        ),
                    ],
                    onChanged: _guardando || rutasAsync.isLoading
                        ? null
                        : (v) => setState(
                            () => _rutaId = v == null || v.isEmpty ? null : v,
                          ),
                  ),
                  if (rutasAsync.hasError && !rutasAsync.hasValue) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            rutaInicialAusente
                                ? 'No pudimos actualizar las rutas. Conservamos tu elección.'
                                : 'No pudimos cargar las rutas.',
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: PaletaRutas.oroSuave,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(rutasPublicadasProvider),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'La ruta aporta el itinerario. Tú eliges dónde y cuándo se reúne el grupo.',
                    style: TipografiaHaku.interfaz(
                      fontSize: 12,
                      color: PaletaRutas.plomo,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Lugar de encuentro',
                    style: TipografiaHaku.titulo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (lugaresAsync.hasError && !lugaresAsync.hasValue)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'No pudimos cargar los lugares.',
                            style: TipografiaHaku.interfaz(
                              color: PaletaRutas.oroSuave,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(lugaresRemotosProvider),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    )
                  else if (lugares.isEmpty)
                    Text(
                      lugaresAsync.isLoading
                          ? 'Cargando lugares…'
                          : 'No hay lugares disponibles. Agrega uno desde Explora.',
                      style: TipografiaHaku.interfaz(
                        color: PaletaRutas.plomoClaro,
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: lugares.any((l) => l.id == _lugarId)
                          ? _lugarId
                          : null,
                      dropdownColor: PaletaRutas.carbon,
                      decoration: _deco('Elige el punto de encuentro'),
                      items: [
                        for (final l in lugares)
                          DropdownMenuItem(
                            value: l.id,
                            child: Text(
                              l.nombre,
                              overflow: TextOverflow.ellipsis,
                              style: TipografiaHaku.interfaz(
                                color: PaletaRutas.piedra,
                              ),
                            ),
                          ),
                      ],
                      onChanged: _guardando
                          ? null
                          : (v) => setState(() => _lugarId = v),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _guardando ? null : _elegirFecha,
                          icon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                          ),
                          label: Text(
                            '${_fecha.day}/${_fecha.month}/${_fecha.year}',
                            style: TipografiaHaku.interfaz(
                              color: PaletaRutas.piedra,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _guardando ? null : _elegirHora,
                          icon: const Icon(Icons.schedule_outlined, size: 18),
                          label: Text(
                            _hora.format(context),
                            style: TipografiaHaku.interfaz(
                              color: PaletaRutas.piedra,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Cupos totales: $_cupos',
                          style: TipografiaHaku.interfaz(
                            color: PaletaRutas.piedra,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _guardando || _cupos <= 1
                            ? null
                            : () => setState(() {
                                _cupos--;
                                if (_minimo > _cupos) _minimo = _cupos;
                              }),
                        icon: const Icon(Icons.remove, color: PaletaRutas.oro),
                      ),
                      IconButton(
                        onPressed: _guardando
                            ? null
                            : () => setState(() => _cupos++),
                        icon: const Icon(Icons.add, color: PaletaRutas.oro),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mínimo para salir: $_minimo',
                          style: TipografiaHaku.interfaz(
                            color: PaletaRutas.piedra,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _guardando || _minimo <= 1
                            ? null
                            : () => setState(() => _minimo--),
                        icon: const Icon(Icons.remove, color: PaletaRutas.oro),
                      ),
                      IconButton(
                        onPressed: _guardando || _minimo >= _cupos
                            ? null
                            : () => setState(() => _minimo++),
                        icon: const Icon(Icons.add, color: PaletaRutas.oro),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Salida de comunidad',
                      style: TipografiaHaku.interfaz(
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    subtitle: Text(
                      _conComunidad
                          ? 'Solo la comunidad elegida podrá encontrarla.'
                          : 'Cualquier explorador podrá encontrarla.',
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: PaletaRutas.plomoClaro,
                      ),
                    ),
                    value: _conComunidad,
                    activeThumbColor: PaletaRutas.oro,
                    onChanged: _guardando
                        ? null
                        : (v) => setState(() {
                            _conComunidad = v;
                            if (!v) _comunidadId = null;
                          }),
                  ),
                  if (_conComunidad) ...[
                    const SizedBox(height: 8),
                    if (misComunidades.isEmpty && !comunidadInicialAusente)
                      Text(
                        comunidadesAsync.isLoading
                            ? 'Cargando tus comunidades…'
                            : 'No eres miembro aprobado de ninguna comunidad.',
                        style: TipografiaHaku.interfaz(
                          color: PaletaRutas.plomoClaro,
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value:
                            misComunidades.any((c) => c.id == _comunidadId) ||
                                comunidadInicialAusente
                            ? _comunidadId
                            : null,
                        dropdownColor: PaletaRutas.carbon,
                        decoration: _deco('Comunidad'),
                        items: [
                          for (final c in misComunidades)
                            DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.nombre,
                                style: TipografiaHaku.interfaz(
                                  color: PaletaRutas.piedra,
                                ),
                              ),
                            ),
                          if (comunidadInicialAusente)
                            DropdownMenuItem(
                              value: comunidadInicialId,
                              child: Text(
                                comunidadInicialTitulo.isEmpty
                                    ? 'Comunidad seleccionada'
                                    : comunidadInicialTitulo,
                                overflow: TextOverflow.ellipsis,
                                style: TipografiaHaku.interfaz(
                                  color: PaletaRutas.piedra,
                                ),
                              ),
                            ),
                        ],
                        onChanged: _guardando
                            ? null
                            : (v) => setState(() => _comunidadId = v),
                      ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: _notasCtrl,
                    enabled: !_guardando,
                    maxLines: 3,
                    style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                    cursorColor: PaletaRutas.oro,
                    decoration: _deco('Mensaje para el grupo (opcional)'),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _guardando
                          ? null
                          : () => _crear(
                              lugares,
                              rutas,
                              catalogoRutasDisponible: rutasAsync.hasValue,
                              misComunidades: misComunidades,
                              catalogoComunidadesDisponible:
                                  comunidadesAsync.hasValue,
                            ),
                      style: FilledButton.styleFrom(
                        backgroundColor: PaletaRutas.oro,
                        foregroundColor: PaletaRutas.ink,
                      ),
                      child: _guardando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: PaletaRutas.ink,
                              ),
                            )
                          : Text(
                              'Crear salida',
                              style: TipografiaHaku.interfaz(
                                fontWeight: FontWeight.w800,
                                color: PaletaRutas.ink,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
