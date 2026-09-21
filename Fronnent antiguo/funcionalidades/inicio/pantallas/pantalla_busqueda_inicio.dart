import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/widgets/avatar_haku.dart';
import '../../perfil_usuario/navegacion_perfil_ajeno.dart';
import '../../lugares/datos/lugares_datasource_local.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../lugares/pantallas/pantalla_detalle_lugar.dart';
import '../../rutas/datos/rutas_datasource_local.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/pantallas/pantalla_detalle_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../proveedores/proveedor_almacen_feed.dart';

enum TipoBusquedaInicio { personas, lugares }

class _ResultadoLugarBusqueda {
  const _ResultadoLugarBusqueda({
    required this.titulo,
    required this.subtitulo,
    required this.imagenUrl,
    this.lugarId,
    this.ruta,
  });

  final String titulo;
  final String subtitulo;
  final String imagenUrl;
  final String? lugarId;
  final ModeloRuta? ruta;
}

/// Búsqueda de personas o lugares desde Inicio.
class PantallaBusquedaInicio extends ConsumerStatefulWidget {
  const PantallaBusquedaInicio({super.key});

  @override
  ConsumerState<PantallaBusquedaInicio> createState() =>
      _EstadoPantallaBusquedaInicio();
}

class _EstadoPantallaBusquedaInicio
    extends ConsumerState<PantallaBusquedaInicio> {
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
    final feed = ref.watch(almacenFeedProvider);
    final base = feed.perfiles.isNotEmpty
        ? feed.perfiles
        : FeedInicioDataSourceLocal.sugerencias;
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

  String? _lugarIdParaRuta(ModeloRuta r) {
    if (r.id.startsWith('lugar_')) {
      return r.id.substring('lugar_'.length);
    }
    final titulo = r.titulo.trim().toLowerCase();
    for (final l in LugaresDataSourceLocal.instancia.todos()) {
      if (l.nombre.trim().toLowerCase() == titulo) return l.id;
    }
    return null;
  }

  List<_ResultadoLugarBusqueda> get _lugares {
    final q = _query.trim().toLowerCase();
    final resultados = <_ResultadoLugarBusqueda>[];
    final idsLugar = <String>{};

    for (final l in LugaresDataSourceLocal.instancia.todos()) {
      final match = q.isEmpty ||
          l.nombre.toLowerCase().contains(q) ||
          l.provincia.toLowerCase().contains(q) ||
          l.descripcion.toLowerCase().contains(q);
      if (match) {
        idsLugar.add(l.id);
        resultados.add(
          _ResultadoLugarBusqueda(
            titulo: l.nombre,
            subtitulo: '${l.provincia} · ${l.categoria.etiqueta}',
            imagenUrl: l.imagenUrl,
            lugarId: l.id,
          ),
        );
      }
    }

    for (final r in RutasDataSourceLocal.obtenerTodas()) {
      final idLugar = _lugarIdParaRuta(r);
      if (idLugar != null) {
        if (idsLugar.contains(idLugar)) continue;
        final l = LugaresDataSourceLocal.instancia.porId(idLugar);
        if (l != null) {
          idsLugar.add(l.id);
          resultados.add(
            _ResultadoLugarBusqueda(
              titulo: l.nombre,
              subtitulo: '${l.provincia} · ${l.categoria.etiqueta}',
              imagenUrl: l.imagenUrl,
              lugarId: l.id,
            ),
          );
          continue;
        }
      }
      final match = q.isEmpty ||
          r.titulo.toLowerCase().contains(q) ||
          r.subtitulo.toLowerCase().contains(q) ||
          r.descripcion.toLowerCase().contains(q);
      if (match) {
        resultados.add(
          _ResultadoLugarBusqueda(
            titulo: r.titulo,
            subtitulo: r.subtitulo.isEmpty ? r.dificultadTexto : r.subtitulo,
            imagenUrl: r.imagenUrl,
            ruta: r,
          ),
        );
      }
    }
    return resultados;
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
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Buscar',
                      style: TipografiaHaku.titulo(
                        fontSize: 22,
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
                padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad),
                children: [
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: (v) => setState(() => _query = v),
                    style: TipografiaHaku.interfaz(
                      fontSize: 14,
                      color: PaletaRutas.piedra,
                    ),
                    cursorColor: PaletaRutas.oro,
                    decoration: InputDecoration(
                      hintText: _tipo == TipoBusquedaInicio.personas
                          ? 'Personas'
                          : 'Lugares',
                      hintStyle: TipografiaHaku.interfaz(
                        fontSize: 14,
                        color: PaletaRutas.plomo,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: PaletaRutas.plomoClaro,
                      ),
                      filled: true,
                      fillColor: PaletaRutas.carbon,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: PaletaRutas.oro,
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
                              titulo: e.value.titulo,
                              subtitulo: e.value.subtitulo,
                              imagenUrl: e.value.imagenUrl,
                              indice: e.key,
                              onTap: () {
                                if (e.value.lugarId != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => PantallaDetalleLugar(
                                        lugarId: e.value.lugarId!,
                                      ),
                                    ),
                                  );
                                } else if (e.value.ruta != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => PantallaDetalleRuta(
                                        ruta: e.value.ruta!,
                                      ),
                                    ),
                                  );
                                }
                              },
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
            color: activo ? PaletaRutas.oro : PaletaRutas.carbon,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: activo
                  ? PaletaRutas.oro
                  : PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icono,
                size: 18,
                color: activo ? PaletaRutas.ink : PaletaRutas.plomoClaro,
              ),
              const SizedBox(width: 6),
              Text(
                etiqueta,
                style: TipografiaHaku.interfaz(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: activo ? PaletaRutas.ink : PaletaRutas.plomoClaro,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardPersona extends ConsumerWidget {
  final SugerenciaSeguimiento persona;
  final int indice;

  const _CardPersona({required this.persona, required this.indice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => abrirPerfilAjeno(
          context,
          ref,
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
            color: PaletaRutas.carbon,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            children: [
              AvatarHaku(url: persona.avatarUrl, size: 48),
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
                        color: PaletaRutas.piedra,
                      ),
                    ),
                    Text(
                      persona.usuario,
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: PaletaRutas.plomoClaro,
                      ),
                    ),
                    Text(
                      persona.bioCorta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: PaletaRutas.plomo,
                      ),
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

class _CardLugar extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String imagenUrl;
  final int indice;
  final VoidCallback onTap;

  const _CardLugar({
    required this.titulo,
    required this.subtitulo,
    required this.imagenUrl,
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
            border: Border.all(
              color: PaletaRutas.plomoOscuro.withValues(alpha: 0.7),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.8),
            child: SizedBox(
              height: 92,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imagenUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const ColoredBox(color: PaletaRutas.carbon),
                  ),
                  ColoredBox(
                    color: PaletaRutas.ink.withValues(
                      alpha: indice.isEven ? 0.55 : 0.42,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TipografiaHaku.titulo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                        Text(
                          subtitulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TipografiaHaku.interfaz(
                            fontSize: 12,
                            color: PaletaRutas.plomoClaro,
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
