import 'package:flutter/material.dart';

import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelo_mensaje_chat.dart';
import 'burbuja_ubicacion_chat.dart';

/// Burbuja de mensaje — layout fijo y legible (sin adornos).
class BurbujaMensajeChat extends StatelessWidget {
  const BurbujaMensajeChat({
    super.key,
    required this.mensaje,
    required this.mio,
    required this.onLongPress,
    required this.onToggleReaccion,
    this.onTapAutor,
  });

  final ModeloMensajeChat mensaje;
  final bool mio;
  final VoidCallback? onLongPress;
  final void Function(String emoji) onToggleReaccion;
  final VoidCallback? onTapAutor;

  @override
  Widget build(BuildContext context) {
    final m = mensaje;
    final eliminado = m.eliminado;
    final maxW = MediaQuery.sizeOf(context).width * 0.78;

    // Stickers: sin caja pesada, solo el glyph.
    if (!eliminado && m.esSticker) {
      return Align(
        alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: mio
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!mio)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onTapAutor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          m.etiquetaAutor,
                          style: TipografiaHaku.interfaz(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: PaletaRutas.oro,
                          ),
                        ),
                      ),
                    ),
                  ),
                Text(
                  m.stickerGlyph ?? '?',
                  style: const TextStyle(fontSize: 52, height: 1.1),
                ),
                _MetaFila(
                  hora: _hora(m.fechaEnvio),
                  editado: false,
                  mio: mio,
                  claro: true,
                ),
                if (m.reacciones.isNotEmpty)
                  _Reacciones(
                    reacciones: m.reacciones,
                    onTap: onToggleReaccion,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final bg = eliminado
        ? PaletaRutas.carbon.withValues(alpha: 0.55)
        : (mio ? PaletaRutas.oro : PaletaRutas.carbon);
    final fg = eliminado
        ? PaletaRutas.plomo
        : (mio ? PaletaRutas.ink : PaletaRutas.piedra);

    return Align(
      alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: eliminado ? null : onLongPress,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(maxWidth: maxW),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(mio ? 14 : 4),
              bottomRight: Radius.circular(mio ? 4 : 14),
            ),
          ),
          child: Column(
            crossAxisAlignment: mio
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!mio && !eliminado)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTapAutor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        m.etiquetaAutor,
                        style: TipografiaHaku.interfaz(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.oro,
                        ),
                      ),
                    ),
                  ),
                ),
              if (eliminado)
                Text(
                  'Mensaje eliminado',
                  style: TipografiaHaku.interfaz(
                    fontSize: 13,
                    color: fg,
                  ).copyWith(fontStyle: FontStyle.italic),
                )
              else if (m.esUbicacion)
                m.ubicacion != null
                    ? BurbujaUbicacionChat(
                        ubicacion: m.ubicacion!,
                        sobreOscuro: !mio,
                      )
                    : Text(
                        '📍 Ubicación',
                        style: TipografiaHaku.interfaz(fontSize: 14, color: fg),
                      )
              else if (m.esImagen)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ImagenHaku(
                    url: m.contenido,
                    width: 210,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Text(
                  m.contenido,
                  style: TipografiaHaku.interfaz(
                    fontSize: 14,
                    color: fg,
                    height: 1.35,
                  ),
                ),
              const SizedBox(height: 4),
              _MetaFila(
                hora: _hora(m.fechaEnvio),
                editado: m.editado && !eliminado,
                mio: mio,
                claro: !mio || eliminado,
              ),
              if (!eliminado && m.reacciones.isNotEmpty)
                _Reacciones(reacciones: m.reacciones, onTap: onToggleReaccion),
            ],
          ),
        ),
      ),
    );
  }

  static String _hora(DateTime d) {
    final local = d.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _MetaFila extends StatelessWidget {
  const _MetaFila({
    required this.hora,
    required this.editado,
    required this.mio,
    required this.claro,
  });

  final String hora;
  final bool editado;
  final bool mio;
  final bool claro;

  @override
  Widget build(BuildContext context) {
    final color = claro
        ? PaletaRutas.plomo
        : PaletaRutas.ink.withValues(alpha: 0.55);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (editado) ...[
          Text(
            'editado',
            style: TipografiaHaku.interfaz(
              fontSize: 10,
              color: color,
            ).copyWith(fontStyle: FontStyle.italic),
          ),
          Text(
            ' · ',
            style: TipografiaHaku.interfaz(fontSize: 10, color: color),
          ),
        ],
        Text(hora, style: TipografiaHaku.interfaz(fontSize: 10, color: color)),
      ],
    );
  }
}

class _Reacciones extends StatelessWidget {
  const _Reacciones({required this.reacciones, required this.onTap});

  final List<ReaccionMensajeAgregada> reacciones;
  final void Function(String emoji) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final r in reacciones)
            InkWell(
              onTap: () => onTap(r.emoji),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: r.mia
                      ? PaletaRutas.oro.withValues(alpha: 0.22)
                      : PaletaRutas.ink.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: r.mia ? PaletaRutas.oro : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Text(
                  '${r.emoji} ${r.cantidad}',
                  style: TipografiaHaku.interfaz(
                    fontSize: 11,
                    color: PaletaRutas.piedra,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
