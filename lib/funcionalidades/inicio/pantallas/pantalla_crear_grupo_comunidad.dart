import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../rutas/datos/rutas_datasource_local.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../datos/mensajes_datasource_local.dart';

/// Formulario: crear grupo de mensajería (nombre, personas, ruta).
class PantallaCrearGrupo extends StatefulWidget {
  const PantallaCrearGrupo({super.key});

  @override
  State<PantallaCrearGrupo> createState() => _EstadoPantallaCrearGrupo();
}

class _EstadoPantallaCrearGrupo extends State<PantallaCrearGrupo> {
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

  void _crear() {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un nombre para el grupo'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_invitados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invita al menos a una persona'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_rutaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elige una ruta para el grupo'),
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

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Grupo "$nombre" creado · ${ruta.titulo} · ${_invitados.length} invitados. '
          'Al finalizar la ruta (solo tú) se eliminará el grupo.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withValues(alpha: 0.9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EncabezadoSeccion(
              titulo: 'Crear grupo',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: FondoSuaveSeccion(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad),
                  children: [
                    Text(
                      'Nombre del grupo',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.marronOscuro,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nombreCtrl,
                      style: TipografiaHaku.interfaz(fontSize: 14),
                      decoration: _inputDecoration('Ej. Trek Humantay'),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Personas a invitar',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.marronOscuro,
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
                        secondary: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: p.avatarUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const ColoredBox(
                              color: Color(0xFFBBBBBB),
                              child: SizedBox(width: 40, height: 40),
                            ),
                          ),
                        ),
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
                            color: PaletaRutas.marronOscuro
                                .withValues(alpha: 0.65),
                          ),
                        ),
                        activeColor: Colors.black,
                      );
                    }),
                    const SizedBox(height: 16),
                    Text(
                      'Ruta que harán',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.marronOscuro,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cuando finalices la ruta como creador, el grupo se eliminará.',
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: PaletaRutas.marronOscuro.withValues(alpha: 0.65),
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
                                    ? Colors.black.withValues(alpha: 0.88)
                                    : Colors.white.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.black
                                      .withValues(alpha: sel ? 0.9 : 0.16),
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
                                                ? Colors.white
                                                : PaletaRutas.marronOscuro,
                                          ),
                                        ),
                                        Text(
                                          '${r.dias} d · ${r.dificultadTexto}',
                                          style: TipografiaHaku.interfaz(
                                            fontSize: 12,
                                            color: (sel
                                                    ? Colors.white
                                                    : PaletaRutas.marronOscuro)
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (sel)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
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
                          backgroundColor: Colors.black.withValues(alpha: 0.92),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Crear grupo',
                          style: TipografiaHaku.interfaz(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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

/// Formulario: crear comunidad (nombre + personas invitadas).
class PantallaCrearComunidad extends StatefulWidget {
  const PantallaCrearComunidad({super.key});

  @override
  State<PantallaCrearComunidad> createState() => _EstadoPantallaCrearComunidad();
}

class _EstadoPantallaCrearComunidad extends State<PantallaCrearComunidad> {
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final Set<String> _invitados = {};

  List<SugerenciaSeguimiento> get _personas =>
      FeedInicioDataSourceLocal.sugerencias;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _crear() {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un nombre para la comunidad'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_invitados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invita al menos a una persona'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final desc = _descCtrl.text.trim().isEmpty
        ? 'Comunidad creada en Haku'
        : _descCtrl.text.trim();

    MensajeriaEstado.instancia.agregarComunidad(
      ComunidadHaku(
        id: 'com_${DateTime.now().millisecondsSinceEpoch}',
        nombre: nombre,
        descripcion: desc,
        miembros: 1 + _invitados.length,
        imagenUrl:
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&q=80',
        invitadosIds: _invitados.toList(),
      ),
    );

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Comunidad "$nombre" creada · ${_invitados.length} invitados',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withValues(alpha: 0.9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: Colors.white,
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
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad),
                  children: [
                    Text(
                      'Nombre de comunidad',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.marronOscuro,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nombreCtrl,
                      style: TipografiaHaku.interfaz(fontSize: 14),
                      decoration: _inputDecoration('Ej. Trekkers Cusco'),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Descripción (opcional)',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.marronOscuro,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      style: TipografiaHaku.interfaz(fontSize: 14),
                      decoration: _inputDecoration(
                        'De qué trata tu comunidad…',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Personas que invitas',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.marronOscuro,
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
                        secondary: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: p.avatarUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const ColoredBox(
                              color: Color(0xFFBBBBBB),
                              child: SizedBox(width: 40, height: 40),
                            ),
                          ),
                        ),
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
                            color: PaletaRutas.marronOscuro
                                .withValues(alpha: 0.65),
                          ),
                        ),
                        activeColor: Colors.black,
                      );
                    }),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _crear,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.92),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Crear comunidad',
                          style: TipografiaHaku.interfaz(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
      color: PaletaRutas.marronOscuro.withValues(alpha: 0.45),
    ),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.75),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.18)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.18)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black, width: 1.2),
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
                  color: PaletaRutas.marronOscuro,
                ),
              ),
              Expanded(
                child: Text(
                  titulo,
                  style: TipografiaHaku.titulo(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.marronOscuro,
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
