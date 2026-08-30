import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/recursos/copy_haku.dart';
import '../../../nucleo/demo/senales_atencion.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../comunidad/datos/salidas_datasource_local.dart';
import '../../comunidad/pantallas/pantalla_salidas.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../publicaciones/pantallas/pantalla_publicaciones.dart';
import '../dominio/modelos/modelo_ruta.dart';
import '../pantallas/pantalla_mapa_ruta.dart';
import 'boton_icono_accion.dart';
import 'estilos_rutas.dart';
import 'menu_acciones_flotante.dart';

/// Menú + unificado para ficha de lugar o ruta.
class MenuAccionesDetalle extends ConsumerWidget {
  const MenuAccionesDetalle.lugar({
    super.key,
    required this.lugar,
    required this.abierto,
    required this.onToggle,
    required this.onCerrar,
  })  : ruta = null,
        _modo = _ModoMenu.lugar;

  const MenuAccionesDetalle.ruta({
    super.key,
    required this.ruta,
    required this.abierto,
    required this.onToggle,
    required this.onCerrar,
  })  : lugar = null,
        _modo = _ModoMenu.ruta;

  final ModeloLugar? lugar;
  final ModeloRuta? ruta;
  final bool abierto;
  final VoidCallback onToggle;
  final VoidCallback onCerrar;
  final _ModoMenu _modo;

  Future<void> _publicar(BuildContext context, WidgetRef ref) async {
    onCerrar();
    final ok = await asegurarSesion(context, ref);
    if (!ok || !context.mounted) return;

    final id = _modo == _ModoMenu.lugar ? lugar!.id : ruta!.id;
    final titulo = _modo == _ModoMenu.lugar ? lugar!.nombre : ruta!.titulo;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaPublicaciones(
          rutaId: id,
          rutaTitulo: titulo,
          irAComunidadAlPublicar: false,
        ),
      ),
    );
  }

  Future<void> _compartir(BuildContext context) async {
    onCerrar();
    final texto = switch (_modo) {
      _ModoMenu.lugar =>
        CopyHaku.compartirLugar(
          lugar!.nombre,
          lugar!.categoria.etiqueta,
          lugar!.provincia,
        ),
      _ModoMenu.ruta =>
        CopyHaku.compartirRuta(
          ruta!.titulo,
          ruta!.distancia.isNotEmpty
              ? ruta!.distancia
              : '${ruta!.dias} día${ruta!.dias == 1 ? '' : 's'}',
        ),
    };
    await Clipboard.setData(ClipboardData(text: texto));
    if (!context.mounted) return;
    mostrarSnackHaku(
      context,
      _modo == _ModoMenu.lugar ? 'Enlace del lugar copiado' : 'Ruta copiada',
      destacado: true,
    );
  }

  void _salidas(BuildContext context) {
    onCerrar();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaSalidas(lugarId: lugar!.id),
      ),
    );
  }

  void _mapa(BuildContext context) {
    onCerrar();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaMapaRuta(ruta: ruta!),
      ),
    );
  }

  List<Widget> _opciones(BuildContext context, WidgetRef ref) {
    return [
      BotonIconoAccion(
        tooltip:
            _modo == _ModoMenu.lugar ? 'Compartir lugar' : 'Compartir ruta',
        icono: Icons.ios_share_rounded,
        onTap: () => _compartir(context),
      ),
      ...switch (_modo) {
        _ModoMenu.lugar => _opcionesLugar(context),
        _ModoMenu.ruta => _opcionesRuta(context),
      },
      BotonIconoAccion(
        tooltip: 'Publicar experiencia',
        icono: Icons.add_a_photo_outlined,
        onTap: () => _publicar(context, ref),
      ),
    ];
  }

  List<Widget> _opcionesLugar(BuildContext context) {
    final nSalidas =
        SalidasDataSourceLocal.instancia.todas(lugarId: lugar!.id).length;
    final badge = SenalesAtencion.contadorSalidasLugar(lugar!.id);
    return [
      BotonIconoAccion(
        tooltip: nSalidas == 0 ? 'Ver salidas' : 'Ver salidas ($nSalidas)',
        icono: Icons.groups_rounded,
        destacado: nSalidas > 0,
        badge: badge,
        onTap: () => _salidas(context),
      ),
    ];
  }

  List<Widget> _opcionesRuta(BuildContext context) {
    if (ruta!.puntos.isEmpty) return const [];
    return [
      BotonIconoAccion(
        tooltip: 'Ver mapa · ${ruta!.puntos.length} paradas',
        icono: Icons.map_outlined,
        destacado: true,
        badge: '${ruta!.puntos.length}',
        onTap: () => _mapa(context),
      ),
    ];
  }

  int get _contadorFab => switch (_modo) {
        _ModoMenu.lugar =>
          SenalesAtencion.contadorMenuDetalleLugar(lugar!.id),
        _ModoMenu.ruta => SenalesAtencion.contadorMenuDetalleRuta(ruta!),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenuAccionesFlotante(
      abierto: abierto,
      onToggle: onToggle,
      contador: _contadorFab,
      opciones: _opciones(context, ref),
    );
  }
}

enum _ModoMenu { lugar, ruta }
