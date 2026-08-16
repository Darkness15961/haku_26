import 'package:flutter/material.dart';

import 'dominio/modelos/perfil_publico.dart';
import 'pantallas/pantalla_perfil_ajeno.dart';

/// Abre el perfil público de otra persona.
void abrirPerfilAjeno(
  BuildContext context, {
  required String id,
  required String nombre,
  required String usuario,
  required String avatarUrl,
  String bioCorta = '',
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PantallaPerfilAjeno(
        perfil: PerfilPublico(
          id: id,
          nombre: nombre,
          usuario: usuario,
          avatarUrl: avatarUrl,
          bioCorta: bioCorta,
        ),
      ),
    ),
  );
}
