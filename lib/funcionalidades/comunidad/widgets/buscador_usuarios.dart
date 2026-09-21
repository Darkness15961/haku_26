import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../../nucleo/widgets/avatar_haku.dart';
import '../../rutas/widgets/estilos_rutas.dart';

class BuscadorUsuarios extends ConsumerStatefulWidget {
  final List<String> usuariosExcluidos;
  final ValueChanged<Map<String, dynamic>> onSeleccionado;

  const BuscadorUsuarios({
    super.key,
    required this.usuariosExcluidos,
    required this.onSeleccionado,
  });

  @override
  ConsumerState<BuscadorUsuarios> createState() => _EstadoBuscadorUsuarios();
}

class _EstadoBuscadorUsuarios extends ConsumerState<BuscadorUsuarios> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _resultados = [];
  bool _cargando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _buscar(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final txt = query.trim();
      if (txt.isEmpty) {
        setState(() {
          _resultados = [];
          _cargando = false;
        });
        return;
      }
      setState(() => _cargando = true);
      try {
        final res = await clienteSupabase
            .from('usuario')
            .select('id, nombre_nick, foto_perfil')
            .ilike('nombre_nick', '%$txt%')
            .limit(10);

        final lista = List<Map<String, dynamic>>.from(res as List);
        // Filtrar los excluidos
        final filtrados = lista
            .where((u) => !widget.usuariosExcluidos.contains(u['id'] as String))
            .toList();

        if (mounted) {
          setState(() {
            _resultados = filtrados;
            _cargando = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _resultados = [];
            _cargando = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          onChanged: _buscar,
          style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
          cursorColor: PaletaRutas.oro,
          decoration: InputDecoration(
            hintText: 'Buscar por @usuario',
            hintStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomo),
            filled: true,
            fillColor: PaletaRutas.carbon,
            prefixIcon: const Icon(Icons.search, color: PaletaRutas.plomo),
            suffixIcon: _cargando
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PaletaRutas.oro,
                      ),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: PaletaRutas.plomo.withValues(alpha: 0.4),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: PaletaRutas.plomo.withValues(alpha: 0.4),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PaletaRutas.oro),
            ),
          ),
        ),
        if (_resultados.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: PaletaRutas.carbon,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PaletaRutas.plomo.withValues(alpha: 0.2),
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _resultados.length,
              itemBuilder: (context, i) {
                final u = _resultados[i];
                return ListTile(
                  leading: AvatarHaku(
                    size: 32,
                    url: u['foto_perfil'] as String?,
                  ),
                  title: Text(
                    '@${u['nombre_nick']}',
                    style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                  ),
                  onTap: () {
                    widget.onSeleccionado(u);
                    _ctrl.clear();
                    setState(() {
                      _resultados = [];
                    });
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
