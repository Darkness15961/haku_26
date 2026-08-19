import 'package:flutter/material.dart';

import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../rutas/dominio/modelos/modelo_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';

/// Mosaico visual de los 5 hilos de cultura viva.
class MosaicoHilosCultura extends StatelessWidget {
  const MosaicoHilosCultura({
    super.key,
    required this.rutas,
    required this.onHilo,
  });

  final List<ModeloRuta> rutas;
  final ValueChanged<HiloCultura> onHilo;

  ModeloRuta? _porHilo(HiloCultura h) {
    for (final r in rutas) {
      if (r.hilo == h) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tejido = _porHilo(HiloCultura.tejido);
    final ceramica = _porHilo(HiloCultura.ceramica);
    final comida = _porHilo(HiloCultura.comida);
    final teatro = _porHilo(HiloCultura.teatro);
    final pintura = _porHilo(HiloCultura.pintura);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cultura viva',
            textAlign: TextAlign.center,
            style: TipografiaHaku.titulo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toca un hilo para explorarlo',
            textAlign: TextAlign.center,
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              color: PaletaRutas.marronCuero,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _Celda(
                    ruta: tejido,
                    hilo: HiloCultura.tejido,
                    onTap: () => onHilo(HiloCultura.tejido),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: _Celda(
                          ruta: ceramica,
                          hilo: HiloCultura.ceramica,
                          onTap: () => onHilo(HiloCultura.ceramica),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _Celda(
                          ruta: comida,
                          hilo: HiloCultura.comida,
                          onTap: () => onHilo(HiloCultura.comida),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: Row(
              children: [
                Expanded(
                  child: _Celda(
                    ruta: teatro,
                    hilo: HiloCultura.teatro,
                    onTap: () => onHilo(HiloCultura.teatro),
                    compacto: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Celda(
                    ruta: pintura,
                    hilo: HiloCultura.pintura,
                    onTap: () => onHilo(HiloCultura.pintura),
                    compacto: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const LineaEncabezadoInca(altura: 2),
        ],
      ),
    );
  }
}

class _Celda extends StatelessWidget {
  const _Celda({
    required this.ruta,
    required this.hilo,
    required this.onTap,
    this.compacto = false,
  });

  final ModeloRuta? ruta;
  final HiloCultura hilo;
  final VoidCallback onTap;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final img = ruta?.imagenUrl ?? CatalogoImagenesHaku.respaldo;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImagenHaku(url: img, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(compacto ? 10 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: PaletaRutas.terracota.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          hilo.etiqueta.toUpperCase(),
                          style: TipografiaHaku.interfaz(
                            fontSize: compacto ? 8 : 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (ruta != null && !compacto)
                        Text(
                          ruta!.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TipografiaHaku.titulo(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
