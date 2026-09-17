import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/servicios/politica_nickname.dart';

class FormateadorNicknameMinusculas extends TextInputFormatter {
  const FormateadorNicknameMinusculas();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = newValue.text.toLowerCase();
    int ajustar(int offset) {
      if (offset < 0) return offset;
      return offset > texto.length ? texto.length : offset;
    }

    return newValue.copyWith(
      text: texto,
      selection: TextSelection(
        baseOffset: ajustar(newValue.selection.baseOffset),
        extentOffset: ajustar(newValue.selection.extentOffset),
      ),
      composing: TextRange.empty,
    );
  }
}

class BotonAyudaNickname extends StatelessWidget {
  const BotonAyudaNickname({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Reglas del nickname',
      visualDensity: VisualDensity.compact,
      onPressed: () => _mostrarAyuda(context),
      icon: const Icon(
        Icons.info_outline_rounded,
        size: 19,
        color: PaletaRutas.oro,
      ),
    );
  }

  Future<void> _mostrarAyuda(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PaletaRutas.carbon,
        title: Text(
          'Tu nickname en HAKU',
          style: TipografiaHaku.titulo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Será tu nombre público en publicaciones, salidas, comunidades y mensajes.',
              style: TipografiaHaku.interfaz(
                height: 1.4,
                color: PaletaRutas.plomoClaro,
              ),
            ),
            const SizedBox(height: 14),
            const _ReglaNickname(texto: 'Entre 3 y 30 caracteres.'),
            const _ReglaNickname(texto: 'Letras, números y guion bajo (_).'),
            const _ReglaNickname(
              texto: 'Comienza y termina con una letra o número.',
            ),
            const _ReglaNickname(
              texto: 'Sin espacios, tildes ni otros símbolos.',
            ),
            const _ReglaNickname(
              texto: 'Es único y las mayúsculas pasan a minúsculas.',
            ),
            const SizedBox(height: 12),
            Text(
              'Ejemplo: @viajero_cusco',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: PaletaRutas.oro,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

class _ReglaNickname extends StatelessWidget {
  const _ReglaNickname({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 17,
              color: PaletaRutas.oro,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TipografiaHaku.interfaz(
                fontSize: 13,
                height: 1.35,
                color: PaletaRutas.plomoClaro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<TextInputFormatter> formateadoresNickname() => [
  const FormateadorNicknameMinusculas(),
];

String? validarNickname(String raw) => PoliticaNickname.validar(raw);
