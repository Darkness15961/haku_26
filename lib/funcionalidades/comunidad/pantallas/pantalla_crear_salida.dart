import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../inicio/datos/feed_inicio_datasource_local.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../lugares/datos/lugares_datasource_local.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/salidas_datasource_local.dart';
import '../dominio/modelo_comunidad.dart';

/// Formulario completo para crear una salida (persona o grupo).
class PantallaCrearSalida extends ConsumerStatefulWidget {
  const PantallaCrearSalida({super.key, this.lugarId});
  final String? lugarId;

  @override
  ConsumerState<PantallaCrearSalida> createState() =>
      _EstadoPantallaCrearSalida();
}

class _EstadoPantallaCrearSalida extends ConsumerState<PantallaCrearSalida> {
  late String _lugarId;
  final _hora = TextEditingController(text: '6:00 AM');
  final _punto = TextEditingController(text: 'Plaza de Armas');
  final _desc = TextEditingController();
  DateTime _fecha = DateTime.now().add(const Duration(days: 3));
  int _cuposAbiertos = 8;
  int _cuposGrupo = 4;
  int _minimo = 3;
  String _dificultad = 'Moderada';
  /// false = persona · true = grupo
  bool _comoGrupo = false;
  String? _comunidadId;

  @override
  void initState() {
    super.initState();
    final lugares = LugaresDataSourceLocal.instancia.todos();
    _lugarId = widget.lugarId ??
        (lugares.isNotEmpty ? lugares.first.id : 'laguna_humantay');
  }

  @override
  void dispose() {
    _hora.dispose();
    _punto.dispose();
    _desc.dispose();
    super.dispose();
  }

  List<ComunidadHaku> _misGrupos(EstadoAlmacenFeed store) {
    final uid = AlmacenFeedNotifier.idUsuarioLocal;
    return store.comunidades
        .where(
          (c) =>
              store.comunidadIds.contains(c.id) ||
              c.miembroIds.contains(uid) ||
              c.creadorId == uid,
        )
        .toList();
  }

  InputDecoration _deco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
      filled: true,
      fillColor: PaletaRutas.carbon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: PaletaRutas.plomoOscuro),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PaletaRutas.oro),
      ),
    );
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
    if (d != null) setState(() => _fecha = d);
  }

  Future<void> _crear() async {
    final lugar = LugaresDataSourceLocal.instancia.porId(_lugarId);
    if (lugar == null) return;

    final store = ref.read(almacenFeedProvider);
    final sesion = ref.read(sesionProvider);
    final nombrePersona =
        sesion.usuario?.nombreUsuario.trim().isNotEmpty == true
            ? sesion.usuario!.nombreUsuario.trim()
            : 'Lucía';

    String organizador = nombrePersona;
    String grupo = '';
    String comunidadId = '';
    var cuposGrupo = 0;

    if (_comoGrupo) {
      final grupos = _misGrupos(store);
      if (grupos.isEmpty || _comunidadId == null) {
        mostrarSnackHaku(context, 'Elige un grupo o crea la salida como persona');
        return;
      }
      final g = grupos.firstWhere((c) => c.id == _comunidadId);
      grupo = g.nombre;
      comunidadId = g.id;
      organizador = nombrePersona;
      cuposGrupo = _cuposGrupo;
    }

    if (_hora.text.trim().isEmpty || _punto.text.trim().isEmpty) {
      mostrarSnackHaku(context, 'Completa hora y punto de encuentro');
      return;
    }

    final salidaId = 's_${DateTime.now().millisecondsSinceEpoch}';

    SalidasDataSourceLocal.instancia.crear(
      ModeloSalida(
        id: salidaId,
        lugarId: lugar.id,
        lugarNombre: lugar.nombre,
        organizador: organizador,
        fecha: _fecha,
        hora: _hora.text.trim(),
        puntoEncuentro: _punto.text.trim(),
        cupos: _cuposAbiertos,
        cuposGrupo: cuposGrupo,
        inscritos: 1,
        minimo: _minimo.clamp(2, _cuposAbiertos),
        dificultad: _dificultad,
        grupo: grupo,
        comunidadId: comunidadId,
        inscritoIds: const [AlmacenFeedNotifier.idUsuarioLocal],
      ),
    );
    await ref.read(almacenFeedProvider.notifier).persistirSatelites();

    final ahora = DateTime.now();
    final textoInvitacion = _desc.text.trim().isNotEmpty
        ? _desc.text.trim()
        : grupo.isEmpty
            ? 'Salida a ${lugar.nombre}. ¿Te unes?'
            : 'Salida con $grupo a ${lugar.nombre}. Cupos limitados.';

    await ref.read(almacenFeedProvider.notifier).crearPublicacion(
          PublicacionFeed(
            id: 'inv_$salidaId',
            autorId: AlmacenFeedNotifier.idUsuarioLocal,
            autor: nombrePersona,
            usuario:
                '@${nombrePersona.toLowerCase().replaceAll(' ', '')}',
            avatarUrl: CatalogoImagenesHaku.resolverAvatar(
                sesion.usuario?.avatarUrl),
            hace: 'ahora',
            texto: textoInvitacion,
            imagenUrl: lugar.imagenUrl,
            likes: 0,
            comentarios: 0,
            estiloFondo: EstiloFondoPublicacion.veloNegro,
            creadoEn: ahora,
            lugarId: lugar.id,
            lugarNombre: lugar.nombre,
            categoria: lugar.categoria.name,
            tipo: 'invitacion_salida',
            salidaId: salidaId,
          ),
        );
    if (!mounted) return;
    mostrarSnackHaku(
      context,
      grupo.isEmpty
          ? 'Salida creada y publicada en Comunidad'
          : 'Salida creada con $grupo y publicada en Comunidad',
      destacado: true,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final lugares = LugaresDataSourceLocal.instancia.todos();
    final store = ref.watch(almacenFeedProvider);
    final misGrupos = _misGrupos(store);
    if (_comoGrupo &&
        _comunidadId == null &&
        misGrupos.isNotEmpty) {
      _comunidadId = misGrupos.first.id;
    }

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        title: Text(
          'Crear salida',
          style: TipografiaHaku.titulo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            '¿Quién organiza?',
            style: TipografiaHaku.interfaz(
              fontWeight: FontWeight.w800,
              color: PaletaRutas.piedra,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _OpcionOrganiza(
                  label: 'Yo (persona)',
                  selected: !_comoGrupo,
                  onTap: () => setState(() {
                    _comoGrupo = false;
                    _comunidadId = null;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OpcionOrganiza(
                  label: 'Un grupo',
                  selected: _comoGrupo,
                  onTap: () => setState(() => _comoGrupo = true),
                ),
              ),
            ],
          ),
          if (_comoGrupo) ...[
            const SizedBox(height: 14),
            if (misGrupos.isEmpty)
              Text(
                'Aún no perteneces a un grupo. Puedes crear la salida como persona.',
                style: TipografiaHaku.interfaz(
                  fontSize: 13,
                  color: PaletaRutas.plomoClaro,
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _comunidadId,
                dropdownColor: PaletaRutas.carbon,
                decoration: _deco('Grupo organizador'),
                style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                items: [
                  for (final g in misGrupos)
                    DropdownMenuItem(
                      value: g.id,
                      child: Text(g.nombre),
                    ),
                ],
                onChanged: (v) => setState(() => _comunidadId = v),
              ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Se publicará a tu nombre, sin etiqueta de grupo.',
                style: TipografiaHaku.interfaz(
                  fontSize: 12,
                  color: PaletaRutas.plomoClaro,
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text(
            'Lugar',
            style: TipografiaHaku.interfaz(
              fontWeight: FontWeight.w800,
              color: PaletaRutas.piedra,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: lugares.any((l) => l.id == _lugarId) ? _lugarId : null,
            dropdownColor: PaletaRutas.carbon,
            decoration: _deco('Destino'),
            style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
            items: [
              for (final l in lugares)
                DropdownMenuItem(value: l.id, child: Text(l.nombre)),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _lugarId = v);
            },
          ),
          const SizedBox(height: 14),
          Material(
            color: PaletaRutas.carbon,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _elegirFecha,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined, color: PaletaRutas.oro),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Fecha: ${_fecha.day}/${_fecha.month}/${_fecha.year}',
                        style: TipografiaHaku.interfaz(
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                    ),
                    Text(
                      'Cambiar',
                      style: TipografiaHaku.interfaz(
                        color: PaletaRutas.oro,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hora,
            style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
            decoration: _deco('Hora de salida'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _punto,
            style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
            decoration: _deco('Punto de encuentro'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 3,
            style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
            decoration: _deco('Nota para el grupo (opcional)'),
          ),
          const SizedBox(height: 18),
          Text(
            'Dificultad',
            style: TipografiaHaku.interfaz(
              fontWeight: FontWeight.w800,
              color: PaletaRutas.piedra,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final d in ['Fácil', 'Moderada', 'Exigente'])
                ChoiceChip(
                  label: Text(
                    d,
                    style: TipografiaHaku.interfaz(
                      fontWeight: FontWeight.w700,
                      color: _dificultad == d
                          ? PaletaRutas.ink
                          : PaletaRutas.piedra,
                    ),
                  ),
                  selected: _dificultad == d,
                  selectedColor: PaletaRutas.oro,
                  backgroundColor: PaletaRutas.carbon,
                  onSelected: (_) => setState(() => _dificultad = d),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Cupos abiertos (enrolados)',
            style: TipografiaHaku.interfaz(
              fontWeight: FontWeight.w800,
              color: PaletaRutas.piedra,
            ),
          ),
          Text(
            'Personas que pueden unirse desde la comunidad',
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              color: PaletaRutas.plomoClaro,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _cuposAbiertos.toDouble(),
                  min: 2,
                  max: 30,
                  divisions: 28,
                  activeColor: const Color(0xFF2F6B5A),
                  inactiveColor: PaletaRutas.plomoOscuro,
                  onChanged: (v) =>
                      setState(() => _cuposAbiertos = v.round()),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$_cuposAbiertos',
                  textAlign: TextAlign.right,
                  style: TipografiaHaku.titulo(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7BC4A8),
                  ),
                ),
              ),
            ],
          ),
          if (_comoGrupo && misGrupos.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Cupos del grupo',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w800,
                color: PaletaRutas.piedra,
              ),
            ),
            Text(
              'Reservados solo para miembros del grupo',
              style: TipografiaHaku.interfaz(
                fontSize: 12,
                color: PaletaRutas.plomoClaro,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _cuposGrupo.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    activeColor: PaletaRutas.oro,
                    inactiveColor: PaletaRutas.plomoOscuro,
                    onChanged: (v) =>
                        setState(() => _cuposGrupo = v.round()),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$_cuposGrupo',
                    textAlign: TextAlign.right,
                    style: TipografiaHaku.titulo(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: PaletaRutas.oro,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Mínimo para salir: $_minimo',
            style: TipografiaHaku.interfaz(
              fontWeight: FontWeight.w700,
              color: PaletaRutas.plomoClaro,
            ),
          ),
          Slider(
            value: _minimo.toDouble().clamp(2, _cuposAbiertos.toDouble()),
            min: 2,
            max: _cuposAbiertos.toDouble().clamp(2, 20),
            divisions: (_cuposAbiertos - 2).clamp(1, 18),
            activeColor: PaletaRutas.plomo,
            inactiveColor: PaletaRutas.plomoOscuro,
            onChanged: (v) => setState(() => _minimo = v.round()),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _crear,
            style: FilledButton.styleFrom(
              backgroundColor: PaletaRutas.oro,
              foregroundColor: PaletaRutas.ink,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'Crear salida',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: PaletaRutas.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionOrganiza extends StatelessWidget {
  const _OpcionOrganiza({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? PaletaRutas.oro : PaletaRutas.carbon,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? null
                : Border.all(color: PaletaRutas.plomoOscuro),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TipografiaHaku.interfaz(
              fontWeight: FontWeight.w800,
              color: selected ? PaletaRutas.ink : PaletaRutas.piedra,
            ),
          ),
        ),
      ),
    );
  }
}
