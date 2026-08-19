import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/almacenamiento/almacenamiento_haku.dart';
import '../../../nucleo/metricas/metricas_descubrimiento.dart';
import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../inicio/proveedores/proveedor_almacen_feed.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';

/// Configuración simulada (sesión + BD local).
class PantallaConfiguracion extends ConsumerStatefulWidget {
  const PantallaConfiguracion({super.key});

  @override
  ConsumerState<PantallaConfiguracion> createState() =>
      _EstadoPantallaConfiguracion();
}

class _EstadoPantallaConfiguracion
    extends ConsumerState<PantallaConfiguracion> {
  late final TextEditingController _nombre;

  @override
  void initState() {
    super.initState();
    final u = ref.read(sesionProvider).usuario;
    _nombre = TextEditingController(text: u?.nombreUsuario ?? 'Explorador HAKU');
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardarNombre() async {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) return;
    final sesion = ref.read(sesionProvider);
    if (!sesion.autenticado || sesion.usuario == null) {
      ref.read(sesionProvider.notifier).iniciarSesion(
            correo: 'explorador@haku.local',
            nombreUsuario: nombre,
          );
    } else {
      ref.read(sesionProvider.notifier).actualizarNombre(nombre);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Listo',
          style: TipografiaHaku.interfaz(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    ref.read(sesionProvider.notifier).cerrarSesion();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _resetBd() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Reiniciar',
          style: TipografiaHaku.titulo(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Se recarga la semilla.',
          style: TipografiaHaku.interfaz(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Reiniciar',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: PaletaRutas.terracota,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final db = await AlmacenamientoHaku.abrir();
    await db.borrar();
    await ref.read(almacenFeedProvider.notifier).cargar();
    await ref.read(metricasDescubrimientoProvider.notifier).reiniciarDemo();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reiniciado',
          style: TipografiaHaku.interfaz(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(sesionProvider);
    final bottom = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FondoSuaveSeccion(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: PaletaRutas.marronOscuro,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Configuración',
                        style: TipografiaHaku.titulo(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: LineaEncabezadoInca(altura: 2),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cuenta',
                            style: TipografiaHaku.titulo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _nombre,
                            style: TipografiaHaku.interfaz(color: Colors.white),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              labelStyle: TipografiaHaku.interfaz(
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sesion.usuario?.correo ?? 'Sin sesión',
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _guardarNombre,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: PaletaRutas.marronOscuro,
                              ),
                              child: Text(
                                'Guardar',
                                style: TipografiaHaku.interfaz(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _TileConfig(
                      icono: Icons.logout_rounded,
                      titulo: 'Salir',
                      subtitulo: '',
                      onTap: _cerrarSesion,
                    ),
                    _TileConfig(
                      icono: Icons.restart_alt_rounded,
                      titulo: 'Reiniciar',
                      subtitulo: '',
                      onTap: _resetBd,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileConfig extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _TileConfig({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icono, color: Colors.white),
          title: Text(
            titulo,
            style: TipografiaHaku.interfaz(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          subtitle: subtitulo.isEmpty
              ? null
              : Text(
                  subtitulo,
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        ),
      ),
    );
  }
}
