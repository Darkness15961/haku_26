import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../../nucleo/widgets/imagen_haku.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../dominio/modelo_comunidad.dart';
import '../proveedores/proveedor_comunidad.dart';
import '../datos/comunidad_datasource_supabase.dart';

class PantallaEditarComunidad extends ConsumerStatefulWidget {
  final ComunidadHaku comunidad;

  const PantallaEditarComunidad({super.key, required this.comunidad});

  @override
  ConsumerState<PantallaEditarComunidad> createState() =>
      _EstadoPantallaEditarComunidad();
}

class _EstadoPantallaEditarComunidad
    extends ConsumerState<PantallaEditarComunidad> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descCtrl;
  final _picker = ImagePicker();

  XFile? _foto;
  Uint8List? _fotoBytes;
  bool _eliminarFotoActual = false;

  late String _tipo;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.comunidad.nombre);
    _descCtrl = TextEditingController(text: widget.comunidad.descripcion);
    _tipo = widget.comunidad.tipo;
  }

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
      _eliminarFotoActual =
          false; // Si se elige nueva, no se vacía, se reemplaza.
    });
  }

  void _removerFoto() {
    setState(() {
      _foto = null;
      _fotoBytes = null;
      _eliminarFotoActual =
          true; // El usuario explícitamente quiere borrar la foto de portada.
    });
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      mostrarSnackHaku(context, 'Escribe un nombre para la comunidad');
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
      final desc = _descCtrl.text.trim();

      if (_foto != null && _fotoBytes != null) {
        // Se sube nueva foto
        final name = _foto!.name.toLowerCase();
        final ext = name.endsWith('.png')
            ? 'png'
            : (name.endsWith('.webp') ? 'webp' : 'jpg');
        final contentType = ext == 'png'
            ? 'image/png'
            : (ext == 'webp' ? 'image/webp' : 'image/jpeg');

        await ds.editarComunidadConPortada(
          comunidadId: widget.comunidad.id,
          nombre: nombre,
          descripcion: desc.isEmpty ? null : desc,
          tipo: _tipo,
          bytes: _fotoBytes!,
          contentType: contentType,
          extension: ext,
          urlAnterior: widget.comunidad.imagenUrl,
        );
      } else {
        // No se eligió foto nueva. Validar si se eliminó la actual o se mantiene.
        String? fotoUrl;
        if (_eliminarFotoActual) {
          fotoUrl = ''; // Indicativo para borrar de la BD
        }

        await ds.editarComunidad(
          comunidadId: widget.comunidad.id,
          nombre: nombre,
          descripcion: desc.isEmpty ? null : desc,
          tipo: _tipo,
          fotoPortadaUrl:
              fotoUrl, // Si es nulo, no se actualiza (se mantiene la que está en la base de datos)
        );

        if (_eliminarFotoActual &&
            widget.comunidad.imagenUrl.isNotEmpty &&
            widget.comunidad.imagenUrl.contains(
              ComunidadDataSourceSupabase.bucketMedia,
            )) {
          // Ya que se borró el link en DB, lo borramos del storage para no dejar huérfanos.
          await ds.eliminarPortadaSubida(widget.comunidad.imagenUrl);
        }
      }

      notificarComunidadesCambiaron(ref);
      if (!mounted) return;
      mostrarSnackHaku(context, 'Comunidad actualizada', destacado: true);
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) mostrarSnackHaku(context, e.message);
    } catch (e) {
      if (mounted) {
        mostrarSnackHaku(context, 'No se pudo actualizar la comunidad');
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
    final ancho = MediaQuery.sizeOf(context).width;
    final horizontal = ancho > 752 ? (ancho - 720) / 2 : 16.0;

    final tieneFotoLocal = _fotoBytes != null;
    final tieneFotoRemota =
        widget.comunidad.imagenUrl.isNotEmpty && !_eliminarFotoActual;
    final mostrarBotonQuitarFoto = tieneFotoLocal || tieneFotoRemota;

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
                      'Editar comunidad',
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
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  12,
                  horizontal,
                  bottom,
                ),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Portada (opcional)',
                        style: TipografiaHaku.titulo(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: PaletaRutas.piedra,
                        ),
                      ),
                      if (mostrarBotonQuitarFoto)
                        TextButton(
                          onPressed: _guardando ? null : _removerFoto,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFD32F2F),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: Text(
                            'Quitar portada',
                            style: TipografiaHaku.interfaz(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
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
                        child: _construirImagenPortada(
                          tieneFotoLocal,
                          tieneFotoRemota,
                        ),
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
                  const SizedBox(height: 8),
                  Text(
                    _tipo == 'privado'
                        ? 'Solo las personas aprobadas podrán verla.'
                        : 'Cualquier explorador podrá encontrarla y unirse.',
                    style: TipografiaHaku.interfaz(
                      fontSize: 12,
                      color: PaletaRutas.plomoClaro,
                    ),
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
                    decoration: _deco('Descripción (opcional)'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _guardando ? null : _guardar,
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
                              'Guardar cambios',
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

  Widget _construirImagenPortada(bool tieneFotoLocal, bool tieneFotoRemota) {
    if (tieneFotoLocal) {
      return Image.memory(_fotoBytes!, fit: BoxFit.cover);
    }

    if (tieneFotoRemota) {
      return ImagenHaku(url: widget.comunidad.imagenUrl, fit: BoxFit.cover);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: PaletaRutas.plomo.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 6),
          Text(
            'Toca para agregar una foto de portada',
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              color: PaletaRutas.plomoClaro,
            ),
          ),
        ],
      ),
    );
  }
}
