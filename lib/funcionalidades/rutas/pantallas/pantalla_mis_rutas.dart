import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../autenticacion/navegacion_auth.dart';
import '../dominio/modelos/modelo_ruta_propia.dart';
import '../proveedores/proveedor_rutas.dart';
import '../widgets/estilos_rutas.dart';
import 'pantalla_crear_ruta.dart';
import 'pantalla_detalle_ruta.dart';

class PantallaMisRutas extends ConsumerStatefulWidget {
  const PantallaMisRutas({super.key});

  @override
  ConsumerState<PantallaMisRutas> createState() => _EstadoPantallaMisRutas();
}

class _EstadoPantallaMisRutas extends ConsumerState<PantallaMisRutas>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: EstadoEditorialRuta.values.length,
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await asegurarSesion(context, ref);
      if (ok && mounted) ref.invalidate(misRutasProvider);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
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
    required String ok,
    required String error,
    EstadoEditorialRuta? irAEstado,
  }) async {
    if (_procesando) return;
    setState(() => _procesando = true);
    try {
      await accion();
      notificarRutasCambiaron(ref);
      if (irAEstado != null && mounted) {
        _tabs.animateTo(EstadoEditorialRuta.values.indexOf(irAEstado));
      }
      _snack(ok);
    } on AuthException catch (e) {
      _snack(e.message);
    } on PostgrestException catch (e) {
      _snack(_mensajePostgrest(e, error));
    } catch (_) {
      _snack(error);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  String _mensajePostgrest(PostgrestException e, String fallback) {
    final message = e.message.trim();
    final tecnico = message.toLowerCase();
    if (e.code == 'PGRST202' ||
        tecnico.contains('schema cache') ||
        tecnico.contains('could not find the function')) {
      return 'El servidor aun no reconoce esta accion. Aplica las migraciones pendientes y recarga Supabase.';
    }
    return message.isEmpty ? fallback : message;
  }

  Future<void> _editar(ModeloRutaPropia propia) async {
    final actualizada = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PantallaCrearRuta(rutaInicial: propia),
      ),
    );
    if (actualizada == true) {
      notificarRutasCambiaron(ref);
    }
  }

  Future<void> _publicar(ModeloRutaPropia propia) async {
    await _ejecutar(
      accion: () async {
        await ref.read(rutasDataSourceProvider).publicarPropia(propia.id);
      },
      ok: 'Ruta publicada',
      error: 'No se pudo publicar',
      irAEstado: EstadoEditorialRuta.publicado,
    );
  }

  Future<void> _desactivar(ModeloRutaPropia propia) async {
    final confirmar = await _confirmar(
      titulo: 'Desactivar Ruta',
      mensaje:
          'No aparecera en Explora. Podras restaurarla desde Desactivadas.',
      accion: 'Desactivar',
    );
    if (!confirmar) return;
    await _ejecutar(
      accion: () async {
        await ref.read(rutasDataSourceProvider).archivarPropia(propia.id);
      },
      ok: 'Ruta desactivada',
      error: 'No se pudo desactivar',
      irAEstado: EstadoEditorialRuta.archivado,
    );
  }

  Future<void> _restaurar(ModeloRutaPropia propia) async {
    final confirmar = await _confirmar(
      titulo: 'Restaurar Ruta',
      mensaje: 'Volvera a Borradores para que la revises antes de publicarla.',
      accion: 'Restaurar',
    );
    if (!confirmar) return;
    await _ejecutar(
      accion: () async {
        await ref.read(rutasDataSourceProvider).restaurarPropia(propia.id);
      },
      ok: 'Ruta restaurada como borrador',
      error: 'No se pudo restaurar',
      irAEstado: EstadoEditorialRuta.borrador,
    );
  }

  Future<void> _eliminar(ModeloRutaPropia propia) async {
    final confirmar = await _confirmar(
      titulo: 'Eliminar definitivamente',
      mensaje:
          'Se borrara esta Ruta de forma permanente. Esta accion no se puede deshacer.',
      accion: 'Eliminar',
      destructiva: true,
    );
    if (!confirmar) return;
    await _ejecutar(
      accion: () async {
        await ref.read(rutasDataSourceProvider).eliminarPropia(propia.id);
      },
      ok: 'Ruta eliminada',
      error: 'No se pudo eliminar',
    );
  }

  void _abrirPublica(ModeloRutaPropia propia) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PantallaDetalleRuta(ruta: propia.ruta),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(misRutasProvider);
    final rutas = async.valueOrNull ?? const <ModeloRutaPropia>[];

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        title: Text(
          'Mis Rutas',
          style: TipografiaHaku.titulo(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: PaletaRutas.piedra,
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: PaletaRutas.piedra,
          unselectedLabelColor: PaletaRutas.plomo,
          indicatorColor: PaletaRutas.oro,
          tabs: [
            for (final estado in EstadoEditorialRuta.values)
              Tab(
                text:
                    '${estado.etiquetaPlural} (${rutas.where((r) => r.estado == estado).length})',
              ),
          ],
        ),
      ),
      body: async.isLoading && !async.hasValue
          ? const Center(
              child: CircularProgressIndicator(color: PaletaRutas.oro),
            )
          : async.hasError && !async.hasValue
          ? _EstadoVacioMisRutas(
              titulo: 'No pudimos cargar tus Rutas',
              onReintentar: () => ref.invalidate(misRutasProvider),
            )
          : TabBarView(
              controller: _tabs,
              children: [
                for (final estado in EstadoEditorialRuta.values)
                  _ListaMisRutas(
                    estado: estado,
                    rutas: rutas.where((r) => r.estado == estado).toList(),
                    onEditar: _editar,
                    onPublicar: estado == EstadoEditorialRuta.borrador
                        ? _publicar
                        : null,
                    onDesactivar: estado == EstadoEditorialRuta.publicado
                        ? _desactivar
                        : null,
                    onRestaurar: estado == EstadoEditorialRuta.archivado
                        ? _restaurar
                        : null,
                    onEliminar: estado == EstadoEditorialRuta.publicado
                        ? null
                        : _eliminar,
                    onAbrir: estado == EstadoEditorialRuta.publicado
                        ? _abrirPublica
                        : null,
                    procesando: _procesando,
                  ),
              ],
            ),
    );
  }
}

class _ListaMisRutas extends StatelessWidget {
  const _ListaMisRutas({
    required this.estado,
    required this.rutas,
    required this.onEditar,
    required this.onPublicar,
    required this.onDesactivar,
    required this.onRestaurar,
    required this.onEliminar,
    required this.onAbrir,
    required this.procesando,
  });

  final EstadoEditorialRuta estado;
  final List<ModeloRutaPropia> rutas;
  final ValueChanged<ModeloRutaPropia> onEditar;
  final ValueChanged<ModeloRutaPropia>? onPublicar;
  final ValueChanged<ModeloRutaPropia>? onDesactivar;
  final ValueChanged<ModeloRutaPropia>? onRestaurar;
  final ValueChanged<ModeloRutaPropia>? onEliminar;
  final ValueChanged<ModeloRutaPropia>? onAbrir;
  final bool procesando;

  @override
  Widget build(BuildContext context) {
    if (rutas.isEmpty) {
      return _EstadoVacioMisRutas(titulo: _vacio(estado));
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      itemCount: rutas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final propia = rutas[index];
        return _TarjetaRutaPropia(
          ruta: propia,
          onEditar: procesando ? null : () => onEditar(propia),
          onPublicar: onPublicar == null || procesando
              ? null
              : () => onPublicar!(propia),
          onDesactivar: onDesactivar == null || procesando
              ? null
              : () => onDesactivar!(propia),
          onRestaurar: onRestaurar == null || procesando
              ? null
              : () => onRestaurar!(propia),
          onEliminar: onEliminar == null || procesando
              ? null
              : () => onEliminar!(propia),
          onAbrir: onAbrir == null || procesando ? null : () => onAbrir!(propia),
        );
      },
    );
  }

  String _vacio(EstadoEditorialRuta estado) {
    return switch (estado) {
      EstadoEditorialRuta.borrador => 'No tienes borradores por ahora',
      EstadoEditorialRuta.publicado => 'Aun no tienes Rutas publicadas',
      EstadoEditorialRuta.archivado => 'No tienes Rutas desactivadas',
    };
  }
}

class _TarjetaRutaPropia extends StatelessWidget {
  const _TarjetaRutaPropia({
    required this.ruta,
    required this.onEditar,
    required this.onPublicar,
    required this.onDesactivar,
    required this.onRestaurar,
    required this.onEliminar,
    required this.onAbrir,
  });

  final ModeloRutaPropia ruta;
  final VoidCallback? onEditar;
  final VoidCallback? onPublicar;
  final VoidCallback? onDesactivar;
  final VoidCallback? onRestaurar;
  final VoidCallback? onEliminar;
  final VoidCallback? onAbrir;

  @override
  Widget build(BuildContext context) {
    final titulo = ruta.ruta.titulo.trim().isEmpty ? 'Ruta' : ruta.ruta.titulo;
    final subtitulo = [
      ruta.ruta.tipoSitio?.trim(),
      ruta.ruta.dificultadTexto.trim(),
      ruta.ruta.provincia.trim(),
    ].whereType<String>().where((v) => v.isNotEmpty).join(' - ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PaletaRutas.plomo.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 74,
              height: 74,
              child: ruta.ruta.imagenUrl.trim().isEmpty
                  ? const ColoredBox(color: PaletaRutas.ink)
                  : Image.network(ruta.ruta.imagenUrl, fit: BoxFit.cover),
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
                        titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaHaku.interfaz(
                          color: PaletaRutas.piedra,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _EstadoPill(texto: ruta.estado.etiqueta),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitulo.isEmpty
                      ? '${ruta.ruta.cantidadLugares} lugares'
                      : subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ruta.ruta.cantidadLugares} lugares - version ${ruta.version}',
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
                      _BotonMini(
                        texto: 'Ver',
                        icono: Icons.visibility_outlined,
                        onTap: onAbrir,
                      ),
                    _BotonMini(
                      texto: 'Editar',
                      icono: Icons.edit_outlined,
                      onTap: onEditar,
                    ),
                    if (onPublicar != null)
                      _BotonMini(
                        texto: 'Publicar',
                        icono: Icons.cloud_upload_outlined,
                        onTap: onPublicar,
                      ),
                    if (onDesactivar != null)
                      _BotonMini(
                        texto: 'Desactivar',
                        icono: Icons.visibility_off_outlined,
                        onTap: onDesactivar,
                      ),
                    if (onRestaurar != null)
                      _BotonMini(
                        texto: 'Restaurar',
                        icono: Icons.settings_backup_restore_rounded,
                        onTap: onRestaurar,
                      ),
                    if (onEliminar != null)
                      _BotonMini(
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

class _EstadoPill extends StatelessWidget {
  const _EstadoPill({required this.texto});

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

class _BotonMini extends StatelessWidget {
  const _BotonMini({
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

class _EstadoVacioMisRutas extends StatelessWidget {
  const _EstadoVacioMisRutas({required this.titulo, this.onReintentar});

  final String titulo;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.route_outlined,
              color: PaletaRutas.plomo,
              size: 38,
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
            if (onReintentar != null) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: onReintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
