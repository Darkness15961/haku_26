import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/widgets/cargador_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelos/modelo_lugar.dart';
import '../dominio/modelos/modelo_lugar_propio.dart';
import '../proveedores/proveedor_lugares.dart';
import 'pantalla_detalle_lugar.dart';
import 'pantalla_registrar_lugar.dart';

class PantallaMisLugares extends ConsumerStatefulWidget {
  const PantallaMisLugares({super.key});

  @override
  ConsumerState<PantallaMisLugares> createState() =>
      _EstadoPantallaMisLugares();
}

class _EstadoPantallaMisLugares extends ConsumerState<PantallaMisLugares>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _busqueda = TextEditingController();
  bool _procesando = false;
  String? _provinciaSeleccionada;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: EstadoEditorialLugar.values.length,
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await asegurarSesion(context, ref);
      if (!mounted) return;
      if (!ok) {
        Navigator.of(context).pop();
        return;
      }
      ref.invalidate(misLugaresProvider);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _busqueda.dispose();
    super.dispose();
  }

  void _snack(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mensaje,
            style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
          ),
          backgroundColor: PaletaRutas.carbon,
        ),
      );
  }

  Future<bool> _confirmar({
    required String titulo,
    required String mensaje,
    required String accion,
    bool destructiva = false,
  }) async {
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PaletaRutas.carbon,
        title: Text(
          titulo,
          style: TipografiaHaku.titulo(color: PaletaRutas.piedra),
        ),
        content: Text(
          mensaje,
          style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: destructiva
                ? TextButton.styleFrom(foregroundColor: Colors.redAccent)
                : null,
            child: Text(accion),
          ),
        ],
      ),
    );
    return respuesta == true;
  }

  Future<void> _ejecutar({
    required Future<void> Function() accion,
    required String mensajeOk,
    required String mensajeError,
    EstadoEditorialLugar? irAEstado,
  }) async {
    if (_procesando) return;
    setState(() => _procesando = true);
    try {
      await accion();
      notificarLugaresCambiaron(ref);
      if (irAEstado != null && mounted) {
        _tabs.animateTo(EstadoEditorialLugar.values.indexOf(irAEstado));
      }
      _snack(mensajeOk);
    } on AuthException catch (e) {
      _snack(e.message);
    } on PostgrestException catch (e) {
      final tecnico = e.message.toLowerCase();
      if (e.code == 'PGRST202' ||
          tecnico.contains('schema cache') ||
          tecnico.contains('could not find the function')) {
        _snack(
          'El servidor aún no reconoce la administración de Lugares. '
          'Aplica la migración pendiente y recarga Supabase.',
        );
      } else {
        _snack(e.message.trim().isEmpty ? mensajeError : e.message);
      }
    } catch (_) {
      _snack(mensajeError);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _crear() async {
    final creado = await Navigator.of(context).push<ModeloLugar>(
      MaterialPageRoute<ModeloLugar>(
        builder: (_) => const PantallaRegistrarLugar(),
      ),
    );
    if (creado != null) notificarLugaresCambiaron(ref);
  }

  Future<void> _editar(ModeloLugarPropio propio) async {
    final actualizado = await Navigator.of(context).push<ModeloLugar>(
      MaterialPageRoute<ModeloLugar>(
        builder: (_) => PantallaRegistrarLugar(
          lugarInicial: propio.lugar,
          provinciaInicial: propio.lugar.provincia,
        ),
      ),
    );
    if (actualizado != null) notificarLugaresCambiaron(ref);
  }

  Future<void> _publicar(ModeloLugarPropio propio) async {
    await _ejecutar(
      accion: () async {
        await ref.read(lugarRemotoDataSourceProvider).publicarPropio(propio.id);
      },
      mensajeOk: 'Lugar publicado',
      mensajeError: 'No se pudo publicar el Lugar',
      irAEstado: EstadoEditorialLugar.publicado,
    );
  }

  Future<void> _desactivar(ModeloLugarPropio propio) async {
    final confirmado = await _confirmar(
      titulo: 'Desactivar Lugar',
      mensaje:
          'Dejará de aparecer en Explora. Podrás restaurarlo desde Desactivados.',
      accion: 'Desactivar',
    );
    if (!confirmado) return;
    await _ejecutar(
      accion: () async {
        await ref.read(lugarRemotoDataSourceProvider).archivarPropio(propio.id);
      },
      mensajeOk: 'Lugar desactivado',
      mensajeError: 'No se pudo desactivar el Lugar',
      irAEstado: EstadoEditorialLugar.archivado,
    );
  }

  Future<void> _restaurar(ModeloLugarPropio propio) async {
    final confirmado = await _confirmar(
      titulo: 'Restaurar Lugar',
      mensaje: 'Volverá a Borradores para que lo revises antes de publicarlo.',
      accion: 'Restaurar',
    );
    if (!confirmado) return;
    await _ejecutar(
      accion: () async {
        await ref
            .read(lugarRemotoDataSourceProvider)
            .restaurarPropio(propio.id);
      },
      mensajeOk: 'Lugar restaurado como borrador',
      mensajeError: 'No se pudo restaurar el Lugar',
      irAEstado: EstadoEditorialLugar.borrador,
    );
  }

  Future<void> _eliminar(ModeloLugarPropio propio) async {
    final confirmado = await _confirmar(
      titulo: 'Eliminar definitivamente',
      mensaje:
          'Se borrará este Lugar de forma permanente. Esta acción no se puede deshacer.',
      accion: 'Eliminar',
      destructiva: true,
    );
    if (!confirmado) return;
    await _ejecutar(
      accion: () =>
          ref.read(lugarRemotoDataSourceProvider).eliminarPropio(propio.id),
      mensajeOk: 'Lugar eliminado',
      mensajeError: 'No se pudo eliminar el Lugar',
    );
  }

  void _abrir(ModeloLugarPropio propio) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PantallaDetalleLugar(lugarId: propio.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(misLugaresProvider);
    final lugares = async.valueOrNull ?? const <ModeloLugarPropio>[];
    final provincias =
        lugares
            .map((propio) => propio.lugar.provincia.trim())
            .where((provincia) => provincia.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final provinciaActiva = provincias.contains(_provinciaSeleccionada)
        ? _provinciaSeleccionada
        : null;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        title: Text(
          'Mis lugares',
          style: TipografiaHaku.titulo(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: PaletaRutas.piedra,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _procesando
                ? null
                : () => ref.invalidate(misLugaresProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Crear Lugar',
            onPressed: _procesando ? null : _crear,
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: PaletaRutas.piedra,
          unselectedLabelColor: PaletaRutas.plomo,
          indicatorColor: PaletaRutas.oro,
          tabs: [
            for (final estado in EstadoEditorialLugar.values)
              Tab(
                text:
                    '${estado.etiquetaPlural} (${lugares.where((lugar) => lugar.estado == estado).length})',
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          _FiltrosMisLugares(
            controller: _busqueda,
            provincias: provincias,
            provinciaSeleccionada: provinciaActiva,
            onBusqueda: (_) => setState(() {}),
            onProvincia: (provincia) {
              setState(() => _provinciaSeleccionada = provincia);
            },
          ),
          Expanded(
            child: async.isLoading && !async.hasValue
                ? const CargadorHaku.pagina(mensaje: 'Cargando tus lugares…')
                : async.hasError && !async.hasValue
                ? _EstadoVacioMisLugares(
                    titulo: 'No pudimos cargar tus Lugares',
                    onAccion: () => ref.invalidate(misLugaresProvider),
                    accion: 'Reintentar',
                  )
                : TabBarView(
                    controller: _tabs,
                    children: [
                      for (final estado in EstadoEditorialLugar.values)
                        _ListaMisLugares(
                          estado: estado,
                          lugares: _filtrar(lugares, estado, provinciaActiva),
                          filtroActivo:
                              _busqueda.text.trim().isNotEmpty ||
                              provinciaActiva != null,
                          procesando: _procesando,
                          onAbrir: estado == EstadoEditorialLugar.publicado
                              ? _abrir
                              : null,
                          onEditar: _editar,
                          onPublicar: estado == EstadoEditorialLugar.borrador
                              ? _publicar
                              : null,
                          onDesactivar: estado == EstadoEditorialLugar.publicado
                              ? _desactivar
                              : null,
                          onRestaurar: estado == EstadoEditorialLugar.archivado
                              ? _restaurar
                              : null,
                          onEliminar: estado == EstadoEditorialLugar.publicado
                              ? null
                              : _eliminar,
                          onCrear: _crear,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<ModeloLugarPropio> _filtrar(
    List<ModeloLugarPropio> lugares,
    EstadoEditorialLugar estado,
    String? provincia,
  ) {
    final consulta = _normalizar(_busqueda.text);
    return lugares.where((propio) {
      if (propio.estado != estado) return false;
      if (provincia != null && propio.lugar.provincia != provincia) {
        return false;
      }
      if (consulta.isEmpty) return true;
      final texto = _normalizar(
        '${propio.lugar.nombre} ${propio.lugar.distrito} '
        '${propio.lugar.provincia} ${propio.lugar.subtituloClasificacion}',
      );
      return texto.contains(consulta);
    }).toList();
  }
}

class _FiltrosMisLugares extends StatelessWidget {
  const _FiltrosMisLugares({
    required this.controller,
    required this.provincias,
    required this.provinciaSeleccionada,
    required this.onBusqueda,
    required this.onProvincia,
  });

  final TextEditingController controller;
  final List<String> provincias;
  final String? provinciaSeleccionada;
  final ValueChanged<String> onBusqueda;
  final ValueChanged<String?> onProvincia;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        border: Border(
          bottom: BorderSide(color: PaletaRutas.plomo.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onBusqueda,
              style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
              cursorColor: PaletaRutas.oro,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Buscar Lugar',
                hintStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomo),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: PaletaRutas.plomoClaro,
                ),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          controller.clear();
                          onBusqueda('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: PaletaRutas.ink,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            tooltip: 'Filtrar por provincia',
            initialValue: provinciaSeleccionada,
            onSelected: (provincia) {
              onProvincia(provincia.isEmpty ? null : provincia);
            },
            color: PaletaRutas.carbon,
            icon: Badge(
              isLabelVisible: provinciaSeleccionada != null,
              backgroundColor: PaletaRutas.oro,
              child: const Icon(Icons.tune_rounded, color: PaletaRutas.piedra),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: '',
                child: Text('Todas las provincias'),
              ),
              for (final provincia in provincias)
                PopupMenuItem<String>(value: provincia, child: Text(provincia)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListaMisLugares extends StatelessWidget {
  const _ListaMisLugares({
    required this.estado,
    required this.lugares,
    required this.filtroActivo,
    required this.procesando,
    required this.onAbrir,
    required this.onEditar,
    required this.onPublicar,
    required this.onDesactivar,
    required this.onRestaurar,
    required this.onEliminar,
    required this.onCrear,
  });

  final EstadoEditorialLugar estado;
  final List<ModeloLugarPropio> lugares;
  final bool filtroActivo;
  final bool procesando;
  final ValueChanged<ModeloLugarPropio>? onAbrir;
  final ValueChanged<ModeloLugarPropio> onEditar;
  final ValueChanged<ModeloLugarPropio>? onPublicar;
  final ValueChanged<ModeloLugarPropio>? onDesactivar;
  final ValueChanged<ModeloLugarPropio>? onRestaurar;
  final ValueChanged<ModeloLugarPropio>? onEliminar;
  final VoidCallback onCrear;

  @override
  Widget build(BuildContext context) {
    if (lugares.isEmpty) {
      return _EstadoVacioMisLugares(
        titulo: filtroActivo ? 'No hay resultados con esos filtros' : _vacio,
        onAccion: estado == EstadoEditorialLugar.borrador && !filtroActivo
            ? onCrear
            : null,
        accion: 'Crear Lugar',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      itemCount: lugares.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final propio = lugares[index];
        return _TarjetaLugarPropio(
          propio: propio,
          onAbrir: onAbrir == null || procesando
              ? null
              : () => onAbrir!(propio),
          onEditar: procesando ? null : () => onEditar(propio),
          onPublicar: onPublicar == null || procesando
              ? null
              : () => onPublicar!(propio),
          onDesactivar: onDesactivar == null || procesando
              ? null
              : () => onDesactivar!(propio),
          onRestaurar: onRestaurar == null || procesando
              ? null
              : () => onRestaurar!(propio),
          onEliminar: onEliminar == null || procesando
              ? null
              : () => onEliminar!(propio),
        );
      },
    );
  }

  String get _vacio => switch (estado) {
    EstadoEditorialLugar.borrador => 'No tienes borradores por ahora',
    EstadoEditorialLugar.publicado => 'Aún no tienes Lugares publicados',
    EstadoEditorialLugar.archivado => 'No tienes Lugares desactivados',
  };
}

class _TarjetaLugarPropio extends StatelessWidget {
  const _TarjetaLugarPropio({
    required this.propio,
    required this.onAbrir,
    required this.onEditar,
    required this.onPublicar,
    required this.onDesactivar,
    required this.onRestaurar,
    required this.onEliminar,
  });

  final ModeloLugarPropio propio;
  final VoidCallback? onAbrir;
  final VoidCallback? onEditar;
  final VoidCallback? onPublicar;
  final VoidCallback? onDesactivar;
  final VoidCallback? onRestaurar;
  final VoidCallback? onEliminar;

  @override
  Widget build(BuildContext context) {
    final lugar = propio.lugar;
    final ubicacion = [
      lugar.distrito.trim(),
      lugar.provincia.trim(),
    ].where((valor) => valor.isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PaletaRutas.plomo.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 78,
              height: 78,
              child: lugar.imagenUrl.trim().isEmpty
                  ? const ColoredBox(
                      color: PaletaRutas.ink,
                      child: Icon(
                        Icons.place_outlined,
                        color: PaletaRutas.plomo,
                      ),
                    )
                  : Image.network(
                      lugar.imagenUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: PaletaRutas.ink,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: PaletaRutas.plomo,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        lugar.nombre.trim().isEmpty ? 'Lugar' : lugar.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.interfaz(
                          color: PaletaRutas.piedra,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _EstadoLugarPill(texto: propio.estado.etiqueta),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ubicacion.isEmpty ? 'Ubicación sin etiqueta' : ubicacion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lugar.subtituloClasificacion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    color: PaletaRutas.plomo,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (onAbrir != null)
                      _BotonLugarMini(
                        texto: 'Ver',
                        icono: Icons.visibility_outlined,
                        onTap: onAbrir,
                      ),
                    _BotonLugarMini(
                      texto: 'Editar',
                      icono: Icons.edit_outlined,
                      onTap: onEditar,
                    ),
                    if (onPublicar != null)
                      _BotonLugarMini(
                        texto: 'Publicar',
                        icono: Icons.cloud_upload_outlined,
                        onTap: onPublicar,
                      ),
                    if (onDesactivar != null)
                      _BotonLugarMini(
                        texto: 'Desactivar',
                        icono: Icons.visibility_off_outlined,
                        onTap: onDesactivar,
                      ),
                    if (onRestaurar != null)
                      _BotonLugarMini(
                        texto: 'Restaurar',
                        icono: Icons.settings_backup_restore_rounded,
                        onTap: onRestaurar,
                      ),
                    if (onEliminar != null)
                      _BotonLugarMini(
                        texto: 'Eliminar',
                        icono: Icons.delete_outline_rounded,
                        onTap: onEliminar,
                        destructivo: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoLugarPill extends StatelessWidget {
  const _EstadoLugarPill({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: PaletaRutas.oro.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PaletaRutas.oro.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          texto,
          style: TipografiaHaku.interfaz(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: PaletaRutas.oro,
          ),
        ),
      ),
    );
  }
}

class _BotonLugarMini extends StatelessWidget {
  const _BotonLugarMini({
    required this.texto,
    required this.icono,
    required this.onTap,
    this.destructivo = false,
  });

  final String texto;
  final IconData icono;
  final VoidCallback? onTap;
  final bool destructivo;

  @override
  Widget build(BuildContext context) {
    final color = destructivo ? Colors.redAccent : PaletaRutas.piedra;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icono, size: 15),
      label: Text(texto),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: destructivo
              ? Colors.redAccent.withValues(alpha: 0.42)
              : PaletaRutas.oro.withValues(alpha: 0.42),
        ),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }
}

class _EstadoVacioMisLugares extends StatelessWidget {
  const _EstadoVacioMisLugares({
    required this.titulo,
    this.onAccion,
    this.accion,
  });

  final String titulo;
  final VoidCallback? onAccion;
  final String? accion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_location_alt_outlined,
              color: PaletaRutas.plomo,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TipografiaHaku.interfaz(
                color: PaletaRutas.piedra,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (onAccion != null && accion != null) ...[
              const SizedBox(height: 10),
              TextButton(onPressed: onAccion, child: Text(accion!)),
            ],
          ],
        ),
      ),
    );
  }
}

String _normalizar(String valor) {
  var salida = valor.trim().toLowerCase();
  const reemplazos = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  for (final entry in reemplazos.entries) {
    salida = salida.replaceAll(entry.key, entry.value);
  }
  return salida;
}
