import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../autenticacion/proveedores/proveedor_sesion.dart';
import '../../comunidad/pantallas/pantalla_salidas.dart';
import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../dominio/modelos/modelo_lugar.dart';
import '../proveedores/proveedor_lugares.dart';
import 'pantalla_detalle_lugar.dart';
import 'pantalla_registrar_lugar.dart';

/// Inicio = descubrir: Sorpréndeme, intereses, para ti, recientes, salidas, registrar.
class PantallaInicioDescubrir extends ConsumerWidget {
  const PantallaInicioDescubrir({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider);
    final nombre = sesion.usuario?.nombreUsuario ?? 'explorador';
    final intereses = ref.watch(interesesUsuarioProvider);
    final ds = ref.watch(lugaresDataSourceProvider);
    ref.watch(lugaresVersionProvider);

    final paraTi = ds.porIntereses(intereses).take(4).toList();
    final recientes = ds.recientes().take(4).toList();
    final bottom = MediaQuery.paddingOf(context).bottom + 110;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FondoSuaveSeccion(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottom),
            children: [
              Text(
                'Hola, $nombre',
                style: TipografiaHaku.titulo(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              BotonPrimarioRuta(
                texto: 'Sorpréndeme',
                icono: Icons.auto_awesome,
                onPressed: () {
                  final l = ds.sorpresa(intereses: intereses);
                  abrirDetalleLugar(context, l.id);
                },
              ),
              const SizedBox(height: 22),
              Text(
                'Intereses',
                style: TipografiaHaku.titulo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: CategoriaLugar.values.map((c) {
                    final on = intereses.contains(c);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c.etiqueta),
                        selected: on,
                        onSelected: (v) {
                          final next = {...intereses};
                          if (v) {
                            next.add(c);
                          } else {
                            next.remove(c);
                          }
                          ref.read(interesesUsuarioProvider.notifier).state =
                              next;
                        },
                        selectedColor: PaletaRutas.pergamino,
                        labelStyle: TipografiaHaku.interfaz(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Para ti',
                style: TipografiaHaku.titulo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ...paraTi.map((l) => _CardLugarDescubrir(lugar: l)),
              const SizedBox(height: 18),
              Text(
                'Nuevos',
                style: TipografiaHaku.titulo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (recientes.isEmpty)
                Text(
                  'Todavía no hay nada',
                  style: TipografiaHaku.interfaz(color: PaletaRutas.marronCuero),
                )
              else
                ...recientes.map((l) => _CardReciente(lugar: l)),
              const SizedBox(height: 18),
              Text(
                'Salidas',
                style: TipografiaHaku.titulo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _CardSalidaTeaser(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PantallaSalidas(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
              BotonSecundarioRuta(
                texto: 'Agregar',
                icono: Icons.add_location_alt_outlined,
                onPressed: () => abrirRegistrarLugarFlow(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardLugarDescubrir extends StatelessWidget {
  const _CardLugarDescubrir({required this.lugar});
  final ModeloLugar lugar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: PaletaRutas.crema,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => abrirDetalleLugar(context, lugar.id),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: lugar.imagenUrl.startsWith('assets/')
                        ? Image.asset(lugar.imagenUrl, fit: BoxFit.cover)
                        : CachedNetworkImage(
                            imageUrl: lugar.imagenUrl,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lugar.nombre,
                        style: TipografiaHaku.titulo(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${lugar.categoria.etiqueta} · ${lugar.distanciaKm.toStringAsFixed(0)} km',
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          color: PaletaRutas.marronCuero,
                        ),
                      ),
                      Text(
                        '★ ${lugar.calificacion} · ${lugar.exploradores}',
                        style: TipografiaHaku.interfaz(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Descubrir',
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: PaletaRutas.verdeBosque,
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

class _CardReciente extends StatelessWidget {
  const _CardReciente({required this.lugar});
  final ModeloLugar lugar;

  @override
  Widget build(BuildContext context) {
    final dias = lugar.descubiertoEn == null
        ? 0
        : DateTime.now().difference(lugar.descubiertoEn!).inDays;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          lugar.nombre,
          style: TipografiaHaku.titulo(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$dias d · ${lugar.fotos} fotos · ${lugar.exploradores}',
          style: TipografiaHaku.interfaz(fontSize: 12, color: PaletaRutas.marronCuero),
        ),
        trailing: TextButton(
          onPressed: () => abrirDetalleLugar(context, lugar.id),
          child: Text(
            'Explorar',
            style: TipografiaHaku.interfaz(
              fontWeight: FontWeight.w700,
              color: PaletaRutas.verdeBosque,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardSalidaTeaser extends StatelessWidget {
  const _CardSalidaTeaser({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PaletaRutas.beigeEnvejecido),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laguna Humantay',
                      style: TipografiaHaku.titulo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '6/8 personas · Sábado · 6:00 AM',
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: PaletaRutas.marronCuero,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Me apunto',
                style: TipografiaHaku.interfaz(
                  fontWeight: FontWeight.w800,
                  color: PaletaRutas.terracota,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
