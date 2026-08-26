import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/metricas/metricas_descubrimiento.dart';
import '../../../nucleo/recursos/catalogo_imagenes_haku.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../comunidad/datos/salidas_datasource_local.dart';
import '../../comunidad/pantallas/pantalla_salidas.dart';
import '../../perfil_usuario/navegacion_perfil_ajeno.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../datos/feed_inicio_datasource_local.dart';
import '../proveedores/proveedor_almacen_feed.dart';

/// Post de comunidad: invitación a salida en grupo (fecha, cupo, Unirse).
class CardInvitacionGrupo extends ConsumerWidget {
  const CardInvitacionGrupo({
    super.key,
    required this.publicacion,
  });

  final PublicacionFeed publicacion;

  String _fechaCorta(DateTime f) {
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${f.day} ${meses[f.month - 1]}';
  }

  Future<void> _abrirDetalle(BuildContext context) async {
    final id = publicacion.salidaId;
    if (id == null || id.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaDetalleSalida(salidaId: id),
      ),
    );
  }

  Future<void> _unirse(BuildContext context, WidgetRef ref, ModeloSalida s) async {
    final ok = await asegurarSesion(context, ref);
    if (!ok || !context.mounted) return;
    final uid = AlmacenFeedNotifier.idUsuarioLocal;
    if (s.unido(uid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ya estás en este grupo',
            style: TipografiaHaku.interfaz(color: Colors.white),
          ),
          backgroundColor: PaletaRutas.carbon,
        ),
      );
      return;
    }
    final done = SalidasDataSourceLocal.instancia.enrolar(s.id, usuarioId: uid);
    if (done) {
      await ref
          .read(metricasDescubrimientoProvider.notifier)
          .registrarEnrolamiento(s.id);
      bumpMetricas(ref);
      await ref.read(almacenFeedProvider.notifier).persistirSatelites();
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          done ? 'Te uniste a la salida' : 'No hay cupos o ya estás inscrito',
          style: TipografiaHaku.interfaz(color: Colors.white),
        ),
        backgroundColor: PaletaRutas.carbon,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(almacenFeedProvider);
    final salidaId = publicacion.salidaId ?? '';
    final s = SalidasDataSourceLocal.instancia.porId(salidaId);
    final uid = AlmacenFeedNotifier.idUsuarioLocal;
    final yaUnido = s?.unido(uid) ?? false;
    final imagen =
        publicacion.imagenUrl ?? CatalogoImagenesHaku.respaldo;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _abrirDetalle(context),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ImagenHaku(url: imagen, fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x33000000),
                              Color(0xCC141210),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: PaletaRutas.oro,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'SALIDA EN GRUPO',
                            style: TipografiaHaku.interfaz(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: PaletaRutas.ink,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                      if (s != null)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: s.llena
                                  ? const Color(0xFF8B3A3A)
                                  : const Color(0xFF2F6B5A),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              s.llena
                                  ? 'Sin cupos'
                                  : s.esDeGrupo
                                      ? '${s.inscritos}/${s.cuposTotales}'
                                      : '${s.inscritos}/${s.cupos} cupos',
                              style: TipografiaHaku.interfaz(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Text(
                          s?.lugarNombre ??
                              publicacion.lugarNombre ??
                              'Nueva ruta',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TipografiaHaku.titulo(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: PaletaRutas.piedra,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        abrirPerfilAjeno(
                          context,
                          ref,
                          id: publicacion.autorId.isNotEmpty
                              ? publicacion.autorId
                              : publicacion.usuario,
                          nombre: publicacion.autor,
                          usuario: publicacion.usuario,
                          avatarUrl: publicacion.avatarUrl,
                        );
                      },
                      child: Text(
                        'Organiza ${publicacion.autor}',
                        style: TipografiaHaku.interfaz(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.oro,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      publicacion.texto,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TipografiaHaku.interfaz(
                        fontSize: 13,
                        height: 1.35,
                        color: PaletaRutas.piedra.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (s != null) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DatoChip(
                            icono: Icons.event_outlined,
                            texto: '${_fechaCorta(s.fecha)} · ${s.hora}',
                          ),
                          _DatoChip(
                            icono: Icons.place_outlined,
                            texto: s.puntoEncuentro,
                          ),
                          _DatoChip(
                            icono: Icons.person_add_alt_1_outlined,
                            texto: '${s.cupos} abiertos',
                          ),
                          if (s.esDeGrupo) ...[
                            _DatoChip(
                              icono: Icons.groups_outlined,
                              texto: '${s.cuposGrupo} del grupo',
                            ),
                            _DatoChip(
                              icono: Icons.hiking,
                              texto: s.grupo,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _abrirDetalle(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: PaletaRutas.piedra,
                                side: BorderSide(
                                  color: PaletaRutas.plomo.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Ver detalle',
                                style: TipografiaHaku.interfaz(
                                  fontWeight: FontWeight.w700,
                                  color: PaletaRutas.piedra,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: s.llena && !yaUnido
                                  ? null
                                  : () => _unirse(context, ref, s),
                              style: FilledButton.styleFrom(
                                backgroundColor: yaUnido
                                    ? PaletaRutas.plomoOscuro
                                    : PaletaRutas.oro,
                                foregroundColor: PaletaRutas.ink,
                                disabledBackgroundColor:
                                    PaletaRutas.plomoOscuro,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                yaUnido
                                    ? 'Ya unido'
                                    : s.llena
                                        ? 'Sin cupos'
                                        : 'Unirse',
                                style: TipografiaHaku.interfaz(
                                  fontWeight: FontWeight.w800,
                                  color: yaUnido || s.llena
                                      ? PaletaRutas.piedra
                                      : PaletaRutas.ink,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      Text(
                        'Salida no disponible',
                        style: TipografiaHaku.interfaz(
                          color: PaletaRutas.plomoClaro,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatoChip extends StatelessWidget {
  const _DatoChip({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: PaletaRutas.ink.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PaletaRutas.plomoOscuro.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: PaletaRutas.oro),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TipografiaHaku.interfaz(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PaletaRutas.piedra,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
