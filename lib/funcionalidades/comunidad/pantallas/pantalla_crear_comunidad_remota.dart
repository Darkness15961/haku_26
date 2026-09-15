import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../proveedores/proveedor_comunidad.dart';
import 'pantalla_detalle_comunidad.dart';

/// Alta remota de `public.comunidad`.
/// Campos = columnas reales: nombre, descripcion?, tipo, foto_portada?.
class PantallaCrearComunidadRemota extends ConsumerStatefulWidget {
  const PantallaCrearComunidadRemota({super.key});

  @override
  ConsumerState<PantallaCrearComunidadRemota> createState() =>
      _EstadoPantallaCrearComunidadRemota();
}

class _EstadoPantallaCrearComunidadRemota
    extends ConsumerState<PantallaCrearComunidadRemota> {
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _picker = ImagePicker();
  XFile? _foto;
  Uint8List? _fotoBytes;
  String _tipo = 'publico';
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _foto = file;
      _fotoBytes = bytes;
    });
  }

  Future<void> _crear() async {
    if (_guardando) return;
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      mostrarSnackHaku(context, 'Escribe un nombre');
      return;
    }

    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    final uid = clienteSupabase.auth.currentUser?.id;
    if (uid == null) {
      mostrarSnackHaku(context, 'Inicia sesión');
      return;
    }

    setState(() => _guardando = true);
    try {
      final ds = ref.read(comunidadRemotoDataSourceProvider);
      String? fotoUrl;
      if (_foto != null && _fotoBytes != null) {
        final name = _foto!.name.toLowerCase();
        final ext = name.endsWith('.png')
            ? 'png'
            : (name.endsWith('.webp') ? 'webp' : 'jpg');
        final contentType = ext == 'png'
            ? 'image/png'
            : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
        fotoUrl = await ds.subirFotoPortada(
          userId: uid,
          bytes: _fotoBytes!,
          contentType: contentType,
          extension: ext,
        );
      }

      final desc = _descCtrl.text.trim();
      final creada = await ds.crear(
        nombre: nombre,
        descripcion: desc.isEmpty ? null : desc,
        tipo: _tipo,
        fotoPortadaUrl: fotoUrl,
      );

      notificarComunidadesCambiaron(ref);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PantallaDetalleComunidad(comunidadId: creada.id),
        ),
      );
    } on AuthException catch (e) {
      if (mounted) mostrarSnackHaku(context, e.message);
    } catch (e) {
      if (mounted) {
        mostrarSnackHaku(context, 'No se pudo crear la comunidad');
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomo),
        filled: true,
        fillColor: PaletaRutas.carbon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PaletaRutas.plomo.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PaletaRutas.plomo.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PaletaRutas.oro),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: PaletaRutas.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _guardando
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Crear comunidad',
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
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
                children: [
                  Text(
                    'Portada (opcional)',
                    style: TipografiaHaku.titulo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Material(
                      color: PaletaRutas.carbon,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _guardando ? null : _elegirFoto,
                        child: _fotoBytes != null
                            ? Image.memory(_fotoBytes!, fit: BoxFit.cover)
                            : (_foto != null
                                ? ImagenHaku(url: _foto!.path, fit: BoxFit.cover)
                                : Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: PaletaRutas.plomo
                                              .withValues(alpha: 0.9),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Sin foto = sin portada en BD',
                                          style: TipografiaHaku.interfaz(
                                            fontSize: 12,
                                            color: PaletaRutas.plomoClaro,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Nombre',
                    style: TipografiaHaku.titulo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nombreCtrl,
                    enabled: !_guardando,
                    style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                    cursorColor: PaletaRutas.oro,
                    decoration: _deco('Ej. Trekkers Cusco'),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Tipo',
                    style: TipografiaHaku.titulo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Pública'),
                        selected: _tipo == 'publico',
                        onSelected: _guardando
                            ? null
                            : (_) => setState(() => _tipo = 'publico'),
                        selectedColor: PaletaRutas.oro.withValues(alpha: 0.25),
                        labelStyle: TipografiaHaku.interfaz(
                          color: PaletaRutas.piedra,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Privada'),
                        selected: _tipo == 'privado',
                        onSelected: _guardando
                            ? null
                            : (_) => setState(() => _tipo = 'privado'),
                        selectedColor: PaletaRutas.oro.withValues(alpha: 0.25),
                        labelStyle: TipografiaHaku.interfaz(
                          color: PaletaRutas.piedra,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Descripción (opcional)',
                    style: TipografiaHaku.titulo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.piedra,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descCtrl,
                    enabled: !_guardando,
                    maxLines: 3,
                    style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                    cursorColor: PaletaRutas.oro,
                    decoration: _deco('Vacío se guarda como NULL'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _guardando ? null : _crear,
                      style: FilledButton.styleFrom(
                        backgroundColor: PaletaRutas.oro,
                        foregroundColor: PaletaRutas.ink,
                      ),
                      child: _guardando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: PaletaRutas.ink,
                              ),
                            )
                          : Text(
                              'Crear',
                              style: TipografiaHaku.interfaz(
                                fontWeight: FontWeight.w800,
                                color: PaletaRutas.ink,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
