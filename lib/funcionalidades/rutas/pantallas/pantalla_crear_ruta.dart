import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../lugares/dominio/modelos/modelo_lugar.dart';
import '../../lugares/proveedores/proveedor_lugares.dart';
import '../dominio/modelos/modelo_ruta.dart';
import '../dominio/modelos/modelo_ruta_propia.dart';
import '../dominio/modelos/solicitud_crear_ruta.dart';
import '../dominio/modelos/trazado_ruta_importado.dart';
import '../proveedores/proveedor_rutas.dart';
import '../widgets/boton_primario_ruta.dart';
import '../widgets/estilos_rutas.dart';
import 'pantalla_detalle_ruta.dart';
import 'pantalla_mapa_ruta.dart';

class PantallaCrearRuta extends ConsumerStatefulWidget {
  const PantallaCrearRuta({super.key, this.rutaInicial});

  final ModeloRutaPropia? rutaInicial;

  @override
  ConsumerState<PantallaCrearRuta> createState() => _EstadoPantallaCrearRuta();
}

class _EstadoPantallaCrearRuta extends ConsumerState<PantallaCrearRuta> {
  final _nombreCtrl = TextEditingController();
  final _resumenCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _zonaCtrl = TextEditingController();
  final _accesoCtrl = TextEditingController();
  final _transporteCtrl = TextEditingController();
  final _requisitosCtrl = TextEditingController();
  final _advertenciasCtrl = TextEditingController();
  final _etiquetasCtrl = TextEditingController();
  final _buscarCtrl = TextEditingController();

  final _paradas = <ParadaRutaEscritura>[];
  int _paso = 0;
  bool _publicando = false;
  Uint8List? _fotoBytes;
  String? _fotoNombre;
  String? _fotoMime;
  String? _fotoUrlActual;
  TrazadoRutaImportado? _trazadoImportado;
  bool _trazadoTocado = false;
  bool _trazadoPrevisualizado = false;
  bool _zonaEditando = false;
  ScaffoldMessengerState? _mensajero;
  TipoRutaEscritura _tipo = TipoRutaEscritura.senderismo;
  DificultadRutaEscritura _dificultad = DificultadRutaEscritura.moderado;
  HiloRutaEscritura _hilo = HiloRutaEscritura.camino;

  static const _opcionesAcceso = <String>[
    '',
    'Libre',
    'Con boleto',
    'Con reserva',
    'Con guia recomendado',
    'Con permiso/comunidad',
    'Temporalmente restringido',
  ];

  static const _opcionesRequisitos = <String>[
    'Agua',
    'Bloqueador',
    'Abrigo',
    'Calzado de trekking',
    'Sombrero',
    'Efectivo',
    'Documento de identidad',
    'Bastones',
    'Aclimatacion',
  ];

  static const _opcionesAdvertencias = <String>[
    'Altitud',
    'Lluvia',
    'Camino resbaloso',
    'Senal limitada',
    'No ir de noche',
    'Cruce vehicular',
    'Respeto comunitario',
    'Ingreso restringido por temporada',
  ];

  bool get _editando => widget.rutaInicial != null;

  @override
  void initState() {
    super.initState();
    final propia = widget.rutaInicial;
    if (propia == null) return;

    final solicitud = SolicitudCrearRuta.desdeRutaPropia(propia);
    _nombreCtrl.text = solicitud.nombre;
    _resumenCtrl.text = solicitud.resumen;
    _descripcionCtrl.text = solicitud.descripcion;
    _zonaCtrl.text = solicitud.zona;
    _accesoCtrl.text = solicitud.acceso;
    _transporteCtrl.text = solicitud.transporte;
    _requisitosCtrl.text = solicitud.requisitos.join(', ');
    _advertenciasCtrl.text = solicitud.advertencias.join(', ');
    _etiquetasCtrl.text = solicitud.etiquetas.join(', ');
    _fotoUrlActual = solicitud.fotoPortadaUrl;
    _tipo = solicitud.tipo;
    _dificultad = solicitud.dificultad;
    _hilo = solicitud.hilo;
    _paradas.addAll(solicitud.paradas);
    if (propia.ruta.trazado.length >= 2) {
      _trazadoImportado = TrazadoRutaImportado.desdeCoordenadas(
        propia.ruta.trazado,
      );
      _trazadoPrevisualizado = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mensajero = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void dispose() {
    _mensajero = null;
    _nombreCtrl.dispose();
    _resumenCtrl.dispose();
    _descripcionCtrl.dispose();
    _zonaCtrl.dispose();
    _accesoCtrl.dispose();
    _transporteCtrl.dispose();
    _requisitosCtrl.dispose();
    _advertenciasCtrl.dispose();
    _etiquetasCtrl.dispose();
    _buscarCtrl.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label,
    labelStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
    filled: true,
    fillColor: PaletaRutas.carbon,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: PaletaRutas.plomo.withValues(alpha: 0.45)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: PaletaRutas.oro),
    ),
  );

  void _snack(String mensaje) {
    final mensajero = _mensajero;
    if (mensajero == null || !mensajero.mounted) return;

    mensajero
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mensaje,
            style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
          ),
          backgroundColor: PaletaRutas.carbon,
        ),
      );
  }

  bool get _tieneContenidoSinGuardar {
    return _editando ||
        _nombreCtrl.text.trim().isNotEmpty ||
        _resumenCtrl.text.trim().isNotEmpty ||
        _descripcionCtrl.text.trim().isNotEmpty ||
        _zonaCtrl.text.trim().isNotEmpty ||
        _accesoCtrl.text.trim().isNotEmpty ||
        _requisitosCtrl.text.trim().isNotEmpty ||
        _advertenciasCtrl.text.trim().isNotEmpty ||
        _paradas.isNotEmpty ||
        _fotoBytes != null ||
        (_fotoUrlActual ?? '').trim().isNotEmpty ||
        _trazadoImportado != null ||
        _trazadoTocado;
  }

  Future<bool> _dialogoSiNo({
    required String titulo,
    required String mensaje,
    required String accion,
  }) async {
    final respuesta = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PaletaRutas.carbon,
        title: Text(
          titulo,
          style: TipografiaHaku.titulo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
        content: Text(
          mensaje,
          style: TipografiaHaku.interfaz(
            height: 1.35,
            color: PaletaRutas.plomoClaro,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Seguir editando',
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              accion,
              style: TipografiaHaku.interfaz(
                color: PaletaRutas.oro,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    return respuesta == true;
  }

  Future<bool> _confirmarSalirFormulario() async {
    if (!_tieneContenidoSinGuardar) return true;
    return _dialogoSiNo(
      titulo: 'Salir de Crear Ruta',
      mensaje:
          'Si sales ahora se perdera la Ruta que estas armando. Puedes seguir editando o descartar esta creacion.',
      accion: 'Descartar',
    );
  }

  Future<void> _salirFormulario() async {
    if (_publicando) return;
    FocusScope.of(context).unfocus();
    final salir = await _confirmarSalirFormulario();
    if (!mounted || !salir) return;
    Navigator.of(context).pop(false);
  }

  Future<void> _elegirFoto() async {
    final picker = ImagePicker();
    final foto = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 82,
    );
    if (foto == null || !mounted) return;
    final bytes = await foto.readAsBytes();
    if (!mounted) return;
    setState(() {
      _fotoBytes = bytes;
      _fotoNombre = foto.name;
      _fotoMime = foto.mimeType;
      _fotoUrlActual = null;
    });
  }

  void _agregarLugar(ModeloLugar lugar) {
    if (_paradas.any((p) => p.lugarId == lugar.id)) {
      _snack('Ese Lugar ya esta en la Ruta');
      return;
    }
    setState(() {
      _paradas.add(ParadaRutaEscritura.desdeLugar(lugar));
      if (!_zonaEditando) {
        final zonas = <String>{
          ...listaTextoCsv(_zonaCtrl.text.replaceAll(' - ', ',')),
          _zonaDeLugar(lugar),
        }..removeWhere((v) => v.trim().isEmpty);
        _zonaCtrl.text = _unirZonas(zonas);
      }
    });
  }

  String _zonaDeLugar(ModeloLugar lugar) {
    final provincia = lugar.provincia.trim();
    if (provincia.isNotEmpty) return provincia;
    return lugar.distrito.trim();
  }

  String _unirZonas(Iterable<String> zonas) {
    final limpias = zonas
        .map((z) => z.trim())
        .where((z) => z.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return limpias.join(' - ');
  }

  String _zonaCalculada() {
    final lugares = ref.read(lugaresRemotosProvider).valueOrNull;
    if (lugares == null || lugares.isEmpty || _paradas.isEmpty) {
      return _zonaCtrl.text.trim();
    }
    final ids = _paradas.map((p) => p.lugarId).toSet();
    return _unirZonas(
      lugares.where((l) => ids.contains(l.id)).map(_zonaDeLugar),
    );
  }

  String _zonaParaGuardar() {
    if (_zonaEditando) return _zonaCtrl.text;
    final calculada = _zonaCalculada();
    return calculada.isEmpty ? _zonaCtrl.text : calculada;
  }

  Set<String> _valoresCsv(TextEditingController controller) =>
      listaTextoCsv(controller.text).toSet();

  void _toggleCsv(TextEditingController controller, String valor) {
    final valores = _valoresCsv(controller);
    if (valores.contains(valor)) {
      valores.remove(valor);
    } else {
      valores.add(valor);
    }
    setState(() => controller.text = valores.join(', '));
  }

  Future<void> _agregarValorPersonalizado(
    TextEditingController controller,
    String titulo,
  ) async {
    final valor = await showDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (_) => _DialogoValorPersonalizado(titulo: titulo),
    );
    if (valor == null || valor.trim().isEmpty || !mounted) return;
    final valores = _valoresCsv(controller)..add(valor.trim());
    setState(() => controller.text = valores.join(', '));
  }

  void _moverParada(int index, int delta) {
    final nuevo = index + delta;
    if (nuevo < 0 || nuevo >= _paradas.length) return;
    setState(() {
      final item = _paradas.removeAt(index);
      _paradas.insert(nuevo, item);
    });
  }

  Future<void> _importarTrazado() async {
    final trazado = await _mostrarDialogoImportarTrazado();
    if (trazado == null || !mounted) return;
    setState(() {
      _trazadoImportado = trazado;
      _trazadoTocado = true;
      _trazadoPrevisualizado = false;
    });
  }

  void _quitarTrazado() {
    setState(() {
      _trazadoImportado = null;
      _trazadoTocado = true;
      _trazadoPrevisualizado = true;
    });
  }

  Future<TrazadoRutaImportado?> _mostrarDialogoImportarTrazado() async {
    return showDialog<TrazadoRutaImportado>(
      context: context,
      useRootNavigator: false,
      builder: (_) => const _DialogoImportarTrazado(),
    );
  }

  Future<void> _previsualizarTrazado() async {
    final trazado = _trazadoImportado;
    if (trazado == null) {
      _snack('Importa un trazado primero');
      return;
    }

    final ruta = ModeloRuta(
      id: widget.rutaInicial?.id ?? 'preview',
      titulo: _nombreCtrl.text.trim().isEmpty
          ? 'Vista previa'
          : _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      imagenUrl: _fotoUrlActual ?? '',
      categoria: CategoriaRuta.recomendadas,
      cantidadLugares: _paradas.length,
      dificultadTexto: _dificultad.etiqueta,
      distancia: trazado.distanciaLegible,
      puntos: _paradasPreview(),
      trazado: trazado.coordenadas,
      puntoPartida: _paradas.isEmpty ? '' : _paradas.first.nombre,
      comoLlegar: _accesoCtrl.text.trim(),
      transporte: _transporteCtrl.text.trim(),
      requisitos: listaTextoCsv(_requisitosCtrl.text),
      advertencias: listaTextoCsv(_advertenciasCtrl.text),
      etiquetas: listaTextoCsv(_etiquetasCtrl.text),
      tipoSitio: _tipo.valor,
      provincia: _zonaCtrl.text.trim().isEmpty
          ? 'Cusco'
          : _zonaCtrl.text.trim(),
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PantallaMapaRuta(ruta: ruta)),
    );
    if (mounted) setState(() => _trazadoPrevisualizado = true);
  }

  List<PuntoRuta> _paradasPreview() {
    final puntos = <PuntoRuta>[];
    for (var i = 0; i < _paradas.length; i++) {
      final p = _paradas[i];
      final lat = p.lat;
      final lng = p.lng;
      if (lat == null || lng == null) continue;
      puntos.add(
        PuntoRuta(
          id: 'preview-$i',
          nombre: p.nombre,
          tipo: i == 0
              ? 'inicio'
              : i == _paradas.length - 1
              ? 'destino'
              : 'parada',
          lat: lat,
          lng: lng,
          nota: p.instrucciones.trim().isEmpty ? null : p.instrucciones.trim(),
          lugarId: p.lugarId,
        ),
      );
    }
    return puntos;
  }

  SolicitudCrearRuta _solicitud({String? fotoUrl}) {
    return SolicitudCrearRuta(
      nombre: _nombreCtrl.text,
      resumen: _resumenCtrl.text,
      descripcion: _descripcionCtrl.text,
      fotoPortadaUrl: fotoUrl,
      tipo: _tipo,
      dificultad: _dificultad,
      hilo: _hilo,
      zona: _zonaParaGuardar(),
      acceso: _accesoCtrl.text,
      transporte: _transporteCtrl.text,
      requisitos: listaTextoCsv(_requisitosCtrl.text),
      advertencias: listaTextoCsv(_advertenciasCtrl.text),
      etiquetas: listaTextoCsv(_etiquetasCtrl.text),
      paradas: List.unmodifiable(_paradas),
    );
  }

  bool _validarPaso() {
    if (_paso == 0) {
      if (_nombreCtrl.text.trim().isEmpty) {
        _snack('Escribe el nombre de la Ruta');
        return false;
      }
      if (_resumenCtrl.text.trim().isEmpty) {
        _snack('Escribe un resumen corto');
        return false;
      }
      if (_descripcionCtrl.text.trim().isEmpty) {
        _snack('Escribe una descripcion');
        return false;
      }
    }
    if (_paso == 1 && _paradas.length < 2) {
      _snack('Elige al menos dos Lugares');
      return false;
    }
    if (_paso == 2) {
      if (_zonaParaGuardar().trim().isEmpty) {
        _snack('Confirma la zona de la Ruta');
        return false;
      }
      if (_accesoCtrl.text.trim().isEmpty) {
        _snack('Elige el acceso de la Ruta');
        return false;
      }
      if (listaTextoCsv(_requisitosCtrl.text).isEmpty) {
        _snack('Agrega al menos un requisito');
        return false;
      }
      if (listaTextoCsv(_advertenciasCtrl.text).isEmpty) {
        _snack('Agrega al menos una advertencia');
        return false;
      }
    }
    return true;
  }

  void _siguiente() {
    FocusScope.of(context).unfocus();
    if (!_validarPaso()) return;
    if (_paso < 3) setState(() => _paso++);
  }

  void _anterior() {
    FocusScope.of(context).unfocus();
    if (_paso > 0) setState(() => _paso--);
  }

  Future<void> _publicar() async {
    if (_publicando) return;
    if (_trazadoImportado != null && !_trazadoPrevisualizado) {
      _snack('Previsualiza el recorrido antes de guardar');
      return;
    }
    final previa = _solicitud();
    final error = previa.validar();
    if (error != null) {
      _snack(error);
      return;
    }
    if (_trazadoImportado == null) {
      final continuar = await _confirmarPublicarSinRecorrido();
      if (continuar != true || !mounted) return;
    }

    final ok = await asegurarSesion(context, ref);
    if (!ok || !mounted) return;
    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      _snack('Inicia sesion');
      return;
    }

    setState(() => _publicando = true);
    String? fotoPath;
    try {
      final ds = ref.read(rutasDataSourceProvider);
      String? fotoUrl;
      final bytes = _fotoBytes;
      if (bytes != null) {
        final subida = await ds.subirFotoPortada(
          userId: user.id,
          bytes: bytes,
          contentType: _fotoMime ?? 'image/jpeg',
          extension: _extensionFoto(),
        );
        fotoPath = subida.path;
        fotoUrl = subida.url;
      } else {
        fotoUrl = _fotoUrlActual;
      }

      final solicitud = _solicitud(fotoUrl: fotoUrl);
      if (_editando) {
        final guardada = await ds.guardarPropia(
          rutaId: widget.rutaInicial!.id,
          solicitud: solicitud,
          publicar: !widget.rutaInicial!.archivada,
        );
        if (_trazadoTocado) {
          await ds.guardarTrazadoPropio(
            rutaId: guardada.id,
            trazado: _trazadoImportado,
          );
        }
        notificarRutasCambiaron(ref);
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      }

      var creada = await ds.crearPublicada(solicitud);
      final trazado = _trazadoImportado;
      if (trazado != null) {
        final propia = await ds.guardarTrazadoPropio(
          rutaId: creada.id,
          trazado: trazado,
        );
        creada = propia.ruta;
      }
      notificarRutasCambiaron(ref);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, bool>(
        MaterialPageRoute<void>(
          builder: (_) => PantallaDetalleRuta(ruta: creada),
        ),
        result: true,
      );
    } on AuthException catch (e) {
      await _limpiarFotoSiFallo(fotoPath);
      if (mounted) _snack(e.message);
    } on PostgrestException catch (e) {
      await _limpiarFotoSiFallo(fotoPath);
      debugPrint(
        'Crear Ruta PostgREST: code=${e.code} message=${e.message} '
        'details=${e.details} hint=${e.hint}',
      );
      if (mounted) {
        _snack(e.message.trim().isEmpty ? 'No se pudo publicar' : e.message);
      }
    } catch (_) {
      await _limpiarFotoSiFallo(fotoPath);
      if (mounted) _snack('No se pudo publicar la Ruta');
    } finally {
      if (mounted) setState(() => _publicando = false);
    }
  }

  Future<bool?> _confirmarPublicarSinRecorrido() {
    return showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PaletaRutas.carbon,
        title: Text(
          'Publicar sin recorrido real',
          style: TipografiaHaku.titulo(color: PaletaRutas.piedra),
        ),
        content: Text(
          'La Ruta se mostrara como itinerario de paradas. Podras agregar el recorrido real despues desde editar.',
          style: TipografiaHaku.interfaz(
            color: PaletaRutas.plomoClaro,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Publicar solo paradas'),
          ),
        ],
      ),
    );
  }

  Future<void> _limpiarFotoSiFallo(String? path) async {
    if (path == null) return;
    try {
      await ref.read(rutasDataSourceProvider).eliminarFotoSubida(path);
    } catch (_) {
      // La publicacion fallo; la limpieza queda como mejor esfuerzo.
    }
  }

  String _extensionFoto() {
    final nombre = _fotoNombre ?? '';
    final i = nombre.lastIndexOf('.');
    if (i == -1 || i == nombre.length - 1) return 'jpg';
    return nombre.substring(i + 1);
  }

  Widget _pasoActual() {
    return switch (_paso) {
      0 => _pasoIdentidad(),
      1 => _pasoItinerario(),
      2 => _pasoFicha(),
      _ => _pasoVistaPrevia(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 16;
    final ancho = MediaQuery.sizeOf(context).width;
    final horizontal = ancho > 760 ? (ancho - 720) / 2 : 16.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _salirFormulario();
      },
      child: Scaffold(
        backgroundColor: PaletaRutas.ink,
        appBar: AppBar(
          backgroundColor: PaletaRutas.ink,
          foregroundColor: PaletaRutas.piedra,
          leading: IconButton(
            tooltip: 'Salir',
            onPressed: _publicando ? null : _salirFormulario,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(
            _editando ? 'Editar Ruta' : 'Crear Ruta',
            style: TipografiaHaku.titulo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: PaletaRutas.piedra,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 8),
                child: _IndicadorPasos(paso: _paso),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    4,
                    horizontal,
                    bottom,
                  ),
                  children: [_pasoActual()],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, bottom),
                child: Row(
                  children: [
                    if (_paso > 0)
                      Expanded(
                        child: BotonSecundarioRuta(
                          texto: 'Atras',
                          icono: Icons.arrow_back_rounded,
                          onPressed: _publicando ? null : _anterior,
                        ),
                      ),
                    if (_paso > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _paso == 3
                          ? BotonPrimarioRuta(
                              texto: _publicando
                                  ? 'Guardando...'
                                  : _editando
                                  ? 'Guardar'
                                  : 'Publicar',
                              icono: Icons.cloud_upload_outlined,
                              habilitado: !_publicando,
                              onPressed: _publicando ? null : _publicar,
                            )
                          : BotonPrimarioRuta(
                              texto: 'Continuar',
                              icono: Icons.arrow_forward_rounded,
                              onPressed: _publicando ? null : _siguiente,
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

  Widget _pasoIdentidad() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nombreCtrl,
          maxLength: 120,
          enabled: !_publicando,
          style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
          cursorColor: PaletaRutas.oro,
          decoration: _deco('Nombre'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _resumenCtrl,
          maxLength: 240,
          enabled: !_publicando,
          style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
          cursorColor: PaletaRutas.oro,
          decoration: _deco('Resumen'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descripcionCtrl,
          enabled: !_publicando,
          maxLines: 5,
          style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
          cursorColor: PaletaRutas.oro,
          decoration: _deco('Descripcion'),
        ),
        const SizedBox(height: 14),
        if (_fotoBytes == null && (_fotoUrlActual ?? '').isEmpty)
          BotonSecundarioRuta(
            texto: 'Foto de portada',
            icono: Icons.add_photo_alternate_outlined,
            onPressed: _publicando ? null : _elegirFoto,
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _fotoBytes != null
                      ? Image.memory(_fotoBytes!, fit: BoxFit.cover)
                      : Image.network(_fotoUrlActual!, fit: BoxFit.cover),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton.filledTonal(
                    onPressed: _publicando
                        ? null
                        : () => setState(() {
                            _fotoBytes = null;
                            _fotoNombre = null;
                            _fotoMime = null;
                            _fotoUrlActual = null;
                          }),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _pasoItinerario() {
    final lugaresAsync = ref.watch(lugaresRemotosProvider);
    final lugares = lugaresAsync.valueOrNull ?? const <ModeloLugar>[];
    final q = _buscarCtrl.text.trim().toLowerCase();
    final filtrados = lugares
        .where((l) {
          if (_paradas.any((p) => p.lugarId == l.id)) return false;
          if (q.isEmpty) return true;
          return l.nombre.toLowerCase().contains(q) ||
              l.provincia.toLowerCase().contains(q) ||
              l.distrito.toLowerCase().contains(q);
        })
        .take(20)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_paradas.isEmpty)
          _TextoPanel('Selecciona al menos dos Lugares activos.')
        else
          Column(
            children: List.generate(_paradas.length, (i) {
              final p = _paradas[i];
              final tipo = i == 0
                  ? 'Inicio'
                  : i == _paradas.length - 1
                  ? 'Destino'
                  : 'Parada ${i + 1}';
              return _FilaParada(
                titulo: p.nombre,
                subtitulo: tipo,
                onSubir: i == 0 ? null : () => _moverParada(i, -1),
                onBajar: i == _paradas.length - 1
                    ? null
                    : () => _moverParada(i, 1),
                onQuitar: _publicando
                    ? null
                    : () => setState(() => _paradas.removeAt(i)),
              );
            }),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _buscarCtrl,
          enabled: !_publicando,
          onChanged: (_) => setState(() {}),
          style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
          cursorColor: PaletaRutas.oro,
          decoration: _deco('Buscar Lugar'),
        ),
        const SizedBox(height: 10),
        if (lugaresAsync.isLoading && !lugaresAsync.hasValue)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Center(
              child: CircularProgressIndicator(color: PaletaRutas.oro),
            ),
          )
        else if (lugaresAsync.hasError && !lugaresAsync.hasValue)
          TextButton(
            onPressed: () => ref.invalidate(lugaresRemotosProvider),
            child: const Text('Reintentar lugares'),
          )
        else if (filtrados.isEmpty)
          _TextoPanel('No hay Lugares disponibles con ese filtro.')
        else
          for (final lugar in filtrados)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                lugar.nombre,
                style: TipografiaHaku.interfaz(
                  color: PaletaRutas.piedra,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                [
                  lugar.distrito,
                  lugar.provincia,
                ].where((v) => v.trim().isNotEmpty).join(' · '),
                style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
              ),
              trailing: IconButton(
                onPressed: _publicando ? null : () => _agregarLugar(lugar),
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: PaletaRutas.oro,
                ),
              ),
            ),
      ],
    );
  }

  Widget _pasoFicha() {
    final accesoActual = _accesoCtrl.text.trim();
    final zonaCalculada = _zonaCalculada();
    final zonaMostrada = _zonaEditando
        ? _zonaCtrl.text.trim()
        : (zonaCalculada.isEmpty ? _zonaCtrl.text.trim() : zonaCalculada);
    final requisitosSeleccionados = _valoresCsv(_requisitosCtrl);
    final advertenciasSeleccionadas = _valoresCsv(_advertenciasCtrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<TipoRutaEscritura>(
          initialValue: _tipo,
          dropdownColor: PaletaRutas.carbon,
          decoration: _deco('Tipo'),
          items: [
            for (final t in TipoRutaEscritura.values)
              DropdownMenuItem(
                value: t,
                child: Text(
                  t.etiqueta,
                  style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                ),
              ),
          ],
          onChanged: _publicando
              ? null
              : (v) {
                  if (v != null) setState(() => _tipo = v);
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<DificultadRutaEscritura>(
          initialValue: _dificultad,
          dropdownColor: PaletaRutas.carbon,
          decoration: _deco('Dificultad'),
          items: [
            for (final d in DificultadRutaEscritura.values)
              DropdownMenuItem(
                value: d,
                child: Text(
                  d.etiqueta,
                  style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                ),
              ),
          ],
          onChanged: _publicando
              ? null
              : (v) {
                  if (v != null) setState(() => _dificultad = v);
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<HiloRutaEscritura>(
          initialValue: _hilo,
          dropdownColor: PaletaRutas.carbon,
          decoration: _deco('Hilo cultural'),
          items: [
            for (final h in HiloRutaEscritura.values)
              DropdownMenuItem(
                value: h,
                child: Text(
                  h.etiqueta,
                  style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                ),
              ),
          ],
          onChanged: _publicando
              ? null
              : (v) {
                  if (v != null) setState(() => _hilo = v);
                },
        ),
        const SizedBox(height: 12),
        _PanelZonaRuta(
          zona: zonaMostrada,
          editando: _zonaEditando,
          controller: _zonaCtrl,
          deco: _deco('Zona'),
          habilitado: !_publicando,
          onEditar: () {
            setState(() {
              _zonaEditando = true;
              _zonaCtrl.text = zonaMostrada;
            });
          },
          onUsarSugerida: zonaCalculada.isEmpty || _publicando
              ? null
              : () {
                  setState(() {
                    _zonaEditando = false;
                    _zonaCtrl.text = zonaCalculada;
                  });
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _opcionesAcceso.contains(accesoActual) ||
              accesoActual.isNotEmpty
              ? accesoActual
              : '',
          dropdownColor: PaletaRutas.carbon,
          decoration: _deco('Acceso'),
          items: [
            for (final acceso in _opcionesAcceso)
              DropdownMenuItem(
                value: acceso,
                child: Text(
                  acceso.isEmpty ? 'No definido' : acceso,
                  style: TipografiaHaku.interfaz(
                    color: acceso.isEmpty
                        ? PaletaRutas.plomoClaro
                        : PaletaRutas.piedra,
                  ),
                ),
              ),
            if (accesoActual.isNotEmpty &&
                !_opcionesAcceso.contains(accesoActual))
              DropdownMenuItem(
                value: accesoActual,
                child: Text(
                  accesoActual,
                  style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
                ),
              ),
          ],
          onChanged: _publicando
              ? null
              : (v) => setState(() => _accesoCtrl.text = v ?? ''),
        ),
        const SizedBox(height: 12),
        _SelectorChipsRuta(
          titulo: 'Requisitos',
          opciones: _opcionesRequisitos,
          seleccionados: requisitosSeleccionados,
          habilitado: !_publicando,
          onToggle: (v) => _toggleCsv(_requisitosCtrl, v),
          onAgregar: () => _agregarValorPersonalizado(
            _requisitosCtrl,
            'Agregar requisito',
          ),
        ),
        const SizedBox(height: 12),
        _SelectorChipsRuta(
          titulo: 'Advertencias',
          opciones: _opcionesAdvertencias,
          seleccionados: advertenciasSeleccionadas,
          habilitado: !_publicando,
          onToggle: (v) => _toggleCsv(_advertenciasCtrl, v),
          onAgregar: () => _agregarValorPersonalizado(
            _advertenciasCtrl,
            'Agregar advertencia',
          ),
        ),
      ],
    );
  }

  Widget _pasoVistaPrevia() {
    final solicitud = _solicitud();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResumenLinea(label: 'Nombre', valor: solicitud.nombre.trim()),
        _ResumenLinea(
          label: 'Tipo',
          valor: '${_tipo.etiqueta} · ${_dificultad.etiqueta}',
        ),
        _ResumenLinea(label: 'Zona', valor: solicitud.zona.trim()),
        _ResumenLinea(label: 'Lugares', valor: '${_paradas.length}'),
        const SizedBox(height: 12),
        _PanelTrazado(
          trazado: _trazadoImportado,
          previsualizado: _trazadoPrevisualizado,
          onImportar: _publicando ? null : _importarTrazado,
          onPrevisualizar: _publicando ? null : _previsualizarTrazado,
          onQuitar: _publicando || _trazadoImportado == null
              ? null
              : _quitarTrazado,
        ),
        if (_trazadoImportado == null) ...[
          const SizedBox(height: 10),
          _TextoPanel(
            'Sin recorrido real: se publicara como itinerario de paradas y no como navegacion detallada.',
          ),
        ],
        const SizedBox(height: 12),
        for (var i = 0; i < _paradas.length; i++)
          _FilaParada(
            titulo: _paradas[i].nombre,
            subtitulo: i == 0
                ? 'Inicio'
                : i == _paradas.length - 1
                ? 'Destino'
                : 'Parada ${i + 1}',
          ),
        if (_paradas.isEmpty) _TextoPanel('Sin Lugares seleccionados.'),
      ],
    );
  }
}

class _PanelZonaRuta extends StatelessWidget {
  const _PanelZonaRuta({
    required this.zona,
    required this.editando,
    required this.controller,
    required this.deco,
    required this.habilitado,
    required this.onEditar,
    required this.onUsarSugerida,
  });

  final String zona;
  final bool editando;
  final TextEditingController controller;
  final InputDecoration deco;
  final bool habilitado;
  final VoidCallback onEditar;
  final VoidCallback? onUsarSugerida;

  @override
  Widget build(BuildContext context) {
    if (editando) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            enabled: habilitado,
            style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
            cursorColor: PaletaRutas.oro,
            decoration: deco,
          ),
          if (onUsarSugerida != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: habilitado ? onUsarSugerida : null,
                icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                label: const Text('Usar zona sugerida'),
              ),
            ),
          ],
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletaRutas.plomo.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.map_outlined, color: PaletaRutas.oro, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zona',
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  zona.isEmpty ? 'Se completara con tus paradas' : zona,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TipografiaHaku.interfaz(
                    color: zona.isEmpty
                        ? PaletaRutas.plomoClaro
                        : PaletaRutas.piedra,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: habilitado ? onEditar : null,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Editar'),
          ),
        ],
      ),
    );
  }
}

class _DialogoValorPersonalizado extends StatefulWidget {
  const _DialogoValorPersonalizado({required this.titulo});

  final String titulo;

  @override
  State<_DialogoValorPersonalizado> createState() =>
      _DialogoValorPersonalizadoState();
}

class _DialogoValorPersonalizadoState
    extends State<_DialogoValorPersonalizado> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label,
    labelStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
    filled: true,
    fillColor: PaletaRutas.carbon,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: PaletaRutas.plomo.withValues(alpha: 0.45)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: PaletaRutas.oro),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PaletaRutas.carbon,
      title: Text(
        widget.titulo,
        style: TipografiaHaku.titulo(color: PaletaRutas.piedra),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        textInputAction: TextInputAction.done,
        style: TipografiaHaku.interfaz(color: PaletaRutas.piedra),
        cursorColor: PaletaRutas.oro,
        decoration: _deco('Escribe una opcion'),
        onSubmitted: (_) => _aceptar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
          ),
        ),
        FilledButton(
          onPressed: _aceptar,
          child: const Text('Agregar'),
        ),
      ],
    );
  }

  void _aceptar() {
    Navigator.of(context).pop(_controller.text.trim());
  }
}

class _DialogoImportarTrazado extends StatefulWidget {
  const _DialogoImportarTrazado();

  @override
  State<_DialogoImportarTrazado> createState() => _DialogoImportarTrazadoState();
}

class _DialogoImportarTrazadoState extends State<_DialogoImportarTrazado> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label,
    labelStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
    filled: true,
    fillColor: PaletaRutas.carbon,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: PaletaRutas.plomo.withValues(alpha: 0.45)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: PaletaRutas.oro),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PaletaRutas.carbon,
      title: Text(
        'Recorrido real',
        style: TipografiaHaku.titulo(color: PaletaRutas.piedra),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pega un GPX o GeoJSON LineString. Si no agregas recorrido real, la Ruta se publicara solo con sus paradas.',
                style: TipografiaHaku.interfaz(
                  color: PaletaRutas.plomoClaro,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: 10,
                minLines: 6,
                style: TipografiaHaku.interfaz(
                  color: PaletaRutas.piedra,
                  fontSize: 12,
                ),
                cursorColor: PaletaRutas.oro,
                decoration: _deco('Pegar GPX o GeoJSON'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TipografiaHaku.interfaz(
                    color: PaletaRutas.oro,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
          ),
        ),
        FilledButton.icon(
          onPressed: _usarRecorrido,
          icon: const Icon(Icons.route_rounded),
          label: const Text('Usar recorrido'),
        ),
      ],
    );
  }

  void _usarRecorrido() {
    try {
      final trazado = parsearTrazadoRuta(_controller.text);
      Navigator.of(context).pop(trazado);
    } on ErrorTrazadoRuta catch (e) {
      setState(() => _error = e.mensaje);
    } catch (_) {
      setState(() => _error = 'No se pudo leer el trazado.');
    }
  }
}

class _SelectorChipsRuta extends StatelessWidget {
  const _SelectorChipsRuta({
    required this.titulo,
    required this.opciones,
    required this.seleccionados,
    required this.habilitado,
    required this.onToggle,
    required this.onAgregar,
  });

  final String titulo;
  final List<String> opciones;
  final Set<String> seleccionados;
  final bool habilitado;
  final ValueChanged<String> onToggle;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    final personalizados = seleccionados
        .where((v) => !opciones.contains(v))
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletaRutas.plomo.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: TipografiaHaku.interfaz(
                    color: PaletaRutas.piedra,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: habilitado ? onAgregar : null,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final opcion in [...opciones, ...personalizados])
                FilterChip(
                  label: Text(opcion),
                  selected: seleccionados.contains(opcion),
                  onSelected: habilitado ? (_) => onToggle(opcion) : null,
                  selectedColor: PaletaRutas.oro.withValues(alpha: 0.22),
                  checkmarkColor: PaletaRutas.oro,
                  backgroundColor: PaletaRutas.ink,
                  side: BorderSide(
                    color: seleccionados.contains(opcion)
                        ? PaletaRutas.oro
                        : PaletaRutas.plomo.withValues(alpha: 0.4),
                  ),
                  labelStyle: TipografiaHaku.interfaz(
                    fontSize: 12,
                    color: PaletaRutas.piedra,
                    fontWeight: seleccionados.contains(opcion)
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelTrazado extends StatelessWidget {
  const _PanelTrazado({
    required this.trazado,
    required this.previsualizado,
    required this.onImportar,
    required this.onPrevisualizar,
    required this.onQuitar,
  });

  final TrazadoRutaImportado? trazado;
  final bool previsualizado;
  final VoidCallback? onImportar;
  final VoidCallback? onPrevisualizar;
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) {
    final t = trazado;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PaletaRutas.plomo.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded, color: PaletaRutas.oro),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t == null
                      ? 'Recorrido real'
                      : '${t.etiquetaOrigen} · ${t.distanciaLegible} · ${t.cantidadPuntos} puntos',
                  style: TipografiaHaku.interfaz(
                    color: PaletaRutas.piedra,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (t != null)
                Icon(
                  previsualizado
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: previsualizado ? PaletaRutas.oro : PaletaRutas.plomo,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t == null
                ? 'Agrega un GPX o GeoJSON cuando tengas el camino real. Puedes omitirlo y publicar solo las paradas.'
                : previsualizado
                ? 'Recorrido revisado en el mapa.'
                : 'Previsualiza el recorrido antes de guardar.',
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              color: PaletaRutas.plomoClaro,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onImportar,
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: Text(t == null ? 'Pegar recorrido' : 'Reemplazar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PaletaRutas.oro,
                  side: BorderSide(
                    color: PaletaRutas.oro.withValues(alpha: 0.55),
                  ),
                ),
              ),
              if (t != null)
                OutlinedButton.icon(
                  onPressed: onPrevisualizar,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Previsualizar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PaletaRutas.piedra,
                    side: BorderSide(
                      color: PaletaRutas.plomo.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              if (t != null)
                IconButton(
                  tooltip: 'Quitar trazado',
                  onPressed: onQuitar,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: PaletaRutas.plomoClaro,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndicadorPasos extends StatelessWidget {
  const _IndicadorPasos({required this.paso});

  final int paso;

  @override
  Widget build(BuildContext context) {
    const labels = ['Identidad', 'Itinerario', 'Ficha', 'Vista'];
    return Row(
      children: List.generate(labels.length, (i) {
        final activo = i == paso;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 6),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: activo ? PaletaRutas.oro : PaletaRutas.carbon,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activo
                    ? PaletaRutas.oro
                    : PaletaRutas.plomo.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              labels[i],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TipografiaHaku.interfaz(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: activo ? PaletaRutas.ink : PaletaRutas.piedra,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _FilaParada extends StatelessWidget {
  const _FilaParada({
    required this.titulo,
    required this.subtitulo,
    this.onSubir,
    this.onBajar,
    this.onQuitar,
  });

  final String titulo;
  final String subtitulo;
  final VoidCallback? onSubir;
  final VoidCallback? onBajar;
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PaletaRutas.plomo.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, color: PaletaRutas.oro, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TipografiaHaku.interfaz(
                    color: PaletaRutas.piedra,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitulo,
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    color: PaletaRutas.plomoClaro,
                  ),
                ),
              ],
            ),
          ),
          if (onSubir != null)
            IconButton(
              onPressed: onSubir,
              icon: const Icon(Icons.arrow_upward_rounded),
              color: PaletaRutas.oro,
            ),
          if (onBajar != null)
            IconButton(
              onPressed: onBajar,
              icon: const Icon(Icons.arrow_downward_rounded),
              color: PaletaRutas.oro,
            ),
          if (onQuitar != null)
            IconButton(
              onPressed: onQuitar,
              icon: const Icon(Icons.close_rounded),
              color: PaletaRutas.plomoClaro,
            ),
        ],
      ),
    );
  }
}

class _ResumenLinea extends StatelessWidget {
  const _ResumenLinea({required this.label, required this.valor});

  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            ),
          ),
          Expanded(
            child: Text(
              valor.isEmpty ? '-' : valor,
              style: TipografiaHaku.interfaz(
                color: PaletaRutas.piedra,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextoPanel extends StatelessWidget {
  const _TextoPanel(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PaletaRutas.plomo.withValues(alpha: 0.32)),
      ),
      child: Text(
        texto,
        style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
      ),
    );
  }
}
