import 'package:flutter/material.dart';

import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../rutas/widgets/estilos_rutas.dart';

IconData iconoCategoriaComunidad(CategoriaLugar c) {
  switch (c) {
    case CategoriaLugar.naturaleza:
      return Icons.park_outlined;
    case CategoriaLugar.cultura:
      return Icons.account_balance_outlined;
    case CategoriaLugar.gastronomia:
      return Icons.restaurant_outlined;
    case CategoriaLugar.aventura:
      return Icons.terrain_outlined;
    case CategoriaLugar.caminata:
      return Icons.hiking;
    case CategoriaLugar.fotografia:
      return Icons.photo_camera_outlined;
    case CategoriaLugar.misterioso:
      return Icons.nightlight_outlined;
    case CategoriaLugar.magico:
      return Icons.auto_awesome_outlined;
  }
}

class ChipCategoriaComunidad extends StatelessWidget {
  final CategoriaLugar categoria;
  final bool seleccionado;
  final VoidCallback? onTap;
  final bool compacto;
  final bool sobreOscuro;

  const ChipCategoriaComunidad({
    super.key,
    required this.categoria,
    this.seleccionado = false,
    this.onTap,
    this.compacto = false,
    this.sobreOscuro = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = seleccionado
        ? PaletaRutas.oro
        : sobreOscuro
            ? PaletaRutas.piedra
            : PaletaRutas.plomoClaro;
    final bg = seleccionado
        ? PaletaRutas.oro.withValues(alpha: 0.18)
        : sobreOscuro
            ? PaletaRutas.piedra.withValues(alpha: 0.12)
            : PaletaRutas.carbon;
    final borderColor = seleccionado
        ? PaletaRutas.oro
        : sobreOscuro
            ? PaletaRutas.plomo.withValues(alpha: 0.35)
            : PaletaRutas.plomoOscuro.withValues(alpha: 0.7);

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compacto ? 8 : 10,
            vertical: compacto ? 4 : 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                iconoCategoriaComunidad(categoria),
                size: compacto ? 13 : 16,
                color: fg,
              ),
              const SizedBox(width: 5),
              Text(
                categoria.etiqueta,
                style: TipografiaHaku.interfaz(
                  fontSize: compacto ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
