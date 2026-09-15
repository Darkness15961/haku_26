import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/metricas/metricas_descubrimiento.dart';
import '../../../nucleo/supabase/cliente_supabase.dart';
import '../../autenticacion/navegacion_auth.dart';
import '../../rutas/widgets/boton_primario_ruta.dart';
import '../../rutas/widgets/estilos_rutas.dart';
import '../../rutas/widgets/fondo_suave_seccion.dart';
import '../../rutas/widgets/linea_encabezado_inca.dart';
import '../dominio/logica_ubicacion_lugar.dart';
import '../dominio/modelos/modelo_territorio.dart';
import '../dominio/resolver_provincia_lugar.dart';
import '../proveedores/proveedor_lugares.dart';
import 'pantalla_elegir_ubicacion_lugar.dart';
import 'sheet_coordenadas_lugar.dart';

/// Wizard limpio: identidad → ubicación → acceso → descripción.
class PantallaRegistrarLugar extends ConsumerStatefulWidget {
  const PantallaRegistrarLugar({super.key, this.provinciaInicial});

  final String? provinciaInicial;

  @override
  ConsumerState<PantallaRegistrarLugar> createState() =>
      _EstadoPantallaRegistrarLugar();
}

class _EstadoPantallaRegistrarLugar
    extends ConsumerState<PantallaRegistrarLugar> {
  static const _pasos = 5;

  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _picker = ImagePicker();

  int _paso = 0;
  XFile? _foto;
  String _acceso = 'Caminando';
  bool _publicando = false;
  bool _ubicando = false;

  ModeloProvinciaDb? _provincia;
  ModeloDistritoDb? _distrito;
  bool _provinciaResuelta = false;
  final Set<int> _tematicaIds = {};
  final Set<int> _actividadIds = {};

  double? _latitud;
  double? _longitud;
  String? _origenUbicacion; // 'gps' | 'mapa' | 'coords'

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  bool get _tieneUbicacion =>
      LogicaUbicacionLugar.esUbicacionValida(_latitud, _longitud) &&
      !LogicaUbicacionLugar.esPuntoSospechoso(_latitud!, _longitud!);

  void _asegurarProvinciaResuelta(List<ModeloProvinciaDb> remotas) {
    if (_provinciaResuelta || remotas.isEmpty) return;
    _provinciaResuelta = true;
    final hallada = ResolverProvinciaLugar.desdeInicial(
      remotas: remotas,
      inicial: widget.provinciaInicial,
    );
    if (hallada == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _provincia != null) return;
      setState(() => _provincia = hallada);
    });
  }

  Future<void> _siguiente() async {
    if (_publicando || _ubicando) return;
    if (_paso == 0) {
      if (_nombre.text.trim().isEmpty) {
        _aviso('Escribe el nombre del lugar');
        return;
      }
      if (_provincia == null) {
        _aviso('Elige una provincia');
        return;
      }
      if (_distrito == null) {
        _aviso('Elige un distrito');
        return;
      }
    }
    if (_paso == 1) {
      if (_tematicaIds.isEmpty) {
        _aviso('Elige al menos una temática');
        return;
      }
    }
    if (_paso == 2) {
      final err = LogicaUbicacionLugar.mensajeErrorUbicacion(_latitud, _longitud);
      if (err != null) {
        _aviso(err);
        return;
      }
    }
    if (_paso < _pasos - 1) {
      setState(() => _paso++);
      return;
    }
    await _finalizar();
  }

  String _mensajeError(Object e) {
    if (e is AuthException) {
      final m = e.message.trim();
      return m.isEmpty ? 'No se pudo publicar. Revisa tu sesión.' : m;
    }
    if (e is StorageException) {
      return 'No se pudo subir la foto. Intenta de nuevo.';
    }
    if (e is PostgrestException) {
      final m = (e.message).toLowerCase();
      if (m.contains('row-level security') || m.contains('policy')) {
        return 'No tienes permiso para publicar. Vuelve a iniciar sesión.';
      }
      if (m.contains('foreign key') || m.contains('violates')) {
        return 'Datos incompletos. Revisa distrito y ubicación.';
      }
      if (e.message.trim().isNotEmpty) return e.message;
    }
    final s = e.toString().toLowerCase();
    if (s.contains('row-level security') || s.contains('rls')) {
      return 'No tienes permiso para publicar. Vuelve a iniciar sesión.';
    }
    return 'No se pudo publicar el lugar. Intenta de nuevo.';
  }

  Future<void> _usarUbicacionActual() async {
    setState(() => _ubicando = true);
    try {
      final servicio = await Geolocator.isLocationServiceEnabled();
      if (!servicio) {
        if (mounted) {
          final abrir = await _dialogoSiNo(
            titulo: 'GPS apagado',
            mensaje:
                'Activa la ubicación del teléfono para marcar el lugar donde estás.',
            accion: 'Abrir ajustes',
          );
          if (abrir) await Geolocator.openLocationSettings();
        }
        return;
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied) {
        if (mounted) {
          _aviso('Sin permiso no podemos usar el GPS. Prueba el mapa.');
        }
        return;
      }
      if (permiso == LocationPermission.deniedForever) {
        if (mounted) {
          final abrir = await _dialogoSiNo(
            titulo: 'Permiso de ubicación',
            mensaje:
                'Antes se negó el permiso. Ábrelo en Ajustes de la app '
                '(Ubicación → Permitir) y vuelve a intentar.',
            accion: 'Ir a ajustes',
          );
          if (abrir) await Geolocator.openAppSettings();
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      final err = LogicaUbicacionLugar.mensajeErrorUbicacion(
        pos.latitude,
        pos.longitude,
      );
      if (err != null) {
        _aviso(err);
        return;
      }
      setState(() {
        _latitud = pos.latitude;
        _longitud = pos.longitude;
        _origenUbicacion = 'gps';
      });
      _aviso('Ubicación marcada');
    } on TimeoutException {
      if (mounted) {
        _aviso('Tardó demasiado el GPS. Prueba el mapa.');
      }
    } catch (e) {
      debugPrint('GPS lugar: $e');
      if (mounted) {
        _aviso('No se pudo obtener la ubicación. Prueba el mapa.');
      }
    } finally {
      if (mounted) setState(() => _ubicando = false);
    }
  }

  Future<bool> _dialogoSiNo({
    required String titulo,
    required String mensaje,
    required String accion,
  }) async {
    final r = await showDialog<bool>(
      context: context,
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
            height: 1.4,
            color: PaletaRutas.plomoClaro,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Ahora no',
              style: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              accion,
              style: TipografiaHaku.interfaz(
                fontWeight: FontWeight.w700,
                color: PaletaRutas.oro,
              ),
            ),
          ),
        ],
      ),
    );
    return r == true;
  }

  Future<bool> _confirmarSalirFormulario() async {
    return _dialogoSiNo(
      titulo: '¿Salir sin publicar?',
      mensaje:
          'Si sales ahora se pierde lo que escribiste en este formulario.',
      accion: 'Salir',
    );
  }

  Future<void> _onBackAppBar() async {
    if (_publicando) return;
    if (_paso > 0) {
      setState(() => _paso--);
      return;
    }
    final salir = await _confirmarSalirFormulario();
    if (salir && mounted) Navigator.of(context).pop();
  }

  Future<void> _elegirEnMapa() async {
    final inicial = _tieneUbicacion
        ? LatLng(_latitud!, _longitud!)
        : null;
    final elegido = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => PantallaElegirUbicacionLugar(
          inicial: inicial,
          distritoNombre: _distrito?.nombre,
          provinciaNombre: _provincia?.nombre,
        ),
      ),
    );
    if (elegido == null || !mounted) return;
    final err = LogicaUbicacionLugar.mensajeErrorUbicacion(
      elegido.latitude,
      elegido.longitude,
    );
    if (err != null) {
      _aviso(err);
      return;
    }
    setState(() {
      _latitud = elegido.latitude;
      _longitud = elegido.longitude;
      _origenUbicacion = 'mapa';
    });
  }

  Future<void> _ingresarCoordenadas() async {
    final elegido = await abrirIngresoCoordenadasLugar(
      context,
      latInicial: _latitud,
      lonInicial: _longitud,
    );
    if (elegido == null || !mounted) return;
    setState(() {
      _latitud = elegido.latitude;
      _longitud = elegido.longitude;
      _origenUbicacion = 'coords';
    });
  }

  Future<void> _finalizar() async {
    final provincia = _provincia;
    final distrito = _distrito;
    if (provincia == null) {
      _aviso('Elige una provincia');
      return;
    }
    if (distrito == null) {
      _aviso('Elige un distrito');
      return;
    }
    final errUbi = LogicaUbicacionLugar.mensajeErrorUbicacion(_latitud, _longitud);
    if (errUbi != null) {
      _aviso(errUbi);
      return;
    }
    if (!supabaseListo) {
      _aviso('Sin conexión con el servidor');
      return;
    }

    final user = clienteSupabase.auth.currentUser;
    if (user == null) {
      final ok = await asegurarSesion(context, ref);
      if (!ok || !mounted) return;
    }
    final uid = clienteSupabase.auth.currentUser?.id;
    if (uid == null) {
      _aviso('Inicia sesión para publicar');
      return;
    }

    setState(() => _publicando = true);
    try {
      final ds = ref.read(lugarRemotoDataSourceProvider);
      String? fotoUrl;
      if (_foto != null) {
        final bytes = await _foto!.readAsBytes();
        final name = _foto!.name.toLowerCase();
        final ext = name.endsWith('.png')
            ? 'png'
            : (name.endsWith('.webp') ? 'webp' : 'jpg');
        final contentType = ext == 'png'
            ? 'image/png'
            : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
        fotoUrl = await ds.subirFotoPortada(
          userId: uid,
          bytes: bytes,
          contentType: contentType,
          extension: ext,
        );
      }

      final lugar = await ds.crear(
        nombre: _nombre.text.trim(),
        descripcion: _descripcion.text.trim(),
        distritoId: distrito.id,
        categoriaIds: [
          ..._tematicaIds,
          ..._actividadIds,
        ],
        acceso: _acceso,
        fotoPortadaUrl: fotoUrl,
        latitud: _latitud!,
        longitud: _longitud!,
        altitud: null,
      );

      notificarLugaresCambiaron(ref);
      ref.read(metricasDescubrimientoProvider.notifier).registrarDescubrimiento(
            lugar.id,
            fuente: 'registrar_lugar',
          );
      bumpMetricas(ref);

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: PaletaRutas.carbon,
          title: Text(
            'Lugar publicado',
            style: TipografiaHaku.titulo(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: PaletaRutas.piedra,
            ),
          ),
          content: Text(
            'Ya aparece en ${distrito.nombre} (${provincia.nombre}).',
            style: TipografiaHaku.interfaz(
              height: 1.4,
              color: PaletaRutas.plomoClaro,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Continuar',
                style: TipografiaHaku.interfaz(
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.oro,
                ),
              ),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(lugar);
    } catch (e, st) {
      debugPrint('Registrar lugar: $e\n$st');
      if (mounted) _aviso(_mensajeError(e));
    } finally {
      if (mounted) setState(() => _publicando = false);
    }
  }

  void _aviso(String m) => mostrarSnackHaku(context, m);

  InputDecoration _campo(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomoClaro),
      hintStyle: TipografiaHaku.interfaz(color: PaletaRutas.plomo),
      filled: true,
      fillColor: PaletaRutas.carbon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: PaletaRutas.plomoOscuro.withValues(alpha: 0.55),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: PaletaRutas.plomoOscuro.withValues(alpha: 0.55),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PaletaRutas.oro, width: 1.4),
      ),
    );
  }

  TextStyle get _tituloPaso => TipografiaHaku.titulo(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: PaletaRutas.piedra,
      );

  TextStyle get _ayudaPaso => TipografiaHaku.interfaz(
        fontSize: 14,
        height: 1.35,
        color: PaletaRutas.plomoClaro,
      );

  TextStyle get _textoPaso => TipografiaHaku.interfaz(color: PaletaRutas.piedra);

  Widget _opcionAcceso(String valor) {
    final sel = _acceso == valor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: PaletaRutas.carbon,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _acceso = valor),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel
                    ? PaletaRutas.oro
                    : PaletaRutas.plomoOscuro.withValues(alpha: 0.55),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  sel ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: sel ? PaletaRutas.oro : PaletaRutas.plomo,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  valor,
                  style: TipografiaHaku.interfaz(
                    fontWeight: FontWeight.w700,
                    color: sel ? PaletaRutas.oro : PaletaRutas.piedra,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _botonUbicacion({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: PaletaRutas.carbon,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: PaletaRutas.plomoOscuro.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              Icon(icono, color: PaletaRutas.oro, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TipografiaHaku.interfaz(
                        fontWeight: FontWeight.w800,
                        color: PaletaRutas.piedra,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitulo, style: _ayudaPaso),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: PaletaRutas.plomo),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provinciasAsync = ref.watch(provinciasRemotasProvider);
    provinciasAsync.whenData(_asegurarProvinciaResuelta);

    final distritosAsync = _provincia == null
        ? const AsyncValue<List<ModeloDistritoDb>>.data([])
        : ref.watch(distritosPorProvinciaProvider(_provincia!.id));
    final categoriasAsync = ref.watch(categoriasLugarRemotasProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _publicando) return;
        if (_paso > 0) {
          setState(() => _paso--);
          return;
        }
        final nav = Navigator.of(context);
        final salir = await _confirmarSalirFormulario();
        if (!mounted) return;
        if (salir) nav.pop();
      },
      child: Scaffold(
      backgroundColor: PaletaRutas.ink,
      appBar: AppBar(
        backgroundColor: PaletaRutas.ink,
        foregroundColor: PaletaRutas.piedra,
        elevation: 0,
        leading: IconButton(
          tooltip: _paso > 0 ? 'Paso anterior' : 'Salir',
          onPressed: _onBackAppBar,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'Crear un lugar',
          style: TipografiaHaku.titulo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: PaletaRutas.piedra,
          ),
        ),
      ),
      body: FondoSuaveSeccion(
        color: PaletaRutas.ink,
        opacidadImagen: 0,
        opacidadVelo: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Paso ${_paso + 1} de $_pasos',
                  style: TipografiaHaku.interfaz(
                    fontSize: 12,
                    color: PaletaRutas.plomoClaro,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (_paso + 1) / _pasos,
                  backgroundColor:
                      PaletaRutas.plomoOscuro.withValues(alpha: 0.5),
                  color: PaletaRutas.oro,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 10),
                const LineaEncabezadoInca(altura: 2),
                const SizedBox(height: 18),
                Expanded(
                  child: _contenidoPaso(
                    provincias: provinciasAsync.asData?.value ?? const [],
                    distritos: distritosAsync.asData?.value ?? const [],
                    categorias: categoriasAsync.asData?.value ?? const [],
                    cargandoGeo: provinciasAsync.isLoading,
                    cargandoDistritos: distritosAsync.isLoading,
                    cargandoCategorias: categoriasAsync.isLoading,
                  ),
                ),
                if (_paso > 0) ...[
                  TextButton(
                    onPressed: _publicando
                        ? null
                        : () => setState(() => _paso--),
                    child: Text(
                      'Atrás',
                      style: TipografiaHaku.interfaz(
                        color: PaletaRutas.plomoClaro,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                BotonPrimarioRuta(
                  texto: _publicando
                      ? 'Publicando…'
                      : (_paso == _pasos - 1 ? 'Publicar' : 'Siguiente'),
                  onPressed: (_publicando ||
                          _ubicando ||
                          (_paso == 0 && _distrito == null) ||
                          (_paso == 1 &&
                              (_tematicaIds.isEmpty ||
                                  categoriasAsync.isLoading)))
                      ? null
                      : _siguiente,
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _contenidoPaso({
    required List<ModeloProvinciaDb> provincias,
    required List<ModeloDistritoDb> distritos,
    required List<ModeloCategoriaDb> categorias,
    required bool cargandoGeo,
    required bool cargandoDistritos,
    required bool cargandoCategorias,
  }) {
    final tematicas = categorias
        .where((c) => c.faceta == FacetaCategoriaLugar.tematica)
        .toList();
    final actividades = categorias
        .where((c) => c.faceta == FacetaCategoriaLugar.actividad)
        .toList();

    switch (_paso) {
      case 0:
        return ListView(
          children: [
            Text('El lugar', style: _tituloPaso),
            const SizedBox(height: 8),
            Text(
              'Distrito, nombre y foto si quieres.',
              style: _ayudaPaso,
            ),
            const SizedBox(height: 18),
            if (cargandoGeo)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(color: PaletaRutas.oro),
              ),
            if (_provincia != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(
                    Icons.map_outlined,
                    size: 16,
                    color: PaletaRutas.oro,
                  ),
                  label: Text(
                    _provincia!.nombre,
                    style: TipografiaHaku.interfaz(
                      fontWeight: FontWeight.w700,
                      color: PaletaRutas.piedra,
                      fontSize: 13,
                    ),
                  ),
                  backgroundColor: PaletaRutas.carbon,
                  side: BorderSide(
                    color: PaletaRutas.oro.withValues(alpha: 0.45),
                  ),
                ),
              )
            else if (provincias.isNotEmpty) ...[
              DropdownButtonFormField<int>(
                initialValue: null,
                dropdownColor: PaletaRutas.carbon,
                style: _textoPaso,
                decoration: _campo('Provincia'),
                items: provincias
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.nombre),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  final p = provincias.firstWhere((e) => e.id == id);
                  setState(() {
                    _provincia = p;
                    _distrito = null;
                  });
                },
              ),
            ] else if (!cargandoGeo)
              Text(
                'No se pudo cargar el territorio. Revisa la conexión.',
                style: _ayudaPaso,
              ),
            if (_provincia != null) ...[
              const SizedBox(height: 14),
              if (cargandoDistritos)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(color: PaletaRutas.oro),
                )
              else if (distritos.isEmpty)
                Text(
                  'No hay distritos cargados para esta provincia.',
                  style: _ayudaPaso,
                )
              else
                DropdownButtonFormField<int>(
                  key: ValueKey(
                    'dist-${_distrito?.id ?? 'none'}-${distritos.length}',
                  ),
                  initialValue: _distrito?.id,
                  dropdownColor: PaletaRutas.carbon,
                  style: _textoPaso,
                  decoration: _campo('Distrito'),
                  hint: Text(
                    'Elige un distrito',
                    style: TipografiaHaku.interfaz(color: PaletaRutas.plomo),
                  ),
                  items: distritos
                      .map(
                        (d) => DropdownMenuItem<int>(
                          value: d.id,
                          child: Text(d.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    setState(() {
                      for (final d in distritos) {
                        if (d.id == id) {
                          _distrito = d;
                          return;
                        }
                      }
                      _distrito = null;
                    });
                  },
                ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _nombre,
              style: _textoPaso,
              cursorColor: PaletaRutas.oro,
              textCapitalization: TextCapitalization.sentences,
              decoration: _campo('Nombre'),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _publicando
                  ? null
                  : () async {
                      final f = await _picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1600,
                        maxHeight: 1600,
                        imageQuality: 85,
                      );
                      if (f != null) setState(() => _foto = f);
                    },
              icon: Icon(
                _foto == null
                    ? Icons.add_a_photo_outlined
                    : Icons.check_circle_outline,
                color: PaletaRutas.oro,
              ),
              label: Text(
                _foto == null ? 'Agregar foto' : 'Foto lista',
                style: TipografiaHaku.interfaz(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: PaletaRutas.piedra,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: PaletaRutas.plomoOscuro.withValues(alpha: 0.55),
                ),
                backgroundColor: PaletaRutas.carbon,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        );

      case 1:
        return ListView(
          children: [
            Text('Clasificación', style: _tituloPaso),
            const SizedBox(height: 8),
            Text(
              'Puedes marcar varias. Al menos una temática; '
              'actividad es opcional.',
              style: _ayudaPaso,
            ),
            const SizedBox(height: 22),
            if (cargandoCategorias)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: PaletaRutas.oro),
                ),
              )
            else if (tematicas.isEmpty && actividades.isEmpty)
              Text(
                'No hay categorías cargadas. Revisa la conexión.',
                style: _ayudaPaso,
              )
            else ...[
              Text(
                '¿Qué es este lugar?',
                style: TipografiaHaku.interfaz(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.piedra,
                ),
              ),
              const SizedBox(height: 6),
              Text('Temática (una o más)', style: _ayudaPaso),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: tematicas.map((c) {
                  final activo = _tematicaIds.contains(c.id);
                  return _ChipSeleccion(
                    texto: c.nombre,
                    activo: activo,
                    onTap: () => setState(() {
                      if (activo) {
                        _tematicaIds.remove(c.id);
                      } else {
                        _tematicaIds.add(c.id);
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Text(
                '¿Qué se puede hacer?',
                style: TipografiaHaku.interfaz(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: PaletaRutas.piedra,
                ),
              ),
              const SizedBox(height: 6),
              Text('Actividad (una o más, opcional)', style: _ayudaPaso),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: actividades.map((c) {
                  final activo = _actividadIds.contains(c.id);
                  return _ChipSeleccion(
                    texto: c.nombre,
                    activo: activo,
                    onTap: () => setState(() {
                      if (activo) {
                        _actividadIds.remove(c.id);
                      } else {
                        _actividadIds.add(c.id);
                      }
                    }),
                  );
                }).toList(),
              ),
            ],
          ],
        );
      case 2:
        return ListView(
          children: [
            Text('¿Dónde está el punto?', style: _tituloPaso),
            const SizedBox(height: 8),
            Text(
              'Elige cómo marcar el lugar en el mapa. '
              'Con el distrito ya elegido, el mapa intenta acercarse solo.',
              style: _ayudaPaso,
            ),
            const SizedBox(height: 20),
            _botonUbicacion(
              icono: Icons.my_location,
              titulo: 'Usar mi ubicación',
              subtitulo: _ubicando
                  ? 'Buscando…'
                  : 'Si estás parado en el lugar ahora',
              onTap: _ubicando ? null : _usarUbicacionActual,
            ),
            const SizedBox(height: 12),
            _botonUbicacion(
              icono: Icons.map_outlined,
              titulo: 'Buscar o marcar en el mapa',
              subtitulo: _distrito == null
                  ? 'Busca un nombre o toca el mapa'
                  : 'Cerca de ${_distrito!.nombre}: busca o toca el punto',
              onTap: _ubicando ? null : _elegirEnMapa,
            ),
            const SizedBox(height: 12),
            _botonUbicacion(
              icono: Icons.pin_drop_outlined,
              titulo: 'Escribir coordenadas',
              subtitulo:
                  'Latitud y longitud exactas (avanzado; pocos lo usan)',
              onTap: _ubicando ? null : _ingresarCoordenadas,
            ),
            if (_tieneUbicacion) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PaletaRutas.carbon,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: PaletaRutas.oro.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      switch (_origenUbicacion) {
                        'gps' => 'Ubicación actual lista',
                        'coords' => 'Coordenadas listas',
                        _ => 'Punto del mapa listo',
                      },
                      style: TipografiaHaku.interfaz(
                        fontWeight: FontWeight.w800,
                        color: PaletaRutas.oro,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_latitud!.toStringAsFixed(5)}, ${_longitud!.toStringAsFixed(5)}',
                      style: TipografiaHaku.interfaz(
                        fontSize: 12,
                        color: PaletaRutas.plomoClaro,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      case 3:
        return ListView(
          children: [
            Text('¿Cómo llegaste al lugar?', style: _tituloPaso),
            const SizedBox(height: 8),
            Text(
              'Cuéntanos cómo llegaste tú (caminando, auto…).',
              style: _ayudaPaso,
            ),
            const SizedBox(height: 18),
            ...['Caminando', 'Auto', 'Transporte', 'Caballo'].map(_opcionAcceso),
          ],
        );
      default:
        return ListView(
          children: [
            Text('Descripción', style: _tituloPaso),
            const SizedBox(height: 8),
            Text(
              'Cuenta qué es este lugar. Opcional, pero ayuda a otros.',
              style: _ayudaPaso,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _descripcion,
              maxLines: 7,
              style: _textoPaso,
              cursorColor: PaletaRutas.oro,
              textCapitalization: TextCapitalization.sentences,
              decoration: _campo(
                'Describe el lugar',
                hint: 'Mirador, ruina, cascada, plaza…',
              ),
            ),
          ],
        );
    }
  }
}

class _ChipSeleccion extends StatelessWidget {
  const _ChipSeleccion({
    required this.texto,
    required this.activo,
    required this.onTap,
  });

  final String texto;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: activo
          ? PaletaRutas.oro.withValues(alpha: 0.22)
          : PaletaRutas.carbon,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: activo
                  ? PaletaRutas.oro.withValues(alpha: 0.7)
                  : PaletaRutas.plomo.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            texto,
            style: TipografiaHaku.interfaz(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: activo ? PaletaRutas.oro : PaletaRutas.plomoClaro,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> abrirRegistrarLugarFlow(
  BuildContext context,
  WidgetRef ref, {
  String? provincia,
}) async {
  final ok = await asegurarSesion(context, ref);
  if (!ok || !context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PantallaRegistrarLugar(provinciaInicial: provincia),
    ),
  );
}
