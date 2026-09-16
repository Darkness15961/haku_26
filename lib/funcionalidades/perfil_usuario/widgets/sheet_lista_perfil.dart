import 'package:flutter/material.dart';

import '../../rutas/widgets/estilos_rutas.dart';

/// Fila simple para sheets del perfil.
class ItemListaPerfil {
  final String titulo;
  final String? subtitulo;
  final VoidCallback? onTap;

  const ItemListaPerfil({
    required this.titulo,
    this.subtitulo,
    this.onTap,
  });
}

/// Lista corta y clara (lugares / rutas / posts / salidas del perfil).
Future<void> mostrarSheetListaPerfil(
  BuildContext context, {
  required String titulo,
  required List<ItemListaPerfil> items,
  String vacio =
      'Todavía no hay nada acá. Cuando aportes, aparece en esta lista.',
  IconData iconoVacio = Icons.inbox_outlined,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: PaletaRutas.carbon,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      final maxH = MediaQuery.sizeOf(ctx).height * 0.58;
      return SafeArea(
        child: SizedBox(
          height: maxH,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
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
                Text(
                  titulo,
                  style: TipografiaHaku.titulo(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.piedra,
                  ),
                ),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              iconoVacio,
                              size: 36,
                              color: PaletaRutas.plomo.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              vacio,
                              textAlign: TextAlign.center,
                              style: TipografiaHaku.interfaz(
                                fontSize: 13,
                                color: PaletaRutas.plomoClaro,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color:
                            PaletaRutas.plomoOscuro.withValues(alpha: 0.45),
                      ),
                      itemBuilder: (context, i) {
                        final it = items[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 2,
                          ),
                          title: Text(
                            it.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaHaku.interfaz(
                              fontWeight: FontWeight.w700,
                              color: PaletaRutas.piedra,
                            ),
                          ),
                          subtitle: it.subtitulo == null
                              ? null
                              : Text(
                                  it.subtitulo!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TipografiaHaku.interfaz(
                                    fontSize: 12,
                                    color: PaletaRutas.plomoClaro,
                                  ),
                                ),
                          trailing: it.onTap == null
                              ? null
                              : const Icon(
                                  Icons.chevron_right,
                                  color: PaletaRutas.plomo,
                                ),
                          onTap: it.onTap == null
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  it.onTap!();
                                },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
