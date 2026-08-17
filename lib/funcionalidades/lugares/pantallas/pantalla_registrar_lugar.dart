import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../nucleo/metricas/metricas_descubrimiento.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../dominio/modelos/modelo_lugar.dart';
import '../proveedores/proveedor_lugares.dart';

/// Wizard corto: registrar un lugar nuevo (captura Fase 1).
class PantallaRegistrarLugar extends ConsumerStatefulWidget {
  const PantallaRegistrarLugar({super.key});

  @override
  ConsumerState<PantallaRegistrarLugar> createState() =>
      _EstadoPantallaRegistrarLugar();
}

class _EstadoPantallaRegistrarLugar
    extends ConsumerState<PantallaRegistrarLugar> {
  final _nombre = TextEditingController();
  final _experiencia = TextEditingController();
  final _picker = ImagePicker();

  int _paso = 0;
  XFile? _foto;
  CategoriaLugar _categoria = CategoriaLugar.naturaleza;
  String _acceso = 'Caminando';
  String _dificultad = 'Medio';
  bool _usandoUbicacion = false;

  @override
  void dispose() {
    _nombre.dispose();
    _experiencia.dispose();
    super.dispose();
  }

  Future<void> _siguiente() async {
    if (_paso == 0) {
      if (_nombre.text.trim().isEmpty) {
        _aviso('Ponle un nombre al lugar');
        return;
      }
    }
    if (_paso < 4) {
      setState(() => _paso++);
      return;
    }
    await _finalizar();
  }

  Future<void> _finalizar() async {
    final id = 'lugar_${DateTime.now().millisecondsSinceEpoch}';
    final lugar = ModeloLugar(
      id: id,
      nombre: _nombre.text.trim(),
      descripcion: _experiencia.text.trim().isEmpty
          ? 'Documentado por la comunidad HAKU.'
          : _experiencia.text.trim(),
      imagenUrl: _foto?.path ??
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
      categoria: _categoria,
      provincia: 'Cusco',
      distrito: _usandoUbicacion ? 'Ubicación actual' : 'Por confirmar',
      distanciaKm: 0,
      calificacion: 5,
      exploradores: 1,
      fotos: _foto == null ? 0 : 1,
      nivelExploracion: NivelExploracion.nuevoEnHaku,
      dificultad: _dificultad,
      acceso: _acceso,
      descubiertoEn: DateTime.now(),
      creadoPorUsuario: true,
    );

    ref.read(lugaresDataSourceProvider).agregar(lugar);
    notificarLugaresCambiaron(ref);
    ref.read(metricasDescubrimientoProvider.notifier).registrarDescubrimiento(
          id,
          fuente: 'registrar_lugar',
        );
    bumpMetricas(ref);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PaletaRutas.crema,
        title: Text(
          '¡Nuevo lugar para HAKU!',
          style: TipografiaHaku.titulo(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Acabas de documentar un descubrimiento.\n+50 puntos de descubrimiento',
          style: TipografiaHaku.interfaz(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Continuar',
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: PaletaRutas.verdeBosque,
              ),
            ),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop(lugar);
  }

  void _aviso(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, style: TipografiaHaku.interfaz(color: Colors.white)),
        backgroundColor: PaletaRutas.marronOscuro,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: PaletaRutas.marronOscuro,
        elevation: 0,
        title: Text(
          'Registrar lugar',
          style: TipografiaHaku.titulo(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: FondoSuaveSeccion(
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Paso ${_paso + 1} de 5',
                style: TipografiaHaku.interfaz(
                  fontSize: 12,
                  color: PaletaRutas.marronCuero,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (_paso + 1) / 5,
                backgroundColor: PaletaRutas.beigeEnvejecido,
                color: PaletaRutas.verdeBosque,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 10),
              const LineaEncabezadoInca(altura: 2),
              const SizedBox(height: 18),
              Expanded(child: _contenidoPaso()),
              BotonPrimarioRuta(
                texto: _paso == 4 ? 'Publicar descubrimiento' : 'Continuar',
                onPressed: _siguiente,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _contenidoPaso() {
    switch (_paso) {
      case 0:
        return ListView(
          children: [
            Text(
              '¿Qué descubriste?',
              style: TipografiaHaku.titulo(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final f = await _picker.pickImage(source: ImageSource.gallery);
                if (f != null) setState(() => _foto = f);
              },
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(
                _foto == null ? 'Agregar fotografía' : 'Foto lista',
                style: TipografiaHaku.interfaz(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: PaletaRutas.marronOscuro,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: PaletaRutas.marronCuero),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Usar ubicación actual',
                style: TipografiaHaku.interfaz(fontWeight: FontWeight.w600),
              ),
              value: _usandoUbicacion,
              activeColor: PaletaRutas.verdeBosque,
              onChanged: (v) => setState(() => _usandoUbicacion = v),
            ),
            TextField(
              controller: _nombre,
              decoration: InputDecoration(
                labelText: 'Nombre del lugar',
                labelStyle: TipografiaHaku.interfaz(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      case 1:
        return ListView(
          children: [
            Text(
              '¿Qué tipo de lugar es?',
              style: TipografiaHaku.titulo(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CategoriaLugar.values.map((c) {
                final sel = c == _categoria;
                return ChoiceChip(
                  label: Text(c.etiqueta),
                  selected: sel,
                  onSelected: (_) => setState(() => _categoria = c),
                  selectedColor: PaletaRutas.pergamino,
                  labelStyle: TipografiaHaku.interfaz(
                    fontWeight: FontWeight.w700,
                    color: PaletaRutas.marronOscuro,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      case 2:
        return ListView(
          children: [
            Text(
              '¿Cómo llegaste?',
              style: TipografiaHaku.titulo(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...['Auto', 'Transporte', 'Caminando', 'Caballo'].map((a) {
              return RadioListTile<String>(
                title: Text(a, style: TipografiaHaku.interfaz()),
                value: a,
                groupValue: _acceso,
                activeColor: PaletaRutas.verdeBosque,
                onChanged: (v) => setState(() => _acceso = v!),
              );
            }),
          ],
        );
      case 3:
        return ListView(
          children: [
            Text(
              '¿Qué tan difícil fue?',
              style: TipografiaHaku.titulo(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...['Fácil', 'Medio', 'Difícil'].map((d) {
              return RadioListTile<String>(
                title: Text(d, style: TipografiaHaku.interfaz()),
                value: d,
                groupValue: _dificultad,
                activeColor: PaletaRutas.verdeBosque,
                onChanged: (v) => setState(() => _dificultad = v!),
              );
            }),
          ],
        );
      default:
        return ListView(
          children: [
            Text(
              'Comparte tu experiencia',
              style: TipografiaHaku.titulo(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _experiencia,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: '¿Qué viste? ¿Qué deberían saber otros?',
                hintStyle: TipografiaHaku.interfaz(color: PaletaRutas.marronCuero),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
    }
  }
}

Future<void> abrirRegistrarLugarFlow(
  BuildContext context,
  WidgetRef ref,
) async {
  final ok = await asegurarSesion(context, ref);
  if (!ok || !context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const PantallaRegistrarLugar(),
    ),
  );
}
