import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/widgets/avatar_haku.dart';
import '../../comunidad/pantallas/pantalla_detalle_comunidad.dart';
import '../../comunidad/widgets/chip_categoria_comunidad.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../rutas/datos/rutas_datasource_local.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../datos/mensajes_datasource_local.dart';
import '../proveedores/proveedor_almacen_feed.dart';

/// Formulario: crear grupo de mensajería (nombre, personas, ruta).
class PantallaCrearGrupo extends ConsumerStatefulWidget {
  const PantallaCrearGrupo({super.key});

  @override
  ConsumerState<PantallaCrearGrupo> createState() => _EstadoPantallaCrearGrupo();
}

class _EstadoPantallaCrearGrupo extends ConsumerState<PantallaCrearGrupo> {
  final _nombreCtrl = TextEditingController();
  final Set<String> _invitados = {};
  String? _rutaId;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  List<SugerenciaSeguimiento> get _personas =>
      FeedInicioDataSourceLocal.sugerencias;

  List<ModeloRuta> get _rutas => RutasDataSourceLocal.obtenerTodas();

  Future<void> _crear() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_invitados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invita'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_rutaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elige ruta'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ruta = RutasDataSourceLocal.obtenerPorId(_rutaId!);
    if (ruta == null) return;

    MensajeriaEstado.instancia.agregarGrupo(
      GrupoRuta.crear(
        nombre: nombre,
        ruta: ruta,
        miembroIds: _invitados.toList(),
      ),
    );
    await ref.read(almacenFeedProvider.notifier).persistirSatelites();
    if (!mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Equipo "$nombre" creado'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withValues(alpha: 0.9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EncabezadoSeccion(
              titulo: 'Crear equipo de ruta',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: FondoSuaveSeccion(
                color: PaletaRutas.ink,
                opacidadImagen: 0,
                opacidadVelo: 0,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad),
                  children: [
                    Text(
                      'Nombre',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nombreCtrl,
                      style: TipografiaHaku.interfaz(
                        fontSize: 14,
                        color: PaletaRutas.piedra,
                      ),
                      cursorColor: PaletaRutas.oro,
                      decoration: _inputDecoration('Ej. Trek Humantay'),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Invitar',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._personas.map((p) {
                      final sel = _invitados.contains(p.id);
                      return CheckboxListTile(
                        value: sel,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _invitados.add(p.id);
                            } else {
                              _invitados.remove(p.id);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.trailing,
                        contentPadding: EdgeInsets.zero,
                        secondary: AvatarHaku(url: p.avatarUrl, size: 40),
                        title: Text(
                          p.nombre,
                          style: TipografiaHaku.interfaz(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          p.usuario,
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            color: PaletaRutas.plomoClaro,
                          ),
                        ),
                        activeColor: PaletaRutas.oro,
                      );
                    }),
                    const SizedBox(height: 16),
                    Text(
                      'Ruta',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Se elimina al terminar.',
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: PaletaRutas.plomoClaro,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._rutas.map((r) {
                      final sel = _rutaId == r.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _rutaId = r.id),
                            borderRadius: BorderRadius.circular(14),
                            child: Ink(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: sel
                                    ? PaletaRutas.oro.withValues(alpha: 0.18)
                                    : PaletaRutas.carbon,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: sel
                                      ? PaletaRutas.oro
                                      : PaletaRutas.plomoOscuro.withValues(
                                          alpha: 0.7,
                                        ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: r.imagenUrl,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) =>
                                          const ColoredBox(
                                        color: Color(0xFFD4C8B8),
                                        child: SizedBox(width: 52, height: 52),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.titulo,
                                          style: TipografiaHaku.interfaz(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: sel
                                                ? PaletaRutas.oro
                                                : PaletaRutas.piedra,
                                          ),
                                        ),
                                        Text(
                                          '${r.dias} d · ${r.dificultadTexto}',
                                          style: TipografiaHaku.interfaz(
                                            fontSize: 12,
                                            color: (sel
                                                    ? PaletaRutas.oro
                                                    : PaletaRutas.plomoClaro)
                                                .withValues(alpha: 0.85),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (sel)
                                    const Icon(
                                      Icons.check_circle,
                                      color: PaletaRutas.oro,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _crear,
                        style: FilledButton.styleFrom(
                          backgroundColor: PaletaRutas.oro,
                          foregroundColor: PaletaRutas.ink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Crear',
                          style: TipografiaHaku.interfaz(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulario: crear comunidad (nombre, categorías, personas).
class PantallaCrearComunidad extends ConsumerStatefulWidget {
  const PantallaCrearComunidad({super.key});

  @override
  ConsumerState<PantallaCrearComunidad> createState() =>
      _EstadoPantallaCrearComunidad();
}

class _EstadoPantallaCrearComunidad
    extends ConsumerState<PantallaCrearComunidad> {
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final Set<String> _invitados = {};
  final Set<CategoriaLugar> _categorias = {};

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_categorias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categoría'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final desc = _descCtrl.text.trim().isEmpty
        ? 'Comunidad'
        : _descCtrl.text.trim();

    final id = await ref.read(almacenFeedProvider.notifier).crearComunidad(
          nombre: nombre,
          descripcion: desc,
          categorias: _categorias.toList(),
          invitadosIds: _invitados.toList(),
        );

    if (!mounted) return;
    Navigator.of(context).pop(true);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaDetalleComunidad(comunidadId: id),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Comunidad "$nombre" creada',
          style: TipografiaHaku.interfaz(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withValues(alpha: 0.9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 24;
    final personas = ref.watch(almacenFeedProvider).exploradores;
    final lista =
        personas.isEmpty ? FeedInicioDataSourceLocal.sugerencias : personas;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EncabezadoSeccion(
              titulo: 'Crear comunidad',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: FondoSuaveSeccion(
                color: PaletaRutas.ink,
                opacidadImagen: 0,
                opacidadVelo: 0,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad),
                  children: [
                    Text(
                      'Nombre',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nombreCtrl,
                      style: TipografiaHaku.interfaz(
                        fontSize: 14,
                        color: PaletaRutas.piedra,
                      ),
                      cursorColor: PaletaRutas.oro,
                      decoration: _inputDecoration('Ej. Trekkers Cusco'),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Categorías',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final cat in CategoriaLugar.values)
                          ChipCategoriaComunidad(
                            categoria: cat,
                            seleccionado: _categorias.contains(cat),
                            onTap: () {
                              setState(() {
                                if (_categorias.contains(cat)) {
                                  _categorias.remove(cat);
                                } else {
                                  _categorias.add(cat);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Descripción',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      style: TipografiaHaku.interfaz(
                        fontSize: 14,
                        color: PaletaRutas.piedra,
                      ),
                      cursorColor: PaletaRutas.oro,
                      decoration: _inputDecoration(
                        'De qué trata tu comunidad…',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Invitar',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...lista.map((p) {
                      final sel = _invitados.contains(p.id);
                      return CheckboxListTile(
                        value: sel,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _invitados.add(p.id);
                            } else {
                              _invitados.remove(p.id);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.trailing,
                        contentPadding: EdgeInsets.zero,
                        secondary: AvatarHaku(url: p.avatarUrl, size: 40),
                        title: Text(
                          p.nombre,
                          style: TipografiaHaku.interfaz(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          p.usuario,
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            color: PaletaRutas.plomoClaro,
                          ),
                        ),
                        activeColor: PaletaRutas.oro,
                      );
                    }),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _crear,
                        style: FilledButton.styleFrom(
                          backgroundColor: PaletaRutas.oro,
                          foregroundColor: PaletaRutas.ink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Crear',
                          style: TipografiaHaku.interfaz(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TipografiaHaku.interfaz(
      fontSize: 14,
      color: PaletaRutas.plomo,
    ),
    filled: true,
    fillColor: PaletaRutas.carbon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: PaletaRutas.oro, width: 1.2),
    ),
  );
}

class _EncabezadoSeccion extends StatelessWidget {
  final String titulo;
  final VoidCallback onBack;

  const _EncabezadoSeccion({
    required this.titulo,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: PaletaRutas.piedra,
                ),
              ),
              Expanded(
                child: Text(
                  titulo,
                  style: TipografiaHaku.titulo(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.piedra,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: LineaEncabezadoInca(altura: 2),
          ),
        ],
      ),
    );
  }
}
