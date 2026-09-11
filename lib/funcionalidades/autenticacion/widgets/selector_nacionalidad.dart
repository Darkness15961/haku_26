import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelos/modelo_nacionalidad.dart';
import '../pantallas/pantalla_iniciar_sesion.dart';

/// Campo tappable + sheet con búsqueda (no dropdown eterno).
class SelectorNacionalidad extends StatelessWidget {
  const SelectorNacionalidad({
    super.key,
    required this.seleccionada,
    required this.cargando,
    required this.error,
    required this.onTap,
  });

  final ModeloNacionalidad? seleccionada;
  final bool cargando;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texto = seleccionada?.etiqueta;
    return InkWell(
      onTap: cargando ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isEmpty: texto == null,
        decoration: decoracionCampoAuth(
          cargando
              ? 'Cargando países…'
              : (error ?? 'Toca para buscar tu país'),
          icono: Icons.public_outlined,
          suffix: Icon(
            Icons.search_rounded,
            color: PaletaRutas.plomoClaro,
          ),
        ),
        child: Text(
          texto ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TipografiaHaku.interfaz(
            fontSize: 14,
            color: PaletaRutas.piedra,
          ),
        ),
      ),
    );
  }
}

/// Abre sheet modal: busca por nombre o código ISO.
Future<ModeloNacionalidad?> abrirBusquedaNacionalidad(
  BuildContext context, {
  required List<ModeloNacionalidad> opciones,
  ModeloNacionalidad? actual,
}) {
  return showModalBottomSheet<ModeloNacionalidad>(
    context: context,
    isScrollControlled: true,
    backgroundColor: PaletaRutas.carbon,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      return _SheetBusquedaNacionalidad(
        opciones: opciones,
        actual: actual,
      );
    },
  );
}

class _SheetBusquedaNacionalidad extends StatefulWidget {
  const _SheetBusquedaNacionalidad({
    required this.opciones,
    this.actual,
  });

  final List<ModeloNacionalidad> opciones;
  final ModeloNacionalidad? actual;

  @override
  State<_SheetBusquedaNacionalidad> createState() =>
      _EstadoSheetBusquedaNacionalidad();
}

class _EstadoSheetBusquedaNacionalidad
    extends State<_SheetBusquedaNacionalidad> {
  final _busqueda = TextEditingController();
  late List<ModeloNacionalidad> _filtradas;

  @override
  void initState() {
    super.initState();
    _filtradas = widget.opciones;
    _busqueda.addListener(_filtrar);
  }

  @override
  void dispose() {
    _busqueda.removeListener(_filtrar);
    _busqueda.dispose();
    super.dispose();
  }

  void _filtrar() {
    final q = _busqueda.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtradas = widget.opciones;
        return;
      }
      _filtradas = widget.opciones.where((n) {
        return n.nombre.toLowerCase().contains(q) ||
            n.codigoIso.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final alto = MediaQuery.sizeOf(context).height * 0.72;

    return SizedBox(
      height: alto,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PaletaRutas.plomo.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Nacionalidad',
              style: TipografiaHaku.titulo(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: PaletaRutas.piedra,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _busqueda,
              autofocus: true,
              style: TipografiaHaku.interfaz(
                fontSize: 14,
                color: PaletaRutas.piedra,
              ),
              cursorColor: PaletaRutas.oro,
              decoration: decoracionCampoAuth(
                'Escribe país o código (PE, MX…)',
                icono: Icons.search_rounded,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filtradas.isEmpty
                ? Center(
                    child: Text(
                      'Sin coincidencias',
                      style: TipografiaHaku.interfaz(
                        fontSize: 14,
                        color: PaletaRutas.plomo,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(8, 0, 8, bottom + 12),
                    itemCount: _filtradas.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: PaletaRutas.plomo.withValues(alpha: 0.2),
                    ),
                    itemBuilder: (context, i) {
                      final n = _filtradas[i];
                      final sel = widget.actual?.id == n.id;
                      return ListTile(
                        title: Text(
                          n.nombre,
                          style: TipografiaHaku.interfaz(
                            fontSize: 15,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w500,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                        subtitle: n.codigoIso.isEmpty
                            ? null
                            : Text(
                                n.codigoIso,
                                style: TipografiaHaku.interfaz(
                                  fontSize: 12,
                                  color: PaletaRutas.plomoClaro,
                                ),
                              ),
                        trailing: sel
                            ? const Icon(
                                Icons.check_rounded,
                                color: PaletaRutas.oro,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(n),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
