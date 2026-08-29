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
          style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
        ),
        backgroundColor: PaletaRutas.carbon,
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
        backgroundColor: PaletaRutas.carbon,
        title: Text(
          'Reiniciar',
          style: TipografiaHaku.titulo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
        content: Text(
          'Se recarga la semilla.',
          style: TipografiaHaku.interfaz(
            fontSize: 14,
            color: PaletaRutas.plomoClaro,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Reiniciar',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: PaletaRutas.oro,
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
          style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
        ),
        backgroundColor: PaletaRutas.carbon,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(sesionProvider);
    final bottom = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: FondoSuaveSeccion(
        color: PaletaRutas.ink,
        opacidadImagen: 0,
        opacidadVelo: 0,
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
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Configuración',
                        style: TipografiaHaku.titulo(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
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
                        color: PaletaRutas.carbon,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
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
                              color: PaletaRutas.piedra,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _nombre,
                            style: TipografiaHaku.interfaz(
                              color: PaletaRutas.piedra,
                            ),
                            cursorColor: PaletaRutas.oro,
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              labelStyle: TipografiaHaku.interfaz(
                                color: PaletaRutas.plomoClaro,
                              ),
                              filled: true,
                              fillColor: PaletaRutas.ink,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: PaletaRutas.plomoOscuro.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: PaletaRutas.plomoOscuro.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: PaletaRutas.oro,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sesion.usuario?.correo ?? 'Sin sesión',
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: PaletaRutas.plomo,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _guardarNombre,
                              style: FilledButton.styleFrom(
                                backgroundColor: PaletaRutas.oro,
                                foregroundColor: PaletaRutas.ink,
                              ),
                              child: Text(
                                'Guardar',
                                style: TipografiaHaku.interfaz(
                                  fontWeight: FontWeight.w700,
                                  color: PaletaRutas.ink,
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
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icono, color: PaletaRutas.piedra),
          title: Text(
            titulo,
            style: TipografiaHaku.interfaz(
              fontWeight: FontWeight.w700,
              color: PaletaRutas.piedra,
            ),
          ),
          subtitle: subtitulo.isEmpty
              ? null
              : Text(
                  subtitulo,
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
          trailing: const Icon(
            Icons.chevron_right,
            color: PaletaRutas.plomo,
          ),
        ),
      ),
    );
  }
}
