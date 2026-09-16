import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';

/// Resultado del sheet de creación de chat grupal (solo elige modo; no crea).
enum OpcionCrearChatGrupal {
  /// Incluir a todos (aprobados / confirmados) al confirmar.
  todos,

  /// Elegir personas y crear recién al pulsar «Crear chat».
  elegir,
}

/// Pregunta al admin/org cómo quiere armar el chat. No crea nada todavía.
Future<OpcionCrearChatGrupal?> mostrarSheetCrearChatGrupal(
  BuildContext context, {
  required String tituloContexto,
}) {
  return showModalBottomSheet<OpcionCrearChatGrupal>(
    context: context,
    backgroundColor: PaletaRutas.carbon,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      Widget tile({
        required IconData icon,
        required String title,
        required String subtitle,
        required OpcionCrearChatGrupal value,
      }) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: PaletaRutas.ink,
            child: Icon(icon, color: PaletaRutas.oro, size: 22),
          ),
          title: Text(
            title,
            style: TipografiaHaku.interfaz(
              fontWeight: FontWeight.w700,
              color: PaletaRutas.piedra,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              color: PaletaRutas.plomoClaro,
            ),
          ),
          onTap: () => Navigator.pop(ctx, value),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: PaletaRutas.plomoOscuro,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  '¿Cómo querés armar el chat?',
                  style: TipografiaHaku.titulo(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: PaletaRutas.piedra,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  'Todavía no hay chat en $tituloContexto. '
                  'Elegí un modo; el chat se crea solo cuando confirmes.',
                  style: TipografiaHaku.interfaz(
                    fontSize: 13,
                    color: PaletaRutas.plomoClaro,
                    height: 1.35,
                  ),
                ),
              ),
              tile(
                icon: Icons.groups_rounded,
                title: 'Agregar a todos',
                subtitle: 'Después confirmás y entran todos',
                value: OpcionCrearChatGrupal.todos,
              ),
              tile(
                icon: Icons.person_search_rounded,
                title: 'Elegir quiénes',
                subtitle: 'Marcás personas y creás al guardar',
                value: OpcionCrearChatGrupal.elegir,
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Ahora no',
                  style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Confirmación explícita antes de crear con todos.
Future<bool> confirmarCrearChatConTodos(
  BuildContext context, {
  required String tituloContexto,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: PaletaRutas.carbon,
        title: Text(
          'Crear chat grupal',
          style: TipografiaHaku.titulo(fontSize: 18, color: PaletaRutas.piedra),
        ),
        content: Text(
          'Se va a crear el chat de $tituloContexto e incluir '
          'a todos los miembros / confirmados actuales.\n\n'
          '¿Confirmás?',
          style: TipografiaHaku.interfaz(
            color: PaletaRutas.plomoClaro,
            height: 1.4,
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
              'Crear chat',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w800,
                color: PaletaRutas.oro,
              ),
            ),
          ),
        ],
      );
    },
  );
  return ok == true;
}
