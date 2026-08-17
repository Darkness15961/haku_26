import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../inicio/datos/feed_inicio_datasource_local.dart';
import '../inicio/pantallas/pantalla_exploradores_deslizables.dart';
import '../inicio/proveedores/proveedor_almacen_feed.dart';

/// Abre el perfil público desde la BD local (mismos IDs que el feed).
void abrirPerfilAjeno(
  BuildContext context,
  WidgetRef ref, {
  required String id,
  required String nombre,
  required String usuario,
  required String avatarUrl,
  String bioCorta = '',
}) {
  final estado = ref.read(almacenFeedProvider);
  final conocidos = estado.perfiles.isNotEmpty
      ? estado.perfiles
      : FeedInicioDataSourceLocal.sugerencias;
  final match = conocidos.where((s) => s.id == id || s.usuario == usuario);
  final persona = match.isNotEmpty
      ? match.first
      : SugerenciaSeguimiento.demo(
          id: id,
          nombre: nombre,
          usuario: usuario,
          avatarUrl: avatarUrl,
          bioCorta: bioCorta,
        );
  final indice = match.isNotEmpty
      ? conocidos.indexWhere((s) => s.id == persona.id)
      : 0;

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PantallaExploradoresDeslizables(
        exploradores: match.isNotEmpty ? conocidos : [persona],
        indiceInicial: indice < 0 ? 0 : indice,
      ),
    ),
  );
}
