import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../perfil_usuario/navegacion_perfil_ajeno.dart';
import '../../rutas/datos/rutas_datasource_local.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/pantallas/pantalla_detalle_ruta.dart';
import '../../rutas/widgets/decoracion_detalle_fondo.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/feed_inicio_datasource_local.dart';

enum TipoBusquedaInicio { personas, lugares }

/// Búsqueda de personas o lugares desde Inicio.
class PantallaBusquedaInicio extends StatefulWidget {
  const PantallaBusquedaInicio({super.key});

  @override
  State<PantallaBusquedaInicio> createState() => _EstadoPantallaBusquedaInicio();
}

class _EstadoPantallaBusquedaInicio extends State<PantallaBusquedaInicio> {
  final _controller = TextEditingController();
  TipoBusquedaInicio _tipo = TipoBusquedaInicio.personas;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<SugerenciaSeguimiento> get _personas {
    final q = _query.trim().toLowerCase();
    final base = FeedInicioDataSourceLocal.sugerencias;
    if (q.isEmpty) return base;
    return base
        .where(
          (p) =>
              p.nombre.toLowerCase().contains(q) ||
              p.usuario.toLowerCase().contains(q) ||
              p.bioCorta.toLowerCase().contains(q),
        )
        .toList();
  }

  List<ModeloRuta> get _lugares {
    final q = _query.trim().toLowerCase();
    final base = RutasDataSourceLocal.obtenerTodas();
    if (q.isEmpty) return base;
    return base
        .where(
          (r) =>
              r.titulo.toLowerCase().contains(q) ||
              r.subtitulo.toLowerCase().contains(q) ||
              r.descripcion.toLowerCase().contains(q),
        )
        .toList();
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
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PaletaRutas.marronOscuro,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Buscar',
                      style: TipografiaHaku.titulo(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: PaletaRutas.marronOscuro,
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
              child: FondoSuaveSeccion(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad),
                  children: [
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      style: TipografiaHaku.interfaz(
                        fontSize: 14,
                        color: PaletaRutas.marronOscuro,
                      ),
                      decoration: InputDecoration(
                        hintText: _tipo == TipoBusquedaInicio.personas
                            ? 'Buscar personas…'
                            : 'Buscar lugares…',
                        hintStyle: TipografiaHaku.interfaz(
                          fontSize: 14,
                          color: PaletaRutas.marronOscuro.withValues(alpha: 0.45),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: PaletaRutas.marronOscuro.withValues(alpha: 0.7),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.72),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.black.withValues(alpha: 0.18),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.black.withValues(alpha: 0.18),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ChipTipo(
                            etiqueta: 'Personas',
                            icono: Icons.person_outline_rounded,
                            activo: _tipo == TipoBusquedaInicio.personas,
                            onTap: () => setState(
                              () => _tipo = TipoBusquedaInicio.personas,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ChipTipo(
                            etiqueta: 'Lugares',
                            icono: Icons.place_outlined,
                            activo: _tipo == TipoBusquedaInicio.lugares,
                            onTap: () => setState(
                              () => _tipo = TipoBusquedaInicio.lugares,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (_tipo == TipoBusquedaInicio.personas)
                      ..._personas.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _CardPersona(
                                persona: e.value,
                                indice: e.key,
                              ),
                            ),
                          )
                    else
                      ..._lugares.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _CardLugar(
                                ruta: e.value,
                                indice: e.key,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          PantallaDetalleRuta(ruta: e.value),
                                    ),
                                  );
                                },
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

class _ChipTipo extends StatelessWidget {
  final String etiqueta;
  final IconData icono;
  final bool activo;
  final VoidCallback onTap;

  const _ChipTipo({
    required this.etiqueta,
    required this.icono,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: activo
                ? Colors.black.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.black.withValues(alpha: activo ? 0.9 : 0.16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icono,
                size: 18,
                color: activo ? Colors.white : PaletaRutas.marronOscuro,
              ),
              const SizedBox(width: 6),
              Text(
                etiqueta,
                style: TipografiaHaku.interfaz(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: activo ? Colors.white : PaletaRutas.marronOscuro,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardPersona extends StatelessWidget {
  final SugerenciaSeguimiento persona;
  final int indice;

  const _CardPersona({required this.persona, required this.indice});

  @override
  Widget build(BuildContext context) {
    final veloNegro = indice.isEven;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => abrirPerfilAjeno(
          context,
          id: persona.id,
          nombre: persona.nombre,
          usuario: persona.usuario,
          avatarUrl: persona.avatarUrl,
          bioCorta: persona.bioCorta,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
            image: DecorationImage(
              image: AssetImage(FondosDetalleHaku.porIndice(indice)),
              fit: BoxFit.cover,
              opacity: 0.45,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: veloNegro
                  ? Colors.black.withValues(alpha: 0.62)
                  : Colors.white.withValues(alpha: 0.78),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: persona.avatarUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const ColoredBox(
                          color: Color(0xFFBBBBBB),
                          child: SizedBox(width: 48, height: 48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            persona.nombre,
                            style: TipografiaHaku.interfaz(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: veloNegro
                                  ? Colors.white
                                  : PaletaRutas.marronOscuro,
                            ),
                          ),
                          Text(
                            persona.usuario,
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: (veloNegro
                                      ? Colors.white
                                      : PaletaRutas.marronOscuro)
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            persona.bioCorta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaHaku.interfaz(
                              fontSize: 12,
                              color: (veloNegro
                                      ? Colors.white
                                      : PaletaRutas.marronOscuro)
                                  .withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardLugar extends StatelessWidget {
  final ModeloRuta ruta;
  final int indice;
  final VoidCallback onTap;

  const _CardLugar({
    required this.ruta,
    required this.indice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 1.1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.8),
            child: SizedBox(
              height: 92,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: ruta.imagenUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const ColoredBox(color: Color(0xFFD4C8B8)),
                  ),
                  ColoredBox(
                    color: indice.isEven
                        ? Colors.black.withValues(alpha: 0.55)
                        : Colors.black.withValues(alpha: 0.42),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          ruta.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TipografiaHaku.titulo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          ruta.subtitulo.isEmpty
                              ? ruta.dificultadTexto
                              : ruta.subtitulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
